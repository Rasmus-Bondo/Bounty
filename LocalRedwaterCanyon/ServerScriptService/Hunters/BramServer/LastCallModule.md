---
tags: [server, modulescript, combat, ultimate, bram]
path: game.ServerScriptService.Hunters.BramServer.LastCallModule
type: ModuleScript
lines: 214
---

# LastCallModule

Bram's ultimate — a 10-second close-quarters power window. Gated on full charge via the runtime-owned UltimateChargeService, same activation pattern as StarfallSightModule/HighNoonModule.

## What it does
1. `UltimateRequest` handler: gates on hero, round-active, not-already-active, alive, and full charge; then zeroes the charge and activates
2. While active, sets two character attributes: `UltimateActive` (MovementChecker speed-check headroom, mirrors Fortuna's convention — note this is **only** a speed-check flag and does not confer High Noon untargetability, which lives on Fortuna's separate `UltimateUntargetable` attribute; HighNoonTargeting used to read `UltimateActive`, which made Bram unlockable for his whole ult; HealthBarController used to read it too, which hid Bram's overhead health bar for his whole ult — it now reads Fortuna's `UltimateInvisible`) and `DamageReductionPercent = 0.5` — every combat damage path (RevolverDamageService, SunspikeDamageService, HighNoonDamage, CardsServer, StarfallSightModule, Bram's own services) checks it before TakeDamage. Zone damage deliberately bypasses the reduction (out-of-zone pressure ignores the ult)
3. +25% move speed as a proportional **buff** on [[HunterMovement]] (`BramLastCall`, TTL = ultimate duration + 1s), so it multiplies with sprint and composes with an enemy slow instead of overwriting either. The old version wrote `passiveConfig.WalkSpeed * 1.25` outright and restored a hardcoded passive on expiry — a guess that was wrong for any Bram who was slowed or otherwise off his passive when the window ended
4. Refreshes both ability cooldowns instantly on activation (BreachChargeService/ShrapnelShellService `:ResetCooldown`)
5. `UltimateState("Start", duration)` → caster client flips to 0.5s reload / 0.25s fire cadence ([[GrudgekeeperClient]]); server-side cadence branch lives in GrudgekeeperModule.isFireReady
6. Lifesteal (25% of actual damage dealt) and the -1s-per-landed-shot cooldown refund are applied by GrudgekeeperModule's damage paths, keyed off `IsActive`
7. No ultimate charge accrues while active (GrudgekeeperModule passes `IsActive` as the runtime ChargeBlockPredicate)
8. Ends on the 10s token expiry, death (Humanoid.Died), round end (RoundActive → false ends all actives), or a **mid-match hunter switch** — a `SelectedHunter` attribute change away from Bram; the switch respawn (HunterSwitchService) skips Humanoid.Died, so this listener is what stops the +speed / UltimateActive / DamageReduction bleeding onto the swapped-in hunter. Clears both attributes and drops the movement buff (which is also TTL-bounded and character-scoped, so a missed teardown path can no longer strand it)

## Dependencies
- **Requires:** [[HunterMovement]], [[HunterActionLock]], [[QuestEvents]] (runtime + Config/CharacterUtil/SpawnProtection/BreachService/ShrapnelService injected via `.Start(runtime, deps)`)
- **Required by:** GrudgekeeperModule

## Connections
### RemoteEvents
| Remote | Direction | Other script |
|--------|-----------|-------------|
| `UltimateRequest` | ← Client | [[GrudgekeeperClient]] requests activation at full charge |
| `UltimateState` | → Client | Start/End broadcast to the caster ([[GrudgekeeperClient]] cadence flip, [[BramHunterGuiClient]] countdown display) |

### BindableEvents
None

### Direct require()
None
