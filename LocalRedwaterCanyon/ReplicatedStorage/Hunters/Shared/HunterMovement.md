---
tags: [shared, modulescript, movement, status-effects]
path: game.ReplicatedStorage.Hunters.Shared.HunterMovement
type: ModuleScript
lines: 613
---

# HunterMovement

The single owner of `Humanoid.WalkSpeed` for every hunter character in Redwater — players and bots. Every movement-speed effect registers a **named modifier** here and the service resolves them into one number. Nothing else in the game writes WalkSpeed.

## What it does
1. **Resolves speed from a modifier set, never from a snapshot.** `override present -> min(overrides)`, otherwise `clamp(base * PRODUCT(buffs) * MIN(slows), 0, ceiling)`. The recurring "hunter is permanently slowed" bug class came from a dozen scripts each snapshotting the live WalkSpeed as "the value before me" and writing it back later; a snapshot taken during someone else's effect locks that effect in forever. Here the value is recomputed from the active modifiers every time anything changes
2. **Four layers.** `Base` — absolute resting speed, highest `Priority` wins (Passive 0 / Ability 10 / Ultimate 20), later Set breaks ties: hunter passive 16 (Fortuna 24), Vesper scope 6, Dust High Noon 6, bot dash burst. `Buff` — proportional, multiplies with every other buff: sprint ramp, Bram's Last Call. `Slow` — proportional, **strongest wins and slows never compound** (the balance rule the old HunterStatusEffects hand-rolled with `math.max` plus a `StatusSlowCount` refcount). `Override` — hard lock beating everything, most restrictive wins so two simultaneous locks (stun + pin) each hold until BOTH release
3. Base-vs-buff is a load-bearing distinction: scope and High Noon are absolute intents ("crawl at 6") and a slow must ride on top of them (`6 * 0.75 = 4.5`), never measure against the hunter's passive
4. **Keyed modifiers** — `SetBase` / `SetBuff` / `SetSlow` / `SetOverride` + matching `Clear*`, all taking a string key. Re-applying the same effect is idempotent, so nothing compounds and no caller needs a manual refcount
5. **TTL on any modifier** — every setter accepts a `Duration` (bare number or `{ Duration = n }`). A caster who dies, errors or hunter-switches mid-effect cannot strand one; the enforcement loop expires it. This is the property that turns a leaked modifier from a permanent bug into a self-healing one
6. **Per-character state, auto-wiped** on `Humanoid.Died` and on `AncestryChanged` to nil parent. The second path covers the mid-match hunter switch, which respawns WITHOUT firing Died. State lives in a weak-keyed table
7. **Jump locking** — `{ LockJump = true }` on a Base or Override saves and restores the humanoid's real `UseJumpPower` / `JumpPower` / `JumpHeight` / `AutoJumpEnabled`, replacing the same save-restore hand-rolled in three other scripts. Publishes `MovementJumpLocked` because `SetStateEnabled(Jumping, false)` is bypassed by ManuelJumpClient's `ChangeState` — the real gate is `canJump()`
8. **Publishes its result** on the character: `MoveSpeed` (resolved number), `MoveSpeedVersion` (bumped only when MoveSpeed actually changes, so the 10Hz loop does not churn replication), `MovementJumpLocked`, and `StatusSlowed` — the last of these lives here rather than in HunterStatusEffects because this service is the only thing that can see all live slows at once
9. **Client prediction without double-counting.** On the client the base is seeded from the server's published `MoveSpeed` instead of from local Bases, then only locally-owned modifiers (the sprint ramp) are applied on top. A client modifier therefore cannot double-count a server one. `PredictBase(character, value, duration)` covers the one case the client leads on (Vesper's scope): it stands in for the server seed until the server acknowledges and expires by itself if the server rejects the request — so the old "fire the remote AFTER the local write" ordering rule no longer matters
10. **One enforcement loop for the whole game** (10Hz) instead of one per HunterStatusEffects instance. It expires TTLs and re-asserts on drift. On the server drift means a rogue writer, and in Studio it warns with the full modifier stack
11. `Get(character)` — the resolved speed; callers that used to read live WalkSpeed to find "the normal speed" want this. `Explain(character)` — dumps why the character is moving at this speed (`base=6.00 / base:VesperScope=6.00 p10 / slow:Status1 x0.75`). Every permanent-slow report so far cost a full source audit because there was no way to ask the running game
12. `IsSlowed` / `ClearPrediction` / `ClearAll` round out the surface

## Dependencies
- **Requires:** Nothing
- **Required by:** HunterStatusEffects, HunterServerRuntime, SprintController, HighNoonMovement, SunspikeModule, VesperScopeController, CardsServer, LastCallModule, BreachChargeService, RoundController, BotController, BotCombat

## Connections
### RemoteEvents
None

### BindableEvents
None

### Direct require()
None
