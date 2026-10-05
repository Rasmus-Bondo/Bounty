---
tags: [server, modulescript, world]
path: game.ServerStorage.World.TerrainTemplateService
type: ModuleScript
lines: 190
---

# TerrainTemplateService

Captures, validates and pastes authored terrain templates (a Model holding a TerrainRegion) into the generated world.

## What it does
1. `Validate(template)` requires `Origin`, `Entrance` and `CaptureBounds` BaseParts, with `CaptureBounds` axis-aligned and sized in multiples of 4 (the voxel size); returns `valid, info` (Origin, Entrance, Bounds, WorldSize) or `false, reason`.
2. `Capture(template)` copies the terrain inside the template's bounds into a stored TerrainRegion on the template (edit-mode authoring).
3. `Paste(template, targetOrigin, pasteEmptyCells)` writes the captured voxels at a target origin, snapped to the voxel grid.
4. `Translation`, `TranslateCFrame` and `WorldSize` convert between the template's authored frame and its placed position and report its world footprint.
5. `Blend(template, targetOrigin, naturalSample, clipMin, clipMax, minY)` blends only the border of a pasted template into the surrounding procedural terrain, leaving the authored interior, water and caves intact.

## Dependencies
- **Requires:** Nothing
- **Required by:** WorldGenerator, BuildPlotTools (also referenced by the WorldTemplates TemplateWorkflow guide)

## Connections
None.
