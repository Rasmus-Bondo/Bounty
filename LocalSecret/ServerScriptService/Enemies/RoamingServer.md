---
tags: [server, script, enemies, disabled]
path: game.ServerScriptService.Enemies.RoamingServer
type: Script
lines: 81
---

# RoamingServer

**DISABLED** (`Enabled = false`). Legacy ambient enemy packs on fixed patrol routes, superseded by ChunkEnemyServer's chunk-owned packs.

## What it does
1. Defines hardcoded routes (`CanyonNorth`, `SaltFlats`, ...) with fixed world coordinates and a pack size, grounding each point by raycasting onto terrain into `workspace.PVE_PatrolRoutes`.
2. Two seconds after start, spawns each route's pack through EnemyService (RoamingDrifter / RoamingGunslinger, hostile to all players, `PackId` = route id).
3. Every 8 s, a wiped pack respawns after a random 12-20 s delay.
4. Does not run while disabled; the fixed coordinates predate the procedurally generated world.

## Dependencies
- **Requires:** [[EnemyService]]
- **Required by:** Nobody

## Connections
### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[EnemyService]] | `Enemy.Spawn()` | Spawn route pack members |
