---
tags: [server, modulescript, missions]
path: game.ServerStorage.Missions.MissionPlacement
type: ModuleScript
lines: 45
---

# MissionPlacement

Short, bounded terrain search for where a mission pressure enemy may spawn.

## What it does
1. `FindSpawn(center, angle, context)` tries 16 candidates fanned around `angle` at 34-50 studs, plus four road points when `context.RoadX` is given.
2. Rejects candidates more than 12 studs above/below the centre ground, on slopes (normal < 0.7), failing `context.IsClear`, or within 18 studs of any position in `context.AvoidPlayers`.
3. Walks an 8-step line from the centre to the candidate and rejects steep or stepped paths (slope < 0.65 or a step > 4.5 studs).
4. Returns the first near-flat point (height < 3) immediately, otherwise the best-scoring one, raised 3.2 studs; nil if none qualify.
5. Terrain access is injected through `context.Ground`, so the module has no world dependency.

## Dependencies
- **Requires:** Nothing
- **Required by:** MissionServer

## Connections
None.
