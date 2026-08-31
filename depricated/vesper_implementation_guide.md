# Vesper Implementation Guide

Long-range sharpshooter. Controls sightlines with the Sunspike Carbine, repositions with a grapple hook, and closes out fights with a piercing celestial ultimate. Fragile up close by design — every kit piece pushes her toward distance, not away from it.

This guide follows the same shape as `HunterImplementationGuide` (`LocalRedwaterCanyon/ReplicatedStorage/Hunters/Shared/HunterImplementationGuide.md`) and the existing Dust/Fortuna implementations. It is a planning document, not a vault file — nothing here should be created in Studio until the open questions below are resolved, and no vault `.md` should exist until the matching script exists.

---

## Stat Block

| Stat | Value | Notes |
|---|---|---|
| Health | 125 | |
| Body damage | 65 | flat, no charge interaction |
| Headshot damage | 125 base → up to 187.5 at max Deadeye Focus charge | scales with passive only |
| Magazine size | 4 | |
| Time between shots | 1.8s | |
| Reload time | 3s | |
| Fire mode | **Hitscan** | confirmed — reuses Dust's `RevolverDamageService` falloff pattern |
| Grapple Hook range | 125 studs | |
| Grapple Hook cooldown | 8s | whiff (no valid surface) does not consume cooldown — confirmed |
| Pinning Round radius | 25 studs | |
| Pinning Round slow | -25% speed, 5s | confirmed |
| Pinning Round mark | reveals through walls, 6s | confirmed, no direct damage |
| Starfall Sight range | 400 studs | pierces enemies + buildings |
| Starfall Sight ring damage | 100 / 75 / 50 | inner (0-0.4 studs) → outer (0.7-1.3 studs) — confirmed |
| Starfall Sight active window | 12s | unused charged shots expire after this — confirmed |
| Deadeye Focus ramp | 0 → 50% bonus over 3s scoped | resets instantly on unscope or fire — confirmed |

---

## What's New vs. What's Reused

Vesper reuses almost the entire shared hunter framework as-is. Three things do **not** have an existing precedent in the codebase and need new shared modules:

