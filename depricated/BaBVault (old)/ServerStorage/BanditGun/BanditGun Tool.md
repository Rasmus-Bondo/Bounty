# BanditGun Tool

The revolver weapon given to players when they opt into a round. A Roblox Tool containing server-side hit detection, client-side aiming/IK, animated cylinder HUD, and reload animations for both the character body and the revolver model.

**Path:** `game.ServerStorage.BanditGun`
**Type:** Tool

## Structure

### Scripts
| Script | Type | Purpose |
|--------|------|---------|
| [[BanditGun GunServer]] | Script | Server-authoritative shooting, damage, ammo, impact FX |
| [[BanditGun GunClient]] | LocalScript | Client aiming, IK, camera, shoulder offset, input handling |
| [[BanditGun RevolverGuiClient]] | LocalScript | Animated cylinder HUD with rotating bullet display |
| [[BanditGun LocalScript]] | LocalScript | Reload animation playback for gun model + character body |

### Assets
| Asset | Type | Description |
|-------|------|-------------|
| Handle | Part | Tool handle with MuzzleAttachment and welded RevolverTest model |
| Handle.RevolverTest | Model | Animated revolver with Humanoid/Animator for gun animations — barrel, body, trigger, igniter, reload mechanism, 6 bullet Motor6Ds |
| FireSound | Sound | Gunshot sound template |
| ReloadSound | Sound | Reload sound template |

## How It Gets to Players

1. [[BanditService]] clones this tool from ServerStorage into the player's Backpack when they are assigned the "Bandit" role
2. Player equips the tool, triggering GunClient's `onEquipped` flow
3. On round end or death, the tool is removed from the character

## Dependencies

- [[GunRemote]] (RemoteEvent) — client-server communication for Fire/Reload/Ammo actions
- [[Config]] — all gun tuning values (damage, range, cooldown, spread, ammo)
- [[ProgressionService]], [[InvulnService]], [[DestructibleService]] — server modules used by GunServer
- [[SFX Folder]], [[VFX Folder]] — impact sound/particle templates
- RevolverGui (ScreenGui in StarterGui) — the HUD that RevolverGuiClient drives
