# changelog-capture.ps1
#
# Not a hook - a helper for the /changelog and /preflight skills. It answers "which capture files
# exist and which one is mine", lists every touched name grouped by place and cross-checks it against
# changelog/UNRELEASED.md, rolls the changelog, and retires a consumed file by MOVING it, never
# deleting it.
#
# CHANGELOG.md in the project root is an INDEX only - one table row per release. The prose lives in
# changelog/: UNRELEASED.md for in-flight work, YYYY-MM-DD-<release>.md for shipped ones. Coverage
# therefore reads UNRELEASED.md, which is the only file /changelog ever writes.
#
# The capture is partitioned per session by .claude/hooks/log-studio-change.ps1 because several
# agents work this project at once. The rule this script exists to enforce: an agent touches its
# own capture file and nothing else, and a retired file stays on disk until a release archives it,
# so -Coverage can still see every script the release touched.
#
#   changelog-capture.ps1                 status: my session id, every pending file, consumed count
#   changelog-capture.ps1 -Coverage       every capture file, then every touched name
#                                         grouped by place, marked SUSPECT if UNRELEASED.md never names it
#   changelog-capture.ps1 -Coverage -Mine same, restricted to this session's own capture
#   changelog-capture.ps1 -Retire         move MY pending file to .changelog/consumed/
#   changelog-capture.ps1 -Retire -All    move EVERY pending file to .changelog/consumed/
#   changelog-capture.ps1 -Archive "Update 1"   move .changelog/consumed/* to archive/<release>/
#   changelog-capture.ps1 -Roll "Hotfix 3.3"    rename UNRELEASED.md into the dated release file,
#                                         write its header, link it from the previous release, drop a
#                                         fresh UNRELEASED.md and add the index row
#   changelog-capture.ps1 -SyncIndex      copy Published / Data-affecting / Summary from the newest
#                                         release file into its index row in CHANGELOG.md
#
# KEEP THIS FILE PURE ASCII. Windows PowerShell 5.1 reads a BOM-less .ps1 as CP1252, where an
# em-dash decodes to a smart quote - which the parser accepts as a string delimiter, so one
# em-dash inside a string literal breaks the whole file with errors pointing at unrelated lines.
# The changelog's own em-dashes and middle dots are built from [char] codes for that reason, and
# every changelog file is read and written as BOM-less UTF-8 through .NET, never Get-Content.

param(
    [switch]$Retire,
    [switch]$All,
    [switch]$Coverage,
    [switch]$Mine,
    [string]$Archive,
    [string]$Roll,
    [switch]$SyncIndex
)

$ErrorActionPreference = 'Stop'

$root = $env:CLAUDE_PROJECT_DIR
if (-not $root) { $root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot) }

$base     = Join-Path $root '.changelog'
$pendDir  = Join-Path $base 'pending'
$consDir  = Join-Path $base 'consumed'
$archDir  = Join-Path $base 'archive'

$session = [string]$env:CLAUDE_CODE_SESSION_ID
$session = $session -replace '[^A-Za-z0-9_-]', ''
if (-not $session) { $session = 'unknown' }

$utf8 = New-Object System.Text.UTF8Encoding($false)

function Get-LineCount($file) {
    if (-not (Test-Path $file)) { return 0 }
    $m = Get-Content -LiteralPath $file -ErrorAction SilentlyContinue | Measure-Object -Line
    return $m.Lines
}

