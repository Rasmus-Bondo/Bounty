---
tags:
  - server
  - modulescript
  - networking
path: game.ServerScriptService.Networking.ChronoServerBootstrap
type: ModuleScript
lines: 40
---

# ChronoServerBootstrap

Initializes the Chrono networking library with server-side configuration and starts replication.

## What it does

1. Locates the Chrono library at `ReplicatedStorage.ExternalLibrary.chrono`
2. Configures Chrono via `Config.SetConfig()` calls (all wrapped in pcall for safety):
   - `PLAYER_REPLICATION` = `"AUTOMATIC"` — auto-replicate player state
   - `DEFAULT_MODEL_REPLICATION_MODE` = `"NATIVE"` — use native Roblox replication for models
   - `MAX_SNAPSHOT_COUNT` = `30` — history buffer size
   - `WARNING_SEVERITY` = `"MEDIUM"` — log warning threshold
3. Locks configuration with `Config._Lock()` to prevent runtime changes
4. Requires the `Replicate` module from `chrono.Server` to start the replication loop
5. Prints a confirmation message to output

## Dependencies

- **Requires:** Config (from `ReplicatedStorage.ExternalLibrary.chrono.Shared`), Replicate (from `ReplicatedStorage.ExternalLibrary.chrono.Server`)
- **Required by:** Main

## Connections

### RemoteEvents

None

### BindableEvents

None

### Direct require()

| Target | Function | Purpose |
|--------|----------|---------|
| [[Config]] | `.SetConfig()`, `._Lock()` | Chrono networking configuration |
| [[Replicate]] | (side-effect on require) | Starts server-side replication loop |
