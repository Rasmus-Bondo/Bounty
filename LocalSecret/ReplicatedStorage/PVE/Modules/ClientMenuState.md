---
tags:
  - client
  - modulescript
  - ui
path: game.ReplicatedStorage.PVE.Modules.ClientMenuState
type: ModuleScript
lines: 30
---

# ClientMenuState

Shared client check for whether any menu is open, so gameplay input and cursor handling stand down without fighting the default camera.

## What it does

1. Tracks the Roblox escape menu via `GuiService.MenuOpened` / `MenuClosed`
2. `Service.IsOpen()` returns true while the Roblox menu is open, or while `PVEProgressionGui` or `PVERunBoon` is enabled
3. Also returns true when `PVE_TrailMap` is enabled with its `Shade` visible
4. Also returns true when `PVE_MissionVote` is enabled with any of `Shade`, `DecisionShade` or `ResultsShade` visible

## Dependencies

- **Requires:** Nothing
- **Required by:** AbilityClient, CombatClient, TrailMapClient, HorseClient, NearbyMission, MissionDiscovery

## Connections

None. Reads ScreenGui and panel visibility from PlayerGui by name.
