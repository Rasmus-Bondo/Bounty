---
tags: [client, localscript, combat, ultimate, viewmodel]
path: game.StarterPlayer.StarterPlayerScripts.HighNoonViewModelOrbit
type: LocalScript
lines: 217
---

# HighNoonViewModelOrbit

Adds a gunslinger "flick" orbit to the view model during High Noon shots. Runs after FPSRevolverClient at a higher render priority.

## What it does

1. Listens to `HighNoonAimNudge` bindable fired by [[HighNoonClient]] on each shot
2. Calculates yaw/pitch from muzzle to hit position in camera-local space
3. Applies a pivot-based orbit rotation around an off-center point (left-biased) with roll
4. Snaps to target angles quickly (speed 36), returns smoothly (speed 10)
5. Forces a visible flick if the target is nearly straight ahead
6. Layers on top of FPSRevolverClient's `PivotTo` via `RenderPriority.Camera + 1000`

## Dependencies

- **Requires:** Nothing
- **Listens to bindable:** `HighNoonAimNudge` (from [[HighNoonClient]])
- **Reads:** `Camera.ClientViewModel` (created by FPSRevolverClient)

## Notes

- B key triggers a manual test flick for debugging
- Resets all orbit state on `CharacterAdded`
