---
tags:
  - server
  - script
  - combat
  - vesper
path: game.ServerScriptService.Hunters.VesperServer.SunspikeModule
type: Script
lines: 664
---

# SunspikeModule

Vesper's server entry — a self-running Script (same pattern as CardsServer; Main does not wire Vesper). Owns the Sunspike Carbine hitscan pipeline, the Deadeye Focus scope timer, Vesper's 125 max health, and constructs/wires all the Vesper-specific services plus her [[HunterStatusEffects]] instance.

## What it does
1. Requires the [[Manifest|Vesper Manifest]] and calls [[HunterServerRuntime]].Start with a `ChargeBlockPredicate` closing over [[StarfallSightModule]].IsActive — no passive/hit ultimate charge accumulates while Starfall Sight is active
2. Reuses Dust's hero-agnostic server modules directly (they take config, not hardcoded Dust values): [[RevolverLagCompensation]], [[RevolverHitForgiveness]], and [[RevolverImpactFX]] — all constructed from [[VesperConfig]]'s LagCompensation / HitForgiveness / Impact tables
3. **Basic fire** (`FireBullet`): mirrors RevolverModule's three-layer resolve — lag-rewind raycast → current-frame raycast (Exclude: shooter, rewind hitboxes, and each HealthPack's green `Pickup` + invisible `TouchHitbox` — not the solid `Base`) → forgiveness sphere. Each hit branch computes travel distance, applies damage via [[SunspikeDamageService]] (falloff + Deadeye headshot bonus), then runs [[HunterHitPipeline]]:Register. All three branches carry bullet penetration via [[BulletPenetration]] — the current-frame branch walks the shot with `Pierce`, the rewind branch reads `penetrationLayers`, the forgiveness branch takes it as a 4th return — feeding a `damageMultiplier` (50% behind one wall, 25% behind two) into [[SunspikeDamageService]]:ApplyDamage as its 6th argument. A round absorbed by cover returns a result rather than nil so it can't fall through to the forgiveness sphere. World impacts get bullet-hole/smoke FX and every surface punched through gets its own `CreateBulletHole`; tracers replicate to other players via `ReplicateShot`
4. **Deadeye Focus**: per-player scope timer keyed by the `ScopeStateChanged` remote. Headshot bonus multiplier = `1 + MaxBonus * clamp(scopedTime / RampTime, 0, 1)`, captured at fire time then ramp-restarted (ResetOnFire). Unscoping clears it. The handler also applies the server-authoritative scoped walk speed by registering `VesperScope` as an Ability-priority **base** on [[HunterMovement]] (6 scoped; unscoping just clears the modifier and falls back to passive 16). Registering a base rather than writing WalkSpeed means an enemy slow composes with the scoped crawl (`6 * 0.75`) instead of measuring against passive — otherwise slowing a scoped Vesper would speed her UP — and there is no "previous speed" to restore, so nothing can get it wrong. `forceScopeExitAfterShot` clears the same key
5. Skips the FireBullet handler entirely while Starfall Sight is active (empowered shots arrive via `UltimateShotRequest` instead)
6. Fire cadence (1.8s) lives in a shared `fireCooldowns` table exposed to [[StarfallSightModule]] via `IsFireReady`/`MarkFired` accessors so basic and empowered shots respect one cooldown
7. Routes `GrappleRequest` → [[GrappleHookService]]:TryGrapple and `PinningThrowRequest` → [[PinningRoundService]]:TryThrow (both gated on hero + round-active)
8. Sets Vesper's MaxHealth/Health to 125 on every CharacterAdded (no per-hero health config exists; Dust/Fortuna use the default 100)
9. Constructs one shared [[HunterStatusEffects]] instance (handed to [[PinningRoundService]]) and starts [[StarfallSightModule]].Start(runtime, deps)
10. Fire handler calls [[SpawnProtectionService]].onAttack and reports shots via `runtime.RoundStats.RegisterShotFired`; combat is gated on `runtime.RoundActive.Value`
11. Cleans up cooldowns, scope state, and per-service player state on PlayerRemoving

**Clears its ability cooldowns on `RoundActive` going true** (2026-08-06): `fireCooldowns`, `scopeStates`, `grappleService:ResetAll()` and `pinningService:ResetAll()`. Pinning's 12s is the one that could realistically survive the gap between the buzzer and the next round. Scope state goes with them — it describes a character the round start has already replaced. RevolverModule's copy of this block carries the general reasoning.

