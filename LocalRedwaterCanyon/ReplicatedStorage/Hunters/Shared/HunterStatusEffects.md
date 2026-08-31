---
tags: [shared, modulescript, status-effects]
path: game.ReplicatedStorage.Hunters.Shared.HunterStatusEffects
type: ModuleScript
lines: 271
---

# HunterStatusEffects

Shared OOP server-authoritative slow + mark + **stun** tracking. Multiple sources need it: Vesper's Pinning Round (slow + reveal mark), Bram's Shrapnel Shell (slow on hit), Bram's Breach Charge (stun on wall slam), and bot reimplementations of all three. Each source constructs its own instance via `.new()`, so a single victim can be under several instances at once.

Slow and stun are expressed as modifiers on [[HunterMovement]], which owns `Humanoid.WalkSpeed`. This module keeps only the STATUS concepts on top of it.

## What it does
1. `ApplySlow(character, slowPercent, duration)` — registers a proportional slow on [[HunterMovement]] under this instance's own key, with the duration as a TTL. Re-applying refreshes the duration and keeps the stronger magnitude; slows never compound, and only the strongest live slow applies
2. **No base-speed capture.** There is no `StatusBaseWalkSpeed` snapshot any more. A slow is proportional and the base it rides on is recomputed by [[HunterMovement]] every time anything changes, so scope / High Noon / an ultimate dropping the base mid-slow just works. That snapshot going stale in exactly that situation was the 2026-07-17 "goes to normal instead of being slowed" bug
3. **No cross-instance refcount.** The `StatusSlowCount` attribute is gone. Each instance owns a distinct modifier key, so overlapping slows from a second Vesper, a bot Vesper or Bram's shell can never restore over each other — whichever clears last simply leaves no modifiers behind
4. **No per-instance enforcement loop.** The old design wrote WalkSpeed every 0.15s from one Heartbeat per instance (Vesper's, Bram's and the bots' each ran their own). There is now one loop in [[HunterMovement]] for the whole game; the loop that remains here is bookkeeping only, retiring local records and status attributes so `IsSlowed` / `IsStunned` stay honest
5. `ApplyMark(character, duration)` — sets the `StatusMarked` attribute for the duration (refreshing extends it). Reveal visuals are each hunter's own client-side concern (e.g. Vesper's thrower-only Highlight driven by `PinningImpactFX` in SunspikeClient)
6. `ApplyStun(character, duration)` — a hard stun: the victim can't walk or jump. Layered as a **100% slow** (so it keeps the `StatusSlowed` hand-off every client already watches — SprintController and SlowVignetteClient read that attribute) plus a [[HunterMovement]] override pinned at 0 with `LockJump`, which owns the jump save/restore that used to be hand-rolled here. Sets `StatusStunned` for any client that wants a stunned overlay. Re-applying refreshes the duration. Used by Bram's Breach Charge wall slam
7. The `StatusSlowed` attribute is published by [[HunterMovement]], not here — it is the only thing that can see all live slows across every instance
8. `IsSlowed` / `IsStunned` / `ClearSlow` / `ClearStun` (releases the override and with it the jump lock, then lifts this instance's slow) / `ClearMark` / `ClearCharacter` / `Destroy()`. Death and character removal are handled by [[HunterMovement]]'s own teardown, so there are no Died connections here

## Team modes

Every `Apply*` takes an optional attacker and refuses outright when the two are allies, so no
slow, burn or stun crosses teams. All callers pass it.

## Dependencies
- **Requires:** [[HunterMovement]], [[TeamAffinity]]
- **Required by:** SunspikeModule (constructs the Vesper instance handed to PinningRoundService), GrudgekeeperModule (constructs the Bram instance handed to BOTH ShrapnelShellService for the slow AND BreachChargeService for the wall-slam stun), BotCombat (constructs the bots' instance)

## Connections
### RemoteEvents
None

### BindableEvents
None

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[HunterMovement]] | `SetSlow` / `ClearSlow` / `SetOverride` / `ClearOverride` | Register the slow and the stun's movement lock as keyed modifiers instead of writing WalkSpeed |
