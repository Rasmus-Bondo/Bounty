---
tags:
  - server
  - modulescript
  - combat
  - ultimate
  - dust
path: game.ServerScriptService.Hunters.DustServer.HighNoonModule
type: ModuleScript
lines: 461
---

# HighNoonModule

Server-authoritative High Noon ultimate ability: live cone target locking, execute/body shot resolution, charge gating. After the Phase 2 port `Start(runtime)` receives the Dust runtime constructed by RevolverModule — no longer owns its own [[UltimateChargeService]], no longer requires HunterSelectionService or `RevolverRemoteSetup` directly.

## What it does

1. `Start(runtime)` validates the runtime is the Dust runtime (`HunterName == "Dust"`) and has a `ChargeService`; errors loudly if either is wrong
2. Aliases `runtime.IsHunter`, `runtime.ChargeService`, and the High-Noon remotes (`HighNoonRequest`, `HighNoonVisual`, `HighNoonAimUpdate`, `HighNoonShootRequest`, `HighNoonChargeUpdate`, `HighNoonShot`) + `WorldRevolverShotVFX` BindableEvent + cross-hunter remotes — all from the runtime
3. Registers a charge-block predicate via `runtime:AddChargeBlockPredicate` so charge stops accumulating while a High Noon is active (`activeHighNoons[player] ~= nil`). The runtime already gates on `IsHunter`, so the predicate composes correctly
4. Validates activation: player must have full charge, valid character, and not already in High Noon
5. On activation, sets `IsUsingHighNoon` attribute on character (blocks normal revolver fire from RevolverModule), slows walk speed via `HighNoonMovement.Lock`, and broadcasts visual start to all clients
5a. Also publishes **`HighNoonHasLock`** on the character (2026-08-11) — true while at least one target is currently LOCKED, i.e. the skull is up. Maintained by the scan loop and written **only on a change**, since that loop runs every 0.08s and an attribute write replicates to every client that can see the character. Set false on activation as well as in `endHighNoon`, so a stale true cannot carry into the next activation. It exists because `HighNoonShootRequest` on its own cannot distinguish a real execute from a trigger pull at empty air — the client sends it after `MinShootTime` whether or not anything was ever locked — and the onboarding tutorial's ult step has to know the difference. Read-only elsewhere; nothing in normal combat branches on it.
5b. **A tutorial server holds the ultimate open for 12s instead of 5** (`TUTORIAL_MAX_HOLD_TIME` / `holdTimeForThisServer`, 2026-08-16). The lesson's ult step asks a first-timer to read six skulls appearing one by one and then fire, which `MaxHoldTime` 5 does not leave room for. Gated on the `workspace.TutorialMode` attribute rather than on RoundSystem's `State` **so this module gains no new require** — it is the same server-written flag TutorialClient gates itself on, it is never true on a match server or in Frostbite, and that is also what keeps this file byte-identical across the mirror.
6. Live cone targeting: while the ultimate is active, re-scans the cone (`HighNoonTargeting:FindTargets`) every `HIGH_NOON_SCAN_INTERVAL` (0.08s) using the caster's current aim. Each enemy accumulates lock time while inside the cone and becomes locked once held for `LockInTime`; leaving the cone drops its progress (re-entry restarts the timer), so panning onto fresh enemies pulls them in and off the ones you turn away from — no initial snapshot
7. Pushes a caster-only `HighNoonVisual` `"TargetUpdate"` (current targeting + locked lists) whenever that picture changes, so HighNoonClient's lock-on indicators track the cone live (server diffs the two sets and only replicates on change)
8. Shot resolution (on fire, gated by `MinShootTime`; the loop also ends at `MaxHoldTime`): does a final scan and tags each hit — locked targets (held for `LockInTime`) get an execute headshot, enemies in the cone but not yet locked take body damage — then fires once via `HighNoonDamage:ShootTargets` using the per-target `isHeadshot` flag. A locked target is a **guaranteed kill**: the damage service is constructed with `GetLockedShotDamage` (a percentage of the victim's MaxHealth) and `LockedIgnoresDamageReduction`, so the shot is lethal against every hunter's HP pool and punches through Bram's Last Call mitigation
9. Shots fire with a configurable delay between each. HighNoonDamage keeps its own gold-colored `FlashHit` + `SendKillFeed`/`SendKillCam`/`SendHealthBarReveal` independent of [[HunterHitPipeline]], but is wired with `RoundStats = runtime.RoundStats` so kills/damage register correctly (matches HitPipeline's `LastDamager` + `RegisterDamage` + `RegisterKill` hooks — earlier High Noon kills silently dropped from round stats, kill streaks, progression XP, and bounty claims)
10. Continuously receives aim direction updates from the client during the ability
11. Cleans up on character death, player disconnect, ability end, or a **mid-match hunter switch** — a `SelectedHunter` attribute change away from Dust. High Noon's caster-death teardown is normally driven by the `isCharacterAlive` poll in the cone loop, which the death-gated switch respawn (HunterSwitchService) already trips; the switch listener is belt-and-suspenders parity with LastCallModule/CardsServer so the slow WalkSpeed + `IsUsingHighNoon` attribute can never bleed onto the swapped-in hunter. `endHighNoon` is idempotent (bails if there's no active state), so the loop-exit path and the switch listener can't double-tear-down. All paths restore movement, clear state, and broadcast end visuals
11a. **A Bram cancels the ultimate outright** (2026-08-31). The cone loop polls `HunterActionLock.IsLocked` on the caster's character every 0.08s and ends the activation the moment the carry (`StatusPinnedUntil`) or the wall-slam stun (`StatusStunned`) lands — no shot, no refund, full `endHighNoon` teardown. The lock is re-read once more after the loop, because `shotRequested` is written from the remote thread and a slam can land between that handler's own check and the fire. Previously only `HighNoonShootRequest` consulted the lock, which refused the trigger *while* it was up: the 2.5s slam stun sits inside a 5s hold window, so Dust kept his cone, kept accumulating lock time in it, and executed as soon as the stun lapsed. The check covers all four charger/victim pairings because both Bram implementations write the same two attributes.
12. Both `HighNoonRequest` (ultimate activation) and `HighNoonShootRequest` (shot during ultimate) handlers call [[SpawnProtectionService]].onAttack(player) to drop the spawn shield

## Dependencies

- **Requires:** `HighNoonServerConfig`, `HighNoonCharacterUtil`, `HighNoonTargeting`, `HighNoonMovement`, `HighNoonDamage` (all from `ReplicatedStorage.Hunters.Dust.Modules`), [[SpawnProtectionService]] (from `ServerScriptService.Combat`), [[QuestEvents]], [[HunterActionLock]] (from `ReplicatedStorage.Hunters.Shared`); receives [[HunterServerRuntime]] handle from caller (no direct require), [[HighNoonCharacterUtil]], [[HighNoonDamage]], [[HighNoonMovement]], [[HighNoonServerConfig]], [[HighNoonTargeting]]
- **Required by:** Main (passes the Dust runtime returned by RevolverModule.Start)

## Connections

### RemoteEvents

| Remote | Direction | Other script |
|--------|-----------|--------------|
| `HighNoonRequest` | ← Client | Client requests ultimate activation with initial aim |
| `HighNoonAimUpdate` | ← Client | Client sends continuous aim direction updates |
| `HighNoonShootRequest` | ← Client | Client requests to fire during ultimate |
| `HighNoonVisual` | → Client | Broadcasts `CasterStart`/`CasterEnd` to all clients + caster-only `Start`/`TargetUpdate`/`End` (live target lists) |
| `HighNoonChargeUpdate` | → Client | Sends current charge value to the requesting client |
| `HitConfirm` | → Client | Confirms hit/kill to the shooter (via HighNoonDamage) |
| `HighNoonShot` | → Client | Replicates individual shot visuals to all clients |
| `HealthBarReveal` | → Client | Fired to the attacker on hit (via HighNoonDamage) |
| `DamageDirection` | → Client | Tells victim's client where the shot came from (via HighNoonDamage) |
| `KillFeed` | → All Clients | Posts kill-feed entry (via HighNoonDamage) |
| `KillCam` | → Client | Triggers victim's kill-cam (via HighNoonDamage) |

### BindableEvents
None — pre-Phase-2 `HighNoonChargeAward` listener is gone; charge now flows through the runtime-owned [[UltimateChargeService]] directly

### Direct require()

| Target | Function | Purpose |
|--------|----------|---------|
| `HighNoonServerConfig` | config tables, `.GetLockedShotDamage()` | Ultimate / Timing / Targeting / Damage / Movement settings; the locked-shot damage resolver is passed into `HighNoonDamage.new` as `GetLockedShotDamage` (that module requires nothing itself) |
| `HighNoonCharacterUtil` | `.GetPlayerCharacterData()`, `.GetSafeAimDirection()` | Character validation + aim sanitization |
| `HighNoonTargeting` | `.new()`, `:FindTargets()`, `:GetCurrentAim()` | Continuous cone-based target scanning during the ability (set-op helpers no longer used by the live flow) |
| `HighNoonMovement` | `.Capture()`, `.Lock()`, `.Restore()` | Saves/restores walk speed during ultimate |
| `HighNoonDamage` | `.new()`, `:ShootTargets()` | Applies damage to locked targets with shot delay; owns its own feedback (gold flash, kill feed, kill cam, hit confirm, damage direction) independent of [[HunterHitPipeline]] |
| [[SpawnProtectionService]] | `SpawnProtectionService.onAttack()` | Drop the spawn shield on ultimate activation and on each shot |
