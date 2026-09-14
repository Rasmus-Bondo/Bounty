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
#   changelog-capture.ps1                 digest of MY pending capture: touched scripts and subtrees
#                                         grouped by place, with tool counts and flags. /changelog reads
#                                         this instead of the raw .jsonl, which is ~10x the tokens
#   changelog-capture.ps1 -All            the same digest over EVERY pending file (the release sweep)
#   changelog-capture.ps1 -Add <file>     insert <file>'s '## Section' bullets and Shared modules /
#                                         Data-affecting bullets into UNRELEASED.md, without anyone
#                                         having to Read a file that reaches 200 KB by release time
#   changelog-capture.ps1 -Add <file> -Retire   ...then print my SUSPECTS and retire my capture
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
#   changelog-capture.ps1 -GitHubRelease  cut the GitHub release for the newest index row, body derived
#                                         from its release file, then verify it (-Preview: print only)
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
    [switch]$SyncIndex,
    [string]$Add,
    [switch]$GitHubRelease,
    [switch]$Preview
)
# PowerShell variable names are case-insensitive, so no local may be called $add, $all, $mine,
# $preview or $retire: assigning to one rebinds the parameter and throws on the type mismatch.

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

# Capture lines carry the tool's instance_id - a per-Studio-process id - plus, since the hook learned
# it, a placeName resolved from get_connected_instances. Older lines fall back to the shared map the
# hook keeps, then to the raw id.
function Get-InstanceMap {
    $map = @{}
    $mapPath = Join-Path $base 'instances.json'
    if (Test-Path $mapPath) {
        try {
            $obj = (Read-Text $mapPath) | ConvertFrom-Json
            foreach ($p in $obj.PSObject.Properties) { $map[$p.Name] = [string]$p.Value }
        } catch { }
    }
    return $map
}

function Get-PlaceName($e, $instMap) {
    $place = [string]$e.placeName
    if ($place) { return $place }
    $raw = [string]$e.place
    if ($instMap.ContainsKey($raw)) { return $instMap[$raw] }
    if ($raw) { return $raw }
    return '(unknown)'
}

# UNRELEASED.md below its first '---' rule, lowercased. Everything above that rule is boilerplate -
# title, concurrency warning, nav links - and counting it would let a nav link ("Hotfix 4",
# "Conventions") mark a script as named.
function Get-UnreleasedProse {
    $chg = Join-Path $root 'changelog\UNRELEASED.md'
    if (-not (Test-Path $chg)) { return $null }
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
    return ($section -join "`n").ToLowerInvariant()
}

# The universe-mirrored module names, parsed out of the gate module instead of kept here as one more
# copy of the list: PreflightGates.luau is the copy that actually compares, so it is the one that is right.
function Get-MirroredModules {
    $set = @{}
    $gate = Join-Path $root '.claude\skills\preflight\PreflightGates.luau'
    if (-not (Test-Path $gate)) { return $set }
    $src = Read-Text $gate
    $i = $src.IndexOf('tier == "universe"')
    if ($i -lt 0) { return $set }
    $j = $src.IndexOf('return roots', $i)
    if ($j -lt 0) { return $set }
    $block = [regex]::Replace($src.Substring($i, $j - $i), '--[^\n]*', '')
    $list = [regex]::Match($block, 'ipairs\(\{([^}]*)\}\)')
    if ($list.Success) {
        foreach ($m in [regex]::Matches($list.Groups[1].Value, '"([A-Za-z0-9_]+)"')) { $set[$m.Groups[1].Value] = $true }
    }
    foreach ($m in [regex]::Matches($block, 'add\("[^"]*/([A-Za-z0-9_]+)"')) { $set[$m.Groups[1].Value] = $true }
    return $set
}

