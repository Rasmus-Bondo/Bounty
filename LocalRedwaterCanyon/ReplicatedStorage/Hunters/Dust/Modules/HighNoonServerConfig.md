---
tags: [shared, modulescript, config, ultimate]
path: game.ReplicatedStorage.Hunters.Dust.Modules.HighNoonServerConfig
type: ModuleScript
lines: 74
---

# HighNoonServerConfig

Central configuration table for all HighNoon ultimate ability parameters.

## What it does
1. Defines Ultimate charge settings: max charge (100), body hit charge (2.5), headshot charge (6), kill charge (5), passive charge/sec (0.125)
2. Defines Timing: lock-in time (2s), min shoot time (1.5s), shoot time (3s), max hold time (5s), shot delay (0.12s)
3. Defines Targeting: range (180 studs), cone angle (45 degrees), max targets (6)
4. Defines Damage: quick damage (45, body shot on an in-cone but not-yet-locked enemy), execute threshold (35 HP), and the locked-shot execute — `LockedHealthPercent` (1.0) as a fraction of the victim's **MaxHealth**, `LockedIgnoresDamageReduction` (true), and `HeadshotDamage` (175) kept only as a floor / unreadable-MaxHealth fallback
5. `GetLockedShotDamage(humanoid)` returns the lethal damage for one fully-locked shot: `max(HeadshotDamage, MaxHealth * LockedHealthPercent)`, falling back to current health and then the flat floor when MaxHealth reads 0 or NaN. Shared by the player path (HighNoonDamage, which receives it as an injected `GetLockedShotDamage` config field from HighNoonModule rather than requiring this module) and the Dust bot path (BotCombat, which already requires this module), so the two can't drift. The flat 175 it replaced killed Vesper (125), Dust and Fortuna (150) but left Bram (225) standing
6. Defines Movement: slow walk speed (6) during ultimate

## Dependencies
- **Requires:** Nothing
- **Required by:** HighNoonModule

## Connections
### RemoteEvents
None

### BindableEvents
None

### Direct require()
None
