---
tags: [shared, modulescript, client, viewmodel, motion]
path: game.ReplicatedStorage.Hunters.Shared.HunterViewModelMotion
type: ModuleScript
lines: 473
---

# HunterViewModelMotion

OOP per-frame viewmodel motion compositor shared across all hunter viewmodels. Owns the always-on base effects (sway, strafe tilt, walk bob, idle bob), plus opt-in effects (jump/land, dash, recoil), plus an arbitrary set of named "extra CFrames" hero-specific animation systems can inject (Fortuna's card flick and reload-left-arm CFrames). Replaces the Dust-only `RevolverViewModelMotion` ModuleScript and the inline motion block in `CardsClient`.

## What it does
1. `.new(config)` — accepts `Player`, `Camera`, `ViewModel`, `BaseOffset`; sway parameters (`SwayMode = "CameraDelta" | "MouseDelta"`, `SwayAmount`, `SwaySpeed`, `SwayRollFactor`); strafe (`StrafeTiltAmount`, `StrafeSideAmount`, `StrafeSmoothSpeed`); walk bob (`BobSpeed`, `BobAmount`, `WalkBobXFactor`, `WalkBobYFactor`); idle bob (`IdleSpeed`, `IdleAmount`, `IdleShape = "Full" | "VerticalOnly"`, `SuppressIdleWhileMoving`); opt-in `EnableJumpLand` + its tuning (`JumpLiftAmount`, `LandingDipAmount`, etc.); opt-in `DashController` (runs dash kick + tumble + ground roll when provided); opt-in `CameraEffects` (appends recoil CFrame when provided)
2. `:Update(deltaTime)` runs once per frame: applies the dash camera offset to `Camera.CFrame` in-place, then composes the final CFrame from `camera * BaseOffset * idle * jumpLand * walkBob * strafe * sway * dash * dashGroundRoll * dashTumble * recoil * extras...` and calls `ViewModel:PivotTo(final)`
3. `:SetExtraCFrame(name, cframe)` — register/update a named extra CFrame appended to the composition in registration order. Fortuna uses this for `BasicFlick` (per-card throw animation) and `ReloadLeftArm`
4. `:ClearExtraCFrame(name)` — drops a named extra CFrame
5. Sway modes:
   - `"MouseDelta"`: reads `UserInputService:GetMouseDelta()` each frame (desktop-only feel — what Dust uses to preserve the original revolver sway)
   - `"CameraDelta"`: computes camera-CFrame delta via `ToObjectSpace + ToOrientation` (input-agnostic — works for mouse, gamepad, touch — Fortuna's default)
6. Idle bob shapes:
   - `"Full"`: XY position + Z roll (Dust default)
   - `"VerticalOnly"`: Y only (Fortuna default — cards in hand look weird with X bob)
7. `SuppressIdleWhileMoving` (Fortuna): zeros idle CFrame when the humanoid is moving and grounded so walk bob + idle don't double up

## Dependencies
- **Requires:** Nothing (uses `UserInputService` directly for `MouseDelta` sway mode)
- **Required by:** FPSRevolverClient (Dust), CardsClient (Fortuna)

## Connections
### RemoteEvents
None

### BindableEvents
None

### Direct require()
None