function Show-Path($file) {
    $p = [string]$file
    if ($p.StartsWith($root)) { $p = $p.Substring($root.Length).TrimStart('\', '/') }
    return ($p -replace '\\', '/')
}

function Get-CaptureFiles {
    $out = @()
    if (Test-Path $pendDir) { $out += @(Get-ChildItem -LiteralPath $pendDir -Filter *.jsonl -ErrorAction SilentlyContinue) }
    if (Test-Path $consDir) { $out += @(Get-ChildItem -LiteralPath $consDir -Filter *.jsonl -ErrorAction SilentlyContinue) }
    $legacyFile = Join-Path $base 'pending.jsonl'
    if (Test-Path $legacyFile) { $out += @(Get-Item -LiteralPath $legacyFile) }
    return $out
}

# A file whose every line edits GameEnvironment is a version bump, not work: it needs no changelog entry.
function Test-BumpOnly($file) {
    $lines = @(Get-Content -LiteralPath $file -ErrorAction SilentlyContinue | Where-Object { $_.Trim() })
    if ($lines.Count -eq 0) { return $false }
    $nonBump = @($lines | Where-Object { $_ -notmatch 'GameEnvironment' })
    return ($nonBump.Count -eq 0)
}

function Read-Text($path) {
    return ([System.IO.File]::ReadAllText($path, $utf8) -replace "`r`n", "`n")
}

function Write-Text($path, $text) {
    [System.IO.File]::WriteAllText($path, $text, $utf8)
}

function Write-PendingLeftovers {
    # An archive is the last act of a release, so anything still in pending/ at that moment is
    # either another pane's live work (fine, leave it alone) or a capture THIS release created
    # after the sweep - which in practice means the /preflight Step 6 version bump. A stranded
    # bump outlives the release and resurfaces at the next one as a two-line capture naming only
    # GameEnvironment, from a session nobody recognises. Name it here rather than let it rot.
    if (-not (Test-Path $pendDir)) { return }
    $left = @(Get-ChildItem -LiteralPath $pendDir -Filter *.jsonl -ErrorAction SilentlyContinue)
    if ($left.Count -eq 0) { return }

    Write-Output ""
    Write-Output ("NOTE: " + $left.Count + " file(s) still in pending/, NOT archived:")
    $anyBump = $false
    foreach ($f in $left) {
        $tag = ""
        if ($f.BaseName -eq $session) { $tag = "  MINE" }
        if (Test-BumpOnly $f.FullName) {
            $anyBump = $true
            $tag = $tag + "  <- version bump only"
        }
        Write-Output ("  " + (Show-Path $f.FullName) + "  " + (Get-LineCount $f.FullName) + " lines" + $tag)
    }
    if ($anyBump) {
        Write-Output "A bump-only file is this release's own version bump. Run -Retire then re-run"
        Write-Output "-Archive with the SAME release name, or it strands into the next release."
    }
    Write-Output "Another pane's in-progress capture is fine to leave here."
}

# ---------------------------------------------------------------------------------------------
# Index helpers, shared by -Roll and -SyncIndex
# ---------------------------------------------------------------------------------------------

$dash = [string][char]0x2014
$dot  = [string][char]0x00B7

# Returns @{ Lines; Sep; Name; File; Published } for the first data row of the release table.
function Get-IndexTop {
    $indexPath = Join-Path $root 'CHANGELOG.md'
    $lines = (Read-Text $indexPath) -split "`n"
    # Anchor on the release table's own header row: "Where to look" above it is a table too.
    $sep = -1
    for ($i = 0; $i -lt $lines.Length - 1; $i++) {
        if ($lines[$i] -match '^\| Release \| Date \| Published \|' -and $lines[$i + 1] -match '^\|---\|') { $sep = $i + 1; break }
    }
    if ($sep -lt 0) { throw "CHANGELOG.md: no '| Release | Date | Published |' table header found" }
    $top = $lines[$sep + 1]
    if ($top -notmatch '^\| \[([^\]]+)\]\(changelog/([^)]+)\) \| ([^|]+) \| (.+?) \| (.+?) \| (.*) \|\s*$') {
        throw ("CHANGELOG.md: cannot parse the top release row: " + $top)
    }
    return @{
        Path = $indexPath; Lines = $lines; Row = ($sep + 1)
        Name = $Matches[1]; File = $Matches[2]; Date = $Matches[3].Trim()
        Published = $Matches[4].Trim(); DataAffecting = $Matches[5].Trim(); Summary = $Matches[6].Trim()
    }
}

# ---------------------------------------------------------------------------------------------

if ($Coverage) {
    # Every capture file with its owner and age, then every touched name
    # grouped by place, cross-checked against the prose in changelog/UNRELEASED.md. Catches a session
    # that was never curated AND one that was curated thinly - the second is invisible to every other
    # gate, because retiring a file is what marks it "described" and nothing else reads the prose.
    #
    # This reports SUSPECTS, not failures. Good changelog prose describes the change in player
    # terms ("the Collection menu stays deaf on join"), not by script name, so an unmentioned name
    # is frequently the correct write-up. Confirm each one; never let it push script names into
    # the entries, which would make the changelog worse to serve a checker.
    $chg = Join-Path $root 'changelog\UNRELEASED.md'
    if (-not (Test-Path $chg)) {
        throw "changelog/UNRELEASED.md not found at $chg. The root CHANGELOG.md is an index only; /changelog writes the prose into changelog/UNRELEASED.md."
    }

    # Everything above the first '---' rule is boilerplate - title, concurrency warning, nav links.
    # Counting it as prose would let a nav link ("Hotfix 4", "Conventions") mark a script as named.
    # NOT $all: PowerShell variable names are case-insensitive, so it collides with the -All switch
    # parameter and throws on assigning an array to a SwitchParameter. Same trap as $mine below.
    $srcLines = (Read-Text $chg) -split "`n"
    $section = New-Object System.Collections.Generic.List[string]
    $started = $false
    foreach ($l in $srcLines) {
        if (-not $started) {
            if ($l -match '^---\s*$') { $started = $true }
            continue
        }
        $section.Add([string]$l)
    }
    if (-not $started) { foreach ($l in $srcLines) { $section.Add([string]$l) } }
    $prose = ($section -join "`n").ToLowerInvariant()

    $files = @(Get-CaptureFiles)
    if ($Mine) {
        # pending/<session>.jsonl and consumed/<session>-<stamp>.jsonl both start with the id.
        # Without this, /changelog reports every other pane's uncurated work as your suspect.
        $files = @($files | Where-Object { $_.BaseName.StartsWith($session) })
        if ($files.Count -eq 0) { Write-Output ("no capture for this session (" + $session + ")"); exit 0 }
    }
    if ($files.Count -eq 0) { Write-Output "no capture files, nothing to cross-check"; exit 0 }

    # Capture lines carry the tool's instance_id - a per-Studio-process id - plus, since the hook
    # learned it, a placeName resolved from get_connected_instances. Older lines fall back to the
    # shared map the hook keeps, then to the raw id.
    $instMap = @{}
    $mapPath = Join-Path $base 'instances.json'
    if (Test-Path $mapPath) {
        try {
            $obj = (Read-Text $mapPath) | ConvertFrom-Json
            foreach ($p in $obj.PSObject.Properties) { $instMap[$p.Name] = [string]$p.Value }
        } catch { }
    }

    Write-Output ("=== capture summary: " + $files.Count + " capture file(s), " + $prose.Length + " chars of UNRELEASED.md prose ===")
    foreach ($f in ($files | Sort-Object LastWriteTime)) {
        $state = 'consumed'
        if ($f.DirectoryName -eq $pendDir) { $state = 'pending ' }
        if ($f.Name -eq 'pending.jsonl') { $state = 'legacy  ' }
        $owner = 'other'
        if ($f.BaseName.StartsWith($session)) { $owner = 'MINE ' }
        $tag = ''
        if (Test-BumpOnly $f.FullName) { $tag = '  <- version bump only (no entry needed)' }
        Write-Output ("  " + $state + "  " + $owner + "  " + (Get-LineCount $f.FullName).ToString().PadLeft(4) + " lines  last " + $f.LastWriteTime.ToString('yyyy-MM-dd HH:mm') + "  " + $f.Name + $tag)
    }

    $scriptTools = @('set_script_source', 'edit_script_lines', 'insert_script_lines', 'delete_script_lines', 'find_and_replace_in_scripts')
    $counts = @{}

    foreach ($f in $files) {
        foreach ($line in (Get-Content -LiteralPath $f.FullName -Encoding UTF8 -ErrorAction SilentlyContinue)) {
            if ([string]::IsNullOrWhiteSpace($line)) { continue }
            $e = $null
            try { $e = $line | ConvertFrom-Json } catch { continue }

            $t = [string]$e.target
            if (-not $t -or $t -eq '(unspecified)') { $t = '(unspecified ' + [string]$e.tool + ')' }
            $parts = $t.Split('.')

            $place = [string]$e.placeName
            if (-not $place) {
                $raw = [string]$e.place
                if ($instMap.ContainsKey($raw)) { $place = $instMap[$raw] }
                elseif ($raw) { $place = $raw }
                else { $place = '(unknown)' }
            }

            if ($scriptTools -contains [string]$e.tool) {
                # A script edit names the script itself; the leaf of the path is what to look for.
                $kind = 'script'
                $n = $parts[$parts.Length - 1]
            } else {
                # Property and instance churn collapses to one changelog line per panel, so
                # tracking every Frame and UIStroke would bury the signal. Roll up to the subtree.
                $kind = 'subtree'
                $n = $parts[$parts.Length - 1]
                if ($parts.Length -ge 3) { $n = $parts[2] }
            }
            $key = $place + '|' + $kind + '|' + $n
            if ($counts.ContainsKey($key)) { $counts[$key]++ } else { $counts[$key] = 1 }
        }
    }

    $rows = @()
    foreach ($k in $counts.Keys) {
        $bits = $k.Split('|')
        $rows += [pscustomobject]@{
            Place = $bits[0]; Kind = $bits[1]; Name = $bits[2]; Count = $counts[$k]
            Named = $prose.Contains($bits[2].ToLowerInvariant())
        }
    }

    foreach ($pl in ($rows | Select-Object -ExpandProperty Place -Unique | Sort-Object)) {
        $pr = @($rows | Where-Object { $_.Place -eq $pl })
        $sus = @($pr | Where-Object { -not $_.Named }).Count
        Write-Output ""
        Write-Output ("--- " + $pl + ": " + $pr.Count + " name(s), " + $sus + " SUSPECT ---")
        $sorted = $pr | Sort-Object @{ Expression = { $_.Named } }, @{ Expression = { $_.Kind } }, @{ Expression = { $_.Count }; Descending = $true }
        foreach ($r in $sorted) {
            $flag = 'named  '
            if (-not $r.Named) { $flag = 'SUSPECT' }
            Write-Output ("  " + $flag + "  " + $r.Kind.PadRight(7) + "  " + $r.Name.PadRight(36) + $r.Count.ToString().PadLeft(4))
        }
    }

    Write-Output ""
    Write-Output "SUSPECT = the name appears nowhere in UNRELEASED.md. Prose that describes the change"
    Write-Output "in player terms is often right - confirm each, do not force script names into entries."
    Write-Output "Never captured at all: execute_luau mutations and edits made by hand in Studio."
    exit 0
}

if ($Roll) {
    # The mechanical half of /preflight Step 5, which used to be five hand edits: rename
    # UNRELEASED.md to the dated release file, swap its header, link it from the previous release,
    # drop a fresh UNRELEASED.md, add the index row. Everything that needs judgement - Summary,
    # Shared modules, Profile schema - is left as TBD for the caller to fill, then -SyncIndex.
    $chgDir = Join-Path $root 'changelog'
    $unrel = Join-Path $chgDir 'UNRELEASED.md'
    if (-not (Test-Path $unrel)) { throw "changelog/UNRELEASED.md not found - nothing to roll" }

    $top = Get-IndexTop
    if ($top.Name -eq $Roll) { throw ("'" + $Roll + "' is already the newest release in CHANGELOG.md") }
    if ($top.Published -match 'rTBD') {
        throw ("The previous release '" + $top.Name + "' has no recorded place versions (" + $top.Published + "). Record them first (Step 9): the new entry's rollback target is those numbers.")
    }
    $prevPublished = $top.Published.Trim('`')

    $date = (Get-Date).ToString('yyyy-MM-dd')
    $slug = ($Roll.ToLowerInvariant() -replace '[^a-z0-9]+', '-').Trim('-')
    if (-not $slug) { throw "Release name '$Roll' has no usable characters." }
    $fileName = $date + '-' + $slug + '.md'
    $dest = Join-Path $chgDir $fileName
    if (Test-Path $dest) { throw ("changelog/" + $fileName + " already exists") }

    # Rename FIRST, then read from the new path: an Edit another pane lands on UNRELEASED.md in the
    # meantime is either inside what we read or fails on a missing file - never silently dropped.
    Move-Item -LiteralPath $unrel -Destination $dest
    $lines = (Read-Text $dest) -split "`n"

    $rules = @()
    for ($i = 0; $i -lt $lines.Length; $i++) { if ($lines[$i] -match '^---\s*$') { $rules += $i } }
    if ($rules.Count -lt 1) { throw "UNRELEASED.md has no '---' rule under its header - roll it by hand" }
    $r1 = $rules[0]
    $header = @(); if ($r1 -gt 0) { $header = $lines[0..($r1 - 1)] }

    # The metadata block sits between the first two rules, as bullets; a section heading there means
    # the file has no block and the body starts at the first rule.
    $meta = @()
    $bodyStart = $r1
    if ($rules.Count -ge 2) {
        $between = @(); if ($rules[1] - $r1 -gt 1) { $between = $lines[($r1 + 1)..($rules[1] - 1)] }
        if (-not ($between | Where-Object { $_ -match '^## ' })) { $meta = $between; $bodyStart = $rules[1] }
    }
    $body = $lines[$bodyStart..($lines.Length - 1)]

    # Carry the running bullets (continuation lines included) keyed by field name.
    $fields = [ordered]@{}
    $cur = $null
    foreach ($l in $meta) {
        if ($l -match '^- \*\*([^:*]+):\*\*') { $cur = $Matches[1]; $fields[$cur] = @($l) }
        elseif ($cur -and $l.Trim()) { $fields[$cur] += $l }
    }
    function Get-Bullet($field, $fallback) {
        if ($fields.Contains($field)) { return ($fields[$field] -join "`n") }
        return ('- **' + $field + ':** ' + $fallback)
    }

    $out = New-Object System.Collections.Generic.List[string]
    $out.Add('# ' + $Roll + ' ' + $dash + ' ' + $date)
    $out.Add('')
    $out.Add('**Summary:** TBD')
    $out.Add('')
    $out.Add('[Index](../CHANGELOG.md) ' + $dot + ' [Conventions](CONVENTIONS.md) ' + $dot + ' Previous: [' + $top.Name + '](' + $top.File + ')')
    $out.Add('')
    $out.Add('---')
    $out.Add('')
    $out.Add('- **Published:** `Bounty rTBD ' + $dot + ' Redwater rTBD ' + $dot + ' Frostbite rTBD`')
    $out.Add('- **Rollback target:** `' + $prevPublished + '` (' + $top.Name + ') ' + $dash + ' revert **all three** places.')
    $out.Add((Get-Bullet 'Shared modules' 'TBD'))
    $out.Add((Get-Bullet 'Profile schema' 'TBD'))
    $out.Add((Get-Bullet 'Data-affecting' 'TBD'))
    foreach ($k in $fields.Keys) {
        if (@('Published', 'Rollback target', 'Shared modules', 'Profile schema', 'Data-affecting') -notcontains $k) {
            $out.Add(($fields[$k] -join "`n"))
        }
    }
    $out.Add('')
    foreach ($l in $body) { $out.Add($l) }
    Write-Text $dest ($out -join "`n")
    Write-Output ("renamed   changelog/UNRELEASED.md  ->  changelog/" + $fileName + "  (header written)")

    # Fresh UNRELEASED.md: the same header, its Previous link pointed at the release just rolled.
    $fresh = New-Object System.Collections.Generic.List[string]
    foreach ($l in $header) {
        if ($l -match '^\[Index\]\(\.\./CHANGELOG\.md\)') {
            $fresh.Add('[Index](../CHANGELOG.md) ' + $dot + ' [Conventions](CONVENTIONS.md) ' + $dot + ' Previous release: [' + $Roll + '](' + $fileName + ')')
        } else { $fresh.Add($l) }
    }
    foreach ($l in @('---', '', '- **Shared modules:** none yet.', '- **Data-affecting:** no.', '', '---', '', '## Added', '', '## Changed', '', '## Fixed', '')) { $fresh.Add($l) }
    Write-Text $unrel ($fresh -join "`n")
    Write-Output "created   changelog/UNRELEASED.md  (fresh, no entries)"

    # Previous release: add or repoint its Next link. The only edit a shipped file ever takes
    # besides its Published versions.
    $prevPath = Join-Path $chgDir $top.File
    if (Test-Path $prevPath) {
        $pl = (Read-Text $prevPath) -split "`n"
        for ($i = 0; $i -lt $pl.Length; $i++) {
            if ($pl[$i] -match '^\[Index\]\(\.\./CHANGELOG\.md\)') {
                $nav = $pl[$i] -replace (' ' + [regex]::Escape($dot) + ' Next: \[[^\]]*\]\([^)]*\)'), ''
                $pl[$i] = $nav + ' ' + $dot + ' Next: [' + $Roll + '](' + $fileName + ')'
                break
            }
        }
        Write-Text $prevPath ($pl -join "`n")
        Write-Output ("linked    changelog/" + $top.File + "  Next -> " + $fileName)
    } else {
        Write-Output ("WARNING: previous release file changelog/" + $top.File + " not found; its Next link was not written")
    }

    # Index row. A read-modify-write of CHANGELOG.md lasting milliseconds - the same exposure as an
    # anchored Edit, and the separator row it anchors on is checked just above.
    $da = 'TBD'
    $daText = Get-Bullet 'Data-affecting' 'TBD'
    if ($daText -match '^- \*\*Data-affecting:\*\*\s*no\b') { $da = 'no' }
    elseif ($daText -match '^- \*\*Data-affecting:\*\*\s*yes\b') { $da = '**yes**' }
    $row = '| [' + $Roll + '](changelog/' + $fileName + ') | ' + $date + ' | `Bounty rTBD ' + $dot + ' Redwater rTBD ' + $dot + ' Frostbite rTBD` | ' + $da + ' | TBD |'
    $idx = Get-IndexTop
    $newIdx = New-Object System.Collections.Generic.List[string]
    for ($i = 0; $i -lt $idx.Lines.Length; $i++) {
        if ($i -eq $idx.Row) { $newIdx.Add($row) }
        $newIdx.Add($idx.Lines[$i])
    }
    Write-Text $idx.Path ($newIdx -join "`n")
    Write-Output ("indexed   CHANGELOG.md  row added for " + $Roll)
    Write-Output ""
    Write-Output ("TO FILL in changelog/" + $fileName + ": Summary, Shared modules (after the Step 6 bump), Profile schema, Data-affecting.")
    Write-Output "Then run -SyncIndex to copy them into the index row."
    exit 0
}

if ($SyncIndex) {
    # The release file is the one home for Published, Data-affecting and Summary; the index row is
    # derived from it. Run after filling the header at Step 5 and after recording versions at Step 9.
    $top = Get-IndexTop
    $relPath = Join-Path (Join-Path $root 'changelog') $top.File
    if (-not (Test-Path $relPath)) { throw ("changelog/" + $top.File + " not found") }
    $rel = (Read-Text $relPath) -split "`n"

    $summary = $null; $published = $null; $da = $null
    foreach ($l in $rel) {
        if (-not $summary -and $l -match '^\*\*Summary:\*\*\s*(.+)$') { $summary = $Matches[1].Trim() }
        if (-not $published -and $l -match '^- \*\*Published:\*\*\s*(`[^`]+`)') { $published = $Matches[1] }
        if (-not $da -and $l -match '^- \*\*Data-affecting:\*\*\s*(\S+)') { $da = $Matches[1].ToLowerInvariant().TrimEnd('.', ',', ';') }
    }
    if (-not $summary -or -not $published -or -not $da) {
        throw ("changelog/" + $top.File + ": could not read all of Summary / Published / Data-affecting from the header")
    }
    if ($summary.Contains('|')) { throw "Summary contains '|', which would break the index table" }

    $daCell = $top.DataAffecting
    if ($da -eq 'no') { $daCell = 'no' }
    elseif ($da -like 'yes*' -or $da -like '**yes*') {
        if ($daCell -notlike '**yes*') { $daCell = '**yes**' }  # keep a hand-written "**yes - one-way**"
    }
    else { $daCell = 'TBD' }

    $row = '| [' + $top.Name + '](changelog/' + $top.File + ') | ' + $top.Date + ' | ' + $published + ' | ' + $daCell + ' | ' + $summary + ' |'
    $lines = $top.Lines
    if ($lines[$top.Row] -eq $row) { Write-Output ("index row for " + $top.Name + " already in sync"); exit 0 }
    $lines[$top.Row] = $row
    Write-Text $top.Path ($lines -join "`n")
    Write-Output ("synced    CHANGELOG.md row for " + $top.Name + ": " + $published + " | " + $daCell)
    if ($summary -eq 'TBD' -or $daCell -eq 'TBD') {
        Write-Output "still TBD - fill Summary / Data-affecting in the release header and run -SyncIndex again"
    } elseif ($published -match 'rTBD') {
        Write-Output "Published is rTBD until the user publishes - record the versions (Step 9), then -SyncIndex again"
    }
    exit 0
}

if ($Archive) {
    $slug = ($Archive -replace '[^A-Za-z0-9]+', '-').Trim('-')
    if (-not $slug) { throw "Archive name '$Archive' has no usable characters." }
    $dest = Join-Path $archDir $slug
    if (-not (Test-Path $consDir)) { Write-Output "nothing to archive (no consumed/)"; Write-PendingLeftovers; exit 0 }
    $files = @(Get-ChildItem -LiteralPath $consDir -Filter *.jsonl -ErrorAction SilentlyContinue)
    if ($files.Count -eq 0) { Write-Output "nothing to archive (consumed/ is empty)"; Write-PendingLeftovers; exit 0 }
    if (-not (Test-Path $dest)) { New-Item -ItemType Directory -Path $dest -Force | Out-Null }
    foreach ($f in $files) {
        Move-Item -LiteralPath $f.FullName -Destination (Join-Path $dest $f.Name) -Force
        Write-Output ("archived  " + $f.Name + "  ->  " + (Show-Path $dest))
    }
    Write-Output ("archived " + $files.Count + " file(s) under release '" + $Archive + "'")
    Write-PendingLeftovers
    exit 0
}

if ($Retire) {
    # Collect the file set FIRST and bail only on an empty set. An earlier version guarded this
    # whole block on pending/ existing, which made the legacy pickup below unreachable in the one
    # state it was written for - a pre-partition capture, where pending/ has never been created.
    # The sweep then printed a clean "nothing to retire", the release rolled without that capture,
    # and the next sweep re-curated the same lines into a duplicate of entries already published.
    $legacyFile = Join-Path $base 'pending.jsonl'
    $files = @()

    if ($All) {
        if (Test-Path $pendDir) {
            $files += @(Get-ChildItem -LiteralPath $pendDir -Filter *.jsonl -ErrorAction SilentlyContinue)
        }
        # The pre-partition capture belongs to no session, so only a sweep can ever claim it.
        if (Test-Path $legacyFile) { $files += @(Get-Item -LiteralPath $legacyFile) }
        if ($files.Count -eq 0) {
            Write-Output "nothing to retire: pending/ is empty or absent, and there is no legacy pending.jsonl"
            exit 0
        }
    } else {
        # NOT $mine: PowerShell variable names are case-insensitive, so it would collide with the
        # -Mine switch parameter and throw on assigning a string to a SwitchParameter.
        $myFile = Join-Path $pendDir ($session + '.jsonl')
        if (-not (Test-Path $myFile)) {
            Write-Output ("nothing to retire: no capture for this session (" + $session + ")")
            Write-Output "other sessions' files were left alone. Use -All only when sweeping for a release."
            if (Test-Path $legacyFile) {
                Write-Output "NOTE: a legacy pending.jsonl is present. It belongs to no session, so only -All claims it."
            }
            exit 0
        }
        $files = @(Get-Item -LiteralPath $myFile)
    }

    if (-not (Test-Path $consDir)) { New-Item -ItemType Directory -Path $consDir -Force | Out-Null }

    $stamp = (Get-Date).ToUniversalTime().ToString('yyyyMMddTHHmmssZ')
    foreach ($f in $files) {
        $lines = Get-LineCount $f.FullName
        $name = $f.BaseName + '-' + $stamp + '.jsonl'
        Move-Item -LiteralPath $f.FullName -Destination (Join-Path $consDir $name) -Force
        Write-Output ("retired   " + $f.Name + "  (" + $lines + " lines)  ->  consumed/" + $name)
    }
    Write-Output "nothing was deleted; -Coverage still reads consumed/ until /preflight archives it."

    # A sweep that silently leaves something behind is the exact failure above, and it looks like
    # success. Assert instead: anything still claimable after -All gets named, and the exit code
    # is non-zero so a release flow stops on it.
    if ($All) {
        $left = @()
        if (Test-Path $pendDir) {
            $left += @(Get-ChildItem -LiteralPath $pendDir -Filter *.jsonl -ErrorAction SilentlyContinue)
        }
        if (Test-Path $legacyFile) { $left += @(Get-Item -LiteralPath $legacyFile) }
        if ($left.Count -gt 0) {
            Write-Output ""
            Write-Output ("WARNING: the sweep left " + $left.Count + " capture file(s) unclaimed:")
            foreach ($f in $left) { Write-Output ("  " + (Show-Path $f.FullName)) }
            Write-Output "An agent writing during the sweep is the benign cause; either way this is uncurated"
            Write-Output "work. Curate it before rolling - a leftover comes back as a duplicate entry later."
            exit 1
        }
    }
    exit 0
}

# Default: status only. Never mutates.
Write-Output ("session   " + $session)

$pending = @()
if (Test-Path $pendDir) {
    $pending = @(Get-ChildItem -LiteralPath $pendDir -Filter *.jsonl -ErrorAction SilentlyContinue | Sort-Object Name)
}

if ($pending.Count -eq 0) {
    Write-Output "pending   (none)"
} else {
    foreach ($f in $pending) {
        $owner = "other session"
        if ($f.BaseName -eq $session) { $owner = "MINE" }
        Write-Output ("pending   " + (Show-Path $f.FullName) + "  " + (Get-LineCount $f.FullName) + " lines  " + $owner + "  last " + $f.LastWriteTime.ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ'))
    }
}

# A stray pre-partition capture. Kept visible so it cannot rot unnoticed; it belongs to nobody.
$legacy = Join-Path $base 'pending.jsonl'
if (Test-Path $legacy) {
    Write-Output ("legacy    .changelog/pending.jsonl  " + (Get-LineCount $legacy) + " lines  (pre-partition, unowned)")
}

$consumed = @()
if (Test-Path $consDir) {
    $consumed = @(Get-ChildItem -LiteralPath $consDir -Filter *.jsonl -ErrorAction SilentlyContinue)
}
$total = 0
foreach ($f in $consumed) { $total += (Get-LineCount $f.FullName) }
Write-Output ("consumed  " + $consumed.Count + " file(s), " + $total + " lines  (curated, awaiting release archive)")
