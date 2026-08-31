# changelog-capture.ps1
#
# Not a hook - a helper for the /changelog and /preflight skills. It answers "which capture files
# exist and which one is mine", cross-checks the capture against changelog/UNRELEASED.md, and
# retires a consumed file by MOVING it, never deleting it.
#
# CHANGELOG.md in the project root is an INDEX only - one table row per release. The prose lives in
# changelog/: UNRELEASED.md for in-flight work, YYYY-MM-DD-<release>.md for shipped ones. Coverage
# therefore reads UNRELEASED.md, which is the only file /changelog ever writes.
#
# The capture is partitioned per session by .claude/hooks/log-studio-change.ps1 because several
# agents work this project at once. The rule this script exists to enforce: an agent touches its
# own capture file and nothing else, and a retired file stays on disk until a release archives it,
# so /preflight can still see every script the release touched.
#
#   changelog-capture.ps1                 status: my session id, every pending file, consumed count
#   changelog-capture.ps1 -Coverage       which touched names appear nowhere in UNRELEASED.md
#   changelog-capture.ps1 -Coverage -Mine same, restricted to this session's own capture
#   changelog-capture.ps1 -Retire         move MY pending file to .changelog/consumed/
#   changelog-capture.ps1 -Retire -All    move EVERY pending file to .changelog/consumed/
#   changelog-capture.ps1 -Archive "Update 1"   move .changelog/consumed/* to archive/<release>/
#
# KEEP THIS FILE PURE ASCII. Windows PowerShell 5.1 reads a BOM-less .ps1 as CP1252, where an
# em-dash decodes to a smart quote - which the parser accepts as a string delimiter, so one
# em-dash inside a string literal breaks the whole file with errors pointing at unrelated lines.

param(
    [switch]$Retire,
    [switch]$All,
    [switch]$Coverage,
    [switch]$Mine,
    [string]$Archive
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
        $lines = @(Get-Content -LiteralPath $f.FullName -ErrorAction SilentlyContinue | Where-Object { $_.Trim() })
        $nonBump = @($lines | Where-Object { $_ -notmatch 'GameEnvironment' })
        $tag = ""
        if ($f.BaseName -eq $session) { $tag = "  MINE" }
        if ($lines.Count -gt 0 -and $nonBump.Count -eq 0) {
            $anyBump = $true
            $tag = $tag + "  <- version bump only"
        }
        Write-Output ("  " + (Show-Path $f.FullName) + "  " + $lines.Count + " lines" + $tag)
    }
    if ($anyBump) {
        Write-Output "A bump-only file is this release's own version bump. Run -Retire then re-run"
        Write-Output "-Archive with the SAME release name, or it strands into the next release."
    }
    Write-Output "Another pane's in-progress capture is fine to leave here."
}

if ($Coverage) {
    # Cross-check the capture against what changelog/UNRELEASED.md actually says. Catches a session
    # that was never curated AND one that was curated thinly - the second is invisible to every
    # other gate, because retiring a file is what marks it "described" and nothing else reads the
    # prose.
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
    $srcLines = @(Get-Content -LiteralPath $chg)
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

    $scriptTools = @('set_script_source', 'edit_script_lines', 'insert_script_lines', 'delete_script_lines', 'find_and_replace_in_scripts')
    $places = @{ 'place:131701626847012' = 'Bounty'; 'place:98517073248449' = 'Redwater' }

    $scripts = @{}
    $subtrees = @{}

    foreach ($f in $files) {
        foreach ($line in (Get-Content -LiteralPath $f.FullName -ErrorAction SilentlyContinue)) {
            if ([string]::IsNullOrWhiteSpace($line)) { continue }
            $e = $null
            try { $e = $line | ConvertFrom-Json } catch { continue }

            $t = [string]$e.target
            if (-not $t -or $t -eq '(unspecified)') { continue }
            $parts = $t.Split('.')

            $place = [string]$e.place
            if ($places.ContainsKey($place)) { $place = $places[$place] }
            elseif (-not $place) { $place = '(unknown)' }

            if ($scriptTools -contains [string]$e.tool) {
                # A script edit names the script itself; the leaf of the path is what to look for.
                $key = $parts[$parts.Length - 1] + '|' + $place
                if ($scripts.ContainsKey($key)) { $scripts[$key]++ } else { $scripts[$key] = 1 }
            } else {
                # Property and instance churn collapses to one changelog line per panel, so
                # tracking every Frame and UIStroke would bury the signal. Roll up to the subtree.
                $n = $parts[$parts.Length - 1]
                if ($parts.Length -ge 3) { $n = $parts[2] }
                $key = $n + '|' + $place
                if ($subtrees.ContainsKey($key)) { $subtrees[$key]++ } else { $subtrees[$key] = 1 }
            }
        }
    }

    function Write-Group($title, $table, $unit) {
        if ($table.Count -eq 0) { return }
        $rows = @()
        foreach ($k in $table.Keys) {
            $bits = $k.Split('|')
            $rows += [pscustomobject]@{
                Name  = $bits[0]
                Place = $bits[1]
                Count = $table[$k]
                Named = $prose.Contains($bits[0].ToLowerInvariant())
            }
        }
        $missing = @($rows | Where-Object { -not $_.Named } | Sort-Object Count -Descending)
        $named   = @($rows | Where-Object { $_.Named } | Sort-Object Count -Descending)

        Write-Output ""
        Write-Output ($title + ": " + $missing.Count + " unnamed of " + $rows.Count)
        foreach ($r in $missing) {
            Write-Output ("  SUSPECT  " + $r.Name.PadRight(34) + $r.Count.ToString().PadLeft(4) + " " + $unit + "  " + $r.Place)
        }
        foreach ($r in $named) {
            Write-Output ("  named    " + $r.Name.PadRight(34) + $r.Count.ToString().PadLeft(4) + " " + $unit + "  " + $r.Place)
        }
    }

    Write-Output ("=== changelog/UNRELEASED.md coverage: " + $files.Count + " capture file(s), " + $prose.Length + " chars of prose ===")
    Write-Group "scripts edited" $scripts "edits"
    Write-Group "instance subtrees touched" $subtrees "changes"
    Write-Output ""
    Write-Output "SUSPECT = the name appears nowhere in UNRELEASED.md. Prose that describes the change"
    Write-Output "in player terms is often right - confirm each, do not force script names into entries."
    Write-Output "Never captured at all: execute_luau mutations and edits made by hand in Studio."
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
    Write-Output "nothing was deleted; /preflight still reads consumed/ for release scope."

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
