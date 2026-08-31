---
tags: [client, localscript]
path: game.StarterPlayer.StarterPlayerScripts.TumbleweedSpawner
type: LocalScript
lines: 516
---

# TumbleweedSpawner

Client-only decorative tumbleweed system that rolls models across the lobby map.

## What it does
1. Waits for `Workspace.TumbleweedSpawns` folder and `ReplicatedStorage.TumbleweedModel.Tumbleweed` template (15 s timeout each)
2. Finds `StartPoint` and `EndPoint` parts inside TumbleweedSpawns to define travel lanes
3. Spawns up to 5 simultaneous tumbleweeds on a random 10.5–17.5 s interval
4. Each tumbleweed clones the template, terrain-raycasts a path of 40 points, and travels it over 5–8.5 s via `RunService.Heartbeat`
5. Applies idle bob, sway, bounce, float, roll-spin, and wobble motion during travel
6. Fades in at spawn (0.8 s tween) and fades out when 82 % complete (0.9 s tween); icosphere scales down on exit
7. Stores active models in `Workspace.LocalTumbleweeds` (client-only folder)

## Dependencies
- **Requires:** Nothing
- **Required by:** Nobody

## Connections
### RemoteEvents
None — purely client-side visual.
