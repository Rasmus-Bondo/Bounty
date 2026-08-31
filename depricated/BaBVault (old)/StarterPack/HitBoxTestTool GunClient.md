# HitBoxTestTool GunClient

Client-side controller for the experimental gun — extends the BanditGun's camera/IK system with a camera recoil system, smooth yaw interpolation, IK weight recovery, dash camera offset, and Q-key dash input.

**Path:** `game.StarterPack.HitBoxTestTool.GunClient`
**Type:** LocalScript (712 lines)
**Runs on:** Client

## How It Works

### Camera & Aiming
- Same shoulder camera system as [[BanditGun GunClient]] (FOV 62, zoom 6, mouse lock)
- Adds smooth yaw interpolation (ROOT_YAW_RESPONSIVENESS = 10) instead of instant snap
- Torso tilt accounts for recoil offset in pitch calculation

### Recoil System
- On fire: applies pitch (2.8 deg), yaw (random +/-0.8 deg), and kick (0.2) impulses
- Per frame: exponential decay back to zero (RECOIL_RETURN_SPEED = 15)
- Recoil feeds into camera offset, torso tilt, and aim target position
- IK weight drops to 0 on fire, recovers after 0.12s delay

### Dash (Client-Side)
- Q key triggers dash: disables IK, resets waist/neck transforms
- Camera offset shifts to DASH_CAMERA_OFFSET (4.4, 0.95, -1.6) with separate smoothness
- After DASH_TIME + 0.1s: restores IK with gradual weight recovery
- Fires DashRequest RemoteEvent to server

### IK Differences from BanditGun
- IKControlType.Position (not Transform) — no EndEffectorOffset
- Weight = 0.72 (not 1.0) with smooth weight interpolation
- Separate elbow pole offsets: RIGHT=2.6, UP=0.85, BACK=1.2

## Recoil Constants

| Constant | Value |
|----------|-------|
| RECOIL_PITCH_IMPULSE | 2.8 deg |
| RECOIL_YAW_IMPULSE | 0.8 deg |
| RECOIL_KICK_IMPULSE | 0.2 |
| RECOIL_RETURN_SPEED | 15 |
| RECOIL_CAMERA_STRENGTH | 0.18 |
| RECOIL_AIM_DISTANCE_LOSS | 2.4 |
| IK_RECOVER_TIME | 0.12s |

## Dash Constants (Client)

| Constant | Value |
|----------|-------|
| DASH_KEY | Q |
| DASH_COOLDOWN | 2s |
| DASH_TIME | 0.5s |
| DASH_CAMERA_OFFSET | (4.4, 0.95, -1.6) |

## Dependencies

- Internal RemoteEvents: FireBullet, DashRequest
- FireSound on tool
- MuzzlePart.MuzzleAttachment for sound positioning

## Used By

- Runs inside [[HitBoxTestTool]] on the client when equipped
