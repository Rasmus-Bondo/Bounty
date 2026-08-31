# BanditGun GunServer

Server-authoritative combat script. Validates all shots, performs raycasts, applies damage, creates visual effects (tracers, muzzle flash, bullet holes, impact sparks), and handles ammo/reload state.

**Path:** `game.ServerStorage.BanditGun.GunServer`
**Type:** Script (656 lines)
**Runs on:** Server

## Core Flow

1. Client sends `"Fire"` via [[GunRemote]] with origin + direction
2. Server validates: shooter alive, tool equipped, cooldown elapsed, ammo available
3. Validates shot origin is within 12 studs of HumanoidRootPart and direction passes forward-dot check
4. Cancels spawn invulnerability if shooter is invulnerable (shot still fires)
5. Applies accuracy spread based on consecutive shots
6. Performs `workspace:Raycast()` with shooter + tool excluded
7. Handles window passthrough (breaks window via [[DestructibleService]], continues ray)
8. Handles breakable parts (`Breakable` attribute)
9. On player hit: checks invulnerability, OptedIn status, calculates body-part damage, triggers ragdoll + elimination on kill
10. On environment hit: creates tracer, bullet hole, impact spark, material-based SFX/VFX

## Damage Model

| Body Part | Config Key | Notes |
|-----------|-----------|-------|
| Head | `GUN_DAMAGE_HEAD` | Resolves accessory hits to underlying body part |
| UpperTorso, LowerTorso, HumanoidRootPart | `GUN_DAMAGE_CHEST` | |
| Everything else (limbs) | `GUN_DAMAGE_LIMB` | |

## Ammo & Reload

- Ammo starts at `Config.GUN_MAX_AMMO` (6)
- Reload triggered by client `"Reload"` action or auto on dry fire
- Reload takes `Config.GUN_RELOAD_TIME` seconds
- Ammo updates sent to client via `remote:FireClient(player, "Ammo", ammo, maxAmmo)`

## Anti-Cheat Validation

| Check | Threshold |
|-------|-----------|
| Origin distance from root | MAX_ORIGIN_DISTANCE_FROM_ROOT = 12 studs |
| Forward-facing dot product | MIN_FORWARD_DOT = -0.25 |
| Fire rate | Config.GUN_FIRE_COOLDOWN |
| Type checks | clientOrigin and clientDirection must be Vector3 |

## Material Impact Maps

Maps Roblox materials to SFX/VFX templates from [[SFX Folder]] and [[VFX Folder]]:

| Material(s) | Sound | VFX |
|-------------|-------|-----|
| Wood, WoodPlanks | WoodImpactSound | WoodImpact |
| Brick, Concrete | BrickImpact | BrickImpact |
| Glass | GlassImpact | GlassImpact |
| Sand, Ground, Mud | SandImpact | SandImpact |
| Rock, Slate, Granite, Marble, Basalt, Limestone, Metal, DiamondPlate, CorrodedMetal | StoneImpact | StoneImpact |

## On Kill

1. Awards +1.32 Cash to killer's leaderstats
2. Plays RoundKill sound
3. Sets ragdoll attributes on victim (`ShouldRagdoll`, `RagdollForceX/Y/Z`)
4. Fires [[EliminatePlayer]] BindableEvent
5. Awards kill progression via [[ProgressionService]]

## Dependencies

- [[Config]] — all gun constants
- [[ProgressionService]] — `awardKill()`
- [[InvulnService]] — `removeInvulnerability()`
- [[DestructibleService]] — `isWindowDestroyed()`, `breakWindow()`
- [[GunRemote]], [[EliminatePlayer]] — events
- [[SFX Folder]], [[VFX Folder]] — impact templates

## Used By

- Runs automatically when the [[BanditGun Tool]] is in a player's character
