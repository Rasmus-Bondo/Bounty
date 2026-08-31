# 32 — Stats menu never resets between rounds

[Open items index](../../OPEN-ITEMS.md) · [Conventions](../../CONVENTIONS.md)

**Closed 2026-08-11** — owner decision: no recurrence in the ~2 weeks since the 2026-08-01 launch. Closed on elapsed time, **not** on a playtest — the status below was still `FIXED (unverified)`.

---

**Status:** FIXED (unverified) → [Hotfix 11](../../2026-08-07-hotfix-11.md) · **Sev:** P2 · **Area:** Redwater — stats menu (M on PC, Stats button on mobile)

**Reported 2026-08-07:** the stats shown when you press M / tap Stats should refresh when a new game
starts. Explicitly **not** the match summary — that one was correct.

**That distinction was the diagnosis, not a detail of the report.** The two surfaces read different
tables. The summary reads `State.playerKills` / `State.playerDeaths`, which the round loop already
clears at the top of every round. The stats menu reads `DataService.sessionTracker`, built once in
`onPlayerAdded` and torn down only on `PlayerRemoving` — nothing reset it, ever. Both halves of the
menu drift off that one table: **My Stats** through `ProgressionService`'s `RequestStats` reply, and
the **Scoreboard** tab through the `SessionKills` / `SessionDeaths` player attributes, which
`incrementSessionStat` mirrors out of the same table.

**It is a regression from Hotfix 9's round loop, and it was correct code before that.** A Redwater
server used to play one match and close, so "session" and "match" were the same span and the name
was accurate. Once servers began looping rounds the panel started showing every round the server had
played added together — round 3 displaying the sum of rounds 1–3.

**Fix (2026-08-07) — `DataService` + `RoundController` + `ProgressionService`:**

1. **`DataService.resetSessionStats(player)` / `resetAllSessionStats()`**, called from the round-start
   reset block next to `State.playerKills = {}`. Zeroes Kills, Deaths, Assists, TimeAlive, TimeDead
   **and rewrites the `Session*` attributes** — the Scoreboard tab reads those directly rather than
   asking the server, so the table alone leaves that tab still showing last round's rows.
2. **`JoinTime` is excluded on purpose.** `onPlayerRemoving` banks `TotalPlaytime` off it, so
   resetting it per round would throw away the playtime earned in every earlier round of the sitting.
   `IsAlive` is excluded too — the `setupTimeTracking` heartbeat owns it and must not be guessed at.
3. **`snapshotRoundStart` now clears `timeRewardTracker`. This is the trap in the whole change.** The
   alive-time reward pays on `sessionData.TimeAlive - timeRewardTracker[userId] >= TIME_REWARD_INTERVAL`.
   Zeroing `TimeAlive` while that high-water mark survives makes the difference permanently negative,
   and **the reward silently stops paying for the rest of the server's life** — no error, no warning,
   just a source of income that quietly ends. Anything else added to the per-match reset must be
   checked for a consumer holding a running total against it.
4. **`ProgressionService.sendStats` / `sendStatsToAll`**, the `RequestStats` handler body lifted into
   a named function and pushed to every player at round start. The panel pulls on open and never
   again, so a player holding it open across the boundary would keep reading stale text with no way
   to notice. `RoundController` calls it through a `pcall`ed `safeSendStatsToAll` — cosmetic work must
   not be able to throw inside the round-start sequence.
5. **`SessionHeader` re-authored `SESSION` → `THIS MATCH`**, so the label states the span it now
   describes. `TextScaled` is false at TextSize 14 in a full-width row, so the longer string cannot
   overflow on a phone.

**Not verified — MCP playtesting is unavailable.** All three scripts compile (`loadstring`), the
header was screenshot-confirmed in place, and the StarterGui `Enabled` state toggled for that capture
was snapshotted and restored. **The playtest that closes this needs two rounds on one server:** get a
kill in round 1 and confirm M reads 0/0 once round 2 begins (**not** during the podium — the summary
still shows round 1, which is correct); check the Scoreboard tab across the same boundary, since it is
the separate read path; **stay alive past `TIME_REWARD_INTERVAL` in round 2 and confirm the time
reward still pays**, which is the regression item 3 guards; and leave the menu open through a round
start to confirm it repaints on its own.

---
