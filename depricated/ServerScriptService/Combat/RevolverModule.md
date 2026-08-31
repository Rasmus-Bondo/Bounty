---
tags: [server, module, combat, core]
path: game.ServerScriptService.Combat.RevolverModule
type: ModuleScript
lines: 1048
---

# RevolverModule

The core combat module — handles all revolver shooting, hit detection, lag compensation, dashing, and bullet VFX on the server.

## What it does

### Shooting
- Listens to `FireBullet` remote from clients
- Validates inputs (camera origin, direction, muzzle position, cooldowns)
- Performs **lag-compensated raycasting**: rewinds hitbox positions based on player ping, raycasts against historical snapshots
- Falls back to live raycasts if no rewind hit, then to **hit forgiveness** (cylinder near-miss detection)
- Applies damage, creates bullet holes and impact smoke on world surfaces
- Replicates shots to other players via `ReplicateShot`
- Sends `HitConfirm` to the shooter on hits

### Lag Compensation System
- Records character hitbox snapshots at 30Hz into a rolling history buffer
- Tracks `Head`, `HumanoidRootPart`, `UpperTorso`, `LowerTorso`, `Torso` plus any parts with `HitboxType` attribute
- Uses a **pooled hitbox system** (30 reusable Parts) to avoid allocation during raycasts
- Rewind time is clamped to 250ms max

### Dashing
- Listens to `DashRequest` remote
- 4-second cooldown, applies velocity impulse in the move direction
- Different speed for ground vs air dashes
- Blocks dash during High Noon
- Plays a server-side dash animation

### On Hit
- Calls `HighNoon.addCharge(player, isHeadshot)` to grant ultimate charge

## Dependencies

- **Requires:** [[HighNoonModule]] (line 26, for `addCharge`)
- **Required by:** [[Main]] (`.init()` called at boot)
- **Listens to remotes:** `FireBullet`, `DashRequest`
- **Fires remotes:** `HitConfirm`, `ReplicateShot`

## Key Constants

| Constant | Value | Purpose |
|----------|-------|---------|
| RANGE | 500 | Max raycast distance |
| DAMAGE | 35 | Body shot damage |
| HEADSHOT_DAMAGE | 65 | Headshot damage |
| HIT_FORGIVENESS_RADIUS | 3.5 | Near-miss cylinder radius |
| MAX_REWIND_TIME | 0.25s | Max lag compensation window |
| DASH_COOLDOWN | 4s | Dash ability cooldown |
| DASH_SPEED | 240 | Ground dash velocity |

## Connections

### RemoteEvents

| Remote | Direction | Other script |
|--------|-----------|-------------|
| `FireBullet` | ← Client | [[FPSRevolverClient]] sends camera origin, direction, muzzle pos |
| `DashRequest` | ← Client | [[FPSRevolverClient]] sends move direction |
| `HitConfirm` | → Client | Received by [[HitMarkScript]] (hitmarker) and [[HighNoonClient]] (during ult) |
| `ReplicateShot` | → Client | Received by [[FPSRevolverClient]] (tracer VFX for other players) |

### Direct require()

| Target | Function | Purpose |
|--------|----------|---------|
| [[HighNoonModule]] | `HighNoon.addCharge(player, isHeadshot)` | Grants ultimate charge on confirmed hits |

### Shared remote listeners

`DashRequest` is also independently listened to by [[DashDustVFXModule]] for dust VFX.
