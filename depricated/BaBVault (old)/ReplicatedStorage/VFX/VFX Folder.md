# VFX Folder

ParticleEmitter templates for bullet impact visual effects. Each emitter is cloned and parented to the hit position when a bullet strikes a specific material.

**Path:** `game.ReplicatedStorage.VFX`
**Type:** Folder

## Particle Emitters

| Name | Material | Description |
|------|----------|-------------|
| WoodImpact | Wood/WoodPlanks | Wood splinter particles |
| BrickImpact | Brick | Brick dust particles |
| GlassImpact | Glass/SmoothPlastic | Glass shard particles |
| SandImpact | Sand | Sand puff particles |
| StoneImpact | Slate/Concrete/Cobblestone | Stone chip particles |

> Note: `WoodSplinterParticle` is a separate ParticleEmitter stored directly in ReplicatedStorage (not in this folder).

## Referenced By

- [[GunServer]] — clones the matching VFX emitter based on hit material and emits a burst at the impact point
