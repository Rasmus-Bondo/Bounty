# BanditGun RevolverGuiClient

Animated revolver cylinder HUD that visually tracks ammo state. Rotates a canvas with 6 bullet images — bullets pop out on fire and pop back in during reload, with the cylinder rotating 60° per shot.

**Path:** `game.ServerStorage.BanditGun.RevolverGuiClient`
**Type:** LocalScript (380 lines)
**Runs on:** Client

## GUI Structure

References `PlayerGui.RevolverGui.Canvas`:
- **RevolverWheel** — background cylinder image
- **Bullet1–6** — individual bullet images arranged in a circle
- **LoadingBullet** — Sound played per bullet during reload

## Animation Constants

| Constant | Value | Purpose |
|----------|-------|---------|
| ROTATE_STEP | 60° | Degrees per chamber rotation |
| SHOT_ROTATE_TIME | 0.09s | Rotation tween time on fire |
| RELOAD_ROTATE_TIME | 0.08s | Rotation tween time per bullet loaded |
| RELOAD_RESET_TIME | 0.12s | Tween back to 0° at reload start |
| READY_ROTATE_TIME | 0.1s | Final settle tween after reload |
| RELOAD_TIME | 4.9s | Total reload animation duration |
| READY_FIRE_ROTATION | 0° | Resting angle after reload |

## Bullet Sizes (UDim2)

| State | Size |
|-------|------|
| Normal | 0.324 × 0.324 |
| Pop-in | 0.36 × 0.36 |
| Shot pop | 0.38 × 0.38 |

## Shot Animation

1. Determines which chamber is "current" based on canvas rotation
2. Pop-out animation on the fired bullet (grow → shrink to 0 → hide)
3. Rotates canvas 60° forward

## Reload Animation

1. Instantly hides all bullets
2. Tweens canvas back to 0°
3. Loads bullets one-by-one from Bullet6 → Bullet1 with:
   - Pop-in animation per bullet
   - LoadingBullet sound per bullet
   - 60° rotation per step
4. Final settle tween to ready position
5. Uses `reloadToken` for cancellation safety

## Remote Events Handled

| Action | Response |
|--------|----------|
| `"Ammo"` | If ammo decreased by 1: animate shot. Otherwise: instant display update |
| `"ReloadStarted"` | Start full reload animation sequence |
| `"ReloadFinished"` | Cancel animation, snap to full state |
| `"ForceStopReload"` | Cancel animation, snap to current state |

## Dependencies

- [[GunRemote]] — listens for ammo/reload events
- RevolverGui (ScreenGui in StarterGui) — the actual GUI this script drives

## Used By

- Runs automatically when the [[BanditGun Tool]] is equipped
