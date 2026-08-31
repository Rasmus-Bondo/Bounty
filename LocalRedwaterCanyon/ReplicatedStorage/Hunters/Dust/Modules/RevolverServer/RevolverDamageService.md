---
tags: [server, modulescript, combat, damage]
path: game.ReplicatedStorage.Hunters.Dust.Modules.RevolverServer.RevolverDamageService
type: ModuleScript
lines: 67
---

# RevolverDamageService

OOP server-side damage handler for regular revolver shots. Supports distance-based damage falloff with configurable start/end distances and per-shot-type (body / headshot) minimum damage.

## What it does
1. Computes scaled damage via `GetDamageForDistance(isHeadshot, distance)` — linear interpolation from full damage at `FalloffStartDistance` down to the per-shot-type minimum at `FalloffEndDistance` (clamped outside the band)
2. `ApplyDamage(hitCharacter, hitHumanoid, isHeadshot, distance, damageMultiplier)` applies the scaled damage via `Humanoid:TakeDamage` and returns `(didKill, damageDealt)` so callers can report the actual damage downstream (kill feed, damage numbers, charge award)
3. The optional `damageMultiplier` is the cover penalty from BulletPenetration.GetDamageMultiplier — 0.5 behind one wall, 0.25 behind two. Applied before the victim's `DamageReductionPercent` (Bram's Last Call), so the two stack multiplicatively. Omitting it leaves damage untouched
4. With no falloff config (start == end) behaves like a flat-damage service (body 35 / headshot 65 by default)

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
