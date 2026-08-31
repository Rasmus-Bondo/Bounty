# HitBoxTestTool GunScript

Server-side logic for the experimental gun — handles shooting with hit highlights, bullet holes, impact smoke, tracer replication, and a dash ability with IK management.

**Path:** `game.StarterPack.HitBoxTestTool.GunScript`
**Type:** Script (429 lines)
**Runs on:** Server

## How It Works

### Shooting
1. Validates player owns tool, checks Vector3 types
2. Clamps camera origin to within 14 studs of head
3. Raycasts with Exclude filter (character + tool)
4. On player hit: applies damage, flashes Highlight on target
5. On environment hit: creates bullet hole + impact smoke
6. Replicates tracer via [[ReplicateShot]] FireAllClients
7. Sends HitConfirm to shooter (isHeadshot, didKill)

### Dash
1. Validates: tool equipped, cooldown (2s), alive, valid direction
2. Disables all IKControls on character during dash
3. Plays dash animation, faces character in dash direction
4. Sets AssemblyLinearVelocity (ground: 240, air: 108 studs/s)
5. After 0.5s: applies end multiplier (ground 0.35x, air 0.15x)
6. Restores IK controls after 0.12s delay

## Combat Constants

| Constant | Value |
|----------|-------|
| RANGE | 500 studs |
| DAMAGE | 45 |
| HEADSHOT_DAMAGE | 95 |
| HIGHLIGHT_TIME | 0.14s |
| MAX_CAMERA_ORIGIN_DISTANCE_FROM_HEAD | 14 studs |

## Dash Constants

| Constant | Value |
|----------|-------|
| DASH_COOLDOWN | 2s |
| DASH_SPEED | 240 studs/s |
| DASH_TIME | 0.5s |
| AIR_DASH_MULTIPLIER | 0.45 |
| GROUND_END_MULTIPLIER | 0.35 |
| AIR_END_MULTIPLIER | 0.15 |

## Hit Highlight Colors

| Type | Fill | Outline | Fill Transparency |
|------|------|---------|-------------------|
| Headshot | (241,121,123) | (255,180,180) | 0.45 |
| Body | (255,145,145) | (255,205,205) | 0.58 |

## Dependencies

- [[Revolver]] folder — SmokeParticles template, [[ReplicateShot]] remote
- Internal RemoteEvents: FireBullet, HitConfirm, DashRequest

## Used By

- Runs inside [[HitBoxTestTool]] when equipped
