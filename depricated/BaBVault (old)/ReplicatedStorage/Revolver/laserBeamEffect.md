# laserBeamEffect

Single-function module that creates an animated bullet tracer beam between two world positions.

**Path:** `game.ReplicatedStorage.Revolver.laserBeamEffect`
**Type:** ModuleScript
**Runs on:** Client

## How It Works

1. Calculates distance between start and end positions
2. Computes tween duration based on `LASER_BEAM_VISUAL_SPEED` (1200 studs/sec)
3. Clones the `LaserBeam` template from `Revolver.Objects`
4. Positions `StartAttachment` at origin, `EndAttachment` at hit point
5. Tweens `StartAttachment.Position` toward the end so the beam "travels"
6. Destroys the beam part on tween completion

## Constants

| Name | Value | Description |
|------|-------|-------------|
| LASER_BEAM_VISUAL_SPEED | 1200 | Studs per second for beam travel |

## Dependencies

- `ReplicatedStorage.Revolver.Objects.LaserBeam` — beam template (Part with Beam + Attachments)

## Used By

- [[GunClient]] — calls this after each shot for local bullet tracer visuals
