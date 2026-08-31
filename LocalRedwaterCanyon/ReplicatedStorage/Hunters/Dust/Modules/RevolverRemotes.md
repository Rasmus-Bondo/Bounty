---
tags: [shared, modulescript, networking]
path: game.ReplicatedStorage.Hunters.Dust.Modules.RevolverRemotes
type: ModuleScript
lines: 20
---

# RevolverRemotes

Accessor module that returns references to all Revolver RemoteEvents.

## What it does
1. Waits for the `Hunters.Dust.Remotes` folder in ReplicatedStorage and (separately) `Hunters.Shared.Remotes` for the cross-hero `HitConfirm` remote
2. Returns a table of RemoteEvent references: FireBullet, ReplicateShot, DashRequest, HighNoonVisual (from `Hunters.Dust.Remotes`), HitConfirm (from `Hunters.Shared.Remotes` — see HunterSharedRemoteSetup)

## Dependencies
- **Requires:** Nothing
- **Required by:** FPSRevolverClient

## Connections
### RemoteEvents
| Remote | Direction | Other script |
|--------|-----------|-------------|
| `FireBullet` | accessor | Used by shooting scripts |
| `ReplicateShot` | accessor | Used by shot replication |
| `DashRequest` | accessor | Used by dash scripts |
| `HighNoonVisual` | accessor | Used by HighNoon visual scripts |
| `HitConfirm` | accessor | Used by hit confirmation |

### BindableEvents
None

### Direct require()
None
