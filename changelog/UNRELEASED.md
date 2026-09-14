# Unreleased

Work that has shipped to no one yet. `/changelog` writes here; `/preflight` renames this file to
`YYYY-MM-DD-<release>.md` when the release rolls and drops a fresh empty one in its place.

**Concurrency:** several agents work this project at once. **Never `Write` this file whole.** Add
entries with `.\.claude\scripts\changelog-capture.ps1 -Add <file>` (what `/changelog` does); amend one
with an `Edit` anchored on its text after a fresh re-read. A whole-file write is the one operation that
destroys a concurrent entry without complaining.

[Index](../CHANGELOG.md) · [Conventions](CONVENTIONS.md) · Previous release: [Hotfix 3.3](2026-09-14-hotfix-3-3.md)

---

- **Shared modules:** none yet.
- **Data-affecting:** no.

---

## Added

## Changed

- **`HunterViewmodelContract` header comment (both match places), comment only.** It said
  "/preflight Step 2 runs it"; since the Hotfix 3.3 preflight rework the contract gate runs in Step 1
  through `ServerStorage.PreflightGates`. No behaviour change, no data. Byte-identical in Redwater and
  Frostbite (26206 B, `c737f84b`), compiles, `Hunters.Shared` match-tier fold equal.
- **Tooling: cheaper `/changelog` and a scripted GitHub release (not game code).** `/changelog` is
  now three calls and never reads a capture file or `UNRELEASED.md`. `changelog-capture.ps1` with no
  arguments prints a grouped digest, flagging `[mirrored]` modules (read from `PreflightGates.luau`),
  `[one-sided]` Redwater/Frostbite edits and names already `[in UNRELEASED]`. `-Add <file> [-Retire]`
  merges entries and metadata into `UNRELEASED.md`, then prints suspects. `-GitHubRelease [-Preview]`
  builds, creates and verifies `/preflight` Step 10's release. The skill drops from 154 to 61 lines and
  no longer carries the mirrored-module list. The capture hook runs `async` (it blocked every Studio
  mutation for ~460 ms) with a longer append retry. `gh api graphql`, `gh issue close` and
  `gh release create` are allowlisted. Rollback: revert the commit; no data, no Studio change. Verified
  on a sandbox copy of `changelog/`: the digest (mine, `-All`, no capture); `-Add` into existing,
  empty and new sections, including the metadata merge; `-Add -Retire`; `-Roll` over the merged file;
  and `-GitHubRelease -Preview`, which reproduces the Hotfix 3.3 release's tag and target. 10
  concurrent hook appends lost no lines. `-GitHubRelease` has not yet created a real release.

## Fixed
