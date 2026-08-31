# 83 — `Config.MIN_PLAYERS = 1` makes the late-join path the normal one, not the exception

[Open items index](../OPEN-ITEMS.md) · [Conventions](../CONVENTIONS.md)

---

**`Config.MIN_PLAYERS = 1` makes the late-join path the normal one, not the exception.** A reserved
Redwater server starts its round on the first arrival after a 5s countdown, and the 90s match lock
then feeds the remaining 6–9 players into an already-running round. That is what turned the
`MatchStart` field bug from an edge case into two thirds of all rows, and it is worth asking
whether it is right on its own terms: every filling player joins mid-match, spawns into a fight
already in progress, and the seeder plays alone for however long the fill takes. Not changed as
part of the telemetry fix — it is a match-flow decision with its own consequences for RP, bot
padding and first-match experience, and it deserves to be decided rather than inherited.
*(raised: MatchStart Unknown fields, 2026-08-05)*
