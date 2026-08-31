# 19 — Bots vanish instantly when a player joins

[Open items index](../../OPEN-ITEMS.md) · [Conventions](../../CONVENTIONS.md)

---

**Status:** **VERIFIED** by the owner 2026-08-05 — live, mid-round join · **Sev:** P2 · **Area:** Redwater — bots

**Reported:** When a player joins, bots should not get kicked instantly. The bot should simply not respawn after the next time it dies.

**Population rule (2026-08-01):** roughly 1 joining player retires 1 bot, with a floor of about 4 bots. Exact numbers are not settled and are not the point of this item — the point is *when* the bot leaves, not how many.

**Cause (2026-08-04).** One line. `BotService:Reconcile` shed surplus bots with
`self:_removeRecord(removeId, "slot filled by player")`, and `_removeRecord` calls
`controller:Destroy()`, which takes the character with it. `_removeRecord` had exactly **one** caller,
which is why this stayed a contained change.

**Fix (2026-08-04, `BotService` only — five edits, no config change):**
1. New per-record `Retiring` flag. Surplus records are **flagged, not removed**; the bot keeps
   playing.
2. `_onBotDied` is where a flagged record actually leaves — `_removeRecord` after `RagdollDuration`,
   skipping the respawn.
3. Under target, `Reconcile` **un-retires before it creates**, newest flag first.
4. The trailing "every record has a controller" pass skips retiring records.
5. `countMap` became `countActiveRecords` (ignores retiring records); `_spawnController` refuses a
   retiring record defensively, whichever path asks.

**Three details that are load-bearing and easy to undo:**
- **The surplus loop had to stop being a `while`.** Retiring records stay in `Records`, so a
  count-based `while` can never see the count fall — the old loop would spin forever the moment
  removal became deferred. It is a bounded `for _ = 1, surplus`.
- **Un-retire must run before create,** not after. `_chooseHunter` counts a retiring record as live,
  so draining the flags first is what keeps `HunterCaps` (Vesper = 2) honest for any record genuinely
  created afterwards.
- **The `Retiring` re-check inside the delayed `_removeRecord` is not belt-and-braces.** A player can
  leave during those 2.5s, and `Reconcile` un-retires the record rather than spawning a replacement;
  without the re-check the un-retired record is deleted anyway.

**The three warnings in the notes above are closed by construction, not by new code.** Routing
retirement through the death path means `_creditPlayerKill`, `_resolveDeath` and
`BotCombat:Destroy`'s `_releasePin` have *all already run* before the record is touched — so the last
kill credits, assists resolve, and a Bram bot dying mid-charge still hands its victim back. This
change **removes** the mid-fight `Destroy` rather than working around it, so it is strictly safer
than the old path on every one of those counts.

**Verified by simulation, since MCP playtesting is unavailable:** the new population logic was
extracted and run against the real `BotConfig` numbers over a 2→10 player ramp with no bot deaths,
staged deaths at a full house, a 10→2 drain, and 40 join/leave thrash cycles. `active == desired` at
every step, never below `MinBots`, total records never above `MaxBots`, no loop ever ran away.
`BotService` compiles (522 lines).

**Accepted consequence — a transient overshoot of the participant target.** A flagged bot that
survives a run of joins means the arena runs above target: worst case **8 bots alongside 10 players
(18 fighters)** where the old behaviour capped at 4 alongside 10 (14). The **bot count itself never
exceeds `MaxBots` = 8**, which is the number that was already true. It is bounded twice over: each
flagged bot leaves on its next death, and `PrepareRound` calls `Cleanup(true)` which clears `Records`
outright, so retirement state cannot cross a round boundary. In practice the overshoot is the number
of *mid-round* joins, since every round starts from a clean roster.

**Deliberately NOT done: a timeout that removes a long-surviving flagged bot anyway.** It
reintroduces the exact reported symptom on a delay, and the round boundary already bounds the worst
case. If the overshoot ever reads as too crowded, the lever is `MaxBots`, not a retirement deadline.

**Still to verify (human, MCP playtesting unavailable):**
1. Join a match in progress and confirm no bot character disappears — the count corrects over the
   next 30s or so as bots die.
2. Kill a bot that is on its way out and confirm the kill, Cash, XP and quest progress all land.
3. Get rammed by a Bram bot that is flagged to leave and confirm you are released normally.
4. Join, then have someone leave, and confirm the bot count returns to normal without a *new* bot
   appearing from nowhere.
5. Fill a server to 10 and confirm bot population settles back to 4 rather than sitting at 8.
