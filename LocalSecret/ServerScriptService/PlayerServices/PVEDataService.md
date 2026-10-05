---
tags: [server, script, data, persistence]
path: game.ServerScriptService.PlayerServices.PVEDataService
type: Script
lines: 93
---

# PVEDataService

Persists secured scrap and camp upgrade levels in the shared `PlayerData_v2` profile under `Data.PVE`. Identical copy in Bounty - Lobby.

## What it does
1. Loads the profile `Player_<UserId>` from `PlayerData_v2` on join (kicks on failure, releases on leave or when another server takes the session).
2. Seeds the `PVEScrap`, `PVERevolverLevel`, `PVEShotgunLevel`, `PVEGritLevel` player attributes from `Data.PVE`, then mirrors every later attribute change back, so gameplay scripts keep writing attributes and never touch persistence.
3. Sets `PVEDataLoaded` once seeded. Loose salvage (`PVEUnsecured`) is never saved.
4. Uses a template holding only the `PVE` block; safe because Reconcile only adds keys. The same block sits in the Bounty, Redwater and Frostbite `DataService` templates.

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
