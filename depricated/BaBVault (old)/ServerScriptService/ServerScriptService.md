# ServerScriptService

Server-side scripts and modules for the entire game. Organized into domain-specific folders: round system, player services, world services, economy, shared config, and testing.

## RoundSystem

The core game loop and all services that start/stop/reset with each round.

| Script | Type | Lines | Description |
|--------|------|-------|-------------|
| [[MainServer]] | Script | 41 | Entry point -- initializes all services, starts round loop |
| [[RoundController]] | ModuleScript | 322 | Main round loop -- waiting, intermission, fight, post-game stats, reset |
| [[SpawnService]] | ModuleScript | 145 | Player teleportation -- lobby spawns, round spawns, zone-safe filtering |
| [[RoleService]] | ModuleScript | 26 | Player role management (Bandit / Eliminated / nil) |
| [[BanditService]] | ModuleScript | 57 | Gun distribution -- clone from ServerStorage, equip, cleanup |
| [[ZoneService]] | ModuleScript | 287 | 4-phase shrinking zone with fire walls, zone damage |
| [[DestructibleService]] | ModuleScript | 64 | Breakable windows -- break on bullet hit, reset between rounds |
| [[LobbyService]] | ModuleScript | 98 | Round opt-in/out, mid-match join with gun+invuln, RoundEvent listener |
| [[InvulnService]] | ModuleScript | 144 | Spawn protection with flicker effect, health revert, generation counter |

## PlayerServices

Player lifecycle services that run independently of rounds.

| Module | Lines | Description |
|--------|-------|-------------|
| [[DataService]] | 378 | DataStore persistence, session tracking, auto-save, BindToClose |
| [[LeaderstatService]] | 42 | Creates leaderstats (Cash, Level) and PlayerStats (XP) folders |
| [[ProgressionService]] | 149 | XP/Cash awards for kills, deaths, round completion, survival time |
| [[MovementService]] | 172 | Server-authoritative sprint/crouch with stamina drain/regen |
| [[CollisionService]] | 36 | Disables player-to-player collision via PhysicsService groups |

## WorldServices

Environment and character effects that are always running.

| Module | Lines | Description |
|--------|-------|-------------|
| [[RagdollService]] | 188 | Server-authoritative death ragdolls with shot impulse |
| [[Ragdoll]] | 164 | OOP ragdoll physics -- converts Motor6Ds to BallSocketConstraints |
| [[FootstepService]] | 126 | Sand footprint decals with sound, fade-in/out lifecycle |
| [[AnimateService]] | 112 | Forces default R15 animations, protects Animate script from overwrites |

## Economy

Shop and purchase systems.

| Script | Type | Lines | Description |
|--------|------|-------|-------------|
| [[BuyCardsServer]] | Script | 10 | Relay -- echoes BuyCardsEvent back to requesting client |
| [[TarotPurchaseValidation]] | Script | 40 | Server-side card purchase validation (cost, stock limit) |

## Shared

Cross-cutting configuration used by multiple services.

| Module | Lines | Description |
|--------|-------|-------------|
| [[Config]] | 71 | All tunable game constants (round timing, combat, movement, economy, footsteps) |
| [[State]] | 19 | Shared round state (active, phase, kills, deaths, opted-in players) |
| [[References]] | 37 | Cached workspace/storage references and replicated values |

## Testing

Development-only scripts for spawning test bots.

| Script | Type | Lines | Description |
|--------|------|-------|-------------|
| [[BotSpawner]] | Script | 35 | Spawns test bot from BotRig at BotSpawner part, auto-respawns on death |
| [[BotSpawner2]] | Script | 35 | Same as BotSpawner but at BotSpawner2 part |

## _deprecated

5 disabled scripts -- older implementations replaced by current services:

| Script | Replaced By |
|--------|-------------|
| Footstep | [[FootstepService]] |
| ForceDefaultR15Animate | [[AnimateService]] |
| PlayerCollisionGroup | [[CollisionService]] |
| RagdollOnDeath | [[RagdollService]] |
| leaderstat | [[LeaderstatService]] |
