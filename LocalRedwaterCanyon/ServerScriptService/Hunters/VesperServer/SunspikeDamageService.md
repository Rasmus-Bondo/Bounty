---
tags: [server, modulescript, combat, damage, vesper]
path: game.ServerScriptService.Hunters.VesperServer.SunspikeDamageService
type: ModuleScript
lines: 78
---

# SunspikeDamageService

OOP damage handler for Vesper's Sunspike Carbine. Mirrors RevolverDamageService's distance-falloff shape, plus a headshot bonus multiplier parameter for the Deadeye Focus passive.

## What it does
1. `GetDamageForDistance(isHeadshot, distance)` — linear falloff from full damage inside `FalloffStartDistance` (240) down to the per-shot-type minimum at `FalloffEndDistance` (300); body 65→45, headshot 125→90
2. `ApplyDamage(hitCharacter, hitHumanoid, isHeadshot, distance, headshotBonusMultiplier, damageMultiplier)` — applies falloff damage; when the hit is a headshot and the multiplier exceeds 1 it scales the post-falloff value (Deadeye Focus: up to ×1.5, so 125 base → 187.5 fully ramped), then `Humanoid:TakeDamage` and returns `(didKill, damageDealt)`
3. The optional 6th `damageMultiplier` is the cover penalty from BulletPenetration.GetDamageMultiplier — 0.5 behind one wall, 0.25 behind two. Applied **after** the Deadeye bonus so cover cuts the boosted number too, and before the victim's `DamageReductionPercent`
4. The headshot multiplier is computed by SunspikeModule from the server-side scope timer at fire time — this module stays stateless

## Dependencies
- **Requires:** Nothing
- **Required by:** SunspikeModule

## Connections
### RemoteEvents
None

### BindableEvents
None

### Direct require()
None
