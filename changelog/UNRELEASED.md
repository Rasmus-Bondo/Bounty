# Unreleased

Work that has shipped to no one yet. `/changelog` writes here; `/preflight` renames this file to
`YYYY-MM-DD-<release>.md` when the release rolls and drops a fresh empty one in its place.

**Concurrency:** several agents work this project at once. **Never `Write` this file whole** — append
with an `Edit` anchored inside a `## Added` / `## Changed` / `## Fixed` heading, and re-read
immediately before editing, because another agent may have written since. A whole-file write is the
one operation that destroys a concurrent entry without complaining; a stale anchor merely errors,
which is the point.

[Index](../CHANGELOG.md) · [Conventions](CONVENTIONS.md) · Previous release: [Hotfix 3.2](2026-09-13-hotfix-3-2.md)

---

- **Shared modules:** none yet.
- **Data-affecting:** no.

---

## Added

- **Tooling: `ServerStorage.PreflightGates` in all three places (not game code).** One ModuleScript
  holding every Studio-side `/preflight` gate — universe mirror fold, whole-place syntax sweep,
  BotConfig / RoundSystem.Config, weapon-skin contract with its accepted lines, clip parity, version
  line — plus the `/mirror` walker, run as `loadstring(game.ServerStorage.PreflightGates.Source)().run(print)`
  instead of pasting ~5 KB of Luau per place per run. Canonical source and `.rbxm` live in
  `.claude/skills/preflight/`; installed in Redwater by `set_script_source`, in Bounty and Frostbite
  by `import_rbxm`. Nothing requires it and ServerStorage never replicates, so it ships inert with the
  next publish. Rollback: delete the module; no data. Verified: all three copies hash `c0d9be94`
  (= the git file); `run(print)` PASSes in all three; universe fold `37fc6c87` reproduces Hotfix 3.2's
  recorded post-bump fold, and clip sum `169085011` and match-tier StarterGui fold `03d26673` match
  their recorded values.
- **Tooling: faster `/preflight`.** Steps 1–3 are one parallel batch; the skill drops from 719 to 275
  lines, with Steps 9–11 moved to `after-publish.md`. `changelog-capture.ps1` gains `-Roll` (rename +
  header + Next link + fresh `UNRELEASED.md` + index row) and `-SyncIndex` (index row derived from the
  release header), and `-Coverage` now lists every capture file and groups names by place. The capture
  hook records `import_rbxm` targets and resolves instance ids to place names from
  `get_connected_instances` — **inert until that tool is added to the hook matcher in
  `.claude/settings.json`**. Scripts tested on a sandbox copy of `changelog/`; the new gate flow ran
  end to end on the live places; not yet used for a real release.

## Changed

## Fixed

- **Frostbite Claim: phones could rotate into portrait.** `StarterGui.ScreenOrientation` `Sensor` →
  `LandscapeSensor`, matching Redwater (no script sets orientation in either place). Set via
  `execute_luau`, so it is not in the capture. Rollback: set it back to `Sensor`; no data impact.
  Verified by property read-back only; needs a phone check after publish. Bounty's value is unchecked
  (place was not open).