function Show-UnreleasedState {
    $chg = Join-Path $root 'changelog\UNRELEASED.md'
    if (-not (Test-Path $chg)) { Write-Output "UNRELEASED.md  not found"; return }
    $parts = @(); $meta = @(); $cur = $null; $n = 0
    foreach ($l in ((Read-Text $chg) -split "`n")) {
        if ($l -match '^## (.+?)\s*$') {
            if ($cur) { $parts += ($cur + ' ' + $n) }
            $cur = $Matches[1]; $n = 0; continue
        }
        if ($cur -and $l -match '^- ') { $n++ }
        if (-not $cur -and $l -match '^- \*\*(Shared modules|Data-affecting):\*\*\s*(.*)$') {
            $v = $Matches[2]
            if ($v.Length -gt 60) { $v = $v.Substring(0, 60) + '...' }
            $meta += ($Matches[1] + ': ' + $v)
        }
    }
    if ($cur) { $parts += ($cur + ' ' + $n) }
    Write-Output ("UNRELEASED.md  bullets: " + ($parts -join ', ') + "  |  " + ($meta -join '  |  '))
}

# What /changelog curates from: touched scripts (full path) and instance subtrees (first two segments)
# grouped by place, with per-tool counts. Replaces reading the raw .jsonl, which runs to 80 KB for a
# busy session and says the same thing one line per tool call.
function Show-Digest([bool]$everyone) {
    $files = @()
    if (Test-Path $pendDir) { $files = @(Get-ChildItem -LiteralPath $pendDir -Filter *.jsonl -ErrorAction SilentlyContinue | Sort-Object Name) }
    $otherCount = @($files | Where-Object { $_.BaseName -ne $session }).Count
    if (-not $everyone) { $files = @($files | Where-Object { $_.BaseName -eq $session }) }
    $legacyFile = Join-Path $base 'pending.jsonl'
    if ($everyone -and (Test-Path $legacyFile)) { $files += @(Get-Item -LiteralPath $legacyFile) }

    Write-Output ("session  " + $session)
    if (-not $everyone -and (Test-Path $legacyFile)) { Write-Output "NOTE     a legacy .changelog/pending.jsonl belongs to no session - only a release sweep (-All) takes it" }
    if ($files.Count -eq 0) {
        if ($everyone) { Write-Output "pending  (none) - nothing to sweep" }
        else {
            Write-Output "pending  no capture for this session"
            if ($otherCount -gt 0) { Write-Output ("         " + $otherCount + " other session file(s) pending - not yours; only a release sweep (-All) takes them") }
        }
        Show-UnreleasedState
        return
    }
    foreach ($f in $files) {
        $owner = 'other session'
        if ($f.BaseName -eq $session) { $owner = 'MINE' }
        if ($f.Name -eq 'pending.jsonl') { $owner = 'legacy, unowned' }
        $tag = ''
        if (Test-BumpOnly $f.FullName) { $tag = '  <- version bump only, no entry needed' }
        Write-Output ("file     " + (Show-Path $f.FullName) + "  " + (Get-LineCount $f.FullName) + " lines  " + $owner + $tag)
    }

    $instMap = Get-InstanceMap
    $mirrored = Get-MirroredModules
    $prose = Get-UnreleasedProse
    $scriptTools = @('set_script_source', 'edit_script_lines', 'insert_script_lines', 'delete_script_lines', 'find_and_replace_in_scripts')
    $short = @{
        edit_script_lines = 'edit'; insert_script_lines = 'insert'; delete_script_lines = 'delete'
        set_script_source = 'source'; find_and_replace_in_scripts = 'replace'; set_properties = 'props'
        import_rbxm = 'import'; insert_asset = 'asset'; generate_model = 'model'
    }
    $groups = @{}
    $first = $null; $last = $null
    foreach ($f in $files) {
        foreach ($line in (Get-Content -LiteralPath $f.FullName -Encoding UTF8 -ErrorAction SilentlyContinue)) {
            if ([string]::IsNullOrWhiteSpace($line)) { continue }
            $e = $null
            try { $e = $line | ConvertFrom-Json } catch { continue }
            $tool = [string]$e.tool
            $t = ([string]$e.target) -replace '^game\.', ''
            if (-not $t) { $t = '(unspecified)' }
            $kind = 'script'
            if ($scriptTools -notcontains $tool) {
                # Property and instance churn is one entry per panel, so roll it up to the subtree.
                $kind = 'subtree'
                $segs = $t.Split('.')
                if ($segs.Length -gt 2) { $t = $segs[0] + '.' + $segs[1] }
            }
            $place = Get-PlaceName $e $instMap
            $key = $place + '|' + $t
            if (-not $groups.ContainsKey($key)) {
                $groups[$key] = [pscustomobject]@{ Place = $place; Path = $t; Kind = $kind; Tools = [ordered]@{} }
            }
            $label = $tool
            if ($short.ContainsKey($tool)) { $label = $short[$tool] }
            $tc = $groups[$key].Tools
            if ($tc.Contains($label)) { $tc[$label] = $tc[$label] + 1 } else { $tc[$label] = 1 }
            $ts = [string]$e.ts
            if ($ts.Length -ge 16) {
                $ts = $ts.Substring(0, 16)
                if (-not $first -or $ts -lt $first) { $first = $ts }
                if (-not $last -or $ts -gt $last) { $last = $ts }
            }
        }
    }
    if ($first) { Write-Output ("span     " + $first + " -> " + $last) }

    # Redwater and Frostbite carry the same codebase, so an edit in one alone is either a per-place file
    # or a mirror nobody finished. Only judged when the places resolved to names.
    $twin = @{ 'Redwater Canyon' = 'Frostbite Claim'; 'Frostbite Claim' = 'Redwater Canyon' }
    $placesSeen = @($groups.Values | Select-Object -ExpandProperty Place -Unique | Sort-Object)
    $anyOneSided = $false
    foreach ($pl in $placesSeen) {
        $rowsP = @($groups.Values | Where-Object { $_.Place -eq $pl } | Sort-Object Kind, Path)
        $nScripts = @($rowsP | Where-Object { $_.Kind -eq 'script' }).Count
        Write-Output ""
        Write-Output ("--- " + $pl + ": " + $nScripts + " script(s), " + ($rowsP.Count - $nScripts) + " instance subtree(s) ---")
        $other = $null
        if ($twin.ContainsKey($pl)) { $other = $twin[$pl] }
        if ($other -and $placesSeen -notcontains $other) {
            Write-Output ("  (no " + $other + " edits captured at all - every row below is one-sided)")
            $anyOneSided = $true
            $other = $null
        }
        foreach ($g in $rowsP) {
            $tools = @($g.Tools.Keys | ForEach-Object { $_ + ' x' + $g.Tools[$_] }) -join ' '
            $leaf = $g.Path.Split('.')[-1]
            $flags = ''
            if ($g.Kind -eq 'script' -and $mirrored.ContainsKey($leaf)) { $flags += ' [mirrored]' }
            if ($other -and -not $groups.ContainsKey($other + '|' + $g.Path)) { $flags += ' [one-sided]'; $anyOneSided = $true }
            if ($prose -and $prose -match ('\b' + [regex]::Escape($leaf.ToLowerInvariant()) + '\b')) { $flags += ' [in UNRELEASED]' }
            Write-Output ("  " + $g.Path + "  " + $tools + $flags)
        }
    }

    Write-Output ""
    Show-UnreleasedState
    Write-Output "[mirrored] a universe-mirrored module: name it under Shared modules."
    if ($anyOneSided) { Write-Output "[one-sided] in one match place only: a per-place file (MapConfig, map geometry) or an unfinished mirror - check before writing." }
    Write-Output "[in UNRELEASED] an entry already names it: if this amends that change, Grep the entry and Edit it instead of adding a bullet."
    Write-Output "Never captured: execute_luau and hand edits in Studio - write those up from what you did."
}

