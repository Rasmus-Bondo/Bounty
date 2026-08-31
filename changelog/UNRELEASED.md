# Unreleased

Work that has shipped to no one yet. `/changelog` writes here; `/preflight` renames this file to
`YYYY-MM-DD-<release>.md` when the release rolls and drops a fresh empty one in its place.

**Concurrency:** several agents work this project at once. **Never `Write` this file whole** — append
with an `Edit` anchored inside a `## Added` / `## Changed` / `## Fixed` heading, and re-read
immediately before editing, because another agent may have written since. A whole-file write is the
one operation that destroys a concurrent entry without complaining; a stale anchor merely errors,
which is the point.

[Index](../CHANGELOG.md) · [Conventions](CONVENTIONS.md) · Previous release: [Update 2](2026-08-29-update-2.md)

---

- **Shared modules:** none of the universe-wide twenty touched. Match-place mirror only — `HighNoonModule` and `BotCombat` across Redwater Canyon and Frostbite Claim, verified byte-identical by length **and** checksum after the sync (`16636 B` / `101943 B`). Bounty untouched.
- **Data-affecting:** no.

## Added

## Changed

## Fixed

- **A Bram now cancels a Dust ultimate outright instead of pausing it.** Being carried by a Breach
  Charge, or slammed into a wall by one, ends High Noon on the spot — no shot, no refund of the
  charge. Previously only the shoot request consulted the action lock, which refuses the trigger only
  *while* the lock is up: the slam stun is shorter than the ultimate's hold window, so Dust kept his
  cone, went on locking the enemies in it, and executed the moment the stun lapsed. Landing the ram
  bought 2.5 seconds; it did not beat the ultimate.

  Covers all four pairings — player or bot Bram, against a player or bot Dust — because both Bram
  implementations write the same two status attributes and the check lives on the victim's side.

  **Revert hazard:** both match places carry it and must ship together. `HunterActionLock` itself is
  unchanged, so nothing else depends on this. The bot path additionally swapped its single
  `task.delay(LockInTime)` for a poll on the same beat as the player's cone scan — reverting restores
  the one-shot timer, not a half-fixed version.

  **Playtested by the owner**, confirmed cancelling in a live round.
