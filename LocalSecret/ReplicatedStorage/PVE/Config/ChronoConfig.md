---
tags:
  - shared
  - modulescript
  - config
  - networking
path: game.ReplicatedStorage.PVE.Config.ChronoConfig
type: ModuleScript
lines: 27
---

# ChronoConfig

Configures the chrono replication library and registers the PVE entity types. It is passed to `Chrono.Start(config)` rather than required by name.

## What it does

1. Disables chrono's GitHub version check, sets `PLAYER_REPLICATION` to `CUSTOM` and `WARNING_SEVERITY` to `MEDIUM`
2. Registers entity type `PVEEnemy`: 20 Hz ticks, 0.11 s interpolation buffer, full tick within 180 studs and half tick within 560, native model replication, CFrame interpolation
3. Registers entity type `PVEHorse`: the same shape with a 0.09 s buffer and 220/600-stud tick distances
4. Returns `true`. Chrono requires it once inside `Start`, so the first of EnemyService, HorseServer or EnemyRenderer to call `Start` on a peer runs it

## Dependencies

- **Requires:** [[chrono]]
- **Required by:** EnemyService, HorseServer, EnemyRenderer (each passes it to `Chrono.Start`)

## Connections

### Direct require()

| Target | Function | Purpose |
|--------|----------|---------|
| [[chrono]] | `Chrono.Config.SetConfig()`, `Chrono.Config.RegisterEntityType()` | Set global options and register the PVE entity types before chrono locks its config |
