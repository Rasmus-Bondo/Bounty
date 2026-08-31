---
tags: [shared, modulescript, events]
path: game.ReplicatedStorage.Hunters.Dust.Modules.RevolverClientEvents
type: ModuleScript
lines: 39
---

# RevolverClientEvents

Creates and returns client-side BindableEvents used for intra-client communication.

## What it does
1. Creates a `ClientEvents` folder under the Revolver assets folder if it doesn't exist
2. Creates BindableEvents for: AmmoChanged, Reloaded, DashCooldownStarted, Skill2CooldownStarted, DashRequested, Skill2Requested, FireRequested, HighNoonAimNudge
3. Returns a table of all BindableEvent references

## Dependencies
- **Requires:** Nothing
- **Required by:** FPSRevolverClient

## Connections
### RemoteEvents
None

### BindableEvents
| Bindable | Direction | Other script |
|----------|-----------|-------------|
| `AmmoChanged` | created | Fired by [[RevolverAmmo]] |
| `Reloaded` | created | Fired by [[RevolverAmmo]] |
| `DashCooldownStarted` | created | Fired by [[RevolverDash]] |
| `Skill2CooldownStarted` | created | Fired by [[RevolverSkill2]] |
| `DashRequested` | created | Fired by [[HunterGuiClient]] (mobile button) |
| `Skill2Requested` | created | Fired by [[HunterGuiClient]] (mobile button) |
| `FireRequested` | created | Fired by [[HunterGuiClient]] (mobile fire button) |
| `HighNoonAimNudge` | created | Used by HighNoon system |

### Direct require()
None
