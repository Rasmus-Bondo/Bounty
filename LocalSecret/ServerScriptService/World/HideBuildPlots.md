---
tags: [server, script, world]
path: game.ServerScriptService.World.HideBuildPlots
type: Script
lines: 15
---

# HideBuildPlots

Removes the edit-mode authoring build plots from the running game.

## What it does
1. If `workspace.WorldBuildPlots` exists, fills every part under its `CleanupBounds` folder with Air terrain (grid-aligned to 4) to erase authored plot terrain.
2. Moves the whole `WorldBuildPlots` folder into ServerStorage so authoring pads never appear in gameplay.

## Dependencies
- **Requires:** Nothing
- **Required by:** Nobody

## Connections
None.
