# Revolver Folder

Contains the bullet tracer visual system and shot replication remote.

**Path:** `game.ReplicatedStorage.Revolver`
**Type:** Folder

## Contents

| Name | Type | Description |
|------|------|-------------|
| [[laserBeamEffect]] | ModuleScript | Creates animated bullet tracer beams |
| Objects/LaserBeam | Part | Template part with Beam, StartAttachment, EndAttachment |
| Remotes/ReplicateShot | RemoteEvent | Replicates shot visuals to other clients |
| SmokeParticles | ParticleEmitter | Muzzle smoke particle template |

## How Bullet Tracers Work

1. Player shoots → [[GunClient]] fires the gun
2. [[laserBeamEffect]] clones the LaserBeam template from `Objects/`
3. Sets StartAttachment at muzzle position, EndAttachment at hit point
4. Tweens StartAttachment toward EndAttachment at 1200 studs/sec
5. Destroys the beam part when tween completes

## Referenced By

- [[GunClient]] — calls `laserBeamEffect()` for local bullet visuals
- [[GunServer]] — may replicate via ReplicateShot for other players to see