# The -Add merge. Metadata bullets (Shared modules / Data-affecting) sit between the first two '---'
# rules; each '## Section' of the entries file is appended at the end of the same section, or as a new
# section at the end of the file. Returns report lines.
function Merge-Entries($chg, $metaNew, $sections) {
    $lines = New-Object System.Collections.Generic.List[string]
    foreach ($l in ((Read-Text $chg) -split "`n")) { $lines.Add($l) }
    $report = New-Object System.Collections.Generic.List[string]

    function Find-Rules {
        $r = @()
        for ($i = 0; $i -lt $lines.Count; $i++) { if ($lines[$i] -match '^---\s*$') { $r += $i; if ($r.Count -eq 2) { break } } }
        return ,$r
    }
    $rules = Find-Rules
    if ($rules.Count -lt 2) { throw "-Add: UNRELEASED.md has no metadata block between two '---' rules - fix the file by hand" }

    foreach ($fieldName in @($metaNew.Keys)) {
        $val = @($metaNew[$fieldName])
        # 'no' / 'none' never overrides: another pane may already have written yes, and the release
        # needs the strongest claim anyone made.
        if ($val[0] -match '^(no|none)\b') { $report.Add("metadata  " + $fieldName + ": '" + $val[0] + "' ignored - only a positive value is merged"); continue }
        $rules = Find-Rules
        $k = -1; $old = ''
        for ($i = $rules[0] + 1; $i -lt $rules[1]; $i++) {
            if ($lines[$i] -match ('^- \*\*' + [regex]::Escape($fieldName) + ':\*\*\s*(.*)$')) { $k = $i; $old = $Matches[1]; break }
        }
        $rest = @($val | Select-Object -Skip 1 | ForEach-Object { '  ' + $_ })
        if ($k -lt 0) {
            $at = $rules[1]
            while ($at -gt $rules[0] + 1 -and -not $lines[$at - 1].Trim()) { $at-- }
            $lines.InsertRange($at, [string[]](@('- **' + $fieldName + ':** ' + $val[0]) + $rest))
            $report.Add("metadata  " + $fieldName + " added")
            continue
        }
        $end = $k + 1
        while ($end -lt $rules[1] -and $lines[$end] -match '^\s+\S') { $end++ }
        if ($old -match '^(no|none)\b') {
            $lines.RemoveRange($k, $end - $k)
            $lines.InsertRange($k, [string[]](@('- **' + $fieldName + ':** ' + $val[0]) + $rest))
            $report.Add("metadata  " + $fieldName + " set")
        } else {
            $lines.InsertRange($end, [string[]](@('  Also: ' + $val[0]) + $rest))
            $report.Add("metadata  " + $fieldName + " appended to the existing value")
        }
    }

    foreach ($name in @($sections.Keys)) {
        $body = $sections[$name]
        $nb = @($body | Where-Object { $_ -match '^- ' }).Count
        $rules = Find-Rules
        $hi = -1
        for ($i = $rules[1] + 1; $i -lt $lines.Count; $i++) {
            if ($lines[$i] -match ('^## ' + [regex]::Escape($name) + '\s*$')) { $hi = $i; break }
        }
        if ($hi -lt 0) {
            while ($lines.Count -gt 0 -and -not $lines[$lines.Count - 1].Trim()) { $lines.RemoveAt($lines.Count - 1) }
            $lines.Add(''); $lines.Add('## ' + $name); $lines.Add('')
            foreach ($b in $body) { $lines.Add($b) }
            $lines.Add('')
            $report.Add("added     " + $nb + " bullet(s) under NEW section ## " + $name)
            continue
        }
        $ni = $lines.Count
        for ($i = $hi + 1; $i -lt $lines.Count; $i++) { if ($lines[$i] -match '^(## |---\s*$)') { $ni = $i; break } }
        $back = $ni
        while ($back -gt $hi + 1 -and -not $lines[$back - 1].Trim()) { $back-- }
        $lines.RemoveRange($back, $ni - $back)
        $ins = New-Object System.Collections.Generic.List[string]
        if ($back -eq $hi + 1) { $ins.Add('') }
        foreach ($b in $body) { $ins.Add($b) }
        $ins.Add('')
        $lines.InsertRange($back, $ins)
        $report.Add("added     " + $nb + " bullet(s) under ## " + $name)
    }

    Write-Text $chg ($lines -join "`n")
    return $report
}

