---
tags: [server, modulescript, combat, bram]
path: game.ServerScriptService.Hunters.BramServer.ShrapnelShellService
type: ModuleScript
lines: 270
---

# ShrapnelShellService

Bram's Ability 2 (E): an instant hitscan shell that explodes on the first surface (or at 100 studs) into a two-tier damage + slow zone. Fires the moment the ability is used — independent of the fire input, the 2-round magazine, and the reload; own 8s cooldown.

## What it does
1. `TryFire(player, aimOrigin, aimDirection)` — validates inputs, cooldown (os.clock table), clamps the claimed origin to ≤14 studs from the head (same anti-spoof as the basic fire path), then raycasts up to 100 studs (Exclude: shooter, rewind hitboxes, and each HealthPack's green `Pickup` + invisible `TouchHitbox` — not the solid `Base`)
2. **Explosion** at the landing point: every alive enemy (`IsEnemy`, shooter excluded) branches by root distance — ≤5.4 studs: 50 damage + 30% slow; ≤12.2: 25 damage + 15% slow; both for 2s
3. Damage flows through the injected `ApplyAbilityDamage` (shared reduction/lifesteal/pipeline path in [[GrudgekeeperModule]]); slows through the shared [[HunterStatusEffects]] instance (refresh + keep-stronger, never compounds)
4. `ShrapnelShellFX` (FireAllClients) broadcasts shooter + shell line + explosion so every client renders it — victims see why they got slowed (rendered by [[BramWorldFXClient]]; unlike Vesper's hero-gated pinning sphere, this is visible to all heroes)
5. `GetRemainingCooldown` / `ReduceCooldown` / `ResetCooldown` for Last Call's refund/refresh mechanics

**`ResetAll()` clears every shell cooldown at round start** (2026-08-06), called by GrudgekeeperModule on `ReplicatedStorage.RoundActive`. Absolute `os.clock()` deadlines against a server that now loops rounds; see RevolverDashService's note for the full reasoning. Pending casts are cleared with them — a shell queued against a character the round start has already replaced can never land. Distinct from `ResetCooldown(player)`, which is Last Call refreshing one player mid-fight.

## Dependencies
- **Requires:** Nothing (all collaborators injected via `.new()` config: CharacterUtil, StatusEffects instance, FXRemote, RewindHitboxFolder, ApplyAbilityDamage)
- **Required by:** GrudgekeeperModule

## Connections
### RemoteEvents
| Remote | Direction | Other script |
|--------|-----------|-------------|
| `ShrapnelShellFX` | → All Clients | [[BramWorldFXClient]] renders shell tracer (non-casters) + two-ring explosion |

### BindableEvents
None

### Direct require()
None (uses the [[HunterStatusEffects]] and [[HunterCharacterUtil]] instances handed in by [[GrudgekeeperModule]])

### CollectionService Tags
| Tag | Usage | Defined by |
|-----|-------|-----------|
| `HealthPack` | Each pack's green `Pickup` + invisible `TouchHitbox` added to the shell raycast Exclude list (the solid `Base` stand still stops the shell) | [[HealthPackSystem]] |