| Piece | Reused as-is | New |
|---|---|---|
| Manifest / server bootstrap / hero gate | `HunterServerRuntime`, `HunterManifest`, `HunterGate` | — |
| Client bootstrap | `HunterClientRuntime` | — |
| Remote/folder creation | `HunterRemoteSetup`, `HunterSharedRemoteSetup` | — |
| Hit feedback (flash, kill feed, hit confirm, damage direction) | `HunterHitPipeline` | — |
| Ultimate charge economy | `UltimateChargeService` | — |
| Auto-reload on empty mag | `HunterAutoReload` | — |
| Mobile ability buttons | `HunterMobileAbilityButton` | — |
| Third-person cosmetic rifle | `HunterWorldModel` | — |
| Hit-part / headshot / team checks | `HunterCharacterUtil` | — |
| Distance damage falloff | — | reuse the **pattern** from `RevolverDamageService`, own instance |
| Scope/ADS (FOV zoom, movement lock, input toggle) | — | **new** — no hunter has ADS today |
| Slow + reveal-through-walls status effect | — | **new** — no status-effect system exists today |
| Grapple hook movement | — | **new** — no pull/hook movement exists today (Dust's dash is a burst-velocity dash, not a point-to-point pull) |
| Piercing multi-ring hitscan (ultimate) | — | **new** — no piercing or radial-falloff shot shape exists today |

---

## Map Investigation (done)

Checked the live Redwater Canyon place via MCP for how the invisible arena boundary is represented, since Grapple Hook must not attach to it:

- `Workspace.WallMap` is a Folder containing many `WALLMAPPART` Parts.
- Each is `Transparency = 1`, `CanCollide = true`, `Anchored = true`, no CollectionService tags, no non-default CollisionGroup.

**Implication:** the grapple raycast should filter these out by folder ancestry (`instance:IsDescendantOf(workspace.WallMap)`), not by tag or collision group, since neither is set. If a designer wants a cleaner filter later, tagging `WallMap`'s children `GrappleBlocked` via CollectionService would be a small one-time cleanup — not required to ship Vesper.

---

## Folder Skeleton

Following the Dust/Fortuna convention (`HunterFolder` in the manifest):

```
ReplicatedStorage/
  Hunters/
    Vesper/
      Config/
        Manifest.lua
        VesperConfig.lua
      Viewmodel/
        VesperDefaultViewmodel/
          ArmsViewModel/

ServerScriptService/
  Hunters/
    VesperServer/
      SunspikeModule.lua        -- entry script, mirrors RevolverModule/CardsServer
      SunspikeDamageService.lua -- mirrors RevolverDamageService (falloff)
      GrappleHookService.lua
      PinningRoundService.lua
      StarfallSightModule.lua   -- ultimate, mirrors HighNoonModule
      VesperStatusEffects.lua   -- slow + mark tracking (server-authoritative)

StarterPlayer/
  StarterPlayerScripts/
    Vesper/
      SunspikeClient.lua        -- mirrors FPSRevolverClient/CardsClient
      VesperScopeController.lua -- new: ADS/FOV/movement-lock
      VesperHunterGuiClient.lua -- mirrors HunterGuiClient/CardsHunterGuiClient
```

---

## Manifest (`Hunters.Vesper.Config.Manifest`)

Mirrors the Dust/Fortuna manifests exactly in shape — see `HunterManifest.md` for the schema `Validate` checks against.

- `HeroName = "Vesper"`, `KillFeedWeaponName = "Sunspike Carbine"`, `DefaultSourceType = "Basic"`
- `HunterFolder = { "Hunters", "Vesper" }`
- `Remotes.Events` (server-created RemoteEvents under `Vesper.Remotes`):
  - `FireBullet` — client → server, basic shot
  - `ReplicateShot` — server → other clients, tracer replication
  - `GrappleRequest` — client → server, throw the hook
  - `GrappleFX` — server → all clients, hook travel/attach visual
  - `PinningThrowRequest` — client → server
  - `PinningImpactFX` — server → all clients, sphere VFX + which players got hit
  - `UltimateRequest` — client → server, activate Starfall Sight
  - `UltimateShotRequest` — client → server, each of the 3 charged shots
  - `UltimateState` — server → client(s), start/end broadcast (mirrors `CardsServer`'s `UltimateState` / `HighNoonVisual` pattern)
  - `UltimateChargeUpdate` — server → client, charge value
  - `ScopeStateChanged` — client → server (tells server she's scoped/unscoped — needed server-side for movement-speed lock and Deadeye Focus charge timing; do **not** trust client for damage, but this drives server-authoritative walk-speed reduction and charge-window timing)
- `Remotes.Bindables` (under `Vesper.ServerEvents`): none anticipated — status effect and world-model VFX bridges can go through `Client.ClientEvents` like Fortuna, not a standalone bindable file
- `UltimateCharge`: `MaxCharge = 100`; per-source `Hit/Headshot/Kill` values — **placeholder, needs balancing pass**, propose mirroring Dust's revolver values (2.5 / 6 / 5) for `Basic`, plus its own `Ultimate` source entry for damage dealt during Starfall Sight; `PassiveChargePerSecond = 0.125` (matches Dust)
- `Client.ViewmodelTemplate = { "Hunters", "Vesper", "Viewmodel", "VesperDefaultViewmodel", "ArmsViewModel" }`
- `Client.ClientEvents` (BindableEvents ensured under `Vesper.ClientEvents`): `AmmoChanged`, `Reloaded`, `GrappleCooldownStarted`, `PinningCooldownStarted`, `UltimateCooldownStarted`, `UltimateChargeChanged`, `ScopeChanged`, `FireRequested`, `GrappleRequested`, `PinningRequested`, `UltimateRequested`, `ReloadRequested`

---

## Config (`VesperConfig`)

Mirrors `CardsConfig`/`RevolverServerConfig` in shape. Concrete numbers below are either **confirmed** (from the design + your answers) or **[ASSUMPTION]** (my placeholder — flag anything you want changed).

```
Passive = {
  WalkSpeed = 16,                     -- confirmed default Roblox speed; she gets mobility from Grapple, not raw speed
  DeadeyeFocus = {
    RampTime = 3,                     -- confirmed: 0 -> 50% over 3s
    MaxBonus = 0.5,                   -- confirmed: +50% headshot damage at max charge
    ResetOnUnscope = true,            -- confirmed: hard reset, no decay
    ResetOnFire = true,               -- confirmed
  },
},

Basic = {
  Cooldown = 1.8,                     -- confirmed: time between shots
  BodyDamage = 65,                    -- confirmed
  HeadshotDamage = 125,               -- confirmed (base, before Deadeye Focus bonus)
  MagazineSize = 4,                   -- confirmed
  ReloadTime = 3,                     -- confirmed
  FalloffStartDistance = 240,         -- confirmed full damage inside this range
  FalloffEndDistance = 300,           -- confirmed damage floors out at range past this
  BodyMinDamage = 45,                 -- confirmed floor for body shots at max range
  HeadshotMinDamage = 90,             -- confirmed floor for headshots at max range
},

Scope = {
  ADSFOV = 35,                        -- [ASSUMPTION] default camera FOV is 70; needs playtesting for mobile legibility
  TransitionTime = 0.25,              -- [ASSUMPTION] FOV tween in/out, mirrors HighNoonFOV's Bezier approach
  WalkSpeedWhileScoped = 6,           -- [ASSUMPTION] ~62% slow while scoped, standard sniper convention
  AllowHipfire = true,                -- [ASSUMPTION] can fire unscoped; Deadeye Focus bonus just never applies since it requires the scope timer
},

GrappleHook = {
  Range = 125,                        -- confirmed
  Cooldown = 8,                       -- confirmed
  RefundCooldownOnWhiff = true,       -- confirmed
  TravelTime = 0.35,                  -- [ASSUMPTION] time to pull Vesper to the anchor point (not instant snap)
  MinSurfaceAngle = nil,              -- [ASSUMPTION] no slope restriction unless you want one
},

PinningRound = {
  Cooldown = 12,                      -- confirmed utility-heavy AoE, kept above Basic/Grapple cadence
  Radius = 25,                        -- confirmed
  SlowPercent = 0.25,                 -- confirmed
  SlowDuration = 5,                   -- confirmed
  MarkDuration = 6,                   -- confirmed
  ThrowSpeed = 90,                    -- [ASSUMPTION] studs/sec, arcing throw like a grenade (not hitscan)
  DirectDamage = 0,                   -- confirmed: utility only
},

Ultimate = {
  Cooldown = nil,                     -- gated by charge, not cooldown (matches Dust/Fortuna convention)
  Range = 400,                        -- confirmed
  ShotCount = 3,                      -- confirmed
  ActiveWindow = 12,                  -- confirmed: the 3 empowered shots expire after 12s if unused
  GuaranteesAmmo = true,              -- confirmed: activation refills ammo to at least ShotCount so all 3 shots fire back-to-back with no forced reload mid-ultimate
  Rings = {                           -- confirmed: stud radii from the shot's centerline, damage decreasing outward
    { Radius = 0.4, Damage = 100 },   -- inner ring
    { Radius = 0.7, Damage = 75  },   -- mid ring
    { Radius = 1.3, Damage = 50  },   -- outer ring
  },
},

UltimateCharge = {
  MaxCharge = 100,
  PassiveChargePerSecond = 0.125,     -- confirmed matches Dust
  Sources = {
    Basic = { Hit = 4, Headshot = 10, Kill = 6 },   -- confirmed matches Dust's revolver values
  },
},
```

---

## Passive: Deadeye Focus

- Server-authoritative timer keyed per-player, started when the server receives `ScopeStateChanged(true)` and cancelled on `ScopeStateChanged(false)` **or** on any confirmed shot.
- Charge fraction = `math.clamp(scopedDuration / RampTime, 0, 1)`; headshot damage = `HeadshotDamage * (1 + MaxBonus * chargeFraction)`.
- Client shows the charge ramping (HUD ring or similar) purely as a mirrored prediction of the same timer — server remains the source of truth for the damage actually applied, same as every other damage number in this codebase.
- Because it's a hard reset (not decay), the implementation is just "elapsed time since last `ScopeStateChanged(true)` with no intervening fire or unscope" — no separate decay-tick loop needed, unlike a true DoT/regen system.

## Weapon: Sunspike Carbine (Basic)

- Same hitscan shape as `RevolverModule`'s `resolveShot`: lag-compensated raycast → current raycast → forgiveness sphere, three-layer fallback via `RevolverLagCompensation`/`RevolverHitForgiveness`-equivalent instances (either share those modules directly since they're hero-agnostic already, or clone the pattern into hero-specific instances — **recommend sharing directly**, they take config, not hardcoded Dust values).
- New `SunspikeDamageService` mirrors `RevolverDamageService` but multiplies headshot damage by the live Deadeye Focus fraction before applying falloff-adjusted damage.
- Feeds every confirmed hit through `HunterHitPipeline:Register` exactly like Dust/Fortuna — no new hit-feedback code needed.
- Reload/ammo: reuse `HunterAutoReload` for the "auto-reload on last shot fired" trigger, same as Dust and Fortuna.

## Ability 1: Grapple Hook

- Client casts a `GrappleRequest` with an aim direction; server raycasts up to 125 studs, `RaycastParams.FilterType = Exclude`, filter list = `{ character, viewmodel parts, workspace.WallMap }`.
- No hit within range, or hit lands inside `workspace.WallMap` → whiff. Whiff fires `GrappleFX` "miss" visual only, cooldown is **not** started (confirmed).
- Valid hit → cooldown starts, server pulls the character toward the anchor point over `TravelTime` (0.35s placeholder). Since `BodyVelocity`/`BodyForce` are banned, implement the pull with either:
  - A `LinearVelocity` + `AlignPosition` constraint pair on the HumanoidRootPart (attach/destroy per-use), or
  - Direct `HumanoidRootPart.AssemblyLinearVelocity` set every hero Heartbeat tick toward the anchor, cleared on arrival/timeout/cancel (simpler, matches how `RevolverDashService` likely already nudges velocity for the dash — check that module's actual technique in Studio before choosing, so both movement abilities in the game use one consistent approach).
- Cancel conditions: character dies, round ends, or player travels close enough to the anchor (arrival threshold, e.g. 4 studs).
- No damage, no interruption of reload — purely movement.

## Ability 2: Pinning Round

- Thrown projectile (arcing, not hitscan) — closest existing precedent is Fortuna's card throw (`CardsConfig.Basic.Speed`), but Pinning Round should probably use actual projectile motion (gravity) rather than a flat-speed straight throw, since it's described as a "bomb." A simple approach: spawn an invisible marker part, tween/simulate a parabolic arc from muzzle to the target point (derived from camera aim + max range), then trigger the sphere effect at landing.
- On landing, `GetPartBoundsInRadius(landingPosition, PinningRound.Radius)` (or `workspace:GetPartBoundsInBox` for perf) to find all enemy HumanoidRootParts within 25 studs.
- **New shared module recommendation:** `VesperStatusEffects` (or promote to `Hunters.Shared.HunterStatusEffects` if you expect future hunters to want slows/marks too — keep it Vesper-local for now and only generalize when a second hunter actually needs it, per the project's own "wait for a third hunter before adding shared kits" precedent in `HunterImplementationGuide`).
  - Slow: multiply target's `Humanoid.WalkSpeed` by `(1 - SlowPercent)` for `SlowDuration`, restoring the pre-slow speed on expiry (careful with stacking multiple slows on the same target — store original speed once, refcount concurrent slows rather than compounding the multiplier).
  - Mark/reveal: server tells the marked player's attributes (`Marked = true` for `MarkDuration`) and fires a client remote to Vesper (and optionally her team) so a UI/world-space indicator can render through walls — reuse the `Highlight` instance technique already established in `HunterHitPipeline`'s hit-flash (`DepthMode = Enum.HighlightDepthMode.AlwaysOnTop` makes it render through geometry), just parented for the duration instead of tweened out after 0.14s.
- No direct damage (confirmed) — purely utility.

## Ultimate: Starfall Sight

**Ring interpretation (confirmed):** the design's "radius 1: 0.4, 2: 0.7, 3: 1.3" is three concentric **stud radii** measured from the shot's centerline — ring 1 (0–0.4 studs from center) deals the most damage, ring 2 (0.4–0.7 studs) less, ring 3 (0.7–1.3 studs) least. That's still narrow compared to open ground, but wide *relative to a normal hitscan ray* (which is effectively 0 studs wide) — a normal bullet only ever hits what's dead-center; a Starfall shot rewards a good line even without pixel-perfect aim. Damage values are confirmed at 100 / 75 / 50 for the three rings.

- Activation: standard `UltimateRequest`, gated on full charge via the shared `UltimateChargeService`, same pattern as `HighNoonModule`/`CardsServer`'s ultimate gate.
- On activation, refills ammo to at least `ShotCount` (3) if she's below that — confirmed, guarantees all 3 empowered shots fire back-to-back with no forced reload mid-ultimate — then starts a server-side `ActiveWindow` timer (confirmed: 12s) and flags her next `ShotCount` (3) fires as empowered. Shots still respect the normal 1.8s cadence between them; only the "won't get stuck needing to reload first" case is special-cased.
- Per empowered shot, instead of a single raycast: sample every alive enemy humanoid (`HunterCharacterUtil.GetHumanoidModels()`) within `Range` (400 studs) roughly along the aim direction, compute each target's perpendicular distance from the aim ray, reject anything beyond the outer ring radius (1.3 studs) **or** angularly behind Vesper, then apply the matching ring's damage (100/75/50). No wall-stopping check at all — the pierce-through-buildings requirement means this is a pure distance/geometry query, not a `workspace:Raycast` that would stop at the first opaque hit.
- Still routes through `HunterHitPipeline:Register` per target hit so kill feed / hit confirm / charge award / round stats all work identically to a normal shot — the pipeline doesn't care that multiple targets were hit by one "shot."
- Visual: the beam itself should probably still render as passing through walls (celestial theme) — that's art/VFX, not gameplay logic, and doesn't block the server-side implementation.
- If any of the 3 empowered shots go unused when the 12s `ActiveWindow` elapses, they're simply lost — no partial refund or charge-back.

---

## Wiring Recipe

Same order as every prior hunter (see `HunterImplementationGuide` step 7):

1. Build the folder skeleton above under `ReplicatedStorage`/`ServerScriptService`/`StarterPlayerScripts`.
2. Write `Manifest.lua` and `VesperConfig.lua`.
3. Add a `HeroSelectionService` entry for "Vesper" (Bounty lobby's hero-select menu — check `SelectHunterScript`/`HunterList` in `LocalBounty` for where new heroes get registered).
4. Server bootstrap: `SunspikeModule.Start()` → `HunterServerRuntime.Start(manifest)` → construct `SunspikeDamageService`, `GrappleHookService`, `PinningRoundService`, `VesperStatusEffects` → return runtime for `StarfallSightModule.Start(runtime)` (mirrors how `Main` wires `RevolverModule` then `HighNoonModule`).
5. Per-shot: call `HunterHitPipeline:Register` after every applied hit (basic and ultimate).
6. Client bootstrap: `SunspikeClient.Start()` → `HunterClientRuntime.Start(manifest)`, plus the new `VesperScopeController` for FOV/movement/input.
7. Mobile buttons: `HunterMobileAbilityButton` for Grapple/Pinning/Ultimate, **plus a new dedicated Scope toggle button** (no existing shared module covers ADS toggling — this is new UI, likely alongside where Dust's `FireRequested` mobile Fire button was added per `Dust Manifest`).
8. Third-person world model: `HunterWorldModel` config for the Sunspike Carbine cosmetic (idle carry pose, reload one-shot, muzzle flash/smoke if you want Dust-style VFX).
9. Once built in Studio: create the vault `.md` files under `LocalRedwaterCanyon/` mirroring every new script (per this project's vault rules), then run `python update_redwater_canyon_graph.py`.

---

## Mobile Parity Checklist

- Scope toggle needs a dedicated visible button (ADS is not a natural touch gesture the way it is with right-click on PC) — do not rely on a tap/hold heuristic, same lesson that already forced Dust's `FireRequested` button into existence.
- `AimAssistController` should very likely stay active (or be *more* lenient) while scoped, since precision aiming on touch is the hardest case it exists to solve — gate any Vesper-specific `CanAimAssistCheck` accordingly rather than disabling assist while scoped.
- Grapple/Pinning/Ultimate all fit the existing `HunterMobileAbilityButton` pattern as-is.
- ADS FOV of 35 (placeholder) should be checked on an actual touch screen for aim legibility before locking in — narrow FOV plus small screens can make tracking targets harder, not easier.

---

## Open Design Questions / Assumptions To Confirm

The ultimate's ammo interaction, ring damage values, and active window are now confirmed (see Config + Ultimate section above). Still open — everything tagged `[ASSUMPTION]` in the Config section, namely:

2. **Base/scoped walk speed** (16 / 6) — balance placeholder.
3. **Hip-fire** — assumed allowed (just without the Deadeye Focus bonus); confirm sniper-only firing isn't intended instead.
4. **Pinning Round cooldown** (12s) and **throw arc/speed** (90 studs/sec, parabolic) — no value was specified in the original design.
5. **Status effect stacking** — what happens if two Pinning Rounds land on the same target, or a marked target is hit by a second mark, before this needs a real answer.
6. Cosmetic/VFX/SFX for the celestial theme (muzzle flash, scope glow, Starfall Sight beam look) — not addressed here, art-side.

None of the above block starting the folder/manifest/config skeleton — they only need answers before the corresponding ability is playtested.
