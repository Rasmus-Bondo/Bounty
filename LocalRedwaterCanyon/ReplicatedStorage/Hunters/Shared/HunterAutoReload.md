---
tags: [shared, modulescript, client, ammo, reload]
path: game.ReplicatedStorage.Hunters.Shared.HunterAutoReload
type: ModuleScript
lines: 176
---

# HunterAutoReload

Shared OOP utility that fires a hunter's reload pipeline when ammo transitions to empty. Listens to a `(newAmmo, oldAmmo)` BindableEvent and, after an optional debounce, calls the hunter-provided `TriggerReload` if ammo is still 0 and the hunter's gating allows it — and waits for that gating rather than giving up on it.

Owns only the "transitioned to empty" trigger. Click-fire-when-empty and skill-burst exhaustion stay in each hunter's input handler because they touch hunter-specific input + skill state.

## What it does
1. `.new(config)` — constructs an instance from `{AmmoChangedSignal, GetAmmo, IsReloading, CanReload?, TriggerReload, Debounce?, RetryInterval?, RetryTimeout?}`. All callbacks are hunter-supplied so the module has zero hunter-specific knowledge
2. `:Start()` — subscribes to `AmmoChangedSignal.Event`. On each fire, if `newAmmo == 0` and `oldAmmo > 0`, increments an internal token and schedules an attempt (immediately if `Debounce <= 0`, else via `task.delay`). The token is passed into the attempt rather than re-checked at the call site, so the deferred and immediate paths cannot disagree about what supersedes an attempt in flight
3. `_attempt(token)` re-checks the token, `GetAmmo() == 0`, `not IsReloading()`, and `CanReload()` before calling `TriggerReload()` — guarding against the player reloading manually during the debounce window or other state changes
4. **A `CanReload()` refusal HOLDS the trigger rather than dropping it** (`_retryWhenBlocked`, added 2026-08-12). The attempt re-polls every `RetryInterval` (0.25s) up to `RetryTimeout` (15s) and fires the moment the hunter is allowed to reload again. It used to just return, and the trigger was then gone for good: the ammo-changed signal is edge-triggered on the N→0 transition, so nothing was ever going to raise it a second time. All four hunters fold HunterActionLock into their `CanReload`, so a player pinned by a Bram Breach Charge at the instant the debounce elapsed was left empty with no reload in flight and none pending. Fortuna is the sharp end of it — Dust, Vesper and Bram each reload from a click on an empty gun, so for them a lost trigger costs one wasted click, but her fire path has no such fallback and this is her only automatic route back to a full hand. The retry loop is self-terminating and needs no external cancel: it exits on a superseded token, on `Destroy`, when ammo is no longer 0 (a manual R, the instant reload on respawn and a round-start refill all raise it), and when a reload has begun by any other route. `RetryTimeout` is only a backstop against an unanticipated blocker, and is deliberately generous because expiring early lands straight back on the original bug. `RetryInterval = 0` restores the old drop-it behaviour
5. `:Destroy()` — invalidates the pending token and disconnects the ammo subscription. Bumping the token is also what stops any live retry loop on its next iteration

## Dependencies
- **Requires:** Nothing
- **Required by:** FPSRevolverClient (Dust auto-reloads after firing last bullet), CardsClient (Fortuna auto-reloads after throwing last card), SunspikeClient (Vesper auto-reloads on empty magazine), GrudgekeeperClient (Bram auto-reloads on empty magazine)

## Connections
### RemoteEvents
None

### BindableEvents
None

### Direct require()
None
