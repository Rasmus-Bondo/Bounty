---
tags:
  - shared
  - modulescript
  - external
  - networking
path: game.ReplicatedStorage.PVE.Packages.chrono
type: ModuleScript
lines: 97
---

# chrono

Third-party entity replication library by Parihsz: server-authoritative networked entity movement with client-side interpolation. Vendored as-is and not edited. This note covers the whole package; its internal submodules have no notes of their own.

## What it does

1. `Start(config)` runs once per peer: requires the optional config ModuleScript, then starts `Server.Replicate` or `Client.Replicate`, locks the config and prints the version. A second call warns and is ignored
2. `Shared/` holds the core: `Config` (global options and entity-type registry), `Entity`, `Holder`, `Events`, `ReplicationRules`, `Snapshots`, `Stats`, `Types`, plus interpolation math, align/mount helpers, `Signal`, `Ticker` and `Warn`
3. `Server/` holds `Replicate`, `Sender`, `Receiver`, `Player`, `ServerClock` and `EntityGrid` (spatial grid that drives distance-based tick rates)
4. `Client/` holds `Replicate`, `Sender`, `Receiver`, `Player`, `ClientClock`, `InterpolationBuffer` and `ModelResolver`
5. Owns its remotes under `Shared.Remotes`: `Replicate`, `Heartbeat` and `Death` (unreliable), plus `ReplicateFull`, `SafeReplicate`, `ClientLoaded`, `ClientHeartbeat` and `ClientClockRelay`
6. Can check GitHub for a newer release on server start. ChronoConfig turns this off

## Dependencies

- **Requires:** Its own internal submodules only
- **Required by:** EnemyService, HorseServer, EnemyRenderer, ChronoConfig

## Connections

### RemoteEvents

Internal to the package (`Shared.Remotes`); no game script fires them directly.
