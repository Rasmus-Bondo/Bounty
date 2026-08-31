---
tags: [server, module, vfx, dash]
path: game.ServerScriptService.Modules.DashDustVFXModule
type: ModuleScript
lines: 136
---

# DashDustVFXModule

Server-side module that spawns sandy dust/smoke particles behind a player when they dash.

## What it does

1. Listens to the `DashRequest` remote (same remote that [[RevolverModule]] uses for dash movement)
2. When a valid dash starts, spawns a trail of smoke stamps behind the character:
   - Raycasts downward to find ground position
   - Creates small anchored Parts with `Smoke` instances
   - Tweens the smoke to fade out over 1.25 seconds
   - Stamps are placed every 40ms for 0.5 seconds
3. Uses a token system so only the latest dash produces smoke (prevents stacking)

## Dependencies

- **Requires:** Nothing
- **Required by:** [[Main]] (`.start()` at boot)

## Connections

### RemoteEvents

| Remote | Direction | Other script |
|--------|-----------|-------------|
| `DashRequest` | ← Client | [[FPSRevolverClient]] sends move direction (shared with [[RevolverModule]]) |

Both this module and [[RevolverModule]] listen to `DashRequest` independently — RevolverModule handles movement, this module handles dust VFX only.

## Key Constants

| Constant | Value | Purpose |
|----------|-------|---------|
| SMOKE_DURATION | 0.5s | How long to stamp dust |
| STAMP_INTERVAL | 0.04s | Time between stamps |
| SMOKE_LIFETIME | 1.25s | How long each smoke lasts |
| SMOKE_COLOR | RGB(190, 150, 95) | Sandy/dusty color |
