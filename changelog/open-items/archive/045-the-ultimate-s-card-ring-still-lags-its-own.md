# 45 — The ultimate's card ring still lags its own damage

[Open items index](../../OPEN-ITEMS.md) · [Conventions](../../CONVENTIONS.md)

**Closed 2026-08-11** — owner review of the standing-concern list.

---

**The ultimate's card ring still lags its own damage** (raised: Hotfix 9, 2026-08-06). Hotfix 9
made the basic throw and Ability1 fly at a constant 0.08s so the card lands with the hit it already
resolved. The ultimate's outward ring was left alone by the owner's decision — `OutSpeed` 105 over
a 35-stud `OutRange` is 0.33s, and the ~440 needed to match would snap all 20 cards out in a single
frame, destroying the expanding-ring visual that is the ult's payoff. It is therefore now the
**only** damage-dealing throw in the game whose cards trail their damage. Recorded because it is a
known, accepted inconsistency rather than an oversight — if it ever gets reported as desync, this
is the answer, and the fix is a different visual for the ring, not a speed change.
