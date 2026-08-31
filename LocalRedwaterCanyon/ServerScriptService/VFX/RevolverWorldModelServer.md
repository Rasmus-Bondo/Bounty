---
tags:
  - server
  - modulescript
  - vfx
  - dust
path: game.ServerScriptService.VFX.RevolverWorldModelServer
type: ModuleScript
lines: 122
---

# RevolverWorldModelServer

Dust-specific bootstrap for the third-person revolver world model. Thin wrapper that constructs a [[HunterWorldModel]] instance with Dust's config and wires it to the `WorldRevolverShotVFX` BindableEvent.

## What it does

1. Ensures `ReplicatedStorage.Hunters.Dust.Remotes/WorldRevolverShotSound` RemoteEvent and `ReplicatedStorage.Hunters.Dust.ServerEvents/WorldRevolverShotVFX` BindableEvent exist
2. Resolves the world gun **folder-driven**: `TemplateResolver` reads `EquippedWeaponSkin_Dust` straight against `Hunters.Dust.Weapon.WorldModel.Skins`, so a new gun is a Model dropped in that folder under the profile's skin name (`HellFire`, `BetaRevolver`, `Icefang`) and no code entry. It replaced a hardcoded three-entry table. `AttachmentOffset` is now a single value for every Dust world gun rather than a per-skin `AttachmentOffsetResolver` — every authored model shares the default's pivot convention.
3. Constructs a [[HunterWorldModel]] with: `HunterName="Dust"`, the `WorldRevolver` template, `CosmeticName="WorldRevolverCosmetic"` (preserved for HideLocalWorldRevolver compatibility), `AttachmentMethod="Motor6D"`, the right-hand offset, `SmokeParticleTemplate` from `Revolver.SmokeParticles`, no idle animation, and no Heartbeat watchdog
4. Calls `worldModel:Start(Players)` to wire all the per-player lifecycle hooks
5. Listens to `WorldRevolverShotVFX` (fired by [[RevolverModule]] / HighNoonDamage on a valid hit): re-checks the player is on Dust, then calls `worldModel:PlayOneShot` with the shoot animation — its id resolved once at boot from the Dust manifest via `HunterAnimations.id("Dust", "World", "Shooting")`; this was one of the FOUR files carrying the same string literal — plus `worldModel:EmitMuzzleFlash` + `EmitMuzzleSmoke`, and fires `WorldRevolverShotSound` to all clients

## Dependencies

- **Requires:** [[HunterWorldModel]], [[HunterAnimations]] (the world Shooting clip id from the Dust manifest — from `ReplicatedStorage.Hunters.Shared`), [[HunterSelectionService]] (gates Dust-only behavior)
- **Required by:** Main

## Connections

### RemoteEvents

| Remote | Direction | Other script |
|--------|-----------|--------------|
| `WorldRevolverShotSound` | → All Clients | Notifies clients to play 3D shot sound; client ignores if shooter == local player; [[EarlyShotRemoteDrain]] drains it during client load |

### BindableEvents

| Bindable | Direction | Other script |
|----------|-----------|--------------|
| `WorldRevolverShotVFX` | ← | [[RevolverModule]] fires this on a valid shot to trigger world-model VFX |

### Direct require()

| Target | Function | Purpose |
|--------|----------|---------|
| [[HunterWorldModel]] | `.new()`, `:Start()`, `:PlayOneShot()`, `:EmitMuzzleFlash()`, `:EmitMuzzleSmoke()` | Shared world-model lifecycle + Dust shoot VFX (replaces the former inline `RevolverWorldModelService`) |
| [[HunterSelectionService]] | `.IsHunter()` | Gate shoot VFX firing to Dust players only |
| [[HunterAnimations]] | `HunterAnimations.id()` | Resolve the world Shooting clip id from the Dust manifest |
