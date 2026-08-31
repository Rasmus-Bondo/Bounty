---
tags:
  - server
  - script
  - combat
  - bram
path: game.ServerScriptService.Hunters.BramServer.GrudgekeeperModule
type: Script
lines: 705
---

# GrudgekeeperModule

Bram's server entry — a self-running Script (same pattern as CardsServer/SunspikeModule; Main does not wire Bram). Owns the Grudgekeeper cone blast (a thick center raycast + a cone sweep that can hit multiple targets), Bram's 225 max health, the shared ability-damage path (damage reduction, lifesteal, pipeline registration), and constructs/wires [[BreachChargeService]], [[ShrapnelShellService]] and [[LastCallModule]].

## What it does
1. Requires the [[Manifest|Bram Manifest]] and calls [[HunterServerRuntime]].Start with a `ChargeBlockPredicate` closing over [[LastCallModule]].IsActive — no passive/hit ultimate charge accumulates during Last Call
2. Reuses Dust's hero-agnostic server modules: [[RevolverLagCompensation]], [[RevolverImpactFX]], and [[RevolverDashService]] (third consumer after Dust and Fortuna's Ability1) — all constructed from [[GrudgekeeperConfig]]
3. **Basic fire** (`FireShotgun`): a thick center raycast resolves lag-rewind thin ray → thin current-world ray (a world hit stops the center shot, keeping pinpoint headshots for a dead-on aim) → a `SpherecastRadius` (2-stud) forgiveness spherecast **only** when the center ray flies through open air (body hit). Then `collectConeTargets` sweeps for **every other humanoid inside the cone** — players AND NPC dummies, via [[HunterCharacterUtil]].GetHumanoidModels (the same registry lag-comp uses, not `Players`) — within `ConeHalfAngleDegrees` 7.6° + 60-stud range + world line-of-sight (other characters don't block). Each target takes the **full** damage for its own distance via [[GrudgekeeperDamageService]]:GetTotalDamageForDistance, one TakeDamage + one [[HunterHitPipeline]]:Register apiece
4. **Penetration**: the center ray walks penetrable cover via [[BulletPenetration]].Pierce, and `traceConeTarget` (replacing the old `hasLineOfSight`) counts the walls between Bram and each cone target rather than treating the first plank as a blocker. Every hit's damage is scaled by `GetDamageMultiplier` before `ApplyAccumulatedDamage` — 50% behind one wall, 25% behind two — so the blast resolves as one cone with one multiplier, not eight independent pellets. A center ray absorbed by cover stops at the wall and suppresses the forgiveness spherecast, which can't reach past it either
5. **Per shot, not per enemy**: the primary target (most damage — the center target if it hit one, else the biggest cone target) registers as SourceType `Basic`; extra cone targets register as `BasicSecondary` (kill charge only). Center target's `IsHeadshot` comes from its part classification; cone-spread targets are body hits. Last Call cooldown refund + lifesteal are summed once per blast
6. Fire cadence is 0.5s normally, 0.25s while Last Call is active (`isFireReady` branches on [[LastCallModule]].IsActive)
7. `applyAbilityDamage` — the shared path for Breach Charge / Shrapnel Shell hits (injected into both services): victim `DamageReductionPercent` attribute check → TakeDamage → pipeline Register (SourceType `Ability`, explicit WeaponName) → lifesteal
8. **Last Call hooks**: 25% lifesteal on all Bram damage while active; every blast that hits ≥1 enemy shaves 1s off both ability cooldowns and reports the new remaining values to the caster via `AbilityCooldownsReduced`
9. Routes `BreachChargeRequest` actions → [[BreachChargeService]] (`Start` → TryStartCharge, `WallHit` → OnWallHit, `End` → EndCharge) and `ShrapnelShellRequest` → [[ShrapnelShellService]]:TryFire (gated on hero + round-active; `Start`/fire also drop the spawn shield via SpawnProtection.onAttack)
10. Sets Bram's MaxHealth/Health to 225 on every CharacterAdded
11. Constructs one shared [[HunterStatusEffects]] instance (handed to [[ShrapnelShellService]] for the slow AND to [[BreachChargeService]] for the wall-slam stun) and starts [[LastCallModule]].Start(runtime, deps)
12. `scatterImpactFX` drops up to 8 cosmetic bullet holes across the cone on terrain (8 no-damage/no-lag-comp rays, one hole per terrain hit) + 1 impact smoke — restores the old pellet-fan look without extra damage bullets. The single tracer endpoint replicates to other players via `ReplicateShot`
13. Cleans up fire cooldowns + per-service player state on PlayerRemoving

**Clears its ability cooldowns on `RoundActive` going true** (2026-08-06): `fireCooldowns`, `breachService:ResetAll()` and `shrapnelService:ResetAll()`. RevolverModule's copy of this block carries the general reasoning.

## Team modes

Every damage site asks the gate: the ability hit, the direct shot, the spherecast and the cone
gather.

## Dependencies
- **Requires:** [[HunterServerRuntime]], [[HunterCharacterUtil]], [[HunterStatusEffects]], [[HunterActionLock]], [[BulletPenetration]] (from `ReplicatedStorage.Hunters.Shared`); [[SpawnProtectionService]] (from `ServerScriptService.Combat`); [[RevolverImpactFX]], [[RevolverLagCompensation]], [[RevolverDashService]] (from `ReplicatedStorage.Hunters.Dust.Modules.RevolverServer`); [[Manifest|Bram Manifest]] + [[GrudgekeeperConfig]] (from `ReplicatedStorage.Hunters.Bram.Config`); [[GrudgekeeperDamageService]], [[BreachChargeService]], [[ShrapnelShellService]], [[LastCallModule]] (siblings in `BramServer`), [[DamageGate]], [[TeamAffinity]] (the shot collision group on the blast ray builder)
- **Required by:** Nobody (self-running Script)

## Connections
### RemoteEvents
| Remote | Direction | Other script |
|--------|-----------|-------------|
| `FireShotgun` | ← Client | [[GrudgekeeperClient]] fires on shot |
| `ReplicateShot` | → Client | Single tracer (muzzle + one endpoint) to non-shooter Bram clients; [[EarlyShotRemoteDrain]] drains it during client load |
| `BreachChargeRequest` | ← Client | [[GrudgekeeperClient]] charge lifecycle: `Start` / `WallHit` / `End` → [[BreachChargeService]] |
| `ShrapnelShellRequest` | ← Client | [[GrudgekeeperClient]] fires the shell (handled via [[ShrapnelShellService]]) |
| `AbilityCooldownsReduced` | → Client | [[GrudgekeeperClient]] gets server-authoritative remaining cooldowns after each Last Call hit refund |
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
| [[Manifest|Bram Manifest]] | (table return) | Declarative description of Bram |
| [[GrudgekeeperConfig]] | config tables | All kit tuning |
| [[HunterCharacterUtil]] | `.GetCharacterHumanoidRootHead()`, `.GetHitCharacterAndHumanoid()`, `.IsHeadshotPart()` | Character validation + hit classification |
| [[SpawnProtectionService]] | `.onAttack()` | Drop spawn shield on fire/abilities |
| [[GrudgekeeperDamageService]] | `.new()`, `:GetTotalDamageForDistance()`, `:ApplyAccumulatedDamage()` | Distance falloff + single-target damage application |
| [[BreachChargeService]] | `.new()`, `:TryStartCharge()`, `:OnWallHit()`, `:EndCharge()`, `:ReduceCooldown()`, `:CleanupPlayer()` | Pinning charge + wall-slam stun |
| [[ShrapnelShellService]] | `.new()`, `:TryFire()`, `:ReduceCooldown()`, `:CleanupPlayer()` | Instant shell + two-ring explosion |
| [[LastCallModule]] | `.IsActive()`, `.Start(runtime, deps)` | Ultimate gating + bootstrap |
| [[HunterStatusEffects]] | `.new()` | Slow + stun tracking instance (handed to ShrapnelShellService for slow + BreachChargeService for the wall-slam stun) |
| [[RevolverImpactFX]] | `.new()`, `:CreateBulletHole()`, `:CreateImpactSmoke()` | Cosmetic cone scatter: up to 8 bullet holes + 1 smoke per shot |
| [[BulletPenetration]] | `.Pierce()`, `.GetDamageMultiplier()` | Center ray walks penetrable cover; `traceConeTarget` counts walls per cone target; scales `hit.Damage` before `ApplyAccumulatedDamage`. Tuned via `GrudgekeeperConfig.Penetration` |
| [[RevolverLagCompensation]] | `.new()`, `:Start()`, `:Raycast()` | Rewind-based per-pellet hit resolution |
| [[RevolverDashService]] | `.new()`, instance handed to [[BreachChargeService]] | Dash validation/cooldown (movement stays client-owned). Constructed with `AnimationId = ""`: the charge's body animation (the looped Charge clip) belongs to GrudgekeeperWorldVisualServer, and the shared dash roll's legs would fight the charge run |

### CollectionService Tags
| Tag | Usage | Defined by |
|-----|-------|-----------|
| `HealthPack` | Each pack's green `Pickup` + invisible `TouchHitbox` added to the pellet raycast Exclude list (the solid `Base` stand still blocks pellets) | [[HealthPackSystem]] |
