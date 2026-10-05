---
tags: [server, modulescript, missions]
path: game.ServerStorage.Missions.RewardCachePlacement
type: ModuleScript
lines: 38
---

# RewardCachePlacement

Places a mission reward chest above its full footprint, preferring an accessible nearby patch.

## What it does
1. `Choose(frame, size, arrival, sample, floorY, allowMove)` tests the authored frame and, when `allowMove`, eight 8-stud offsets around it.
2. Skips candidates more than 48 studs (flat) from the arrival point.
3. Samples terrain height across the chest footprint and four approach points, scoring by height spread plus a small distance penalty.
4. Returns the best position raised above the highest footprint sample (or `floorY`), with its spread and offset; asserts when no candidate lies inside the mission footprint.

## Dependencies
- **Requires:** Nothing
- **Required by:** MissionServer

## Connections
None.
