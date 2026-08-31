---
tags: [shared, modulescript, vfx, combat]
path: game.ReplicatedStorage.Revolver.laserBeamEffect
type: ModuleScript
lines: 36
---

# laserBeamEffect

Shared module that creates a tracer beam effect between two points, used for revolver and ultimate shots.

## What it does

1. Clones `ReplicatedStorage.Revolver.Objects.LaserBeam` template
2. Positions it from start to end point using `CFrame.lookAt`
3. Tweens the start attachment toward the end at 1200 studs/sec (linear easing)
4. Destroys the beam on tween completion

## Dependencies

- **Requires:** Nothing
- **Required by:** [[FPSRevolverClient]] (line 28, for revolver tracers), [[HighNoonClient]] (line 34, for ultimate tracers)
- **Reads from:** `ReplicatedStorage.Revolver.Objects.LaserBeam` (template)

## Connections

No RemoteEvents or BindableEvents. This is a pure utility function called via `require()`.
