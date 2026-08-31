---
tags: [server, modulescript, combat, ultimate, targeting]
path: game.ReplicatedStorage.Hunters.Dust.Modules.HighNoonTargeting
type: ModuleScript
lines: 306
---

# HighNoonTargeting

OOP server-side target acquisition for the HighNoon ultimate using cone-based detection with line of sight. Re-scanned continuously by HighNoonModule (~every 0.08s) so the target set follows the caster's aim live rather than from a one-time snapshot.

## What it does
1. Scans all alive Humanoids in workspace for valid enemy targets. One workspace walk now collects two things: the cone candidates, and **every** rig in the arena (dead and untargetable ones included) for the sight ignore list below
2. Skips any character flagged untargetable by an active ultimate — reads the `UltimateUntargetable` attribute, set by CardsServer on a Fortuna **player** and by BotCombat on a Fortuna **bot**, both for the duration of the invisibility window (not the 0.47s windup). An invisible Fortuna can't be locked, any existing lock drops on the next scan (≈0.08s), and the fire-time `finalScan` in HighNoonModule re-applies the same filter so a Fortuna who ults during lock-in is dropped before the shot lands. The check reads `UltimateUntargetable` rather than `UltimateActive` on purpose: `UltimateActive` is the shared MovementChecker speed-check headroom flag that Bram's Last Call also sets, and reading it here silently made Bram unlockable for his entire ultimate
3. Skips spawn-protected characters — reads the `SpawnProtected` attribute set by SpawnProtectionService for the 3s shield window (dropped early the moment that player attacks). The ForceField already absorbs the shot, so this is about *acquisition*: without it the caster spent lock slots, and could spend the whole ultimate, on someone who could not be hurt, while the victim watched lock-on reticles ride their shield. Read as a plain attribute, not a require — the targeting module lives in `ReplicatedStorage` and cannot reach `ServerScriptService`. Same treatment as the untargetable case: still added to `rigs`, so a protected player does not become a wall
4. Filters by cone angle (45 degrees) and range (180 studs) from the attacker's aim direction
5. `BuildSightParams` builds **one** RaycastParams per scan (previously one per target, which rebuilt the `GetTagged` walk for every candidate), excluding the attacker's own character, the `VesperHookSpotsBot` + `WallMap` folders, every `HealthPack`'s green `Pickup` + invisible `TouchHitbox` (the floating pickup doesn't break LOS; the solid `Base` stand still does), **and every rig in the arena**
6. Validates line of sight in `HasLineOfSight(origin, targetPart, sightParams, character)`, which is **two-tier** — see item 8. Because all rigs are filtered out, the target's own parts can no longer terminate the ray, so a tier passes when the segment reached its endpoint without meeting anything solid (`not Stopped and Result == nil`, or a plain raycast returning nil) rather than the old "did the ray land on this specific character". A side effect worth knowing: sight no longer depends on the target's parts being queryable
7. **Enemies cannot body-block for each other.** Before, the ignore list held only the attacker, so any other rig between the caster's head and the target's `UpperTorso` centre dropped that target from the scan — which wiped its lock progress mid-channel (occlusion is indistinguishable from leaving the cone) and, at the fire-time `finalScan`, left it undamaged entirely, not even a body shot. Bots made it far worse than players: their `BotAssistHitbox` volumes are 4.5 studs wide against a ~2 stud rig and are `CanQuery`, so a bot standing *beside* the target still ate the ray. Two stacked bots meant one guaranteed survivor, and killing the front one didn't help — `ShootTargets` never re-scans. Untargetable (invisible Fortuna) and dead rigs are excluded too: being unlockable must not also make you a wall. The deliberate trade-off is that a target fully hidden behind another player is now lockable
8. **Cover is two-tier, because "penetrable" and "see-through" are not the same thing.** Tier one runs `Pierce` with `overrides.IsPenetrable = BulletPenetration.IsAuthoredPenetrable`, so cover somebody *marked* penetrable — the tagged cacti, fences, wagons, barrels and crates — stays fully transparent to the lock exactly as it is to the bullet. Tier two catches cover that qualifies **by material alone**: the pierce stops there, and the lock then needs one of five rig sample points (chest, both shoulders, head, hips) to be reachable by a plain raycast. Shoulders are offset perpendicular to the *sight line*, not the rig's facing, so a target cannot change his own lockability by turning on the spot. Every wooden building in both maps is material-only cover, and Frostbite's central house is why the tier exists: its walls are wood, so one cast from the street locked every player on every floor — a worst case of 147 interior positions inside a single cone, cut to 67. A target in the open still settles on the first raycast, as it always did. This supersedes the flat "penetrable cover never breaks the lock" rule, which itself replaced a hardcoded `Cacti` folder exclusion. **Acquisition only** — High Noon's shots still cross cover at **full damage**, so a target whose shoulder clears a plank is locked and the round goes through the plank
9. Sorts targets by distance (nearest first) and caps at max targets (6)
10. `FindTargets` and `GetCurrentAim` drive the live loop. Legacy set helpers (`MakeTargetSet`, `IntersectTargetList`, `TargetListToVisualTargets`) remain on the module but are no longer used since the two-snapshot intersection was replaced by live cone tracking

## Dependencies
- **Requires:** [[BulletPenetration]] (from `ReplicatedStorage.Hunters.Shared`), [[TeamAffinity]] (the shot collision group, so the lock cannot acquire through an enemy spawn-house door); everything else configured externally
- **Required by:** HighNoonModule

## Connections
### RemoteEvents
None

### BindableEvents
None

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[BulletPenetration]] | `.Pierce()`, `.IsAuthoredPenetrable` | Walks the LOS segment in `HasLineOfSight` through cover that was explicitly tagged or attributed penetrable, so targets behind cacti/fences/wagons stay lockable; `IsAuthoredPenetrable` is passed as `overrides.IsPenetrable` to suppress the material rule, which is what stops a wooden building wall from being see-through to the lock. Pierce clones the params before adding crossed parts to its own filter, which is what lets the one shared `BuildSightParams` result be reused across every candidate in a scan |

### CollectionService Tags
| Tag | Usage | Defined by |
|-----|-------|-----------|
| `HealthPack` | Read via `GetTagged` in `BuildSightParams`; each pack's green `Pickup` + invisible `TouchHitbox` added to the LOS raycast Exclude list (the solid `Base` stand still breaks LOS) | [[HealthPackSystem]] |
