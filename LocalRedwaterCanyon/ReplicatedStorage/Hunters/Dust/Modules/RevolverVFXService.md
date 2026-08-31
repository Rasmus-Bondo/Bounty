---
tags: [shared, modulescript, vfx, combat]
path: game.ReplicatedStorage.Hunters.Dust.Modules.RevolverVFXService
type: ModuleScript
lines: 37
---

# RevolverVFXService

Static utility module for muzzle flash and smoke particle effects.

## What it does
1. Emits a single flash particle from the FlashEmitter on the muzzle part
2. Clones a smoke ParticleEmitter template to the muzzle attachment and emits 4 particles
3. Auto-destroys cloned smoke emitters via Debris after 2 seconds
4. Provides a generic `EmitSmokeTemplate` method for reuse

## Dependencies
- **Requires:** Nothing
- **Required by:** FPSRevolverClient

## Connections
### RemoteEvents
None

### BindableEvents
None

### Direct require()
None
