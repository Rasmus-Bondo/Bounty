---
tags:
  - client
  - localscript
  - combat
  - viewmodel
  - dust
path: game.StarterPlayer.StarterPlayerScripts.Dust.FPSRevolverClient
type: LocalScript
lines: 1425
---

# FPSRevolverClient

Core client-side FPS controller handling the first-person view model, shooting, reloading, dashing, Skill2 (fan fire), air hang, camera recoil, and input routing. After the Phase 3 port the init prelude delegates hunter gate + folder/remote/event/viewmodel-template lookup to [[HunterClientRuntime]] driven by the [[Manifest|Dust Manifest]]; the entry script is now under `StarterPlayerScripts.Dust/` for symmetry with the `Fortuna/` folder.

## What it does

1. Requires [[HunterClientRuntime]] + the [[Manifest|Dust Manifest]] and calls `HunterClientRuntime.Start(dustManifest)`; if not on Dust, the runtime returns nil and the script silently exits — no more inline `waitForSelectedHunter` block
2. Aliases `runtime.Remotes.{FireBullet, ReplicateShot, DashRequest, HighNoonVisual}`, `runtime.ClientEvents.{AmmoChanged, Reloaded, DashCooldownStarted, Skill2CooldownStarted, DashRequested, Skill2Requested}`, and `runtime.Viewmodel.Template`
3. Locks camera to first-person, hides mouse cursor, locks mouse to center
4. Creates the ClientViewModel from the runtime's viewmodel template and attaches it to the camera. It samples `EquippedWeaponSkin_Dust` **once**, at boot, to pick the skinned template, and `RevolverViewModel.Create` is called from this one site only — respawns just re-show the same model via `setViewModelEnabled`, and the resulting `viewModel` / `handle` / `muzzlePart` references are captured by ~10 sub-modules, so there is no cheap rebuild. Correctness therefore depends on the attribute being final before this line runs, which is what HunterSelectionService's direct-joiner publish barrier guarantees (Fortuna's CardsClient instead rebuilds on an `EquippedWeaponSkin_Fortuna` changed listener)
5. Initializes 14 hunter-specific sub-modules (kept as direct requires — they're Dust-only):
   - **Shooting**: raycasts from camera, fires `FireBullet` to server, plays muzzle VFX/sounds/animations, applies recoil + FOV kick
   - **Reloading**: timed reload with left-arm tween animations, reload sound, finish sound, blocks shooting during reload
   - **Dashing**: sends `DashRequest` to server, applies client-side velocity, tumble/roll view model animation, FOV kick, instant reload on ground dash
   - **Skill2 (Fan Fire)**: rapid 6-shot burst with reduced recoil, left-arm fanning animation, cooldown, auto-reload after
   - **Air Hang**: applies upward VectorForce while airborne to slow falls (configurable strength)
6. Manages view model motion via [[HunterViewModelMotion]]: sway, strafe tilt, walk bob, idle bob, jump lift, dash tumble — all composed per frame at RenderPriority.Camera + 1
7. Routes input via RevolverInput: mouse1/touch = shoot, R = reload, Q = dash, E = Skill2
8. Runs [[AimAssistController]] each frame between cameraEffects and viewModelMotion, gated to touch-only inputs; the SetCanAimAssistCheck callback disables it whenever `isUsingHighNoon` is true so it doesn't fight High Noon's own targeting. Immediately after it, ticks a [[MobileAutoFireController]] (touch only) that calls `shoot()` directly — never the `FireRequested` bindable, which HighNoonClient also connects — while the assist's `GetLock()` report holds; its `CanAutoFire` gate is `isLocalCombatAllowed() and not isUsingHighNoon`, its `FireInterval` is the weapon's `fireCooldown`, and its `OnLockChanged` publishes the `AutoFireLocked` player attribute (currently unconsumed — the lock ring was removed 2026-08-07). The controller is also ticked in the render loop's not-combat-allowed early-out (where the gate fails) so death or round-end resets the lock state the same frame, and destroyed pcall-guarded in the hunter-switch teardown
8. Listens to mobile BindableEvents (DashRequested, Skill2Requested) for touch input
9. Listens to `ReplicateShot` to render other players' laser beam tracers
10. Listens to `HighNoonVisual` to disable shooting and cancel active abilities when High Noon starts/ends. Since 2026-08-09 `Start` also **latches the left arm visible** (`leftArmController:SetHoldVisible(true)`) instead of hiding it, because the ultimate's draw clip and its per-shot Fan-The-Hammer replays both pose LeftArm. It has to be a latch, not a plain show: the Skill2 and reload cancels immediately above finish asynchronously — RevolverSkill2's burst coroutine runs on past its own `Cancel()` — and their trailing force-hide would otherwise blank the arm a few frames into the ultimate and leave it blank. `End` releases the latch *before* hiding, and `stopLocalGunState` does the same so dying or a round end mid-ultimate can't pin the arm visible into the next life
11. Fires ammo/cooldown BindableEvents to update the HUD
12. Builds the shared mobile **SPRINT** toggle button ([[HunterMobileSprintButton]]) wired to the runtime `SprintController` — replaces the old left-screen double-tap-to-sprint gesture (touch only)
12a. Resolves Dust's first-person locomotion each frame into one of three states and pushes it to `RevolverAnimations:SetLocomotion(...)`: `Run` while sprinting, `Walk` while moving on the ground otherwise, `Idle` when airborne or stationary — sprinting on the spot included. Movement is read off `currentHumanoid` (`MoveDirection.Magnitude > 0.05` and `FloorMaterial ~= Air`), the same idiom the air-hang code uses. The combat-disallowed branch pushes `Idle`, since a held loop is the one viewmodel track nothing else stops and it would otherwise resume mid-stride on the next spawn. Added 2026-08-29: both clips were authored but installed on no rig, so Dust's locomotion was procedural bob alone while the other three hunters had arm cycles. They layer **under** `EnableSprintViewModelMotion`, not instead of it
13. Supplies the `SetCanSprintCheck` gate: combat allowed, not High Noon. The dash is deliberately **not** in the gate — gating it collapsed the sprint alpha to 0 for the dash's duration, which read as an FOV drop around the dash's own FOV kick. Each frame it publishes `cameraEffects.SprintFOVOffset = sprintAlpha * SprintFOVIncrease`, which RevolverCameraEffects adds on top of `TargetFOV`, so the sprint widen and the dash/shoot FOV kicks compose

## Dependencies

- **Requires:** [[HunterClientRuntime]], [[HunterActionLock]], [[HunterViewModelMotion]], [[HunterAutoReload]], [[AimAssistController]], [[MobileAutoFireController]], [[HunterMobileSprintButton]], [[HunterMobileReloadButton]] (all from `ReplicatedStorage.Hunters.Shared`); [[Manifest|Dust Manifest]] (from `ReplicatedStorage.Hunters.Dust.Config`); [[HunterClientState]]; [[RevolverConfig]], [[RevolverSoundService]], [[RevolverVFXService]], [[RevolverViewModel]], [[RevolverLeftArm]], [[RevolverCameraEffects]], [[RevolverAnimations]], [[RevolverAmmo]], [[RevolverInput]], [[RevolverDash]], [[RevolverShooting]], [[RevolverSkill2]], [[RevolverReload]], [[laserBeamEffect]] (all from `ReplicatedStorage.Hunters.Dust.Modules`). No longer requires `RevolverRemotes` or `RevolverClientEvents` — runtime resolves both.
- **Required by:** Nobody

## Connections

### RemoteEvents

| Remote | Direction | Other script |
|--------|-----------|--------------|
| `FireBullet` | → Server | [[RevolverModule]] processes the shot |
| `ReplicateShot` | ← Server | [[RevolverModule]] replicates other players' tracers |
| `DashRequest` | → Server | [[RevolverModule]] executes server-side dash |
| `HighNoonVisual` | ← Server | [[HighNoonModule]] syncs High Noon start/end state |

### BindableEvents

| Bindable | Direction | Other script |
|----------|-----------|--------------|
| `AmmoChanged` | → | [[HunterGuiClient]] updates ammo counter |
| `Reloaded` | → | [[HunterGuiClient]] resets bullet icons |
| `DashCooldownStarted` | → | [[HunterGuiClient]] starts Skill1 cooldown, [[LandingImpactClient]] adds the dash camera kick |
| `Skill2CooldownStarted` | → | [[HunterGuiClient]] starts Skill2 cooldown |
| `DashRequested` | ← | [[HunterGuiClient]] mobile dash button |
| `Skill2Requested` | ← | [[HunterGuiClient]] mobile Skill2 button |
| `FireRequested` | ← | [[HunterGuiClient]] mobile Fire button (replaced TouchTap-anywhere in [[RevolverInput]]) |

### Direct require()

| Target | Function | Purpose |
|--------|----------|---------|
| [[HunterClientRuntime]] | `.Start(manifest)` | Hunter gate + folder/remote/event/viewmodel-template resolution; returns runtime handle |
| [[Manifest|Dust Manifest]] | (table return) | Declarative description of Dust |
| [[RevolverConfig]] | config tables | Combat, Skill2, Dash, Reload, ViewModel, Recoil, AirHang settings |
| RevolverSoundService | `.PlayFire()`, `.PlayTrigger()`, `.PlayDash()`, `.PlayReloadSound()`, etc. | All weapon and ability sounds |
| RevolverVFXService | `.PlayMuzzleEffects()` | Muzzle flash and smoke particles |
| RevolverViewModel | `.Create()` | Creates the first-person arms + revolver model |
| RevolverLeftArm | `.new()` | Left arm visibility controller with tween support. Passed `viewModelData.LeftArmParts` (falling back to `.LeftArm`) so the sibling `LeftArmSmooth` mesh fades with the blocky arm instead of staying on screen |
| RevolverCameraEffects | `.new()` | Recoil impulse, FOV kick, per-frame camera updates |
| RevolverAnimations | `.new()` | Shoot, reload, Skill2 animation tracks |
| RevolverAmmo | `.new()` | Ammo tracking, reload state, fires AmmoChanged/Reloaded |
| RevolverInput | `.new()`, `:Start()` | Keyboard/mouse/touch input routing |
| RevolverDash | `.new()`, `:TryDash()`, `:GetIsDashing()`, `:UpdatePostDashVelocityClamp()` | Client-side dash execution and state |
| RevolverShooting | `.new()`, `:FireOneBullet()` | Raycast, fire remote, VFX, recoil per shot |
| [[HunterViewModelMotion]] | `.new()`, `:Update()` | Per-frame sway/bob/strafe/tumble composition |
| RevolverSkill2 | `.new()`, `:TryUse()`, `:Cancel()`, `:GetIsUsing()` | Fan fire burst ability |
| RevolverReload | `.new()`, `:Start()`, `:Cancel()`, `:InstantReload()` | Timed reload with animations/sounds |
| [[HunterAutoReload]] | `.new()`, `:Start()` | Triggers `reload()` when ammo transitions to 0 |
| [[AimAssistController]] | `.new()`, `:SetCanAimAssistCheck()`, `:Update()` | Touch-only camera magnetism toward enemies, disabled during High Noon |
| [[MobileAutoFireController]] | `.new()`, `:Update()`, `:Destroy()` | Touch-only auto-fire while the assist's lock holds; calls `shoot()` directly, gated off during High Noon. Passes `MaxLockDistance = CombatConfig.Range` (250) as of 2026-08-29, following Fortuna's and Bram's convention — the shared `AimAssistConfig.MaxRange` is 350 and belongs to Vesper, so without this cap a mobile Dust auto-fires at targets his shot cannot reach |
| [[HunterMobileSprintButton]] | `.new()`, `:Start()` | Mobile SPRINT toggle button wired to `runtime.SprintController` |
| laserBeamEffect | `(start, end)` | Renders third-person shot tracer beams |
