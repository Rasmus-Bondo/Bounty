---
tags: [server, modulescript, missions]
path: game.ServerStorage.Missions.EscortPacing
type: ModuleScript
lines: 27
---

# EscortPacing

Pure escort ambush schedule: progress gates plus a minimum gap so ambushes never stack.

## What it does
1. Three ambush thresholds at 18%, 48% and 76% escort progress, a 5 s warning before each spawn and a 16 s minimum gap between groups.
2. `New(party)` sizes the schedule for 1-4 players: group size 2-3 and a living-enemy cap of 4 (solo) or 6.
3. `Step(state, time, ratio, alive)` returns `"Warn"` when the next threshold is reached and there is room under the cap, then `"Spawn"` with the group index and size once the warning has elapsed.
4. `Pause(state, seconds)` pushes the next allowed ambush and any pending warning back.

## Dependencies
- **Requires:** Nothing
- **Required by:** MissionServer

## Connections
None.
