---
tags:
  - shared
  - modulescript
  - external
path: game.ReplicatedStorage.ExternalLibrary.chrono
type: ModuleScript
lines: 93
---

# chrono

External entity replication library (v2.0.10) by Parihsz. Provides server-authoritative networked entity movement with client-side interpolation.

## What it does

1. Entry point for the Chrono library — exposes `Start()` to initialize client or server replication
2. Auto-detects client vs server and requires the appropriate `Replicate` module
3. Re-exports core APIs: [[Entity]], [[Config]], Holder, Events, ReplicationRules, Snapshots, Stats
4. Checks GitHub for newer versions on server startup (optional)

## Dependencies

- **Requires:** [[Config]], [[Entity]], Holder, Events, ReplicationRules, Snapshots, Stats, Types, Server.Player, Server.Receiver, Server.ServerClock, [[Replicate]]
- **Required by:** Nobody directly (bootstraps require sub-modules)

## Connections

### Direct require()

| Target | Function | Purpose |
|--------|----------|---------|
| [[Config]] | `Config._Lock()`, `Config._GetConfig()` | Lock config after start, check version |
| [[Entity]] | Re-exported as `chrono.Entity` | Entity creation API |
| Server.Replicate | `require()` on server | Start server replication loop |
| Client.Replicate | `require()` on client | Start client replication loop |
