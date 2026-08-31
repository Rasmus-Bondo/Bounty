---
tags: [shared, modulescript, combat, ammo]
path: game.ReplicatedStorage.Hunters.Dust.Modules.RevolverAmmo
type: ModuleScript
lines: 132
---

# RevolverAmmo

OOP ammo manager that tracks current/max ammo and reload state with a token-based cancellation system.

## What it does
1. Tracks current ammo count (default max: 6) and reload state
2. Uses a token system to safely cancel/invalidate in-progress reloads
3. Fires `AmmoChangedEvent` BindableEvent when ammo is consumed or set
4. Fires `ReloadedEvent` BindableEvent when reload completes or is instant
5. Provides query methods: HasAmmo, IsFull, CanStartReload, GetIsReloading

## Dependencies
- **Requires:** Nothing
- **Required by:** FPSRevolverClient

## Connections
### RemoteEvents
None

### BindableEvents
| Bindable | Direction | Other script |
|----------|-----------|-------------|
| `AmmoChanged` | → | [[HunterGuiClient]] updates ammo counter |
| `Reloaded` | → | [[HunterGuiClient]] resets bullet icons |

### Direct require()
None
