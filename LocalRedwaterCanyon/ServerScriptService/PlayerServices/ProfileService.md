---
tags:
  - server
  - modulescript
  - data
  - persistence
  - third-party
path: game.ServerScriptService.PlayerServices.ProfileService
type: ModuleScript
lines: 2414
---

# ProfileService

Third-party DataStore wrapper by Madwork/loleris that provides session-locked, auto-saved player profiles. Not modified — treat as a read-only dependency.

Official docs: https://madstudioroblox.github.io/ProfileService/

## What it does

1. Wraps Roblox `DataStoreService` with a per-key write queue (7-second cooldown) and a mock DataStore for Studio use
2. Applies session locking on `LoadProfileAsync` — only one server owns a profile at a time; supports `ForceLoad` and `Steal` strategies for takeover
3. Auto-saves all loaded profiles on a configurable cycle (default 30 s), splitting the load evenly across the interval
4. Surfaces `IssueSignal`, `CorruptionSignal`, and `CriticalStateSignal` for error monitoring; enters critical state after 5 API errors within 120 s
5. Supports `GlobalUpdateProfileAsync` for cross-server messaging and `ViewProfileAsync` / `ProfileVersionQuery` for read-only inspection without a session lock
6. Provides `ProfileStore.Mock` for testing with an in-memory mock DataStore independent of the live store

## Dependencies

- **Requires:** Nothing (standalone; embeds its own ScriptSignal implementation)
- **Required by:** DataService

## Connections

### RemoteEvents

None

### BindableEvents

None

### Direct require()

None
