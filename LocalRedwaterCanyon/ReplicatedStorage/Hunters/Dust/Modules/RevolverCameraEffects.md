---
tags: [client, modulescript, camera, combat]
path: game.ReplicatedStorage.Hunters.Dust.Modules.RevolverCameraEffects
type: ModuleScript
lines: 178
---

# RevolverCameraEffects

OOP camera recoil and FOV effect system using spring physics and smooth damping.

## What it does
1. Manages viewmodel recoil via pitch, yaw, and kick impulses with configurable return speed
2. Applies spring-based camera recoil (strength 70, damping 12) that modifies camera CFrame each frame
3. FOV kick with auto-return after configurable delay (shoot: +3.2, dash: +6)
4. Camera recovery kick after a short delay to counteract the upward recoil
5. `GetViewModelRecoilCFrame` returns a composed CFrame for viewmodel offset
6. `Update(dt)` called each frame to decay recoil values and apply camera modifications
7. Acts as Dust's single FOV compositor — one smooth-damp per frame folds the shoot/dash kick (`TargetFOV`) and the sprint widen (`SprintFOVOffset`) into one value. Sunspike's and Grudgekeeper's compositors were derived from this one and reference its smoothing speed by name.
8. **Releases the camera when idle.** It only writes `FieldOfView` while the composed target or the current value is more than `FOV_IDLE_EPSILON` (0.05) away from `DefaultFOV`; otherwise it clears `FOVActive` and stops writing, so another system can own the camera. On the next active frame it re-captures its smoothing origin from `camera.FieldOfView` rather than easing from a stale value. `ResetFOV` clears the flag too, since it writes a known value directly. This is what lets HighNoon's FOV controller hold the tight ultimate zoom — that controller disconnects once its zoom-in lands, and an unconditional writer here reclaimed the camera on that frame (launch issue #24).

## Dependencies
- **Requires:** Nothing
- **Required by:** FPSRevolverClient

## Connections
### RemoteEvents
None

### BindableEvents
None

### Direct require()
None
