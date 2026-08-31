---
tags: [server, modulescript, combat, bram]
path: game.ServerScriptService.Hunters.BramServer.GrudgekeeperDamageService
type: ModuleScript
lines: 80
---

# GrudgekeeperDamageService

Distance-falloff damage for Bram's Grudgekeeper shotgun. Since the single-thick-raycast rework, `GrudgekeeperModule` feeds the full total for the hit's distance straight to `ApplyAccumulatedDamage`.

## What it does
1. `GetTotalDamageForDistance(isHeadshot, distance)` — flat 100/50 (head/body) inside the 20-stud near zone, linear falloff to 25/15 at the 60-stud max range, 0 beyond. This is what the module now uses for the single target it hits
2. `GetPelletDamage(isHeadshot, distance)` — the above divided by PelletCount (8). **Legacy/unused** since the fan → single-cast rework; retained but no longer called by the module
3. `ApplyAccumulatedDamage(character, humanoid, totalDamage)` — applies the damage in ONE TakeDamage; honours the victim's `DamageReductionPercent` attribute (Last Call mitigation — matters in Bram mirrors); returns `didKill, damageDealt`

## Dependencies
- **Requires:** Nothing
- **Required by:** GrudgekeeperModule

## Connections
### RemoteEvents
None

### BindableEvents
None

### Direct require()
None
