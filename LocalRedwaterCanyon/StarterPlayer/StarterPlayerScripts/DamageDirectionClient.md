---
tags:
  - client
  - localscript
  - ui
  - combat-feedback
path: game.StarterPlayer.StarterPlayerScripts.DamageDirectionClient
type: LocalScript
lines: 401
---

# DamageDirectionClient

Shows a red directional arc around the crosshair pointing toward the source of incoming damage.

## What it does
1. Listens to the `DamageDirection` RemoteEvent for a world-space source position
2. Builds a 19-segment curved arc indicator (red gradient, brightest at center) and fades it in (0.06s), holds it (0.42s), then fades it out (0.48s)
3. Converts the source's world position into a camera-relative angle each frame (`RunService.RenderStepped`) and smoothly rotates the arc to keep tracking the source as the camera turns
4. Supports up to 4 concurrent indicators (multiple simultaneous damage sources), trimming the oldest when exceeded
5. Ignores sources too close to the camera (`MIN_SOURCE_DISTANCE` = 2 studs) to avoid a degenerate angle

## Dependencies
- **Requires:** Nothing
- **Required by:** Nobody

## Connections
### RemoteEvents
| Remote | Direction | Other script |
|--------|-----------|-------------|
| `DamageDirection` | ← Server | Listened from `Hunters.Shared.Remotes` (cross-hero — created by [[HunterSharedRemoteSetup]]); fired by [[RevolverModule]], [[HighNoonDamage]], and [[CardsServer]] on every hit against the local player |

### BindableEvents
None

### Direct require()
None
