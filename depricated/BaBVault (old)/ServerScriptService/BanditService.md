# BanditService

Manages the BanditGun tool lifecycle — cloning from template, equipping, and cleanup.

**Path:** `game.ServerScriptService.RoundSystem.BanditService`
**Type:** ModuleScript (57 lines)
**Runs on:** Server

## How It Works

### Gun Template
Clones from `ServerStorage.BanditGun` (via [[References]].banditGunTemplate). The template contains the full [[GunServer]] + [[GunClient]] tool hierarchy.

### Methods

#### giveBanditGun(player)
1. Removes any existing BanditGun (prevents duplicates)
2. Clones template to player's Backpack
3. Auto-equips via `humanoid:EquipTool()`

#### removeBanditGunFromPlayer(player)
Destroys BanditGun from both Backpack and Character (handles both unequipped and equipped states).

#### removeBanditGunFromEveryone()
Iterates all players and removes guns. Called during round reset.

#### giveGunToAllPlayers()
Gives a gun to every player. (Available but [[RoundController]] gives guns individually to opted-in players.)

## Dependencies

- [[References]] — `banditGunTemplate` from ServerStorage
- Players service

## Used By

- [[RoundController]] — gives guns at round start and on mid-round respawn, removes all guns on reset
