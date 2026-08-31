---
tags: [client, modulescript, combat, ability]
path: game.ReplicatedStorage.Hunters.Dust.Modules.RevolverSkill2
type: ModuleScript
lines: 195
---

# RevolverSkill2

OOP fan-the-hammer ability that rapidly fires all remaining ammo with reduced recoil.

## What it does
1. Validates activation: not already using, not dashing, not reloading, cooldown elapsed (8s), has ammo
2. Fires all remaining bullets in a rapid sequence with reduced recoil multiplier (0.55)
3. Shows/hides left arm per shot with precise timing around animation wait times
4. Fires `Skill2CooldownStarted` BindableEvent for UI cooldown display
5. Auto-requests reload when all ammo is expended
6. Blocks regular shooting during the burst sequence

## Dependencies
- **Requires:** Nothing (configured externally via callbacks and injected dependencies)
- **Required by:** FPSRevolverClient

## Connections
### RemoteEvents
None (fires bullets via OnFireOneBullet callback → [[RevolverShooting]])

### BindableEvents
| Bindable | Direction | Other script |
|----------|-----------|-------------|
| `Skill2CooldownStarted` | → | [[HunterGuiClient]] starts Skill2 cooldown |

### Direct require()
None (all dependencies injected via constructor config)
