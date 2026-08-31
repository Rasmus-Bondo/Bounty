# Bram Implementation Guide

Close-range bruiser. Highest health in the roster, hits devastatingly hard once he's on top of you, and has to force his way into that range with Breach Charge before Grudgekeeper's falloff punishes him for shooting from afar. Last Call turns him into a short, terrifying window of sustained close-quarters pressure.

Follows the same shape as `HunterImplementationGuide` (`LocalRedwaterCanyon/ReplicatedStorage/Hunters/Shared/HunterImplementationGuide.md`) and the Dust/Fortuna/Vesper implementations. Planning document only — nothing here should be created in Studio yet.

---

## Stat Block

| Stat | Value | Notes |
|---|---|---|
| Health | 225 | highest in the roster; Thick Hide is purely this stat, no regen/lifesteal outside the ultimate — confirmed |
| Magazine size | 2 | |
| Time between shots | 0.5s | |
| Reload time | 1s | |
| Fire mode | **Multi-pellet raycast fan** | confirmed — 8 pellets/shot (placeholder count), each an independent raycast within a fixed cone angle |
| Max range | 60 studs | no damage dealt past this — confirmed |
| Headshot damage (total, if every pellet connects) | 100 within 20 studs → 25 at 60 studs | linear falloff between 20 and 60 studs — confirmed |
| Body damage (total, if every pellet connects) | 50 within 20 studs → 15 at 60 studs | same falloff shape — confirmed |
| Breach Charge cooldown | 6s | dash forward, knockback + light impact damage on contact |
| Shrapnel Shell cooldown | 8s | fires immediately, straight shot, doesn't consume magazine ammo — confirmed |
| Shrapnel Shell inner ring | 5.4 stud radius, 50 dmg, -30% slow for 2s | confirmed |
| Shrapnel Shell outer ring | 12.2 stud radius, 25 dmg, -15% slow for 2s | confirmed |
| Last Call duration | 10s | 50% damage reduction, 25% lifesteal, 0.5s reload, 0.25s between shots, +25% move speed, refreshes ability cooldowns on activation, -1s ability cooldown per landed shot — all confirmed |

---

## What's New vs. What's Reused

| Piece | Reused as-is | New |
|---|---|---|
| Manifest / server bootstrap / hero gate | `HunterServerRuntime`, `HunterManifest`, `HunterGate` | — |
| Client bootstrap | `HunterClientRuntime` | — |
| Remote/folder creation | `HunterRemoteSetup`, `HunterSharedRemoteSetup` | — |
| Hit feedback (flash, kill feed, hit confirm, damage direction) | `HunterHitPipeline` | — |
| Ultimate charge economy | `UltimateChargeService` | — |
| Auto-reload on empty mag | `HunterAutoReload` | — |
| Mobile ability buttons | `HunterMobileAbilityButton` | — |
| Third-person cosmetic shotgun | `HunterWorldModel` | — |
| Hit-part / headshot / team checks | `HunterCharacterUtil` | — |
| Dash movement (Breach Charge) | `RevolverDashService` — Fortuna already reuses this hero-agnostically for Ability1's opening dash, so Bram becoming its third consumer is exactly the intended pattern | needs a **new knockback+impact-damage layer** on top, since neither Dust nor Fortuna's dash deals damage or displaces enemies |
| Multi-target radial damage | Fortuna's ultimate ("20-card outward ring") is precedent that one ability can already hit several enemies around a point | Shrapnel Shell's two-tier radius (damage + slow, not just damage) is new |
| Slow-on-hit status effect | — | **new** — same primitive Vesper's Pinning Round needs. **This is the second hunter to need a slow effect — worth promoting straight to `Hunters.Shared.HunterStatusEffects` now instead of building it Bram-local**, since the "wait until a second hunter needs it" bar (set in `HunterImplementationGuide`'s guidance on shared kits) is met the moment both Vesper and Bram ship it |
| Multi-pellet shotgun spread | — | **new** — no hunter fires more than one hit-test per trigger pull today |
| Armor / damage-reduction buff | — | **new** — no existing "reduce incoming damage by X%" mechanic |
| Lifesteal | — | **new** — no existing "heal attacker for a % of damage dealt" mechanic |
| Cooldown reduction on hit | — | **new** — no existing "landing a hit shaves time off an ability's cooldown" mechanic |

---

## Confirmed Design Decisions (from this session)

