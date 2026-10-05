---
tags: [server, script, enemies, world]
path: game.ServerScriptService.Enemies.ChunkEnemyServer
type: Script
lines: 313
---

# ChunkEnemyServer

Ambient trail enemy packs owned by generated world chunks, persisting their state across chunk unload/reload.

## What it does
1. Listens to `PVEWorldChunkLifecycle` (`Load` / `Unload` / `Reserve`) and re-scans `PVEWorldLoadedChunks` every 3 s: chunks within 550 studs of a player activate, beyond 650 they despawn.
2. Each chunk gets deterministic state from an FNV hash of its key: patrol route, remaining guard count, cooldown and generation. Chunks near spawn (within 2 of the origin) and protected chunks never spawn packs.
3. Spawns guards through EnemyService (TrailDrifter / TrailGunslinger, hostile to all players) at ground points validated by `PVEWorldQuery` (`Sample`, `RoadCenter`, `IsAmbientSpawnAllowed`).
4. Holds a global cap of 12 living ambient enemies; when over budget it despawns distant, unengaged packs to make room.
5. Ties each pack to an exploration encounter (guarded cache, rescue or roadside first-aid stop) via ExplorationEncounterService `Load` / `SetGuards` / `Clear` / `Unload`; a cleared cache never replenishes for the session.
6. On `Reserve` it despawns packs and encounters standing where ambient spawns are no longer allowed (e.g. mission sites).

## Dependencies
- **Requires:** [[ExplorationEncounterService]], [[EnemyService]], [[WorldGenerationConfig]]
- **Required by:** Nobody

## Connections
### BindableEvents
| Bindable | Direction | Other script |
|----------|-----------|-------------|
| `ServerStorage.PVEWorldChunkLifecycle` (BindableEvent) | ← | [[WorldRuntime]] chunk load/unload/reserve |
| `ServerStorage.PVEWorldLoadedChunks` (BindableFunction) | → Invoke | [[WorldRuntime]] current loaded chunk records |
| `ServerStorage.PVEWorldQuery` (BindableFunction) | → Invoke | [[WorldRuntime]] terrain height, road centre, spawn permission |

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[EnemyService]] | `Spawn`, `Despawn` | Create and remove pack members |
| [[ExplorationEncounterService]] | `Load`, `Unload`, `SetGuards`, `Clear`, `Positions` | Encounter reward sites guarded by the pack |
| [[WorldGenerationConfig]] | `ChunkSize` | Chunk-to-world coordinates |
