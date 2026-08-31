---
tags: [client, modulescript, camera, ultimate]
path: game.ReplicatedStorage.Hunters.Dust.Modules.HighNoonFOV
type: ModuleScript
lines: 87
---

# HighNoonFOV

OOP FOV controller for the HighNoon ultimate ability using cubic Bezier easing.

## What it does
1. Plays a two-phase FOV intro: first zooms out to wide FOV (78) over 0.6s, then zooms in to tight FOV (44) over 2.1s
2. Uses cubic Bezier curves for smooth, cinematic FOV transitions
3. Reset smoothly returns to the default FOV over 0.85s
4. Token system ensures only the latest FOV command takes effect
5. Updates camera FOV per-frame via RenderStepped connection

## Dependencies
- **Requires:** Nothing
- **Required by:** HighNoonClient

## Connections
### RemoteEvents
None

### BindableEvents
None

### Direct require()
None
