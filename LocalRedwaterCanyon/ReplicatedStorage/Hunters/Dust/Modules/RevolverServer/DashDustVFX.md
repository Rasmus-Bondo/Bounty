---
tags: [server, modulescript, vfx, movement]
path: game.ReplicatedStorage.Hunters.Dust.Modules.RevolverServer.DashDustVFX
type: ModuleScript
lines: 157
---

# DashDustVFX

OOP server-side dust trail effect that spawns sandy smoke stamps behind a dashing character.

## What it does
1. Creates smoke stamps behind the character every 0.04s for the dash duration (0.5s)
2. Raycasts downward to find ground position for each stamp
3. Spawns an anchored invisible Part with a Smoke instance for each stamp
4. Smoke tweens from start opacity (0.42) to 0 over lifetime (1.25s) with growing size
5. Randomizes position along the side spread (1.8 studs) and behind distance (1.2 studs)
6. Token system supports concurrent dashes from multiple players

## Dependencies
- **Requires:** Nothing
- **Required by:** DashDustVFXServer

## Connections
### RemoteEvents
None

### BindableEvents
None

### Direct require()
None
