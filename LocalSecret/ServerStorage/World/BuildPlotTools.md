---
tags: [server, modulescript, world, authoring]
path: game.ServerStorage.World.BuildPlotTools
type: ModuleScript
lines: 37
---

# BuildPlotTools

Edit-mode authoring helpers that turn a `workspace.WorldBuildPlots` plot into a stored world template.

## What it does
1. `Capture(name)` captures a named edit-mode plot's terrain through TerrainTemplateService.
2. `Store(name, newName)` clones a captured plot into `ServerStorage.WorldTemplates` with `Enabled = false`, refusing duplicate names.
3. Moves a direct `Build` folder into a `Presentation` Model and strips `AuthoringHelpers`, `AuthoringLabel`s and SelectionBoxes from the copy.
4. Not used at runtime; called from the command bar as directed by the authoring workflow guides.

## Dependencies
- **Requires:** [[TerrainTemplateService]]
- **Required by:** Nobody at runtime (named in the build-plot and nuclear-mission authoring guides)

## Connections
### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[TerrainTemplateService]] | `Capture(plot)` | Capture plot terrain into a TerrainRegion |