function Show-Coverage([bool]$mineOnly, [bool]$suspectsOnly) {
    # Every capture file with its owner and age, then every touched name
    # grouped by place, cross-checked against the prose in changelog/UNRELEASED.md. Catches a session
    # that was never curated AND one that was curated thinly - the second is invisible to every other
    # gate, because retiring a file is what marks it "described" and nothing else reads the prose.
    #
    # This reports SUSPECTS, not failures. Good changelog prose describes the change in player
    # terms ("the Collection menu stays deaf on join"), not by script name, so an unmentioned name
    # is frequently the correct write-up. Confirm each one; never let it push script names into
    # the entries, which would make the changelog worse to serve a checker.
    $prose = Get-UnreleasedProse
    if ($null -eq $prose) {
        throw "changelog/UNRELEASED.md not found. The root CHANGELOG.md is an index only; /changelog writes the prose into changelog/UNRELEASED.md."
    }

    $files = @(Get-CaptureFiles)
    if ($mineOnly) {
        # pending/<session>.jsonl and consumed/<session>-<stamp>.jsonl both start with the id.
        # Without this, /changelog reports every other pane's uncurated work as your suspect.
        $files = @($files | Where-Object { $_.BaseName.StartsWith($session) })
        if ($files.Count -eq 0) { Write-Output ("no capture for this session (" + $session + "), nothing to cross-check"); return }
    }
    if ($files.Count -eq 0) { Write-Output "no capture files, nothing to cross-check"; return }

    $instMap = Get-InstanceMap

    if (-not $suspectsOnly) { Write-Output ("=== capture summary: " + $files.Count + " capture file(s), " + $prose.Length + " chars of UNRELEASED.md prose ===") }
    foreach ($f in ($files | Sort-Object LastWriteTime)) {
        if ($suspectsOnly) { break }
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

            $place = Get-PlaceName $e $instMap

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

    $totalSus = 0
    foreach ($pl in ($rows | Select-Object -ExpandProperty Place -Unique | Sort-Object)) {
        $pr = @($rows | Where-Object { $_.Place -eq $pl })
        $sus = @($pr | Where-Object { -not $_.Named }).Count
        $totalSus += $sus
        if ($suspectsOnly -and $sus -eq 0) { continue }
        Write-Output ""
        Write-Output ("--- " + $pl + ": " + $pr.Count + " name(s), " + $sus + " SUSPECT ---")
        $sorted = $pr | Sort-Object @{ Expression = { $_.Named } }, @{ Expression = { $_.Kind } }, @{ Expression = { $_.Count }; Descending = $true }
        foreach ($r in $sorted) {
            if ($suspectsOnly -and $r.Named) { continue }
            $flag = 'named  '
            if (-not $r.Named) { $flag = 'SUSPECT' }
            Write-Output ("  " + $flag + "  " + $r.Kind.PadRight(7) + "  " + $r.Name.PadRight(36) + $r.Count.ToString().PadLeft(4))
        }
    }

    Write-Output ""
    if ($suspectsOnly -and $totalSus -eq 0) { Write-Output "coverage: every captured name appears in UNRELEASED.md"; return }
    Write-Output "SUSPECT = the name appears nowhere in UNRELEASED.md. Prose that describes the change"
    Write-Output "in player terms is often right - confirm each, do not force script names into entries."
    if (-not $suspectsOnly) { Write-Output "Never captured at all: execute_luau mutations and edits made by hand in Studio." }
}

if ($Coverage) { Show-Coverage ([bool]$Mine) $false; exit 0 }

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

if ($Add) {
    # Entries go in through here so nobody has to Read UNRELEASED.md first - it reached 233 KB before
    # Update 2 rolled. The merge is a read-modify-write lasting milliseconds: the same exposure as an
    # anchored Edit (and as -Roll's index row), where the Edit route also needs a fresh whole-file Read.
    if (-not (Test-Path -LiteralPath $Add)) { throw ("-Add: file not found: " + $Add) }
    $metaNew = [ordered]@{}
    $sections = [ordered]@{}
    $cur = $null
    $field = $null
    foreach ($l in ((Read-Text $Add) -split "`n")) {
        if ($l -match '^## (.+?)\s*$') {
            $cur = $Matches[1]
            if (-not $sections.Contains($cur)) { $sections[$cur] = New-Object System.Collections.Generic.List[string] }
            continue
        }
        if ($cur) { $sections[$cur].Add($l.TrimEnd()); continue }
        if ($l -match '^- \*\*(Shared modules|Data-affecting):\*\*\s*(.*)$') {
            $field = $Matches[1]
            $metaNew[$field] = New-Object System.Collections.Generic.List[string]
            $metaNew[$field].Add($Matches[2].Trim())
        } elseif ($field -and $l -match '^\s+\S') {
            $metaNew[$field].Add($l.Trim())
        } elseif ($l.Trim()) {
            throw ("-Add: above the first '## ' heading only a Shared modules or Data-affecting bullet may appear, got: " + $l)
        }
    }
    foreach ($k in @($sections.Keys)) {
        $body = $sections[$k]
        while ($body.Count -gt 0 -and -not $body[0].Trim()) { $body.RemoveAt(0) }
        while ($body.Count -gt 0 -and -not $body[$body.Count - 1].Trim()) { $body.RemoveAt($body.Count - 1) }
        if ($body.Count -eq 0) { $sections.Remove($k) }
    }
    if ($sections.Count -eq 0 -and $metaNew.Count -eq 0) { throw "-Add: nothing to add. Put bullets under '## Added' / '## Changed' / '## Fixed'." }

    $chg = Join-Path $root 'changelog\UNRELEASED.md'
    if (-not (Test-Path $chg)) { throw "changelog/UNRELEASED.md not found" }
    $report = $null
    for ($try = 1; $try -le 5; $try++) {
        try { $report = Merge-Entries $chg $metaNew $sections; break }
        catch {
            # Only a file held by a peer's write at this instant is worth retrying.
            if ($try -eq 5 -or ([string]$_.Exception.Message).StartsWith('-Add:')) { throw }
            Start-Sleep -Milliseconds (40 * $try)
        }
    }
    foreach ($r in $report) { Write-Output $r }
    if (-not $Retire) { exit 0 }
    Show-Coverage (-not $All) $true
    Write-Output ""
}

if ($GitHubRelease) {
    # Step 10 of /preflight. Everything comes from the newest index row and its release file, so the
    # body cannot disagree with the changelog: no hand-composed notes, no separate verification call.
    $repo = 'Rasmus-Bondo/Bounty'
    $top = Get-IndexTop
    $file = $top.File
    $relPath = Join-Path (Join-Path $root 'changelog') $file
    if (-not (Test-Path $relPath)) { throw ("changelog/" + $file + " not found") }
    if ($top.Published -match 'rTBD') { throw ($top.Name + " has no recorded place versions (" + $top.Published + "). Record them (Step 9), commit and push, then re-run.") }

    # The human version string has a space and cannot be a git ref, so the tag is the dated filename
    # without its date: 2026-08-29-update-2.md -> update-2.
    $tag = ($file -replace '^\d{4}-\d{2}-\d{2}-', '') -replace '\.md$', ''

    $rel = (Read-Text $relPath) -split "`n"
    $pubLine = $null; $rollLine = $null
    $ruleCount = 0
    $bullets = New-Object System.Collections.Generic.List[string]
    foreach ($l in $rel) {
        if ($l -match '^---\s*$') { $ruleCount++; continue }
        if (-not $pubLine -and $l -match '^- \*\*Published:\*\*\s*(.*)$') { $pubLine = $Matches[1] }
        if (-not $rollLine -and $l -match '^- \*\*Rollback target:\*\*\s*(.*)$') { $rollLine = $Matches[1] }
        # Past the metadata block, one line per change: the entry's own bolded summary, never rewritten.
        if ($ruleCount -ge 2 -and $l -match '^- \*\*(.+?)\*\*') { $bullets.Add('- **' + $Matches[1].Trim() + '**') }
    }
    $pubVersions = [regex]::Match([string]$pubLine, '`([^`]+)`').Groups[1].Value
    $rollVersions = [regex]::Match([string]$rollLine, '`([^`]+)`').Groups[1].Value
    if (-not $pubVersions) { throw ("changelog/" + $file + ": no backticked versions in the Published field") }
    $pubDate = [regex]::Match([string]$pubLine, 'published (\d{4}-\d{2}-\d{2})').Groups[1].Value
    if (-not $pubDate) { $pubDate = $top.Date }
    if ($bullets.Count -eq 0) { throw ("changelog/" + $file + ": no '- **summary**' bullets below the metadata block") }

    $nl = "`n"
    $notes = '**Published ' + $pubDate + '** ' + $dot + ' ' + $pubVersions + $nl
    if ($rollVersions) { $notes += '**Rollback lands on:** ' + $rollVersions + $nl }
    $notes += '**Data-affecting:** ' + ($top.DataAffecting -replace '\*', '') + $nl + $nl
    $notes += ($bullets -join $nl) + $nl + $nl
    $notes += 'Full entry: https://github.com/' + $repo + '/blob/main/changelog/' + $file + $nl

    # Target the commit that carries the release file, not main: other panes may have pushed since. It
    # must already be on the remote, or GitHub cannot tag it.
    $sha = [string](& git -C $root log -1 '--format=%H' '--' ('changelog/' + $file))
    if (-not $sha) { throw ("changelog/" + $file + " is not committed") }
    $onRemote = @(& git -C $root branch -r --contains $sha) -match 'origin/main'
    [Console]::OutputEncoding = $utf8

    if ($Preview) {
        Write-Output ("tag " + $tag + "  title '" + $top.Name + "'  target " + $sha + "  pushed: " + [bool]$onRemote)
        Write-Output "--- notes ---"
        Write-Output $notes
        exit 0
    }
    if (-not $onRemote) { throw ("commit " + $sha + " is not on origin/main - push first") }
    $tags = @(& gh release list --repo $repo --limit 200 --json tagName --jq '.[].tagName')
    if ($LASTEXITCODE -ne 0) { throw "gh release list failed - is gh authenticated?" }
    if ($tags -contains $tag) { throw ("GitHub release '" + $tag + "' already exists - tags are never reused") }

    $notesFile = [System.IO.Path]::GetTempFileName()
    Write-Text $notesFile $notes
    & gh release create $tag --repo $repo --title $top.Name --target $sha --latest --notes-file $notesFile
    $code = $LASTEXITCODE
    [System.IO.File]::Delete($notesFile)
    if ($code -ne 0) { throw ("gh release create failed (exit " + $code + ")") }

    # A release whose numbers disagree with the index is worse than none, so read it back.
    $body = (@(& gh release view $tag --repo $repo --json body --jq '.body') -join "`n")
    $missing = @([regex]::Matches($pubVersions, 'r\d+') | ForEach-Object { $_.Value } | Where-Object { -not $body.Contains($_) })
    if ($missing.Count -gt 0) { throw ("release " + $tag + " created, but its body is missing " + ($missing -join ', ') + " - fix it on GitHub") }
    Write-Output ("verified  release " + $tag + " carries " + $pubVersions)
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

# Default: the digest. Never mutates.
Show-Digest ([bool]$All)
exit 0
