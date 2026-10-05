---
tags: [server, modulescript, missions]
path: game.ServerStorage.Missions.MissionArtService
type: ModuleScript
lines: 72
---

# MissionArtService

Swaps authored cosmetic artwork onto mission props (wagon, rocket, loader, pump, valve, TNT) while gameplay anchors stay server-owned.

## What it does
1. Maps each role to an `ASSET_*` build plot under `WorldBuildPlots` (in ServerStorage at runtime, workspace in edit mode).
2. `Validate(role)` checks the plot has an `Origin` BasePart and an Archivable `Build` folder with 1-200 parts, each within 48 studs of Origin and not oversized; warns about scripts/joints/prompts that will be stripped. Opt-in via the plot's `UseInMissions` attribute.
3. `Apply(role, parent, targetFrame)` clones the build, strips scripts, joints, constraints, humanoids, prompts, click detectors and body movers, re-poses every part relative to `targetFrame`, and makes it anchored and non-colliding. Falls back to prototype art (returns false) with a warning when validation fails.
4. `SetVisible(model, visible)` hides or restores the art, remembering original transparency and effect `Enabled` states.

## Dependencies
- **Requires:** Nothing
- **Required by:** MissionVariety (also referenced by the MissionArtWorkflow authoring guide)

## Connections
None.
