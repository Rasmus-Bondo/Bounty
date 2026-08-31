# 10 — Duplicate kill entries in the kill feed

[Open items index](../../OPEN-ITEMS.md) · [Conventions](../../CONVENTIONS.md)

**Closed 2026-08-11** — owner decision: no recurrence in the ~2 weeks since the 2026-08-01 launch. Closed on elapsed time, **not** on a playtest — the status below was still `FIXED (unverified)`.

---

**Status:** FIXED (unverified) · **Sev:** P2 · **Area:** Redwater — kill feed

**Reported:** A kill shows twice in a row in the feed (e.g. "playerY killed playerX" appears two lines running).

**Clarified 2026-08-01:** the killer attribution is **correct** — this is purely a duplicated feed line, not a wrong-killer bug.

**It stays P2 — the escalation the old note asked about does not apply, and this was established
rather than assumed.** `HunterHitPipeline:214-218` says so outright: kill-stat and assist crediting
resolve **once per death** on the universal `Humanoid.Died` handlers via the victim's `LastDamager`
attribute, deliberately *not* on the feed path, so that finishers bypassing the pipeline (zone, fall,
a bot's blow) still credit properly. Cash, XP and quest progress hang off that death resolution, not
off the row. A duplicate row therefore costs nothing but the row.

**One exception, and it is the reason the bot path is gated differently below.**
`BotController:RecordKill` is the only emitter that *also books* the kill — it did
`Record.Stats.Kills += 1` and `FireAllClients` in the same six lines. A double call there would have
doubled the bot's scoreboard kill as well as its feed line. Player kills have no such coupling.

**Diagnosed 2026-08-04: there are exactly three emitters and one listener, and every one of them was
already correctly guarded.** This is the part not to re-derive.

| Emitter | Serves | Kill test |
|---|---|---|
| `HunterHitPipeline:_sendKillFeed` | Dust revolver, Vesper Sunspike + Starfall, Fortuna Cards, Bram Grudgekeeper + abilities | `DidKill` from the caller |
| `HighNoonDamage:SendKillFeed` | Dust's ultimate, its own parallel chain | `oldHealth > 0 and Health <= 0` |
| `BotController:RecordKill` | every bot kill | caller-guarded at both call sites |

`KillFeedClient:506` is the only `OnClientEvent` connection in the place and it is top-level, so the
client cannot double-render. Every caller computes `oldHealth > 0 and Health <= 0`, and `TakeDamage`
is synchronous, so a second hit into a corpse reports no kill. The paths that could plausibly reach
one victim twice were each checked and are closed: Dust's `resolveShot` is an **exclusive** fallback
chain (lag-comp → raycast → forgiveness, first match returns); Bram's cone blast de-dupes its target
list through `seen` in `collectConeTargets` and `GrudgekeeperDamageService:ApplyAccumulatedDamage`
early-returns on a dead humanoid; `applyAbilityDamage` (Breach Charge **and** Shrapnel Shell) does the
same. **No `Humanoid.Died` handler anywhere emits a row.** So the duplicate is a runtime race, not a
structural double-call, and it could not be reproduced by reading.

**Fix (2026-08-04):** new shared `ReplicatedStorage.Hunters.Shared.KillFeedGate`. `Claim` returns
true exactly once per victim **character Model** and false thereafter; all three emitters ask before
firing. The key is sound because a character dies at most once — players get a fresh model from
`LoadCharacter`, arena bots a fresh `template:Clone()` per life (`BotService:_spawnController`), and
even the `BotSpawner2` test dummies destroy and re-clone — so nothing has to clear the entry on
respawn. The table is weak-keyed, so an entry is collected with the model it keys and a long match
cannot accumulate them.

Because the cause is unknown, the gate is **also the diagnostic**: the refused branch warns with both
call sites side by side (killer, victim, weapon and a `source` tag for each), the gap between them,
the victim's full name and `debug.traceback`. The next live export names the root cause with no repro
needed — the technique that closed #25 in one pass, except the fix ships at the same time instead of
waiting on the diagnosis. **When exports stop carrying `[KillFeedGate] duplicate row refused`, the
underlying double-call is gone and the gate can be reconsidered.**

Three choices worth not undoing:
- **Keyed on the character, not a time window.** "Same killer + victim within N seconds" would also
  swallow a legitimate second kill after a fast respawn, and N would be a guess. The character
  instance has no tuning value to get wrong.
- **A non-Instance victim is let through, not refused.** A missing row is a worse failure than a
  duplicated one, so the gate never eats a row it cannot identify.
- **The bot claim is taken before the stat**, not merely before the row, so a refusal keeps stat, row
  and kill cam consistent. On the player path the claim sits *after* the existing nil-guard, so a row
  that was never going to fire does not consume the claim.

Also removed: an unused `killFeedRemote` handle at `BotCombat:56` that resolved the remote and never
fired it — a second emitter there would have bypassed the gate. The vault's `BotCombat.md` claimed it
fired the feed, which was wrong; `BotController:RecordKill` is and was the sole bot emitter.
`KillFeedClient.md` had also named the wrong three emitters. Both corrected.

**Still to verify (human, MCP playtesting unavailable):** play a match with bots and confirm no kill
posts two rows; check the server log for `[KillFeedGate] duplicate row refused` — **its presence is
the win condition, not a failure**, since it means the gate caught the live double-call and the
traceback names it. Confirm a fast respawn-and-die-again still posts its second row (the gate must
not swallow it), and that a bot's scoreboard kill count still tracks its feed lines.
