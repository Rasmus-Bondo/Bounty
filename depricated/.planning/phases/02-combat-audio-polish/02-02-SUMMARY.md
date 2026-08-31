---
phase: 02-combat-audio-polish
plan: 02
status: complete
started: "2026-03-29T00:15:00Z"
completed: "2026-03-29T00:45:00Z"
---

# Summary: Fix Crosshair Alignment and Arm Positioning

## What Was Built

Fixed crosshair-to-bullet alignment by solving two root causes: third-person camera parallax (horizontal offset) and GuiInset coordinate mismatch (vertical offset). Arm positioning was investigated and confirmed working as-is.

## Tasks Completed

1. **Camera parallax fix** — Rewrote `getShotDirection()` to perform a camera preliminary raycast from viewport center to find the actual surface point the crosshair aims at, then compute muzzle-to-target direction. This eliminates the horizontal offset caused by the shoulder camera being 3.25 studs right of the character.

2. **GuiInset vertical fix** — Set `RevolverGui.IgnoreGuiInset = true` so the crosshair is positioned relative to the full screen. Crosshair Position set to `UDim2(0.5, 0, 0.5, 0)` with AnchorPoint `(0.5, 0.5)`. Previously, `IgnoreGuiInset = false` caused the crosshair to render ~18px below viewport center while `ViewportPointToRay` targeted true center.

3. **Arm positioning verified** — IKControl with ChainRoot=rightUpperArm confirmed working correctly. Attempted ChainRoot=upperTorso per original plan but it broke arm visibility (too much IK freedom). Reverted — arm was fine as-is.

## Key Files

- `game.ServerStorage.BanditGun.GunClient` — `getShotDirection()` rewritten with camera preliminary raycast using `ViewportPointToRay`
- `game.StarterGui.RevolverGui` — `IgnoreGuiInset = true`
- `game.StarterGui.RevolverGui.Crosshair` — Position `(0.5, 0, 0.5, 0)`, AnchorPoint `(0.5, 0.5)`

## Deviations

- IKControl ChainRoot change reverted (upperTorso broke arm visibility, rightUpperArm was correct)
- Crosshair fix was IgnoreGuiInset, not the Y position tweak originally planned

## Self-Check: PASSED

- [x] Crosshair Position at (0.5, 0.5)
- [x] AnchorPoint at (0.5, 0.5)
- [x] IgnoreGuiInset = true on RevolverGui
- [x] getShotDirection uses camera preliminary raycast for parallax
- [x] Bullets hit where crosshair points
- [x] IKControl.ChainRoot = rightUpperArm (confirmed working)
