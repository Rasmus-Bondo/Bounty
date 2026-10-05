---
tags:
  - shared
  - modulescript
  - config
  - combat
path: game.ReplicatedStorage.PVE.Config.CombatConfig
type: ModuleScript
lines: 11
---

# CombatConfig

Static tuning table for PVE movement, health and the two PVE weapons. It is independent of the legacy hunter system.

## What it does

1. Returns base player tuning: `WalkSpeed` 16, `SprintSpeed` 24, `MaxHealth` 100, `EquipDelay` 0.45
2. Defines `Weapons.Revolver`: 6-round magazine, 28 damage, 1.7x headshot, 350-stud range with damage falloff from 150 studs down to a 0.65 scale
3. Defines `Weapons.Shotgun`: 2-round magazine, 8 pellets at 10 damage, 4.2 spread, 160-stud range with falloff from 32 studs down to a 0.25 scale
4. Each weapon also carries projectile speed, fire interval, reload time, recoil, the first-person `ViewOffset`, the world-model `Grip` CFrame and a `WorldIdle` animation id

## Dependencies

- **Requires:** Nothing
- **Required by:** CombatServer, CombatClient

## Connections

None. Pure data module.
