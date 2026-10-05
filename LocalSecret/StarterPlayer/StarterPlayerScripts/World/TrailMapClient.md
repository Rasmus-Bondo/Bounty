---
tags: [client, localscript, world, ui, map]
path: game.StarterPlayer.StarterPlayerScripts.World.TrailMapClient
type: LocalScript
lines: 337
---

# TrailMapClient

The M-key session trail map of explored terrain, plus a tracked encounter waypoint.

## What it does
1. Builds the `PVE_TrailMap` ScreenGui in code: map button, full-screen `Shade` with a 520 px canvas, legend and details panel.
2. Opening the map (M / button) calls the `WorldMapSnapshot` RemoteFunction; the server returns only a bounded view (centre, chunk size, radius, explored cells, roads, rails, camp, mission, station, escort route, party, exploration entries).
3. Renders explored cells coloured by region (RedMesa / SaltBasin / scrub / rift), roads and rails as pooled line frames, and markers with collision-avoiding labels and edge arrows.
4. Clicking an exploration marker sets a waypoint and closes the map; a HUD panel and an on-screen / edge-clamped world label then show name and distance until cleared, used up, or respawn.
5. Refreshes the snapshot every 3 s while the map is open or a waypoint is tracked; Escape or × closes it.
6. Its open state is what ClientMenuState checks (`PVE_TrailMap.Shade` visible), so other HUD and input stand down while the map is up.

## Dependencies
- **Requires:** [[ClientMenuState]]
- **Required by:** Nobody

## Connections
### RemoteEvents
| Remote | Direction | Other script |
|--------|-----------|-------------|
| `Remotes.WorldMapSnapshot` (RemoteFunction) | → Server, returns snapshot | [[WorldRuntime]] bounded map snapshot |

### BindableEvents
None

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[ClientMenuState]] | `Menus.IsOpen()` | Hide the waypoint HUD while a menu is open |
