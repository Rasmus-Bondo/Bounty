# Config

Central configuration module containing all tunable game constants. Every service reads from this table — no magic numbers scattered across scripts.

**Path:** `game.ServerScriptService.Shared.Config`
**Type:** ModuleScript (71 lines)
**Runs on:** Server

## Constants

### Round System

| Constant | Value | Description |
|----------|-------|-------------|
| MIN_PLAYERS | 1 | Minimum players needed to start a round |
| INTERMISSION_TIME | 10 | Seconds between rounds |
| ROUND_TIME | 600 | Maximum round duration (10 minutes) |
| RESPAWN_DELAY | 3 | Seconds before dead player respawns |
| PLAYER_MAX_HEALTH | 150 | Starting health for each player |
| LOBBY_SWITCH_COOLDOWN | 5 | Seconds before a player can toggle round participation again |

### Invulnerability

| Constant | Value | Description |
|----------|-------|-------------|
| INVULN_DURATION | 10 | Seconds of spawn protection |
| INVULN_FLICKER_BASE | 0.3 | Character flicker rate (seconds) |
| INVULN_FLICKER_FAST | 0.1 | Faster flicker when about to expire |
| INVULN_WARNING_TIME | 3 | Seconds before expiry to switch to fast flicker |

### Zone System

| Constant | Value | Description |
|----------|-------|-------------|
| ZONE_DAMAGE_PER_SEC | 10 | Damage/sec outside safe zone |
| ZONE_PHASE_DURATION | 150 | Duration of each shrink phase (2.5 min) |
| ZONE_DAMAGE_INTERVAL | 0.5 | Seconds between damage ticks |
| ZONE_START_Z | -700 | Southern Z boundary |
| ZONE_END_Z | 200 | Northern Z boundary |
| ZONE_CENTER_RANDOM_RANGE | 40 | Max random offset for zone center |

### Movement

| Constant | Value | Description |
|----------|-------|-------------|
| WALK_SPEED | 16 | Default walking speed (studs/sec) |
| SPRINT_SPEED | 24 | Sprint speed (studs/sec) |
| CROUCH_SPEED | 8 | Crouch speed (studs/sec) |
| MAX_STAMINA | 100 | Maximum stamina pool |
| STAMINA_DRAIN_RATE | 100/6 | Stamina consumed per second sprinting (~16.7) |
| STAMINA_REGEN_RATE | 100/3.5 | Stamina recovered per second (~28.6) |
| STAMINA_REGEN_DELAY | 2 | Seconds after sprinting before regen starts |
| CROUCH_HIP_HEIGHT | 1.5 | Humanoid hip height when crouching |
| NORMAL_HIP_HEIGHT | 2 | Humanoid hip height when standing |

### Combat / Gun

| Constant | Value | Description |
|----------|-------|-------------|
| GUN_FIRE_COOLDOWN | 0.4 | Minimum seconds between shots |
| GUN_RELOAD_TIME | 4.9 | Seconds for a full reload |
| GUN_RANGE | 350 | Maximum raycast distance (studs) |
| GUN_DAMAGE_HEAD | 150 | Headshot damage (one-shot kill) |
| GUN_DAMAGE_CHEST | 75 | Torso damage |
| GUN_DAMAGE_LIMB | 35 | Arm/leg damage |
| GUN_MAX_AMMO | 6 | Rounds per cylinder |
| GUN_SPREAD_PER_SHOT | 0.5 | Degrees of spread per consecutive shot |
| GUN_MAX_SPREAD | 5 | Maximum spread cap (degrees) |
| GUN_SPREAD_RESET_TIME | 1.0 | Seconds of not firing to reset spread |

### Progression / Economy

| Constant | Value | Description |
|----------|-------|-------------|
| XP_PER_KILL | 100 | XP per elimination |
| CASH_PER_KILL | 10 | Cash per elimination |
| ROUND_BONUS_XP | 50 | XP for surviving a full round |
| ROUND_BONUS_CASH | 5 | Cash for surviving a full round |
| TIME_REWARD_XP | 25 | XP awarded periodically |
| TIME_REWARD_CASH | 3 | Cash awarded periodically |
| TIME_REWARD_INTERVAL | 120 | Seconds between time rewards |
| XP_PER_LEVEL | 1000 | XP per level (linear) |

### Data Persistence

| Constant | Value | Description |
|----------|-------|-------------|
| AUTO_SAVE_INTERVAL | 300 | Seconds between DataStore saves (5 min) |

### Footsteps

| Constant | Value | Description |
|----------|-------|-------------|
| FOOTSTEP_INTERVAL | 0.22 | Seconds between footprint spawns |
| FOOTSTEP_VISIBLE_TIME | 3.2 | Seconds a footprint stays visible |
| FOOTSTEP_FADE_OUT_TIME | 0.8 | Seconds to fade away |
| FOOTSTEP_FADE_IN_TIME | 0.08 | Seconds to appear |
| FOOTSTEP_MIN_PITCH | 0.5 | Lowest random pitch |
| FOOTSTEP_MAX_PITCH | 0.65 | Highest random pitch |
| FOOTSTEP_MIN_VOLUME | 0.35 | Lowest random volume |
| FOOTSTEP_MAX_VOLUME | 0.45 | Highest random volume |

## Dependencies

- None — pure data table

## Used By

- Nearly every module in RoundSystem: [[RoundController]], [[MovementService]], [[FootstepService]], [[ProgressionService]], [[InvulnService]], [[ZoneService]], [[BanditService]] (indirectly via gun timing)
