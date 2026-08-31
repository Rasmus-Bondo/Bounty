---
tags: [server, modulescript, data, external-library]
path: game.ServerScriptService.PlayerServices.ProfileService
type: ModuleScript
lines: 2414
---

# ProfileService

External library providing session-locked DataStore profiles with auto-save and global updates.

## What it does
1. Wraps Roblox DataStoreService with session locking to prevent data corruption from multiple servers
2. Provides `LoadProfileAsync` with ForceLoad/Steal conflict resolution
3. Auto-saves profiles on a configurable interval (default 30s)
4. Supports GlobalUpdates for cross-server messaging via DataStore
5. Includes mock DataStore mode for Studio testing
6. Handles critical state detection when DataStore errors spike

## Dependencies
- **Requires:** Nothing
- **Required by:** DataService

## Connections
### RemoteEvents
None

### BindableEvents
None

### Direct require()
None
