# StarterPack

Contains all tools that clone into each player's Backpack on join. Currently holds the active revolver and experimental test guns.

**Path:** `game.StarterPack`
**Type:** StarterPack

## Contents

| Child | Type | Description |
|-------|------|-------------|
| CamGun | Folder | Holds the active [[BanditGun GunServer\|BanditGun]] tool + a backup test tool |
| [[HitBoxTestTool]] | Tool | Standalone experimental gun with dash, recoil, and hardcoded damage |

## CamGun Folder

| Child | Type | Description |
|-------|------|-------------|
| BanditGun | Tool | **Active revolver** — 4 scripts, integrated with [[Config]], [[ProgressionService]], [[InvulnService]] |
| HitBoxTestTool (With Hitbox - Backup) | Tool | Backup copy of [[HitBoxTestTool]] (3 scripts, same code) |

## BanditGun Scripts

| Script | Type | Lines | Purpose |
|--------|------|-------|---------|
| [[BanditGun GunServer]] | Script | 656 | Server-side shooting, damage, reload, impact effects |
| [[BanditGun GunClient]] | LocalScript | 599 | Camera, IK aiming, animations, input, client-predicted sound |
| [[BanditGun RevolverGuiClient]] | LocalScript | 380 | Revolver wheel HUD — bullet pop/rotate animations |
| [[BanditGun LocalScript]] | LocalScript | 69 | Gun model reload animation (R key) |

## HitBoxTestTool Scripts

| Script | Type | Lines | Purpose |
|--------|------|-------|---------|
| [[HitBoxTestTool GunScript]] | Script | 429 | Server shooting + dash mechanic |
| [[HitBoxTestTool GunClient]] | LocalScript | 712 | Camera, IK, recoil system, dash client-side |
| [[HitBoxTestTool FireServerScript]] | LocalScript | 12 | Legacy simple fire script (uses deprecated Mouse) |

## Architecture Note

The **BanditGun** is the production weapon — it reads damage/ammo values from [[Config]], awards kills through [[ProgressionService]], checks invulnerability via [[InvulnService]], and breaks windows via [[DestructibleService]]. It communicates through the shared [[GunRemote]] in ReplicatedStorage.

The **HitBoxTestTool** is an experimental/prototype gun with hardcoded values, its own internal RemoteEvents (FireBullet, HitConfirm, DashRequest), a camera recoil system, and a dash ability. It uses [[ReplicateShot]] from the [[Revolver]] folder for tracer replication.
