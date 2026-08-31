# BanditGun RevolverGuiClient

Animates the revolver cylinder HUD — rotates the wheel on each shot, pops bullets in/out with scale tweens, and plays a full reload sequence with per-bullet loading animation.

**Path:** `game.StarterPack.CamGun.BanditGun.RevolverGuiClient`
**Type:** LocalScript (380 lines)
**Runs on:** Client

## How It Works

### Shot Animation
1. Identifies which chamber is active from current canvas rotation
2. Plays pop-out tween on the fired bullet (grow → shrink to 0 → hide)
3. Rotates canvas one step (60 deg) to advance to next chamber

### Reload Animation
1. Clears all bullets instantly
2. Tweens canvas back to 0 deg (aligned position)
3. Loads bullets 6→1 with staggered timing (RELOAD_TIME / maxAmmo per step)
4. Each bullet pops in with grow → shrink tween + LoadingBullet sound
5. Rotates canvas one step between each bullet
6. Final tween to READY_FIRE_ROTATION (0 deg)
7. Uses token system to cancel mid-reload if interrupted

### Equip/Unequip
- Equip: resets rotation, syncs bullet display to current ammo
- Unequip: cancels reload animation, hides entire GUI

## Animation Constants

| Constant | Value | Purpose |
|----------|-------|---------|
| ROTATE_STEP | 60 | Degrees per chamber (360/6) |
| SHOT_ROTATE_TIME | 0.09s | Rotation tween after firing |
| RELOAD_ROTATE_TIME | 0.08s | Rotation tween per bullet during reload |
| RELOAD_RESET_TIME | 0.12s | Tween back to 0 before reload starts |
| READY_ROTATE_TIME | 0.1s | Final alignment tween |
| RELOAD_TIME | 4.9s | Total reload animation duration |
| READY_FIRE_ROTATION | 0 | Resting angle after reload |

## Bullet Sizes

| State | Size (UDim2) |
|-------|-------------|
| NORMAL_SIZE | 0.324, 0.324 |
| POP_IN_SIZE | 0.36, 0.36 |
| SHOT_POP_SIZE | 0.38, 0.38 |

## GUI Structure

Reads from `PlayerGui.RevolverGui.Canvas`:
- RevolverWheel — background wheel image
- Bullet1–Bullet6 — individual bullet ImageLabels
- LoadingBullet — Sound played per bullet during reload
- Canvas.Rotation — animated to rotate the entire wheel

## Dependencies

- [[GunRemote]] — receives Ammo, ReloadStarted, ReloadFinished, ForceStopReload
- RevolverGui ScreenGui in PlayerGui

## Used By

- Runs inside BanditGun Tool, paired with [[BanditGun GunClient]]