## Team modes

All three damage paths -- rewound, direct and forgiven -- ask the gate before applying anything.

## Dependencies
- **Requires:** [[HunterServerRuntime]], [[HunterCharacterUtil]], [[HunterStatusEffects]], [[HunterActionLock]], [[HunterMovement]], [[BulletPenetration]] (from `ReplicatedStorage.Hunters.Shared`); [[SpawnProtectionService]] (from `ServerScriptService.Combat`); [[RevolverImpactFX]], [[RevolverLagCompensation]], [[RevolverHitForgiveness]] (from `ReplicatedStorage.Hunters.Dust.Modules.RevolverServer`); [[Manifest|Vesper Manifest]] + [[VesperConfig]] (from `ReplicatedStorage.Hunters.Vesper.Config`); [[SunspikeDamageService]], [[GrappleHookService]], [[PinningRoundService]], [[StarfallSightModule]] (siblings in `VesperServer`), [[DamageGate]]
- **Required by:** Nobody (self-running Script)

## Connections
### RemoteEvents
| Remote | Direction | Other script |
|--------|-----------|-------------|
| `FireBullet` | ← Client | [[SunspikeClient]] fires on shot |
| `ReplicateShot` | → Client | Replicates tracers to non-shooter Vesper clients; [[EarlyShotRemoteDrain]] drains it during client load |
| `GrappleRequest` | ← Client | [[SunspikeClient]] requests a grapple (handled via [[GrappleHookService]]) |
| `PinningThrowRequest` | ← Client | [[SunspikeClient]] requests a pinning throw (handled via [[PinningRoundService]]) |
| `ScopeStateChanged` | ← Client | [[VesperScopeController]] reports scope in/out; drives Deadeye timer + walk-speed lock |
| `HitConfirm` | → Client | Via [[HunterHitPipeline]] |
| `DamageDirection` | → Client | Via [[HunterHitPipeline]] |
| `HealthBarReveal` | → Client | Via [[HunterHitPipeline]] |
| `KillFeed` | → All Clients | Via [[HunterHitPipeline]] |
| `KillCam` | → Client | Via [[HunterHitPipeline]] |

### BindableEvents
None

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[HunterServerRuntime]] | `.Start(manifest, opts)` | Hero gate, remotes, charge service, hit pipeline |
| [[Manifest|Vesper Manifest]] | (table return) | Declarative description of Vesper |
| [[VesperConfig]] | config tables | All kit tuning |
| [[HunterCharacterUtil]] | `.GetCharacterHumanoidRootHead()`, `.GetHitCharacterAndHumanoid()`, `.IsHeadshotPart()` | Character validation + hit classification |
| [[SpawnProtectionService]] | `.onAttack()` | Drop spawn shield on fire |
| [[SunspikeDamageService]] | `.new()`, `:ApplyDamage()` | Falloff damage + Deadeye headshot bonus |
| [[GrappleHookService]] | `.new()`, `:TryGrapple()`, `:CleanupPlayer()` | Grapple validation + cooldown |
| [[PinningRoundService]] | `.new()`, `:TryThrow()`, `:CleanupPlayer()` | Pinning projectile + status application |
| [[HunterStatusEffects]] | `.new()` | Slow/mark tracking instance (handed to PinningRoundService) |
| [[StarfallSightModule]] | `.IsActive()`, `.Start(runtime, deps)` | Ultimate gating + bootstrap |
| [[RevolverImpactFX]] | `.new()`, `:CreateWorldImpact()` | Bullet holes + smoke on world hits |
| [[RevolverLagCompensation]] | `.new()`, `:Start()`, `:Raycast()` | Rewind-based hit resolution |
| [[RevolverHitForgiveness]] | `.new()`, `:FindForgivenHumanoid()` | Near-miss sphere check (now returns the penetration layer count as a 4th value) |
| [[BulletPenetration]] | `.Pierce()`, `.GetDamageMultiplier()` | Walks shots through penetrable cover and scales damage per wall crossed; tuned via `VesperConfig.Penetration` |

### CollectionService Tags
| Tag | Usage | Defined by |
|-----|-------|-----------|
| `HealthPack` | Each pack's green `Pickup` + invisible `TouchHitbox` added to the bullet raycast Exclude list (the solid `Base` stand still blocks shots) | [[HealthPackSystem]] |
