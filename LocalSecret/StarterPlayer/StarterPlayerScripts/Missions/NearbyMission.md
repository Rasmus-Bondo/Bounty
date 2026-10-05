---
tags: [client, localscript, missions, ui]
path: game.StarterPlayer.StarterPlayerScripts.Missions.NearbyMission
type: LocalScript
lines: 55
---

# NearbyMission

Side panel showing the state of the nearest exploration encounter (traveller rescue or trail cache).

## What it does
1. Builds the `PVENearbyEncounter` ScreenGui and polls every 0.2 s.
2. Finds the nearest Rescue or Cache model in `workspace.PVE_ExplorationEncounters` within 100 studs of its `PromptPoint`, with hysteresis so the current pick sticks to 105 studs.
3. Shows the encounter kind and distance, then `N GUARDS REMAINING` from the server-owned `GuardsRemaining` attribute, or the free-traveller / supplies prompt once `Cleared`.
4. Hides while dead, downed or while a menu is open.

## Dependencies
- **Requires:** [[ClientMenuState]]
- **Required by:** Nobody

## Connections
### RemoteEvents
None

### BindableEvents
None

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[ClientMenuState]] | `Menus.IsOpen()` | Hide the panel behind open menus |
