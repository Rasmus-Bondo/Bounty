---
tags:
  - shared
  - modulescript
  - external
path: game.ReplicatedStorage.ExternalLibrary.chrono.Shared.Entity
type: ModuleScript
lines: 909
---

# Entity

Core entity class for Chrono. Represents a networked object with position, model, snapshot interpolation, and network ownership.

## What it does

1. Creates entities with `Entity.new()` — assigns config, model, replication mode, registers with Holder
2. Manages network ownership (`SetNetworkOwner`) — server sets owner, adjusts physics/CFrame replication accordingly
3. Pushes CFrame snapshots for interpolation via `Entity.Push()` — stores timestamped position data
4. Supports three model replication modes: NATIVE (Roblox handles it), NATIVE_WITH_LOCK (Roblox model but server CFrame locked), CUSTOM (separate cloned models on client/server)
5. Provides entity events: Destroying, NetworkOwnerChanged, PushedSnapShot, TickChanged, DataChanged, ModelChanged, LockChanged
6. Handles entity mounting (parent-child position offsets between entities)
7. Manages entity lifecycle: create, pause/resume replication, teleport (SetCFrame), destroy

## Dependencies

- **Requires:** [[Config]], Types, Snapshots, InterpolationMath, ClientClock, Holder, Signal, Events, ModelHelper, Warn
- **Required by:** chrono (re-exported), game scripts that create/manage entities

## Connections

### Direct require()

| Target | Function | Purpose |
|--------|----------|---------|
| [[Config]] | `_GetEntityType()`, `_GetEntityModel()` | Resolve entity config and model templates |
| Snapshots | `Snapshot()` | Create interpolation snapshot buffers |
| InterpolationMath | `Hermite`, `VelocityAt` | Smooth CFrame interpolation |
| Holder | `RegisterEntity()`, `UnregisterEntity()` | Track active entities |
| Signal | `Signal.new()` | Create event signals |
| Events | `_Signals` | Internal event bus |
