---
tags:
  - shared
  - modulescript
  - config
  - world
path: game.ReplicatedStorage.PVE.Config.WorldGenerationConfig
type: ModuleScript
lines: 28
---

# WorldGenerationConfig

Static tuning table for the procedural, chunk-streamed PVE world.

## What it does

1. Sets the chunk grid: 192-stud chunks, 16-stud cells, voxel resolution 4
2. Sets streaming radii in chunks: load 2, far 3, ultra 4, unload 4, client decor 2, with at most one chunk built per 0.35 s update step
3. Sets terrain bounds: base height 0, depth 64, Y range -64 to 384, clear height 448
4. Sets road layout: width 17, shoulder 30, branch spacing 384
5. Sets decoration density: 7-13 props per chunk, landmark chance 0.16, template chance 0.22 with spacing modulo 4 and a 160-stud maximum XZ footprint

## Dependencies

- **Requires:** Nothing
- **Required by:** WorldRuntime, ChunkEnemyServer, MissionServer, WorldViewDistanceClient

## Connections

None. Pure data module.
