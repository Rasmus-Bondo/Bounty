# log-studio-change.ps1
#
# PostToolUse hook. Appends one line to .changelog/pending/<session>.jsonl for every mutation made
# to the Roblox Studio data model, so the changelog does not depend on anyone remembering to write
# it down. Capture is mechanical; turning the capture into prose is the /changelog skill's job.
#
# One file per session, never one shared file. Several agents work this project at once, and a
# single shared capture broke in two ways: whichever agent curated first deleted the capture for
# everyone still mid-work, and two panes appending at the same moment could collide on a file lock
# - which this hook, by design, swallows in silence. Partitioning at capture time fixes both.
# Keep this file pure ASCII: PowerShell 5.1 reads a BOM-less .ps1 as CP1252, where an em-dash
# decodes into a smart quote the parser treats as a string delimiter.
# The session comes from CLAUDE_CODE_SESSION_ID (the hook process inherits it), so a pane and every
# subagent it spawns share one file while other panes are untouchable.
#
# This hook must NEVER block or fail a tool call. Every path exits 0, including the error path.

$ErrorActionPreference = 'Stop'

try {
    $raw = [Console]::In.ReadToEnd()
    if ([string]::IsNullOrWhiteSpace($raw)) { exit 0 }

    $payload = $raw | ConvertFrom-Json
    $tool = [string]$payload.tool_name
    $in = $payload.tool_input

    function Get-Field($obj, $name) {
        if ($null -eq $obj) { return $null }
        if ($obj.PSObject.Properties.Name -contains $name) { return $obj.$name }
        return $null
    }

    # A dry run changed nothing, so recording it would put phantom edits in the changelog.
    $dry = Get-Field $in 'dryRun'
    if ($dry -eq $true) { exit 0 }

    # The Studio tools each name "what did this touch" differently. Take the first that exists;
    # precision matters less than always capturing something greppable.
    $target = $null
    foreach ($key in 'instancePath', 'parent', 'path', 'pattern') {
        $v = Get-Field $in $key
        if ($v) { $target = [string]$v; break }
    }
    if (-not $target) { $target = '(unspecified)' }
    if ($target.Length -gt 200) { $target = $target.Substring(0, 200) + '...' }

    $place = Get-Field $in 'instance_id'
    if (-not $place) { $place = '(default)' }

    $name = Get-Field $in 'name'

    # Which file this line belongs in. The env var groups a pane with its own subagents; the
    # payload id can be a child session, so it is recorded as provenance rather than used for
    # routing - routing on it would scatter one pane's work across files nobody claims.
    $session = [string]$env:CLAUDE_CODE_SESSION_ID
    if (-not $session) { $session = [string](Get-Field $payload 'session_id') }
    $session = $session -replace '[^A-Za-z0-9_-]', ''
    if (-not $session) { $session = 'unknown' }

    $entry = [ordered]@{
        ts     = (Get-Date).ToString('o')
        tool   = $tool -replace '^mcp__robloxstudio__', ''
        target = $target
        place  = [string]$place
    }
    if ($name) { $entry.name = [string]$name }

    $origin = [string](Get-Field $payload 'session_id')
    if ($origin -and $origin -ne $session) { $entry.origin = $origin }

    $root = $env:CLAUDE_PROJECT_DIR
    if (-not $root) { $root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot) }

    $dir = Join-Path (Join-Path $root '.changelog') 'pending'
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }

    # Parallel tool calls inside one pane still share this file, so a lock collision is possible.
    # Retry briefly rather than losing the line - the catch below would hide the loss entirely.
    $path = Join-Path $dir ($session + '.jsonl')
    $line = ($entry | ConvertTo-Json -Compress) + "`n"
    $enc = New-Object System.Text.UTF8Encoding($false)
    for ($i = 0; $i -lt 5; $i++) {
        try { [System.IO.File]::AppendAllText($path, $line, $enc); break }
        catch { Start-Sleep -Milliseconds (25 * ($i + 1)) }
    }
}
catch {
    # Swallow everything. A broken changelog hook must never be able to stop the actual work.
}

exit 0
