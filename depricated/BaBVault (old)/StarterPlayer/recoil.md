# recoil

**Status: DISABLED** — Standalone camera recoil prototype. Not used in production; the active recoil system is built into [[HitBoxTestTool GunClient]] instead.

**Path:** `game.StarterPlayer.StarterPlayerScripts.recoil`
**Type:** LocalScript (59 lines, disabled)
**Runs on:** N/A (script is disabled)

## How It Works

Generic camera recoil that applies directly to `workspace.CurrentCamera.CFrame`:

1. On mouse click: adds pitch kick (KickUp) and random horizontal kick (KickSide) to `recoilTarget`
2. Each RenderStepped: lerps `recoilOffset` toward `recoilTarget` (fast), then decays `recoilTarget` toward zero (slower)
3. Applies accumulated offset as CFrame.Angles rotation on the camera

## Config Values

| Parameter | Value |
|-----------|-------|
| KickUp | 2.5 deg |
| KickSide | 0.8 deg max |
| RecoverySpeed | 6 |
| MaxAccum | 12 deg |

## Notes

- Fires on raw MouseButton1 click — not connected to any weapon system
- Would conflict with both FirstPersonCamera and BanditGun GunClient camera control
- The [[HitBoxTestTool GunClient]] has a more sophisticated recoil system with pitch/yaw/kick impulses and exponential decay
