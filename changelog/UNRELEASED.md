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

- **Code `UIBOUNTY` — 2 chests.** Added to `CodeRedemptionService`'s `CODES` table in Bounty, Redwater
  and Frostbite (`expiresAt = 1789930800`, Sun 20 Sep 2026 21:00 CEST; no `startsAt`, so it opens at
  publish). `CODES` + `resolveCode` checksum-identical across all three (2351 / 389 bytes). Rollback:
  removing it only stops new redemptions; chests already banked stay. Verified by compile + calling
  the gate on the live table; not redeemed in a playtest. **The release must publish before Sun 20 Sep
  21:00 CEST or the code ships already expired.**

## Changed

## Fixed
