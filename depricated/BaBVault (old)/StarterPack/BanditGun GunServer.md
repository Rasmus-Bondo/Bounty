# BanditGun GunServer

Server-side revolver logic — handles shooting, damage calculation, reload, ammo management, bullet tracers, muzzle flash, impact effects (sparks, bullet holes, material-based sounds/VFX), breakable objects, and window passthrough.

**Path:** `game.StarterPack.CamGun.BanditGun.GunServer`
**Type:** Script (656 lines)
**Runs on:** Server

## How It Works

### Shooting Flow
1. Client fires [[GunRemote]] with `"Fire"`, origin, direction
2. Server validates: correct owner, not reloading, fire cooldown passed, shooter alive
3. Validates shot is reasonable: origin within 12 studs of HumanoidRootPart, direction dot > -0.25
4. Cancels invulnerability if shooter is invulnerable (shot still fires)
5. Applies accuracy spread based on consecutive rapid shots
6. Performs raycast (excludes shooter character + tool)
7. Creates tracer, muzzle flash, plays fire sound
8. Processes hit: player damage, breakable parts, or environment impacts

### Window Passthrough
- If ray hits a Window part, breaks it via [[DestructibleService]] and continues raycast behind it
- Already-destroyed windows are also passed through

### Damage System
- Resolves accessory hits to underlying body part via Weld
- Blocks damage to invulnerable players and non-opted-in players
- On kill: awards $1.32 cash, triggers ragdoll, fires [[EliminatePlayer]], calls [[ProgressionService]].awardKill

### Reload
- Waits `Config.GUN_RELOAD_TIME` then refills ammo
- Cancelled if tool is unequipped mid-reload

## Accuracy Spread

| Config Key | Purpose |
|------------|---------|
| GUN_SPREAD_RESET_TIME | Seconds of no-fire before spread resets |
| GUN_SPREAD_PER_SHOT | Degrees added per consecutive shot |
| GUN_MAX_SPREAD | Maximum spread cap in degrees |

## Damage Values (from Config)

| Config Key | Body Part |
|------------|-----------|
| GUN_DAMAGE_HEAD | Head |
| GUN_DAMAGE_CHEST | UpperTorso, LowerTorso, Torso, HumanoidRootPart |
| GUN_DAMAGE_LIMB | All other parts |

## Anti-Cheat Validation

| Check | Constant |
|-------|----------|
| Origin distance from root | MAX_ORIGIN_DISTANCE_FROM_ROOT = 12 |
| Forward direction dot product | MIN_FORWARD_DOT = -0.25 |
| Fire rate | Config.GUN_FIRE_COOLDOWN |
| Vector3 type checks | clientOrigin, clientDirection |

## Material Impact Maps

Sounds and VFX are mapped by material:

| Material | Sound | VFX |
|----------|-------|-----|
| Wood, WoodPlanks | WoodImpactSound | WoodImpact |
| Brick, Concrete | BrickImpact | BrickImpact |
| Glass | GlassImpact | GlassImpact |
| Sand, Ground, Mud | SandImpact | SandImpact |
| Rock, Slate, Granite, Marble, Basalt, Limestone | StoneImpact | StoneImpact |
| Metal, CorrodedMetal, DiamondPlate | StoneImpact | StoneImpact |

## Visual Effects

- **Tracer**: Neon part (255, 221, 110), 0.12 stud thick, 0.06s lifetime
- **Muzzle flash**: ParticleEmitter + PointLight on MuzzleAttachment
- **Bullet hole**: Decal on anchored part, 25s lifetime
- **Impact spark**: ParticleEmitter, 6 particles, 0.3s lifetime
- **Impact VFX**: Material-based particle template from [[VFX]] folder
- **Impact sound**: Positional sound from [[SFX]] folder (rolloff 5–100 studs)

## Dependencies

- [[Config]] — all gun constants (damage, ammo, cooldown, spread, range, reload time)
- [[ProgressionService]] — kill XP/stats awards
- [[InvulnService]] — invulnerability check/removal
- [[DestructibleService]] — window breaking
- [[GunRemote]] — client-server communication
- [[EliminatePlayer]] — BindableEvent for kill processing
- [[SFX]] folder — impact sounds, RoundKill sound
- [[VFX]] folder — impact particle templates

## Used By

- Runs inside the BanditGun Tool when equipped by a player
