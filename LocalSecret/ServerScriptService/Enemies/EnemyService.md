---
tags: [server, modulescript, enemies]
path: game.ServerScriptService.Enemies.EnemyService
type: ModuleScript
lines: 593
---

# EnemyService

Server-authoritative lightweight enemy proxies with AI, pathing and boss attacks; clients render the full rigs.

## What it does
1. `Spawn(position, settings)` builds an invisible proxy Model (root + UpperTorso + Head hitboxes, Humanoid) in `workspace.PVE_Enemies`, tags it with `PVEEnemy`, `PVEId`, `PVEArchetype`, `PVEElite`, `PVEPackId`, `PVEMissionEnemy`, `PVEHostileToAll`, and registers it as a Chrono `PVEEnemy` entity for client interpolation.
2. Archetypes Drifter (melee), Gunslinger (ranged), Bomber (dynamite), Brute (charge) and Warden (boss) each get default health/speed, overridable via settings (`Health`, `Speed`, `Damage`, `Cooldown`, `DetectRange`, `Leash`, `PatrolPoints`, `HomePosition`, `OnDeath`, `OnPhase`).
3. Registers player/proxy/corpse collision groups so proxies pass through players and corpses, and spaces crowds with a shared X/Z grid.
4. Pathfinding is budgeted globally (max two concurrent computations, eight starts/second); `Diagnostics()` reports the counters.
5. Damage that would kill an in-encounter player fires `PVEPlayerDowned` instead of killing them; otherwise it applies `TakeDamage`. Targets respect `PVEInEncounter`, `PVEDowned` and `PVEBossArena`.
6. Warden boss: slam and sweep telegraphs resolved through BossAttackRules, phase changes at 70% / 35% health that summon two minions each and call `OnPhase`.
7. Every attack, telegraph, phase and death is broadcast on `EnemyFX`; on death the proxy becomes a corpse and its Chrono entity is destroyed after 8.7 s. `Despawn(npc)` removes one early.

## Dependencies
- **Requires:** [[BossAttackRules]], [[chrono]] (passes the ChronoConfig ModuleScript instance to `Chrono.Start`, which requires it)
- **Required by:** ChunkEnemyServer, RoamingServer, MissionServer

## Connections
### RemoteEvents
| Remote | Direction | Other script |
|--------|-----------|-------------|
| `Remotes.EnemyFX` | → All clients | [[EnemyRenderer]] animations/death, [[BossTelegraphClient]] Warden and dynamite telegraphs |

### BindableEvents
| Bindable | Direction | Other script |
|----------|-----------|-------------|
| `ServerStorage.PVEPlayerDowned` | → | [[ReviveServer]] lethal hit becomes a down |

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[BossAttackRules]] | `InSlam`, `InSweep` | Warden area-of-effect hit tests |
| [[chrono]] | `Chrono.Start`, `Chrono.Entity.new/Destroy` | Replicate proxy motion to clients |
