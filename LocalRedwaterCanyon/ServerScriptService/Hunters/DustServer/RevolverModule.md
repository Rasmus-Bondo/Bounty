---
tags:
  - server
  - modulescript
  - combat
  - dust
path: game.ServerScriptService.Hunters.DustServer.RevolverModule
type: ModuleScript
lines: 536
---

# RevolverModule

Server-authoritative revolver combat for Dust: fire, dash, three-layer hit resolution (lag-rewind → current raycast → forgiveness sphere), world impact VFX, replicated tracers. After the Phase 2 port the entry script delegates all hunter-agnostic boilerplate (folder + remote setup, hunter gate, charge-service construction, hit pipeline construction) to [[HunterServerRuntime]] driven by the [[Manifest|Dust Manifest]], and returns the runtime so Main can hand it to [[HighNoonModule]].Start.

## What it does

1. Requires the [[Manifest|Dust Manifest]] and calls [[HunterServerRuntime]].Start(manifest) — receives a runtime handle exposing `IsHunter`, `HitPipeline`, `ChargeService`, `Remotes`, `ServerEvents`, `SharedRemotes`, `RoundStats`, `RoundActive`
2. Aliases `runtime.Remotes.{FireBullet, DashRequest, ReplicateShot, WorldRevolverShotSound}` and `runtime.ServerEvents.WorldRevolverShotVFX` locally
3. Constructs the Dust-specific hunter services: `RevolverImpactFX`, `RevolverDamageService` (now configured with `BodyMinDamage`/`HeadshotMinDamage`/`FalloffStartDistance`/`FalloffEndDistance` from `CombatConfig` for distance-based damage falloff), `RevolverDashService`, [[RevolverLagCompensation]], [[RevolverHitForgiveness]]
4. Validates client-sent camera origin, direction, and muzzle position; clamps both to max distance from head to prevent exploits
5. Three-layer hit resolution in `resolveShot`: `handleLagCompensatedHit` (rewind raycast via [[RevolverLagCompensation]]) → `handleCurrentRaycastHit` (current-frame raycast) → `handleForgivenHit` (sphere check via [[RevolverHitForgiveness]]) — each branch computes the bullet's travel distance from `rayOrigin` to the resolved hit position, passes it to `RevolverDamageService:ApplyDamage` to get scaled `(didKill, damageDealt)`, then runs the full post-hit feedback chain via [[HunterHitPipeline]]:Register (RegisterDamage → LastDamager attribute → flash highlight → DamageDirection → HealthBarReveal → RegisterKill → HitConfirm → ChargeAward via runtime.ChargeService → KillFeed → KillCam) — the pipeline's `Damage` field reflects the scaled value (clamped to `oldHealth` for kill shots)
6. All three branches carry bullet penetration via [[BulletPenetration]]: `handleCurrentRaycastHit` walks the shot with `Pierce` instead of a single raycast, the rewind branch reads `penetrationLayers` off the lag-comp hit, and the forgiveness branch takes it as a 4th return. Each feeds `BulletPenetration.GetDamageMultiplier` into `ApplyDamage` — 50% behind one wall, 25% behind two. A shot absorbed by cover (`Stopped`) returns a result rather than nil, so it can't fall through to the forgiveness sphere and hit someone behind the wall anyway. Tuned per-hunter via `RevolverServerConfig.Penetration`
7. Creates world impact VFX (bullet holes, smoke) on non-character hits via `RevolverImpactFX`, plus a `CreateBulletHole` on every surface the round punched through (smoke stays on the surface that finally stopped it, so a wallbang doesn't puff twice)
8. Replicates shot visuals (muzzle-to-hit tracer) to all other players via `ReplicateShot`
9. Handles dash requests via `RevolverDashService`; cleans up cooldowns + dash state on PlayerRemoving
10. Gates firing and dashing on `runtime.RoundActive.Value == true` — combat only during the fight phase
11. Sets `LastDamager` attribute (shooter's UserId) on hit characters for kill attribution
12. Skips the FireBullet handler entirely if the character has `IsUsingHighNoon` attribute set (avoids double-fire during the ultimate)
    - Fire handler also calls [[SpawnProtectionService]].onAttack(player) to drop the spawn shield on the first shot
13. Reports shot-fired stats via `runtime.RoundStats.RegisterShotFired` when RoundStatsService is available (degrades gracefully if missing)
14. Returns the runtime from Start so Main can `HighNoonModule.Start(dustRuntime)` and share the single Dust [[UltimateChargeService]] instance

**Clears its ability cooldowns on `RoundActive` going true** (2026-08-06, the infinite match loop): `fireCooldowns` and `dashService:ResetAll()`. Every cooldown in the hunter stack is an absolute `os.clock()` stamp, and the server plays rounds back to back now, so a dash taken in the last seconds of one round was still on cooldown at the start of the next. `RoundActive` is the same signal UltimateChargeService already resets charges on. **`weaponGuard` is deliberately absent** — its state carries the character it was built for and the round start hands every player a new one, so the magazine and the Skill2 burst window reset by construction. The same block exists in CardsServer, SunspikeModule and GrudgekeeperModule; this is the one carrying the reasoning.

## Team modes

All three damage paths -- the rewound hit, the direct hit and the forgiven hit -- ask the gate
before applying anything.

## Dependencies

- **Requires:** [[HunterServerRuntime]], [[HunterCharacterUtil]], [[HunterActionLock]], [[BulletPenetration]] (all from `ReplicatedStorage.Hunters.Shared`), [[Manifest|Dust Manifest]] (from `ReplicatedStorage.Hunters.Dust.Config`), [[SpawnProtectionService]] (from `ServerScriptService.Combat`), `RevolverServerConfig`, `RevolverImpactFX`, [[RevolverDamageService]], `RevolverDashService`, [[RevolverLagCompensation]], [[RevolverHitForgiveness]] (all from `ReplicatedStorage.Hunters.Dust.Modules.RevolverServer`), [[RevolverDashService]], [[RevolverImpactFX]], [[RevolverServerConfig]], [[DamageGate]]
- **Required by:** Main

## Connections

### RemoteEvents

| Remote | Direction | Other script |
|--------|-----------|--------------|
| `FireBullet` | ← Client | [[FPSRevolverClient]] fires when player shoots |
| `DashRequest` | ← Client | [[FPSRevolverClient]] requests a dash |
| `ReplicateShot` | → Client | Replicates shot tracer to non-shooter players; [[EarlyShotRemoteDrain]] drains it during client load |
| `WorldRevolverShotSound` | → All Clients | Plays the world-model shot sound for other players; [[EarlyShotRemoteDrain]] drains it during client load |
| `HitConfirm` | → Client | Confirms hit/headshot/kill to shooter (via [[HunterHitPipeline]]) |
| `DamageDirection` | → Client | Tells the victim's client where the damage came from (via [[HunterHitPipeline]]) |
| `HealthBarReveal` | → Client | Reveals a local-only overhead health bar on the victim to the attacker (via [[HunterHitPipeline]]); [[HealthBarSpawnerClient]] consumes |
| `KillFeed` | → All Clients | Posts a kill-feed entry (via [[HunterHitPipeline]]) |
| `KillCam` | → Client | Triggers victim's kill-cam (via [[HunterHitPipeline]]) |

### BindableEvents

| Bindable | Direction | Other script |
|----------|-----------|--------------|
| `WorldRevolverShotVFX` | → | Fires `(player)` on each shot; consumed by [[RevolverWorldModelServer]] / world-model VFX |

(`HighNoonChargeAward` BindableEvent — pre-Phase-2 bridge to [[HighNoonModule]] — is no longer fired. Runtime-owned [[UltimateChargeService]] is shared between RevolverModule and HighNoonModule directly.)

### Direct require()

| Target | Function | Purpose |
|--------|----------|---------|
| [[HunterServerRuntime]] | `.Start(manifest)` | Wires hunter gate, remotes, charge service, hit pipeline; returns runtime handle |
| [[Manifest|Dust Manifest]] | (table return) | Declarative description of Dust |
| [[HunterCharacterUtil]] | `.GetCharacterHumanoidRootHead()`, `.GetHitCharacterAndHumanoid()`, `.IsHeadshotPart()` | Character validation + hit-part classification |
| [[BulletPenetration]] | `.Pierce()`, `.GetDamageMultiplier()` | Walks shots through penetrable cover and scales damage per wall crossed |
| [[SpawnProtectionService]] | `SpawnProtectionService.onAttack()` | Drop the spawn shield the first time the player fires |
| `RevolverServerConfig` | config tables | Combat / HitForgiveness / LagCompensation / Impact / Dash settings |
| `RevolverImpactFX` | `.new()`, `:CreateWorldImpact()` | Bullet hole decals + smoke particles |
| [[RevolverDamageService]] | `.new()`, `:ApplyDamage()` | Body/headshot damage application (flash now lives in [[HunterHitPipeline]]) |
| `RevolverDashService` | `.new()`, `:DoDash()`, `:CleanupPlayer()` | Server-side dash execution |
| [[RevolverLagCompensation]] | `.new()`, `:Start()`, `:Raycast()` | Rewind-based hit resolution |
| [[RevolverHitForgiveness]] | `.new()`, `:FindForgivenHumanoid()` | Near-miss sphere check |

### CollectionService Tags
| Tag | Usage | Defined by |
|-----|-------|-----------|
| `HealthPack` | Read via `GetTagged` in `buildShotRaycastParams`; each pack's green `Pickup` + invisible `TouchHitbox` added to the bullet raycast Exclude list (bullets pass through the floating pickup; the solid `Base` stand still blocks them) | [[HealthPackSystem]] |
