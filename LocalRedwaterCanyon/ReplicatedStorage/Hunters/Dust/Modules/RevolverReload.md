---
tags: [client, modulescript, combat, reload]
path: game.ReplicatedStorage.Hunters.Dust.Modules.RevolverReload
type: ModuleScript
lines: 209
---

# RevolverReload

OOP reload controller that orchestrates the timed reload sequence with animations, sounds, and left arm visibility.

## What it does
1. Checks reload eligibility: ammo not full, not currently dashing, custom check passes
2. Starts reload via AmmoController token system to allow safe cancellation
3. Schedules left arm show/hide, reload sounds, and finish sound via `task.delay` chains
4. Disables shooting during reload, re-enables on completion
5. Supports cancel (interrupts reload) and instant reload (immediate refill)

## Dependencies
- **Requires:** Nothing (configured externally via callbacks and injected dependencies)
- **Required by:** FPSRevolverClient

## Connections
### RemoteEvents
None

### BindableEvents
None

### Direct require()
None (all dependencies injected via constructor config)
