---
tags: [shared, modulescript, vfx, combat]
path: game.ReplicatedStorage.Hunters.Dust.Modules.laserBeamEffect
type: ModuleScript
lines: 36
---

# laserBeamEffect

Creates a visual laser beam trail between two world positions for gunshot visualization.

## What it does
1. Clones a LaserBeam template from `ReplicatedStorage.Hunters.Dust.Objects`
2. Positions and orients the beam from start to end position
3. Tweens the start attachment toward the end attachment at 1200 studs/sec
4. Destroys the beam part once the tween completes

## Dependencies
- **Requires:** Nothing
- **Required by:** FPSRevolverClient, HighNoonClient, SunspikeClient (Vesper tracers + piercing ultimate beam), GrudgekeeperClient (Bram tracer fan + shell tracer), BramWorldFXClient (shell tracer for non-casters)

## Connections
### RemoteEvents
None

### BindableEvents
None

### Direct require()
None
