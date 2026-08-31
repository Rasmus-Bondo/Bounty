---
tags: [server, modulescript, vfx, combat]
path: game.ReplicatedStorage.Hunters.Dust.Modules.RevolverServer.RevolverImpactFX
type: ModuleScript
lines: 151
---

# RevolverImpactFX

OOP module for creating world impact effects (bullet holes and smoke) at raycast hit points.

## What it does
1. Creates anchored bullet hole decals at hit positions, oriented to surface normals with random rotation
2. Skips bullet holes on character models (only creates on world geometry)
3. Creates impact smoke by cloning a smoke particle template to an attachment at the hit point
4. Supports ParticleEmitter, Attachment, BasePart, and Model templates for smoke
5. Auto-destroys bullet holes after 12s and smoke after 2s via Debris

## Dependencies
- **Requires:** Nothing (configured externally)
- **Required by:** RevolverModule, SunspikeModule (Vesper instantiates its own instance from VesperConfig.Impact), GrudgekeeperModule (Bram instance from GrudgekeeperConfig.Impact)

## Connections
### RemoteEvents
None

### BindableEvents
None

### Direct require()
None (all dependencies injected via constructor config)
