---
tags: [server, modulescript, world]
path: game.ServerScriptService.World.WorldGenerator
type: ModuleScript
lines: 972
---

# WorldGenerator

Procedural chunked world class: terrain, biomes, road, railway, authored templates and mission destinations.

## What it does
1. `Generator.new(config, assets, origin)` seeds a per-session salt, collects enabled `ServerStorage.WorldTemplates` (Models with a TerrainRegion and `Enabled = true`), and creates `workspace.PVEGeneratedWorld.Chunks`.
2. Deterministic geometry queries: `Key`, `Coordinates`, `Center`, `RegionAt`, `Hash`, `IsProtected`, `RoadCenter`, `RailCenter`, `RailHeight`, `IsRoad`, and `Sample(x, z)` returning height, biome and on-road flag (Desert, Dunes, Canyon, Rift, Oasis, Road, Railbed...).
3. `GetRecord(cx, cz)` builds a chunk record lazily; `AssignTemplate` places weighted authored templates on a spacing modulo and chance, validated and sized through TerrainTemplateService. Multi-chunk templates reserve their footprint as one streaming group (`RegisterTemplateFootprint`, `ExpandTemplateGroups`).
4. `Load(cx, cz)` fills terrain voxels and builds the chunk Model (template, railway, collision, landmark, anvil rock); `Unload(key)` destroys it and clears the voxels back to Air.
5. Station helpers (`StationSlotZ`, `IsStationReserve`, `GetStationSlot`) keep railway stations on fixed slots along the line.
6. `GetDestination(fromPosition, missionId, visitIndex)` picks the next unused mission site ahead along the road by difficulty (Easy/Standard/Hard), preferring a template with a matching `TemplateDifficulty`; `FindTemplateSite` places an explicit template clear of road, rail and stations.
7. `Destroy()` unloads everything and removes the root folder.

## Dependencies
- **Requires:** [[TerrainTemplateService]]
- **Required by:** WorldRuntime

## Connections
### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[TerrainTemplateService]] | `Validate`, `WorldSize`, terrain paste helpers | Validate and place captured terrain templates |
