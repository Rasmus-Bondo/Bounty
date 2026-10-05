---
tags: [client, localscript, world, settings, ui]
path: game.StarterPlayer.StarterPlayerScripts.World.WorldViewDistanceClient
type: LocalScript
lines: 87
---

# WorldViewDistanceClient

View-distance toggle (Normal / Far / Ultra) that asks the server to stream a larger chunk radius.

## What it does
1. Maps the three modes to `LoadRadius`, `FarLoadRadius` and `UltraLoadRadius` from WorldGenerationConfig.
2. Defaults to Far on keyboard devices and Normal otherwise; a non-Normal default is sent to the server at startup.
3. V key or the `PVE_ViewDistance` button cycles modes (0.65 s debounce) and fires the chosen radius to the server.
4. Tweens the Lighting `Atmosphere` density / offset / haze per mode so farther views look less foggy.

## Dependencies
- **Requires:** [[WorldGenerationConfig]]
- **Required by:** Nobody

## Connections
### RemoteEvents
| Remote | Direction | Other script |
|--------|-----------|-------------|
| `Remotes.WorldViewDistance` | → Server | [[WorldRuntime]] requested load radius |

### BindableEvents
None

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[WorldGenerationConfig]] | `LoadRadius`, `FarLoadRadius`, `UltraLoadRadius` | Radius per view mode |
