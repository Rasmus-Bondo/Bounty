# HitBoxTestTool

Experimental/prototype revolver with hardcoded damage, a dash ability, camera recoil system, and hit confirmation highlights. Uses its own internal RemoteEvents instead of the shared [[GunRemote]].

**Path:** `game.StarterPack.HitBoxTestTool`
**Type:** Tool
**Status:** Experimental — not the active production weapon (that's the BanditGun in CamGun)

## Contents

| Child | Type | Description |
|-------|------|-------------|
| [[HitBoxTestTool GunScript]] | Script | Server-side shooting, dash, hit highlights |
| [[HitBoxTestTool GunClient]] | LocalScript | Camera, IK, recoil, dash client-side |
| [[HitBoxTestTool FireServerScript]] | LocalScript | Legacy simple fire (uses deprecated Mouse) |
| FireBullet | RemoteEvent | Client → server fire request |
| HitConfirm | RemoteEvent | Server → client hit feedback |
| DashRequest | RemoteEvent | Client → server dash request |
| FireSound | Sound | Gunfire sound |
| Handle | Part | Tool handle with RevolverTest model |
| MuzzlePart | Part | Muzzle with MuzzleAttachment + FlashEmitter |

## Key Differences from BanditGun

| Feature | BanditGun | HitBoxTestTool |
|---------|-----------|----------------|
| Damage values | From [[Config]] module | Hardcoded (45 body / 95 head) |
| Ammo system | Server-managed with reload | No ammo tracking |
| Spread | Consecutive-shot spread | No spread |
| Networking | Shared [[GunRemote]] | Own internal RemoteEvents |
| Dash ability | No | Yes (Q key, 2s cooldown) |
| Camera recoil | No | Yes (pitch/yaw/kick impulse) |
| Hit highlight | No | Yes (red flash on hit character) |
| Tracer replication | Server-created tracer parts | Uses [[ReplicateShot]] FireAllClients |
| Impact effects | Material-based sounds + VFX | Bullet holes + smoke particles |
| Kill integration | [[ProgressionService]], [[EliminatePlayer]] | None — just TakeDamage |

## Backup Copy

A duplicate exists at `game.StarterPack.CamGun.HitBoxTestTool (With Hitbox - Backup)` with the same scripts.

## Dependencies

- [[Revolver]] folder in ReplicatedStorage — SmokeParticles template, ReplicateShot remote
