# 107 — Round-start leaver-abort fix is unplayed

[Open items index](../OPEN-ITEMS.md) · [Conventions](../CONVENTIONS.md)

**Closed 2026-08-15 — owner decision. Never playtested; the test below was never run.** Live since
2026-08-13 (Hotfix 17) with no recurrence reported. Closed on elapsed time, not on evidence. If it
resurfaces, raise a **new id**.

**Status:** CLOSED 2026-08-15 (never verified) · **Sev:** P1 · **Area:** Redwater — `SpawnService`, `SkinService`
*(raised: Hotfix 17)*

---

**Symptom.** A player leaving during `respawnAllPlayers` threw out of the loop, so every player
behind them in `Players:GetPlayers()` order started the round on last round's character at whatever
health they finished on. Logged on r2545 — and one log line is one aborted loop, not one affected
player, so the real count is higher than the log suggests.

**Repro.** Needs a player to disconnect inside the round-start respawn window, which is a fraction
of a second. Not reproduced deliberately; the r2545 log rows are the evidence it happens. A Studio
approximation would have to fake `player.Parent == nil` mid-loop rather than reproduce the race.

**The test that closes it.** Two parts, and the first is the reliable one: after publishing, watch
the Creator Hub server log for `LoadCharacter can only be called when Player is in the world` —
**expect zero**. Second, on live with 3+ players, have one leave as a round ends and confirm the
others spawn at full health with a fresh character rather than carrying their previous body.

**Shipped in:** [Hotfix 17](../2026-08-13-hotfix-17.md) — under `## Fixed`.
