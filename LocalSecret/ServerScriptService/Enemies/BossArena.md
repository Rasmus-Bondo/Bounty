---
tags: [server, modulescript, enemies, boss]
path: game.ServerScriptService.Enemies.BossArena
type: ModuleScript
lines: 189
---

# BossArena

Temporary Grave Warden dust arena: a server-owned circular boundary that holds boss-fight participants inside.

## What it does
1. `Arena.Start(center, participants)` builds a Persistent `PVE_BossDustArena` model of 24 invisible wall panels (radius 82) that follow terrain height, plus dust-smoke emitters around the rim.
2. Force-dismounts each eligible participant through `PVEForceDismount`, sets `PVEBossArena`, and teleports anyone outside back inside the ring.
3. Clamps participants inside the radius on Heartbeat (every 0.05 s) for the whole fight.
4. Returns a handle: `Pulse(phase)` intensifies the smoke for a Warden phase change; `Stop()` clears `PVEBossArena`, disables collisions, fades the walls out and destroys the model.

## Dependencies
- **Requires:** Nothing
- **Required by:** MissionServer

## Connections
### BindableEvents
| Bindable | Direction | Other script |
|----------|-----------|-------------|
| `ServerStorage.PVEForceDismount` | → | [[HorseServer]] dismount riders entering the arena |
