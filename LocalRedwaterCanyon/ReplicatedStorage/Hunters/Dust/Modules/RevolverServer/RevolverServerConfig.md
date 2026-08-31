---
tags: [server, modulescript, config, combat]
path: game.ReplicatedStorage.Hunters.Dust.Modules.RevolverServer.RevolverServerConfig
type: ModuleScript
lines: 87
---

# RevolverServerConfig

Server-side configuration table for combat, hit forgiveness, lag compensation, impact FX, and dash.

## What it does
1. Defines Combat: range (**250** — cut from 500 on 2026-08-29; falloff already floors at `FalloffEndDistance` 200, so studs 200–500 were identical for a human and served only long-range aimbotting), damage (35), headshot damage (65), fire cooldowns (normal 0.4s, skill2 0.07s), origin validation distances. (Pre-Phase-2 `HighlightTime = 0.14` was removed when the red hit-flash moved into HunterHitPipeline.)
2. Defines HitForgiveness: radius (3.5 studs), max distance (**250** studs — cut from 350 alongside `Combat.Range` on 2026-08-29 and must never exceed it; `FindForgivenHumanoid` tests `distanceAlongRay` against this value independently of the shot ray, so a larger number forgives near-misses onto targets the ray already stopped short of)
3. Defines Penetration: Dust's per-hunter overrides for the shared BulletPenetration rules (`DamageMultiplierPerLayer` 0.5, `MaxLayers` 2). Anything omitted falls back to `BulletPenetration.Config`, so this is the lever for tuning Dust's wallbangs without touching Vesper or Bram
4. Defines LagCompensation: history rate (1/30), max history (0.65s), max rewind (0.25s), tracked body parts
5. Defines Impact: bullet hole texture, lifetime (12s), size (0.35), smoke emit count (20)
6. Defines Dash: cooldown (4s), speed (240), time (0.5s), air dash multiplier (0.45), end speed multipliers

## Dependencies
- **Requires:** Nothing
- **Required by:** RevolverModule

## Connections
### RemoteEvents
None

### BindableEvents
None

### Direct require()
None