- **Shotgun shape:** multi-pellet raycast fan, not a single cone-volume check. Each pellet is an independent raycast; a single shot can naturally hit multiple clustered enemies since pellets can scatter across different targets.
- **Thick Hide:** 225 max health only. No regen or lifesteal outside of Last Call.
- **Shrapnel Shell:** fires the instant the ability is used (not tied to the normal fire trigger), travels as a straight shot, does not consume the 2-round magazine or trigger a reload. Fully independent action on its own 8s cooldown.
- **Breach Charge numeric gaps:** filled with placeholders below (dash speed/distance, impact damage, knockback strength weren't specified in the original design) — flagged `[ASSUMPTION]`, need your sign-off before tuning/playtesting.

---

## Pellet Math (working out the cone from your numbers)

Your design gives two data points that, read together, define a clean fixed-angle cone with no extra assumptions needed:

- 0–20 studs: flat full damage (100 headshot / 50 body total)
- 20–60 studs: damage falls off linearly to 25 headshot / 15 body by 60 studs, and "cone radius at the end is 8 studs"

If the cone is a fixed half-angle from the muzzle (like a real shotgun spread, not a radius that starts and stops arbitrarily), then `radius(distance) = distance * tan(halfAngle)`. Solving for `radius(60) = 8`: `halfAngle = atan(8/60) ≈ 7.6°`. That same angle naturally gives `radius(20) ≈ 2.7 studs` — a tight, believable point-blank spread — without needing to invent a separate near-zone radius number. So:

- **Cone half-angle: ≈7.6°**, fixed from the muzzle out to the 60-stud max range.
- Damage for each pellet is based on **that pellet's own travel distance** (where its raycast actually lands), using the two-zone falloff above — not on how far off-center within the cone it landed.
- **Pellet count: 8 (assumption — not specified in the design).** The confirmed numbers (100/50 near, 25/15 far) are read as the *total* damage dealt **if every pellet connects** — i.e. they're a ceiling, not a per-pellet value. Per-pellet damage = `TotalDamageForZone(distance, isHeadshot) / PelletCount`. A target that eats all 8 pellets to the head at point-blank takes exactly 100; a target grazed by 2 of 8 pellets at the same range takes 25. Headshot/body classification is still per-pellet via the existing `HunterCharacterUtil.IsHeadshotPart` check, so a single shot can mix head and body pellets on the same target.
- Pellet spread within the cone: randomize each pellet's direction inside the half-angle (small random yaw/pitch offset per pellet), not a fixed evenly-spaced fan — reads more like a real shotgun blast and avoids an obviously-patterned spread.

---

## Folder Skeleton

```
ReplicatedStorage/
  Hunters/
    Bram/
      Config/
        Manifest.lua
        GrudgekeeperConfig.lua
    Shared/
      HunterStatusEffects.lua   -- NEW shared module (promoted from Vesper-local, see above)

ServerScriptService/
  Hunters/
    BramServer/
      GrudgekeeperModule.lua      -- entry script, mirrors RevolverModule/CardsServer
      GrudgekeeperDamageService.lua -- per-pellet falloff damage
      BreachChargeService.lua     -- wraps RevolverDashService + knockback/impact layer
      ShrapnelShellService.lua    -- immediate straight-shot + two-tier explosion
      LastCallModule.lua          -- ultimate, mirrors HighNoonModule/StarfallSightModule

StarterPlayer/
  StarterPlayerScripts/
    Bram/
      GrudgekeeperClient.lua      -- mirrors FPSRevolverClient/CardsClient/SunspikeClient
      BramHunterGuiClient.lua     -- mirrors HunterGuiClient/CardsHunterGuiClient
```

---

## Manifest (`Hunters.Bram.Config.Manifest`)

- `HeroName = "Bram"`, `KillFeedWeaponName = "Grudgekeeper"`, `DefaultSourceType = "Basic"`
- `HunterFolder = { "Hunters", "Bram" }`
- `Remotes.Events` (under `Bram.Remotes`):
  - `FireShotgun` — client → server, basic blast (sends aim origin/direction; server generates all 8 pellet rays)
  - `ReplicateShot` — server → other clients, replicates the pellet tracer fan
  - `BreachChargeRequest` — client → server, dash direction
  - `BreachChargeFX` — server → all clients, dash + impact visual
  - `ShrapnelShellRequest` — client → server, fire direction
  - `ShrapnelShellFX` — server → all clients, shell travel + explosion visual
  - `UltimateRequest` — client → server, activate Last Call
  - `UltimateState` — server → client(s), start/end broadcast
  - `UltimateChargeUpdate` — server → client, charge value
- `Remotes.Bindables`: none anticipated — client-internal bindables live under `Client.ClientEvents` like Fortuna/Vesper
- `UltimateCharge`: `MaxCharge = 100`; per-source `Basic.{Hit,Headshot,Kill}` — **placeholder, mirrors Dust's 2.5/6/5**, awarded once per shot that connects (not once per pellet — see Cooldown/Charge note below); `PassiveChargePerSecond = 0.125`
- `Client.ViewmodelTemplate = { "Hunters", "Bram", "Viewmodel", "GrudgekeeperDefaultViewmodel", "ArmsViewModel" }`
- `Client.ClientEvents`: `AmmoChanged`, `Reloaded`, `BreachChargeCooldownStarted`, `ShrapnelShellCooldownStarted`, `UltimateCooldownStarted`, `UltimateChargeChanged`, `FireRequested`, `BreachChargeRequested`, `ShrapnelShellRequested`, `UltimateRequested`, `ReloadRequested`

---

## Config (`GrudgekeeperConfig`)

```
Passive = {
  MaxHealth = 225,                    -- confirmed; no regen/lifesteal outside Last Call
},

Basic = {
  Cooldown = 0.5,                      -- confirmed: time between shots
  MagazineSize = 2,                    -- confirmed
  ReloadTime = 1,                      -- confirmed
  PelletCount = 8,                     -- confirmed not specified in design; standard shotgun pellet count
  ConeHalfAngleDegrees = 7.6,          -- derived from radius(60)=8 studs, see "Pellet Math" above
  MaxRange = 60,                       -- confirmed: no damage past this
  NearZoneDistance = 20,               -- confirmed: flat full damage inside this
  HeadshotDamageNear = 100,            -- confirmed (total if all pellets connect)
  HeadshotDamageFar = 25,              -- confirmed, at 60 studs
  BodyDamageNear = 50,                 -- confirmed
  BodyDamageFar = 15,                  -- confirmed, at 60 studs
  -- per-pellet damage = TotalDamageForZone(distance, isHeadshot) / PelletCount
},

BreachCharge = {
  Cooldown = 6,                        -- confirmed
  DashSpeed = 200,                     -- [ASSUMPTION] studs/sec burst, mirrors RevolverDashService's shape (240 for Dust) scaled down for a heavier bruiser
  DashBurstTime = 0.4,                 -- [ASSUMPTION]
  ImpactDamage = 15,                   -- [ASSUMPTION] light, per the design's own "light impact damage" wording
  KnockbackSpeed = 50,                 -- [ASSUMPTION] studs/sec impulse applied outward from Bram to struck enemies
  KnockbackDuration = 0.3,             -- [ASSUMPTION] decays similarly to RevolverDashService's end-speed-multiplier pattern
  HitboxRadius = 6,                    -- [ASSUMPTION] radius checked around Bram's current position during the dash burst; each enemy hit once per dash (debounced)
},

ShrapnelShell = {
  Cooldown = 8,                        -- confirmed
  Range = 100,                         -- confirmed 
  ConsumesAmmo = false,                -- confirmed
  FiresImmediately = true,             -- confirmed
  TravelMode = "Hitscan",              -- confirmed  a travel-time projectile
  InnerRadius = 5.4,                   -- confirmed
  InnerDamage = 50,                    -- confirmed
  InnerSlowPercent = 0.30,             -- confirmed
  OuterRadius = 12.2,                  -- confirmed
  OuterDamage = 25,                    -- confirmed
  OuterSlowPercent = 0.15,             -- confirmed
  SlowDuration = 2,                    -- confirmed
},

Ultimate = {
  Duration = 10,                       -- confirmed
  DamageReductionPercent = 0.5,        -- confirmed — applied to all incoming damage regardless of source
  LifestealPercent = 0.25,             -- confirmed — heals Bram for 25% of damage he deals, from any source, while active
  ReloadTimeDuringUlt = 0.5,           -- confirmed
  CooldownDuringUlt = 0.25,            -- confirmed (time between shots)
  RefreshAbilityCooldownsOnActivate = true, -- confirmed: Breach Charge + Shrapnel Shell cooldowns zero out on activation
  CooldownReductionPerHitLanded = 1,   -- confirmed value, but see interpretation note below
  MoveSpeedBonusPercent = 0.25,        -- confirmed
},

UltimateCharge = {
  MaxCharge = 100,
  PassiveChargePerSecond = 0.125,      -- [ASSUMPTION] matches Dust/Vesper convention
  Sources = {
    Basic = { Hit = 2.5, Headshot = 6, Kill = 5 },  -- [ASSUMPTION] matches Dust's revolver values
  },
},
```

**Interpretation note — "per shot" not "per pellet":** with 8 pellets per trigger pull, "basic attacks that hit enemies reduce cooldown of abilities by 1 second" (and, separately, ultimate-charge awards for `Hit`/`Headshot`) should trigger **once per shot that lands at least one pellet**, not once per pellet or once per enemy struck. Otherwise a single blast into a cluster during Last Call (0.25s between shots) could refund several seconds of cooldown or charge per trigger pull, which almost certainly isn't the intent behind a flat "-1 second" number. Flag if you actually want it to scale with pellets/targets hit instead.

---

## Weapon: Grudgekeeper (Basic)

- Server receives `FireShotgun` with the client's aim origin/direction, generates `PelletCount` (8) independent raycast directions randomized within `ConeHalfAngleDegrees` (≈7.6°) of the aim vector, capped at `MaxRange` (60 studs).
- Each pellet runs the same lag-compensated → current-raycast → forgiveness-sphere resolution chain Dust/Vesper use — consider dropping the forgiveness-sphere layer for pellets specifically if 8x the per-shot raycasts becomes a performance concern; the lag-compensated + current-raycast pair alone should be plenty accurate at shotgun ranges.
- Per pellet: classify headshot/body via `HunterCharacterUtil.IsHeadshotPart`, compute `TotalDamageForZone(distance, isHeadshot) / PelletCount`, accumulate per-target across all 8 pellets.
- After resolving all pellets, call `HunterHitPipeline:Register` **once per target hit** (summed pellet damage, `IsHeadshot` = true if any pellet hit the head) rather than once per pellet — keeps kill feed/hit confirm/charge award sane and consistent with the "per shot" interpretation above.
- Reload/ammo: reuse `HunterAutoReload`, same as every other hunter.

## Ability 1: Breach Charge

- New `BreachChargeService` wraps a Bram-specific instance of `RevolverDashService` (config-driven, already hero-agnostic — Fortuna already reuses it this way for Ability1's opening dash) for the horizontal burst-then-decay velocity, and layers a knockback+damage pass on top:
  - Each frame during `DashBurstTime` (0.4s), check for enemies within `HitboxRadius` (6 studs) of Bram's current position that haven't been hit by *this* dash yet (debounce set, cleared at dash start).
  - On first contact with each enemy: apply `ImpactDamage` (15) through the normal damage/hit-pipeline path, and push them outward from Bram at `KnockbackSpeed` (50 studs/sec) decaying over `KnockbackDuration` (0.3s) — same "set `AssemblyLinearVelocity` directly, no BodyVelocity/BodyForce" approach as the dash itself and as recommended for Vesper's Grapple Hook, so all of the game's non-standard movement uses one consistent technique.
- Cooldown starts on activation, not on landing a hit — it's usable purely for repositioning even if it never connects with an enemy.

## Ability 2: Shrapnel Shell

- Fires immediately on activation (confirmed) — independent of the normal fire input and magazine, on its own 8s cooldown.
- Hitscan raycast (placeholder — see `TravelMode` assumption) from Bram's aim origin out to `Range` (150 studs, placeholder), stopping at the first enemy character or piece of world geometry.
- At the landing point, run the shared **`HunterStatusEffects`** overlap check twice (inner then outer radius, or once with both radii and a distance-based branch):
  - Inner (5.4 studs): `InnerDamage` (50) + `InnerSlowPercent` (30%) for `SlowDuration` (2s)
  - Outer (12.2 studs, excluding anyone already caught by the inner ring): `OuterDamage` (25) + `OuterSlowPercent` (15%) for `SlowDuration` (2s)
- Every damaged target routes through `HunterHitPipeline:Register` same as a normal hit (multiple targets in one explosion is fine — Fortuna's ultimate ring already establishes that one ability activation can register several separate hits).

## New Shared Module: `HunterStatusEffects`

Promote this straight to `ReplicatedStorage.Hunters.Shared` rather than building it Bram-local, since Vesper's Pinning Round needs the exact same primitive (slow-on-hit, timed, restores original speed on expiry) and Bram is the second hunter to need it:

- `:ApplySlow(humanoid, slowPercent, duration)` — refcounted so overlapping slows from different sources don't compound multiplicatively; stores the humanoid's original `WalkSpeed` once per debuff-free target, restores it when the last active slow on that target expires.
- Marking/reveal-through-walls (Vesper-only for now) can stay a separate concern in the same module or a sibling one — Bram's kit doesn't need it, so don't force it into this module's surface area just because it's adjacent.

## Ultimate: Last Call

- Standard `UltimateRequest` gated on full charge via `UltimateChargeService`, same activation pattern as every other ultimate.
- On activation: set `Ultimate Active` flag/attribute on the character (mirrors Fortuna's `UltimateActive` attribute pattern), apply the reload/fire-rate overrides (0.5s / 0.25s), apply `MoveSpeedBonusPercent` (+25%) to `WalkSpeed`, zero out both ability cooldowns immediately (`RefreshAbilityCooldownsOnActivate`).
- Damage reduction: intercept incoming damage application (wherever `Humanoid:TakeDamage`/pipeline damage application happens for Bram specifically) and multiply by `(1 - DamageReductionPercent)` while the ultimate flag is set.
- Lifesteal: whenever Bram deals confirmed damage (from any source — basic pellets, Breach Charge impact, Shrapnel Shell) while the flag is set, heal him for `LifestealPercent * actualDamageDealt`, clamped to `MaxHealth`.
- Cooldown reduction on hit: each landed shot (per the "per shot not per pellet" interpretation above) reduces both ability cooldowns by `CooldownReductionPerHitLanded` (1s) while the flag is set.
- Duration: 10s timer, clears the flag and reverts fire-rate/reload/move-speed overrides on expiry, character death, or round end.

---

## Wiring Recipe

Same order as every prior hunter:

1. Build the folder skeleton above.
2. Write `Manifest.lua` and `GrudgekeeperConfig.lua`.
3. Promote/create `Hunters.Shared.HunterStatusEffects` (shared with Vesper's Pinning Round — build this once, both hunters consume it).
4. Add a `HeroSelectionService` entry for "Bram".
5. Server bootstrap: `GrudgekeeperModule.Start()` → `HunterServerRuntime.Start(manifest)` → construct `GrudgekeeperDamageService`, `BreachChargeService`, `ShrapnelShellService` → return runtime for `LastCallModule.Start(runtime)`.
6. Per-shot (and per-explosion, per-impact): call `HunterHitPipeline:Register` after every applied hit.
7. Client bootstrap: `GrudgekeeperClient.Start()` → `HunterClientRuntime.Start(manifest)`.
8. Mobile buttons: `HunterMobileAbilityButton` for Breach Charge/Shrapnel Shell/Ultimate; Bram's basic fire likely wants the same dedicated Fire button pattern Dust uses (`FireRequested`) rather than a tap/hold heuristic.
9. Third-person world model: `HunterWorldModel` config for the Grudgekeeper cosmetic.
10. Once built in Studio: create the vault `.md` files under `LocalRedwaterCanyon/` (including the promoted `HunterStatusEffects.md`, and a retroactive one if Vesper's version was already vaulted under a different path), then run `python update_redwater_canyon_graph.py`.

---

## Mobile Parity Checklist

- Dedicated Fire, Breach Charge, Shrapnel Shell, and Ultimate buttons — no ability here suits a tap/hold heuristic given how decisive and fast Bram's kit is (0.5s between shots, instant-fire Shrapnel Shell).
- `AimAssistController` should help more than usual on Bram given the multi-pellet spread already forgives imperfect aim somewhat — no special-casing needed, the existing yaw/pitch magnetism just helps land pellets in the cone.
- Breach Charge's dash direction on touch should default to camera-forward if no distinct movement-joystick direction is held, same convention worth checking against however Dust/Fortuna's dash already resolves "no explicit direction" on touch.

---

## Open Design Questions / Assumptions To Confirm

Everything tagged `[ASSUMPTION]` in the Config section above, plus:

1. **Pellet count (8)** — not specified in the design; changes how "spready" vs "reliable" the gun feels at range, and how granular per-pellet damage is.
2. **Breach Charge numbers** (200 studs/sec dash, 0.4s burst, 15 impact damage, 50 studs/sec knockback) — all placeholders per your request, need a playtesting pass.
4. **Cooldown-reduction/charge-award granularity** ("per shot, not per pellet/target") — a reasonable default interpretation, but confirm it's what you want, especially during Last Call where a single trigger pull could otherwise refund cooldown repeatedly against a group.
5. **Damage-reduction scope** — assumed Last Call's 50% reduction applies to all incoming damage regardless of source; flag if certain damage types (e.g., another Bram's Shrapnel Shell, fall damage) should bypass it.
6. Cosmetic/VFX/SFX for Grudgekeeper (muzzle flash matching a heavy shotgun, Breach Charge's rocket-assisted launch effect, Shrapnel Shell's explosion, Last Call's armored visual state) — not addressed here, art-side.

None of the above block starting the folder/manifest/config skeleton or building the shared `HunterStatusEffects` module — they only need answers before the corresponding ability is playtested.
