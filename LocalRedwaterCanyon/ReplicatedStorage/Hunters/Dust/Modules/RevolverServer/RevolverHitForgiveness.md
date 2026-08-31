---
tags: [server, modulescript, combat, aim-assist]
path: game.ReplicatedStorage.Hunters.Dust.Modules.RevolverServer.RevolverHitForgiveness
type: ModuleScript
lines: 134
---

# RevolverHitForgiveness

OOP server-side hit forgiveness that detects near-miss shots within a configurable radius.

## What it does
1. When a direct raycast misses, checks if any enemy humanoid's root/head is within 3.5 studs of the ray
2. Finds the closest point on the ray to each potential target's position
3. Caps forgiveness to targets within `MaxDistance` studs along the ray — module default 350, but **Dust passes 250** as of 2026-08-29 so forgiveness can never outrange his shot
4. `GetCoverBetween` validates the "forgiven" hit via [[BulletPenetration]].Pierce instead of a plain raycast: penetrable cover between shooter and target no longer disqualifies the hit, it just costs damage. A non-penetrable part that isn't the target still blocks, and a shot absorbed by cover (`Stopped`) is rejected outright
5. Returns the closest valid forgiven target — character, humanoid, hit position, and the penetration layer count for damage scaling (4 values; layers defaults to 0)

## Team modes

Allies are dropped from the near-miss candidates, so forgiveness can never award a hit on a
teammate. Cover checks pass the shooter through to the penetration walk for the same reason.

## Dependencies
- **Requires:** [[BulletPenetration]] (from `ReplicatedStorage.Hunters.Shared`), [[TeamAffinity]]
- **Required by:** RevolverModule, SunspikeModule (Vesper instantiates its own instance from VesperConfig.HitForgiveness)

## Connections
### RemoteEvents
None

### BindableEvents
None

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[BulletPenetration]] | `.Pierce()` | Walks shooter→target through penetrable cover in `GetCoverBetween`, returning reachability plus the wall count |
