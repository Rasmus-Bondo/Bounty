---
phase: 02-combat-audio-polish
plan: 03
status: complete
started: "2026-03-29T00:45:00Z"
completed: "2026-03-29T01:00:00Z"
---

# Summary: Material Impact VFX System

## What Was Built

Expanded the bullet impact system from wood-only to 5 material types with unique ParticleEmitter templates. Replaced wood-specific functions with a generic material detection and impact effect system.

## Tasks Completed

1. **Created VFX folder with 5 ParticleEmitter templates** — `ReplicatedStorage.VFX` containing:
   - WoodImpact (cloned from existing WoodSplinterParticle)
   - BrickImpact (gray-brown dust with gravity)
   - GlassImpact (bright reflective shards, high velocity, gravity-affected)
   - SandImpact (tan dust cloud with upward drift)
   - StoneImpact (gray chips with fast falloff)
   All templates have Enabled=false for manual Emit() calls.

2. **Generic material detection system** — Added `MATERIAL_VFX_MAP` mapping 18 material types to 5 VFX categories. Created `emitImpactEffects(result)` that detects `hitPart.Material`, clones the matching VFX template, creates temporary Part at hit position oriented to surface normal, emits 15-30 random particles, and cleans up via Debris.

## Key Files

- `game.ReplicatedStorage.VFX` — Folder with 5 ParticleEmitter templates
- `game.ServerStorage.BanditGun.GunServer` — `MATERIAL_VFX_MAP`, `getImpactVFXName()`, `emitImpactEffects()`, vfxFolder reference

## Deviations

- Kept `createImpactSpark` (generic sparks) for all environment hits alongside material-specific particles
- Removed `isWoodMaterial`, `emitWoodImpactEffects`, `woodSplinterTemplate`, `woodImpactSoundTemplate`

## Self-Check: PASSED

- [x] 5 ParticleEmitter templates in ReplicatedStorage.VFX
- [x] All templates have Enabled=false
- [x] MATERIAL_VFX_MAP covers 18 material types across 5 categories
- [x] emitImpactEffects uses material detection and template cloning
- [x] Debris:AddItem for cleanup
- [x] No remaining wood-specific references in fireShot
