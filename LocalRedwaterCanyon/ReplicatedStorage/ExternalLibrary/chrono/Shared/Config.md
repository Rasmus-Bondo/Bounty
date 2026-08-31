---
tags:
  - shared
  - modulescript
  - external
path: game.ReplicatedStorage.ExternalLibrary.chrono.Shared.Config
type: ModuleScript
lines: 237
---

# Config

Central configuration for the Chrono replication system. Manages tick rates, buffer sizes, entity types, model registration, and replication modes.

## What it does

1. Defines base config: buffer sizes, tick distances, bandwidth limits, replication mode (NATIVE/CUSTOM), death/CFrame replication settings
2. Provides `RegisterEntityType()` to define custom entity configs (tick rate, buffer, rotation, model replication mode)
3. Provides `RegisterEntityModel()` to register models/parts as entity templates with optional broad-phase culling
4. Locks config after `Start()` — no modifications allowed after lock
5. Resolves default entity types: DEFAULT (30Hz), WITH_ROT (20Hz + full rotation), PLAYER (20Hz, native replication)

## Dependencies

- **Requires:** Types, Warn, Ticker
- **Required by:** chrono, Entity, ChronoServerBootstrap, and most other Chrono sub-modules

## Connections

### Direct require()

| Target | Function | Purpose |
|--------|----------|---------|
| Types | Type definitions | EntityConfig, MODEL_REPLICATION_MODE |
| Warn | `Warn.low()` | Log on config lock |
| Ticker | `Ticker.new()` | Create server tick loop per entity type |
