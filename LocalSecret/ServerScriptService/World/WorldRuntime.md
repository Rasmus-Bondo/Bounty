---
tags: [server, script, world]
path: game.ServerScriptService.World.WorldRuntime
type: Script
lines: 663
---

# WorldRuntime

Runs the generated world: chunk streaming around players, the world query API for other server systems, and per-player decor and map data.

## What it does
1. Builds a WorldGenerator around `PVE_EncounterPost` (or `SpawnLocation`), loads the origin chunk, lifts the post and spawn to the generated ground and seats every spawning character on the terrain.
2. Every `UpdateInterval` gathers the chunks needed around each player (per-player view radius, look-ahead for fast movers and galloping horses), the active mission area and any Studio preview area, then loads them through a prioritised queue and unloads everything outside the keep set, firing `PVEWorldChunkLifecycle` for each.
3. Sends per-player chunk decor (`WorldChunk` Load/Unload with placements) and tracks discovered chunks (`PVEDiscoveredChunks` attribute).
4. `WorldViewDistance` lets a client pick Load / Far / Ultra radius (0.5 s rate limit); `WorldMapSnapshot` (RemoteFunction, 1.5 s rate limit) returns discovered cells, regions, Rift features and exploration markers merged from `PVEExplorationMapSnapshot`.
5. `PVEWorldQuery` answers `Sample`, `Coordinates`, `IsLoaded`, `RoadCenter`, `RailCenter`, `RailHeight`, `StationSlot`, `PinStation`, `IsAmbientSpawnAllowed`, `ReserveMission`, `ReserveMissionRoute` (reserving a mission fires `Reserve` and reloads affected chunks).
6. `PVEWorldDestination` returns the next mission position; `PVEWorldTemplateDestination` places a named world template and returns its entrance; `PVEWorldChunkState` records per-chunk collected items; `PVEPreviewTemplate` (Studio only) previews a template.
7. Publishes `PVE.GeneratedWorld` status attributes (Active, ChunkSize, LoadedChunks, MaxViewRadius) and marks the world inactive on close.

## Dependencies
- **Requires:** [[WorldGenerationConfig]], [[WorldGenerator]]
- **Required by:** Nobody

## Connections
### RemoteEvents
| Remote | Direction | Other script |
|--------|-----------|-------------|
| `Remotes.WorldChunk` | → Client | [[WorldClient]] per-player chunk decor load/unload |
| `Remotes.WorldViewDistance` | ← Client | [[WorldViewDistanceClient]] view radius choice |
| `Remotes.WorldMapSnapshot` (RemoteFunction) | ← Client invoke | [[TrailMapClient]] trail map data |
| `Remotes.WorldDiscovery` | none | Created but never fired and no client listens |

### BindableEvents
| Bindable | Direction | Other script |
|----------|-----------|-------------|
| `ServerStorage.PVEWorldChunkLifecycle` (BindableEvent) | → (creates) | [[ChunkEnemyServer]] Load / Unload / Reserve |
| `ServerStorage.PVEWorldLoadedChunks` (BindableFunction) | ← OnInvoke (creates) | [[ChunkEnemyServer]] loaded chunk records |
| `ServerStorage.PVEWorldQuery` (BindableFunction) | ← OnInvoke (creates) | [[ChunkEnemyServer]], [[HorseServer]], [[MissionServer]] |
| `ServerStorage.PVEWorldDestination` (BindableFunction) | ← OnInvoke (creates) | [[MissionServer]] next mission site |
| `ServerStorage.PVEWorldTemplateDestination` (BindableFunction) | ← OnInvoke (creates) | [[MissionServer]] place a named template site |
| `ServerStorage.PVEExplorationMapSnapshot` (BindableFunction) | → Invoke | [[ExplorationEncounterService]] encounter markers for the map |
| `ServerStorage.PVEWorldChunkState` (BindableFunction) | ← OnInvoke (creates) | No script invokes it |
| `ServerStorage.PVEPreviewTemplate` (BindableFunction) | ← OnInvoke (Studio only) | Invoked manually by authoring workflows |

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[WorldGenerationConfig]] | `ChunkSize`, `LoadRadius`, `FarLoadRadius`, `UltraLoadRadius`, `UnloadRadius`, `UpdateInterval` | Streaming tuning |
| [[WorldGenerator]] | `Generator.new`, `Load`, `Unload`, `Sample`, `GetDestination`, ... | World generation |
