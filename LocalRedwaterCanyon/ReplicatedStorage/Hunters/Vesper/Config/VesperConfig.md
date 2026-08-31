---
tags: [shared, modulescript, config, vesper]
path: game.ReplicatedStorage.Hunters.Vesper.Config.VesperConfig
type: ModuleScript
lines: 189
---

# VesperConfig

All tuning numbers for Vesper's kit. Values marked PLACEHOLDER in-source are balance assumptions from `vesper_implementation_guide.md` awaiting a playtest pass (ADSFOV 35, scoped walk speed 6, scoped sensitivity 0.4×, grapple TravelTime 0.35, pinning cooldown 12 / throw speed 250).

## What it does
1. `Passive` — Health 125 (applied by SunspikeModule on CharacterAdded; no shared per-hero health config exists), WalkSpeed 16, and `DeadeyeFocus` (RampTime 3s, MaxBonus +50% headshot damage, hard reset on unscope AND on fire)
2. `Basic` — Sunspike Carbine: Range 500, Cooldown 1.8s, body 65 / headshot 125, falloff 240→300 studs down to floors 45/90, magazine 4, reload 3s, plus the same camera-origin/muzzle anti-exploit clamps as Dust (14/16 studs from head)
3. `Scope` — ADSFOV 35, TransitionTime 0.25s, WalkSpeedWhileScoped 6, ScopedSensitivityMultiplier 0.4 (mouse look at 40% of the player's setting while scoped), AllowHipfire true (hipfire simply never earns the Deadeye bonus)
4. `GrappleHook` — Range 125, Cooldown 8s, MissCooldownMultiplier 0.5 (a whiff consumes half the cooldown), TravelTime 0.35s, ArrivalRadius 4, PullTargetHeightOffset 4 (pull aims above the hook point so Vesper crests platform lips), HopVelocity 60 (little upward pop applied when the pull ends naturally, so a ground-level grapple can clear a platform lip and land on top), MaxLandingSpeed 40 (ceiling on the **horizontal** release speed — the 25% residual applied on release is a fraction of `distance / TravelTime` and so scaled with hook length unbounded, releasing a max-range hook at 89 studs/s which HopVelocity then granted 0.61s of hang time, carrying Vesper ~55 studs past a perch whose mean width is 20; capped on XZ only so the vertical carry, the hop and time-to-landing are all unchanged, and any hook under ~56 studs behaves exactly as before), plus the four anti-cheat grace dials: GraceBuffer 1s (initial window), MaxGraceTime 4s (hard ceiling on one grapple's grace), LandingSettle 0.4s (held after touchdown to bleed residual velocity), GracePollInterval 0.2s (airborne re-check rate — the extension it grants must outlast MovementChecker's 0.5s sample)
5. `PinningRound` — Cooldown 12s, Radius 25, Slow 25%/5s, Mark 6s, ThrowSpeed 250 studs/s straight line (no gravity), MaxFlightTime 2s (~500 stud reach), DirectDamage 0 (utility only)
6. `Ultimate` — Starfall Sight: Range 400, ShotCount 3, ActiveWindow 12s, three concentric Rings from the shot centerline (**0.7/1.2/2.2** studs → 100/75/50 damage, sorted ascending — widened from 0.4/0.7/1.3 on 2026-07-28). Radii are compared against each body part's **centre point**, not its geometry, and the closest part on the target wins, so they only make sense against the R15 rig: UpperTorso 1.00 half-width / 0.80 half-height, Head radius 0.60, arm and hand centres ±1.50 off the centreline, silhouette edge ±2.00, part centres spaced 0.6–1.4 apart vertically. At 0.4 the 100-damage ring was narrower than half the torso, so a solid centre-mass shot 0.6 studs off centre paid 75 and at 1.1 studs paid 50. Consequence of the closest-part rule: a clipped hand now pays the full 100 — separating limbs from torso needs code, not a radius. ShotCount is a **separate ammo pool** displayed above the ult icon; the magazine is frozen for the window rather than topped up (the old `GuaranteesAmmo` key is gone)
7. `Penetration` — Vesper's per-hunter overrides for the shared BulletPenetration rules: `DamageMultiplierPerLayer` **0.35** (deliberately below the shared 0.5 that Dust and Bram use) and `MaxLayers` 2. Anything omitted falls back to `BulletPenetration.Config`. Sunspike is a 500-stud hitscan rifle and most of the arena's long sightlines have wood in them, so her wallbangs are tuned down here rather than globally. Through one wall: body 65→22.75, headshot 125→43.75; through two: 7.96 / 15.31
8. `HitForgiveness` / `LagCompensation` / `Impact` — mirror Dust's RevolverServerConfig values verbatim; consumed by the shared RevolverHitForgiveness / RevolverLagCompensation / RevolverImpactFX instances that SunspikeModule constructs

## Dependencies
- **Requires:** Nothing
- **Required by:** SunspikeModule, SunspikeClient, VesperScopeController, VesperHunterGuiClient

## Connections
### RemoteEvents
None

### BindableEvents
None

### Direct require()
None
