---
tags: [shared, modulescript, combat, kill-feed, diagnostic]
path: game.ReplicatedStorage.Hunters.Shared.KillFeedGate
type: ModuleScript
lines: 89
---

# KillFeedGate

One kill-feed row per death — a shared claim gate every kill-feed emitter asks before firing, which also warns with a traceback when it refuses (launch issue #10).

## What it does
1. `.Claim(victimCharacter, killerName, victimName, weaponName, source)` returns `true` exactly once per victim character Model and `false` for every later call naming the same one. Callers fire their kill-feed row only when it returns `true`.
2. Keys on the **victim's character Model**, which is sound because a character dies at most once: players get a fresh model from `LoadCharacter`, arena bots a fresh `template:Clone()` per life from BotService's `_spawnController`. Nothing has to clear the entry on respawn.
3. Stores entries in a **weak-keyed table**, so a record is collected along with the character Model it keys. A long match cannot accumulate them and there is no teardown hook to forget.
4. A `victimCharacter` that is not an Instance is **let through** rather than refused — a missing kill-feed row is a worse failure than a duplicated one, so the gate never swallows a row it cannot identify.
5. **The refusal branch is the diagnostic.** It warns with both call sites side by side (killer, victim, weapon and `source` tag for the refused row and for the one that already posted), the gap between them, the victim's full name, and `debug.traceback`, so a live log export names the root cause of the duplicate without needing a repro.

## Why it exists
Every emitter's own kill test was already correct: each computes `oldHealth > 0 and Health <= 0`, and `TakeDamage` is synchronous, so a second hit into a corpse reports no kill. No path could be shown to double-call by reading — Dust's `resolveShot` is an exclusive fallback chain, Bram's cone blast de-dupes its target list via `seen`, and no `Humanoid.Died` handler emits a row at all. The gate therefore closes the symptom on an invariant that holds whatever the cause turns out to be, while the warn identifies that cause from the next export.

**The warn did its job — cause found 2026-08-13.** There was no double-call. Because every emitter demands `Health > 0` *before* it damages anything, a refusal is proof the same body was lethally damaged **twice**: Roblox's default `Health` script (inserted into every player character, no dead check of its own) was ticking corpses back above 0, and the shooter's next round found a live-looking target and killed it again. Bots never appeared as victims because a cloned rig never receives that script — which is what identified it. Fixed in HunterCharacterUtil (`IsAlive` tests the Dead state; the `Died` handler pins the corpse at zero). The gate stays as the standing check on that fix: a refusal now means a body survived its own death again.

Deliberately **not** a time window. "Same killer and victim within N seconds" would also swallow a legitimate second kill after a fast respawn, and N would be a guess; the character instance has no tuning value to get wrong.

Once exports stop carrying `[KillFeedGate] duplicate row refused`, the underlying double-call is gone and the gate can be reconsidered.

## Dependencies
- **Requires:** Nothing
- **Required by:** HunterHitPipeline (all four hunters' basic and ability kills), HighNoonDamage (Dust's ultimate, its own parallel chain), BotController (every bot kill)

## Connections
### RemoteEvents
None — it gates the `KillFeed` remote's callers rather than firing anything itself.

### BindableEvents
None

### Direct require()
None
