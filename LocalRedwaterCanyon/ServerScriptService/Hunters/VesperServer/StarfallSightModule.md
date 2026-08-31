---
tags:
  - server
  - modulescript
  - combat
  - ultimate
  - vesper
path: game.ServerScriptService.Hunters.VesperServer.StarfallSightModule
type: ModuleScript
lines: 351
---

# StarfallSightModule

Vesper's ultimate: three empowered PIERCING shots inside a 12s window. Gated on full charge via the runtime-owned UltimateChargeService (same pattern as HighNoonModule / CardsServer's ultimate gates). `Start(runtime, deps)` receives the Vesper runtime from [[SunspikeModule]]; `IsActive(player)` is exposed at module scope so SunspikeModule's ChargeBlockPredicate (and its FireBullet skip) can close over it before the runtime starts.

## What it does
1. **Activation** (`UltimateRequest`): requires hero + round active + alive + full charge + not already active. Consumes all charge (`chargeService:Set(player, 0)`), stores `{ShotsLeft = 3, ExpiresAt = now + 12}`, fires `UltimateState("Start", shotCount, window)` to the caster, and schedules a token-checked expiry that ends the ultimate (unused shots are simply lost — no refund)
2. **Empowered shot** (`UltimateShotRequest`): validates hero/round/state/vectors, shares the 1.8s fire cadence with the basic attack via the `IsFireReady`/`MarkFired` accessors from [[SunspikeModule]], calls [[SpawnProtectionService]].onAttack, registers the shot with RoundStats, and clamps the camera origin near the head like the basic fire
3. **Piercing resolve** — a pure geometry query, NOT a raycast (walls and bodies never stop it): for every alive humanoid model within 400 studs in front of the aim ray, computes the perpendicular distance from the ray to every real body BasePart (torso, limbs, head, root — filtered via [[HunterCharacterUtil]].ShouldIgnoreCombatPart to skip accessories/decorative parts), takes the closest, then applies the matching ring's damage — 0.7 studs → 100, 1.2 → 75, 2.2 → 50 (widened from 0.4/0.7/1.3 on 2026-07-28; see [[VesperConfig]] for how the radii map onto the R15 rig). (Previously checked only HumanoidRootPart/Head, which let shots that visually clipped an arm or leg whiff entirely — fixed 2026-07-06)
4. **Enemy spawn-house block** — the one thing a Starfall shot does not pierce. Before damage is applied, `isBlockedByTeamBase` casts a single ray from the shot origin to the body part that earned the hit, Include-filtered on the ENEMY's spawn-house Model alone (`[[TeamBaseService]].baseFor` of the other team, resolved from the shooter's `[[TeamAffinity]].teamOf` and cached per side), wearing the shooter's `TeamAffinity.shotGroup` so their door is solid to her. A hit means the target is skipped. Her OWN house is not in the list at all — it is wooden structure like any other and she shoots out through it exactly as she shoots through the rest of the map. Nothing outside that one Model can block, so it can never drift into a general line-of-sight check, and it fails open the way TeamBaseService does — an unstamped shooter, FFA, a map with no houses, or a non-team mode with the house parked into ServerStorage all leave the cast with nothing to hit
5. Every damaged target routes through [[HunterHitPipeline]]:Register with `SourceType = "Ultimate"` and `WeaponName = "Starfall Sight"` so kill feed / hit confirm / stats / assists all work like any other shot (the Ultimate charge source is all zeros, so no charge accrues)
6. Replicates the full-length beam to all OTHER players via `ReplicateShot` (the caster draws its own client-side). The beam is drawn at full Range regardless of the step-4 block — it visibly pierces every wall in the map, which is what the ability has always looked like, and no client raycast is involved on either side
7. Ends after the third shot or window expiry → `UltimateState("End")`; state also drops on PlayerRemoving

Damage-through-cover was confirmed by playtest on 2026-07-28 — apart from the enemy-base check in step 4 there is no raycast anywhere in this path, so terrain, walls and bodies genuinely cannot stop a Starfall shot. The remaining reason a shot behind cover can register nothing is the ring radii being measured to each body part's *centre*, not the miss being blocked.

## Team modes

The ring loop asks the gate per target, so the ultimate sweeps past teammates. The enemy's spawn house is the only exception the piercing rule makes for team modes — step 4 — so a Vesper cannot ult into it, or through it at someone standing beyond. Her own house blocks nothing: measured across every authored spawn marker in both maps, a 72-direction sweep from inside her own base is 864/864 clear.

## Dependencies
- **Requires:** [[QuestEvents]], [[HunterActionLock]], [[TeamBaseService]] and [[TeamAffinity]] at module scope; `Start(runtime, deps)` receives the [[HunterServerRuntime]] handle plus [[VesperConfig]], [[HunterCharacterUtil]], [[SpawnProtectionService]], and the fire-cadence accessors from [[SunspikeModule]], [[DamageGate]]
- **Required by:** SunspikeModule

## Connections
### RemoteEvents
| Remote | Direction | Other script |
|--------|-----------|-------------|
| `UltimateRequest` | ← Client | [[SunspikeClient]] requests activation at full charge |
| `UltimateShotRequest` | ← Client | [[SunspikeClient]] fires each empowered shot |
| `UltimateState` | → Client | "Start"/"End" to the caster; client mirrors shot mode, freezes the magazine and shows the shot count as its own ammo pool above the ult icon |
| `ReplicateShot` | → Client | Full-range beam replication to non-casters; [[EarlyShotRemoteDrain]] drains it during client load |
| `HitConfirm` / `DamageDirection` / `HealthBarReveal` / `KillFeed` / `KillCam` | → Client(s) | Via [[HunterHitPipeline]] |

### BindableEvents
None

### Direct require()
None (runtime + deps injected via `Start`)
