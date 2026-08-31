---
tags: [client, modulescript, combat, movement]
path: game.ReplicatedStorage.Hunters.Dust.Modules.RevolverDash
type: ModuleScript
lines: 448
---

# RevolverDash

OOP dash controller that handles the client-side dash ability with velocity capping and post-dash physics.

## What it does
1. Validates dash: not already dashing, cooldown elapsed (4s), player alive, moving
2. Supports air dashing with horizontal velocity cap (38) and vertical clamping
3. Triggers instant reload, dash sounds, and FOV kick on activation
4. Fires `DashRequest` RemoteEvent to server with move direction
5. Fires `DashCooldownStarted` BindableEvent for UI cooldown display
6. Drives the dash via a Plane-mode `LinearVelocity` (infinite force, horizontal-only); clamps upward Y velocity each frame during the dash to `max(dash-start Y, DashUpwardVelocityCap=6)` so dashing into a sloped wall can't launch the player into the air
7. Blocks dashing up walls: each frame raycasts ahead in the dash direction (`DashWallCheckDistance=4`) and, if heading into a surface steeper than `DashWallSlopeThreshold=55°` (a wall, not a walkable ramp), zeroes horizontal velocity and ends the dash. Ignores characters/bots and allows glancing slides along wall faces
8. Applies post-dash velocity clamping and temporary jump lock after dash ends
9. Tracks viewmodel kick and tumble kick values for visual effects

## Dependencies
- **Requires:** Nothing (configured externally via callbacks and injected dependencies)
- **Required by:** FPSRevolverClient

## Connections
### RemoteEvents
| Remote | Direction | Other script |
|--------|-----------|-------------|
| `DashRequest` | → Server | [[RevolverModule]] and [[DashDustVFXServer]] execute server-side dash |

### BindableEvents
| Bindable | Direction | Other script |
|----------|-----------|-------------|
| `DashCooldownStarted` | → | [[HunterGuiClient]] starts Skill1 cooldown, [[LandingImpactClient]] adds the dash camera kick |

### Direct require()
None
