---
tags:
  - client
  - localscript
  - combat
  - vesper
path: game.StarterPlayer.StarterPlayerScripts.Vesper.SunspikeClient
type: LocalScript
lines: 1593
---

# SunspikeClient

Vesper's client combat controller: fire/reload/ability input, ammo state, tracers, grapple pull execution, and ability FX. First-person presentation (arms viewmodel, camera/mouse lock, mobile aim assist) is NOT here — the generic HunterFirstPersonClient fallback covers any hero that isn't Dust/Fortuna, including Vesper.

Keybinds: LMB / mobile Fire button = shoot, R = reload, Q = Grapple Hook, E = Pinning Round, F = Starfall Sight.

## What it does
1. Requires [[HunterClientRuntime]] + the [[Manifest|Vesper Manifest]]; exits silently when not on Vesper. Aliases `runtime.Remotes.*`, `runtime.ClientEvents.*`, and `runtime.SprintController`
2. **Fire** (`tryFire`): gates on round active / alive / not reloading / 1.8s local cadence; cancels an active sprint (parity with Dust — the trigger pull drops you out of sprint); empty-mag click triggers reload instead. Normal shots send `FireBullet(cameraOrigin, lookVector, muzzlePos)` and draw a raycast-terminated tracer via [[laserBeamEffect]] — the tracer raycast excludes each `HealthPack`'s green `Pickup` + invisible `TouchHitbox` (not the solid `Base`) so the beam passes through the pickup like the server does, and resolves its endpoint through [[BulletPenetration]].Pierce so the trail carries on past penetrable cover instead of stopping short of a victim the server does hit; while Starfall Sight is active shots send `UltimateShotRequest` and draw a full-range piercing beam. Decrements local ammo and fires `AmmoChanged`
3. **Reload**: token-cancellable 3s timer → refills to 4, fires `Reloaded`. Fires `ReloadStarted` the moment a reload begins so [[VesperScopeController]] auto-drops the scope AND blocks re-scoping; fires `ReloadEnded` both on natural completion and on early cancellation (ultimate activation, death, round end) so the scope block always lifts. [[HunterAutoReload]] triggers it automatically 0.25s after ammo hits 0
4. **Grapple pull** (client-owned movement, mirroring the dash lesson): on `GrappleFX("Hit")` for the local player, starts the 8s cooldown UI (`GrappleCooldownStarted`) and pulls by setting `HumanoidRootPart.AssemblyLinearVelocity` toward the anchor every Heartbeat at `distance / TravelTime` speed, stopping at the 4-stud arrival radius, on timeout (2× TravelTime), or on death — then bleeds momentum to 25% so arrival doesn't fling, with the **horizontal** component capped at `GrappleConfig.MaxLandingSpeed` (40). That 25% is a fraction of `distance / TravelTime`, so it grew with hook length unbounded: a max-range hook was released at 89 studs/s and the hop below granted it 0.61s of hang time, carrying Vesper ~55 studs past a perch whose mean width is 20. The cap is XZ-only, so the vertical carry, the hop, and how long the player is airborne before regaining control are all unchanged, and any hook under ~56 studs is unaffected. On a **natural** completion only (arrival radius or timeout — NOT death/respawn/round-end/re-cast) it also applies a little upward hop (`GrappleConfig.HopVelocity`, floored via `math.max` so a steep upward pull is only ever boosted, never cut) so a ground-level grapple can clear a platform lip and land on top. All clients draw an amber rope Beam from the thrower to the hook point for both "Hit" and "Miss"
5. **Pinning Round**: optimistically consumes the 12s client cooldown (`PinningCooldownStarted`) and sends `PinningThrowRequest`. On `PinningLaunchFX` it dead-reckons the visible trail locally every RenderStepped (a recoloured `Hunters.Vesper.Objects.VesperUltTrail2` Part carrying one Beam) from the server-supplied origin/direction/speed — the server replicates no projectile part. The trail raycast mirrors [[PinningRoundService]]`:_buildRaycastParams` (thrower's character, `RewindHitboxes`, HealthPack `Pickup`/`TouchHitbox` but not `Base`) and additionally **passes through gameplay-only volumes** — anything with the `BotAssistHitbox` attribute or named `RewindHitbox`, which are invisible, deliberately oversized, and on a client bot visual are the *only* queryable parts (BotVisualClient). A local ray hit is a **hint only** (`PinningImpactFX` is authoritative), so the beam dissipates over 0.15s instead of freezing in place, with a `Debris:AddItem` backstop sized to the flight window so an anchored beam can never be stranded mid-air. Trails are keyed by caster through `pinningThrowerKey`, which substitutes a shared sentinel when the caster arrives as `nil` — bots are Models in `workspace.ArenaBots`, so a distant one streams out and its Instance reference crosses the remote as nil. On `PinningImpactFX` every client blooms the expanding ForceField zone sphere; `PinningZoneUpdate` then drives per-victim `VesperMarkHighlight` reveals (DepthMode AlwaysOnTop — renders through walls) on enter/exit, cleared on zone end. The reveal is thrower-only by design
6. **Starfall Sight**: `UltimateRequest` at full charge. The ultimate runs on its **own 3-round ammo pool, entirely separate from the magazine** — empowered shots never decrement `S.Ammo`, and the magazine is frozen for the window (both `startReload` and the [[HunterAutoReload]] `CanReload` hook bail while `S.Starfall` is set), so she comes out of the ultimate with exactly the ammo she went in with and a reload can never eat the window. On `UltimateState("Start")` it stores `{ShotsLeft, ShotCount}`, cancels any in-progress reload, and fires `UltimateActiveChanged(true, window)` + `UltimateAmmoChanged(shots, shots)`; each empowered shot decrements `ShotsLeft` and re-fires `UltimateAmmoChanged`. A local `ShotsLeft <= 0` guard blocks a fourth beam in the round-trip gap before the server's "End". On "End" `clearStarfall()` fires `UltimateActiveChanged(false)`, and if the magazine is empty it kicks `startReload` by hand (auto-reload never saw an AmmoChanged during the frozen window). `clearStarfall` also runs on death, respawn and round end so the HUD's pips/timer drop immediately. (Replaced the old GuaranteesAmmo behaviour, which topped the magazine up to 3 and spent magazine ammo per empowered shot)
7. Forwards `UltimateChargeUpdate` → `UltimateChargeChanged` bindable for the HUD
8. Renders other Vesper players' tracers from `ReplicateShot` (round-active gated)
9. Sprint + FOV: `SetCanSprintCheck` returns false while scoped (scope state arrives via the `ScopeChanged` bindable from [[VesperScopeController]]); scoping in also cancels an active sprint; drives `runtime.SprintController:Update` every RenderStepped. **This script is the single authority over `camera.FieldOfView` for Vesper** (mirrors Dust's RevolverCameraEffects): a per-frame `smoothDamp` (speed 14) toward one shared target that composes scope (`ScopeConfig.ADSFOV` 35 while `S.IsScoped`) and sprint (base 70 + `GetSprintAlpha()`×8) — so a scope→sprint handoff eases in one continuous motion and a sprint cancel eases back, never snapping. Gated on alive (hands FieldOfView to KillCam/showcase when dead) and idles out once settled at base. [[VesperScopeController]] no longer writes FieldOfView itself. **The same loop publishes `SprintChanged` on the state edge (2026-08-11)** so the viewmodel can hold a sprint pose: SprintController exposes a ramp rather than a signal, and every `HunterClientRuntime.Start` call builds its *own* controller, so this script's is the only one ever `Update()`d and no other script can read it. The publish is gated on `isAlive` so death drops the pose that frame instead of waiting out the 0.15s deceleration, and on **actual movement** (`MoveDirection.Magnitude > 0.05`, 2026-08-22) — the ramp tracks sprint *intent*, so holding Shift while standing still played the run pose on a stationary Vesper; same gate Bram's viewmodel `Running` loop uses. Only the animation is movement-gated: the FOV widen and the speed buff still ride the raw ramp. Fires only on a change since the loop runs every frame
10. Listens to the mobile-button bindables (FireRequested / GrappleRequested / PinningRequested / UltimateRequested / ReloadRequested fired by [[VesperHunterGuiClient]])
11. Resets ammo/reload/pull/ultimate state on CharacterAdded, death, and round end
12. **Auto-fire (touch only, 2026-08-07):** Vesper's camera magnetism lives in HunterFirstPersonClient, so this script runs its own **rotation-disabled** [[AimAssistController]] instance (`Enabled = false` — after the acquire/rotate eligibility split that stops magnetism but not acquisition) purely as the lock source, with `SetCanAimAssistCheck(isCombatAllowed)` and the whole camera subtree excluded from its LOS ray (the arms viewmodel is parented under the camera). A [[MobileAutoFireController]] reads its `GetLock()` and calls `tryFire()` at `BasicConfig.Cooldown` intervals; both are ticked in a dedicated `BindToRenderStep("VesperAutoFire", Camera.Value + 2)` — one priority after HunterFirstPersonClient's magnetism at Camera+1, so the lock is measured against the camera the shot ray will use, with `SetCamera(workspace.CurrentCamera)` refreshed per frame. **The scope gate was REMOVED 2026-08-07** after a mobile playtest reported scoped auto-fire as "very unreliable". It used to hold fire while `S.IsScoped` until `os.clock() - S.ScopedSince >= DeadeyeFocus.RampTime` (3s), to protect the passive's headshot bonus from `ResetOnFire`. Three seconds of dead trigger with the crosshair on an enemy reads as auto-fire being broken, and the bonus it protected is **headshot-only** while the lock is measured from the target's **root** — so it was spending every scoped shot to preserve a bonus that mostly did not apply. `CanAutoFire` is now just `isCombatAllowed`, and scoped and hipfire behave identically. A player who wants to charge Deadeye holds fire manually with auto-fire off in settings. `S.ScopedSince` went with it (write-only once the gate was gone; VesperHunterGuiClient keeps its own `scopedSince` local for the ramp bar and never read this one). `OnLockChanged` publishes the `AutoFireLocked` player attribute (currently unconsumed — the lock ring was removed 2026-08-07). Teardown unbinds the render step and destroys both instances pcall-guarded (a leaked binding would keep firing Vesper's rifle for the swapped-in hunter; a duplicate named bind would error on swap-back)
12. **[TEMP DEBUG]** On each empowered shot, `drawUltimateRingsDebug` draws 3 nested Neon cylinders (caster-only, not replicated) along the shot spanning `UltimateConfig.Range`, sized/colored per `UltimateConfig.Rings` radius+damage tier, auto-cleaned up after 5s — visualizes the piercing damage falloff zones for tuning. Remove before ship

## Dependencies
- **Requires:** [[HunterClientRuntime]], [[HunterActionLock]], [[HunterAutoReload]], [[HunterMobileSprintButton]], [[HunterMobileReloadButton]], [[AimAssistController]], [[MobileAutoFireController]], [[BulletPenetration]] (from `ReplicatedStorage.Hunters.Shared`); [[Manifest|Vesper Manifest]] + [[VesperConfig]] (from `ReplicatedStorage.Hunters.Vesper.Config`); [[laserBeamEffect]] + [[RevolverConfig]] (from `ReplicatedStorage.Hunters.Dust.Modules`), [[HunterClientState]]
- **Required by:** Nobody

## Connections
### RemoteEvents
| Remote | Direction | Other script |
|--------|-----------|-------------|
| `FireBullet` | → Server | [[SunspikeModule]] resolves the shot |
| `UltimateShotRequest` | → Server | [[StarfallSightModule]] resolves the piercing shot |
| `UltimateRequest` | → Server | [[StarfallSightModule]] activates at full charge |
| `UltimateState` | ← Server | [[StarfallSightModule]] Start/End (ammo guarantee + shot mode) |
| `UltimateChargeUpdate` | ← Server | Charge value from the runtime-owned UltimateChargeService |
| `GrappleRequest` | → Server | [[GrappleHookService]] validates the hook |
| `GrappleFX` | ← Server | [[GrappleHookService]] hit/miss verdict + anchor point |
| `PinningThrowRequest` | → Server | [[PinningRoundService]] launches the projectile |
| `PinningLaunchFX` | ← Server | [[PinningRoundService]] origin/direction/speed/flight time for the local trail sim |
| `PinningImpactFX` | ← Server | [[PinningRoundService]] authoritative landing position + zone duration |
| `PinningZoneUpdate` | ← Server | [[PinningRoundService]] per-victim zone enter/exit + zone end (thrower only) |
| `ReplicateShot` | ← Server | Other players' tracers |

### BindableEvents
| Bindable | Direction | Other script |
|----------|-----------|-------------|
| `AmmoChanged` | → | [[VesperHunterGuiClient]] updates ammo display |
| `Reloaded` | → | [[VesperHunterGuiClient]] resets bullet icons |
| `GrappleCooldownStarted` | → | [[VesperHunterGuiClient]] Skill1 cooldown UI |
| `PinningCooldownStarted` | → | [[VesperHunterGuiClient]] Skill2 cooldown UI |
| `UltimateChargeChanged` | → | [[VesperHunterGuiClient]] ultimate charge display |
| `UltimateActiveChanged` | → | [[VesperHunterGuiClient]] Starfall window start/end (countdown + pip row + magazine dim) |
| `UltimateAmmoChanged` | → | [[VesperHunterGuiClient]] empowered rounds left in the ult ammo pool |
| `ScopeChanged` | ← | [[VesperScopeController]] scope state (sprint blocking) |
| `SprintChanged` | → | [[VesperViewModelAnimationClient]] holds / drops the viewmodel sprint pose |
| `ReloadStarted` | → | [[VesperScopeController]] auto-unscope + blocks re-scoping on reload |
| `ReloadEnded` | → | [[VesperScopeController]] lifts the scope block (completion or early cancel) |
| `FireRequested` | ← | [[VesperHunterGuiClient]] mobile Fire button |
| `GrappleRequested` | ← | [[VesperHunterGuiClient]] mobile Skill1 button |
| `PinningRequested` | ← | [[VesperHunterGuiClient]] mobile Skill2 button |
| `UltimateRequested` | ← | [[VesperHunterGuiClient]] mobile Ultimate button |
| `ReloadRequested` | ← | [[VesperHunterGuiClient]] (declared; no dedicated mobile button yet — auto-reload covers empty mags) |

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[HunterClientRuntime]] | `.Start(manifest)` | Hero gate + remote/event resolution + SprintController |
| [[Manifest|Vesper Manifest]] | (table return) | Declarative description of Vesper |
| [[VesperConfig]] | config tables | Basic/Grapple/Pinning/Ultimate tuning |
| [[HunterAutoReload]] | `.new()`, `:Start()` | Auto-reload on empty magazine |
| [[laserBeamEffect]] | `(startPos, endPos)` | Tracer beams (own shots + replicated) |
| [[BulletPenetration]] | `.Pierce()` | Walks the local tracer through penetrable cover so the visual matches the server's shot |
| [[HunterMobileSprintButton]] | `.new()`, `:Start()` | Mobile SPRINT toggle button wired to `runtime.SprintController` (replaces the old left-screen double-tap-to-sprint gesture; touch only) |
| [[AimAssistController]] | `.new()`, `:SetCanAimAssistCheck()`, `:SetCamera()`, `:Update()`, `:GetLock()`, `:Destroy()` | Rotation-disabled instance (`Enabled = false`) used purely as the auto-fire lock source — magnetism stays in HunterFirstPersonClient |
| [[MobileAutoFireController]] | `.new()`, `:Update()`, `:Destroy()` | Touch-only auto-fire while the lock holds; calls `tryFire()`. `CanAutoFire = isCombatAllowed` only — the Deadeye ramp scope gate was removed 2026-08-07, so scoped and hipfire behave identically. No `MaxLockDistance`: Vesper is deliberately uncapped. **`FireQuality = 0.55`** — the only hunter that sets it, requiring the crosshair well inside tolerance rather than merely inside it, because her shots are the scarcest in the roster (4 rounds, 3s reload, 1.8s between) and she fights where the tolerance is under a degree |
| [[RevolverConfig]] | `.AimAssist` table | Lock-source tuning (`MaxRange`, `AcquireConeDeg`, `LockRadiusStuds`, `MaxLockAngleDeg`) shared with every other hunter's assist |

### CollectionService Tags
| Tag | Usage | Defined by |
|-----|-------|-----------|
| `HealthPack` | Read via `GetTagged`; each pack's green `Pickup` + invisible `TouchHitbox` added to the local tracer raycast Exclude list so the beam passes through the pickup (the solid `Base` stand still stops it) | [[HealthPackSystem]] |
