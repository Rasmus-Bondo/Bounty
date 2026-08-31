---
tags: [client, modulescript, viewmodel, visual]
path: game.ReplicatedStorage.Hunters.Dust.Modules.RevolverLeftArm
type: ModuleScript
lines: 210
---

# RevolverLeftArm

OOP controller for the viewmodel left arm visibility with token-based tween cancellation.

## What it does
0. `new()` accepts **either a single instance or a list** of them, held as `LeftArmParts`. Dust's viewmodel carries the original blocky `LeftArm` *and* the `LeftArmSmooth` mesh welded alongside it as a **sibling**, so one instance is no longer enough — callers pass RevolverViewModel's `LeftArmParts`. `Destroy()` empties that list rather than nil'ing it, because the render loop keeps calling `Update()` for the frames around teardown and an empty list no-ops where nil would error on `ipairs`
1. Manages transparency of every part in the set plus all their BasePart/Decal/Texture descendants
2. Supports instant show/hide, tween visible/hidden with configurable duration
3. Force-hidden mode: temporarily hides the arm for a specified duration regardless of desired state
4. Token system ensures only the latest visibility command takes effect
5. `Update()` called each frame to enforce force-hidden state and restore desired transparency when expired
6. `SetHoldVisible(hold)` **latches** the arm on screen: while held, `SetVisibleInstant(false)`, `ForceHiddenFor`, `TemporarilyHideFor` and `TweenVisible(false)` all no-op, and switching the latch on clears any force-hide window already in flight (otherwise `Update()` keeps painting transparency 1 over the held arm until it expires). Added 2026-08-09 for Dust's ultimate, which poses **both** hands — its draw clip and the per-shot Fan-The-Hammer replays each animate LeftArm

Why the ultimate needs a latch rather than a one-shot show: the hides that would undo it land *later* than the call that starts the ability. FPSRevolverClient cancels Skill2 and reload at ultimate start, but RevolverSkill2's burst coroutine runs on past its own `Cancel()` and force-hides the arm a few frames in — which blanked it for the rest of the ultimate. Every release path (ultimate end, and `stopLocalGunState` on death or round end) must drop the latch before hiding, or the hide is swallowed by it.

Because every visibility path (`SetVisibleInstant`, `TweenVisible`, `ForceHiddenFor`, `TemporarilyHideFor`, `SetHoldVisible`, `Update`) resolves its targets through the one `_getTransparencyObjects` helper, widening that helper to a list was the whole of the smooth-arm fix — no caller changed behaviour. The net effect is that the smooth left arm now follows the identical contract as the old one: hidden by default, visible only while reloading, during Fan-The-Hammer, and for the High Noon ultimate.

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
