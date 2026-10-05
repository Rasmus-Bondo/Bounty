---
tags: [client, localscript, missions, ui]
path: game.StarterPlayer.StarterPlayerScripts.Missions.MissionDiscovery
type: LocalScript
lines: 64
---

# MissionDiscovery

One-time "discovered" toast for exploration encounters; presentation only, no rewards or spawn requests.

## What it does
1. Builds the `PVEEncounterDiscovery` ScreenGui and polls every 0.2 s.
2. Looks for the nearest unseen Cache / Rescue / FirstAid model in `workspace.PVE_ExplorationEncounters` within 80 studs with clear line of sight to its `PromptPoint`.
3. Requires the same candidate for 0.75 s, then marks its `ChunkKey` seen for the session and shows a 4 s toast (`TRAIL CACHE / STRANDED TRAVELLER / FIRST-AID STOP DISCOVERED`), with a 7 s cooldown between toasts.
4. Suppressed while dead, downed, boarding the train or with a menu open.
5. Writes `LastDiscoveredKey` and `NoticeCount` attributes on its own ScreenGui for Studio checks.

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
| [[ClientMenuState]] | `Menus.IsOpen()` | Hold notices while a menu is open |
