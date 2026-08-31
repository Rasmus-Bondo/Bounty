---
tags: [client, modulescript, combat, shooting]
path: game.ReplicatedStorage.Hunters.Dust.Modules.RevolverShooting
type: ModuleScript
lines: 151
---

# RevolverShooting

OOP shooting controller that handles client-side bullet firing, raycasting, and server communication.

## What it does
1. Casts a ray from the camera position along its LookVector (optical axis) to determine hit position — this matches the crosshair, which `HitMarkScript` pins to true optical center (`ScreenInsets.None`). Replaced an earlier `ViewportPointToRay(ViewportSize/2)` cast that diverged from LookVector once a device GUI inset exists (mobile), causing a vertical crosshair/bullet mismatch; on PC (no inset) the two conventions coincide. Now matches Vesper's fire convention
2. Excludes the player's own character, viewmodel, and every `HealthPack`'s green `Pickup` + invisible `TouchHitbox` children (NOT the solid `Base`) so bullets pass through the floating pickup while the base stand still blocks them
3. `GetLocalHitPosition` resolves the tracer endpoint through [[BulletPenetration]].Pierce rather than a single raycast, so the local trail carries on past penetrable cover instead of stopping short of a victim the server does hit. Falls back to the absorb point when cover eats the shot, or full range in open air
3. Consumes ammo via AmmoController before firing
4. Triggers recoil, FOV kick, shoot animation, muzzle effects, and fire sound via callbacks
5. Calls `laserBeamEffect` to render the bullet trail from muzzle to hit point
6. Fires `FireBullet` RemoteEvent to server with ray origin, direction, muzzle position, skill2 flag, and server timestamp

## Dependencies
- **Requires:** [[BulletPenetration]] (from `ReplicatedStorage.Hunters.Shared`); everything else is configured externally via callbacks and injected dependencies
- **Required by:** FPSRevolverClient

## Connections
### RemoteEvents
| Remote | Direction | Other script |
|--------|-----------|-------------|
| `FireBullet` | → Server | [[RevolverModule]] validates and resolves the shot |

### BindableEvents
None

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[BulletPenetration]] | `.Pierce()` | Walks the local tracer through penetrable cover so the visual matches the server's shot |

### CollectionService Tags
| Tag | Usage | Defined by |
|-----|-------|-----------|
| `HealthPack` | Read via `GetTagged`; each pack's green `Pickup` + invisible `TouchHitbox` added to the bullet raycast Exclude list (the solid `Base` stand still blocks shots) | [[HealthPackSystem]] |
