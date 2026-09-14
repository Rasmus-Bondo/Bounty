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

## Changed

## Fixed

- **Frostbite Claim: phones could rotate into portrait.** `StarterGui.ScreenOrientation` `Sensor` →
  `LandscapeSensor`, matching Redwater (no script sets orientation in either place). Set via
  `execute_luau`, so it is not in the capture. Rollback: set it back to `Sensor`; no data impact.
  Verified by property read-back only; needs a phone check after publish. Bounty's value is unchecked
  (place was not open).
