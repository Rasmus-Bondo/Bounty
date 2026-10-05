---
tags: [server, script, data, persistence]
path: game.ServerScriptService.PlayerServices.PVEDataService
type: Script
lines: 93
---

# PVEDataService

Loads the shared `PlayerData_v2` profile so the lobby carries the player's PVE scrap and upgrade levels. Identical copy in Secret.

## What it does
1. Loads profile `Player_<UserId>` on join (kicks on failure, releases on leave or when another server takes the session).
2. Seeds `PVEScrap` and the three `PVE*Level` player attributes from `Data.PVE`, and mirrors later changes back (the lobby does not change them today).
3. Sets `PVEDataLoaded` once seeded.

## Dependencies
- **Requires:** [[ProfileService]]
- **Required by:** Nobody

## Connections
### RemoteEvents
None

### BindableEvents
None

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[ProfileService]] | `GetProfileStore()`, `LoadProfileAsync()` | Session-locked access to the shared profile |
