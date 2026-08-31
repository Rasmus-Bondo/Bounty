---
name: hunter-shared-refactor
description: "Hunter shared-modules architecture — all 3 phases COMPLETE 2026-06-28; what lives in Hunters.Shared, the decisions behind it, and the add-a-hunter guide"
metadata: 
  node_type: memory
  type: project
  originSessionId: c85e292e-ac44-45cb-8a0c-ab5292dfa7da
  modified: 2026-07-28T16:18:38.002Z
---

Dust and Fortuna's duplicated rigging was extracted into shared, hero-agnostic modules under `ReplicatedStorage.Hunters.Shared` so a new hunter only writes hero-*specific* behavior. Done in three phases, **all complete as of 2026-06-28**. Vesper, Bram and the bot kits were all built on top of it since, which is the real proof it worked.

**Why:** adding a hunter shouldn't mean re-writing hero-selection gating, world-model replication, lag compensation, or viewmodel animation.

## The one thing to read first

`game.ReplicatedStorage.Hunters.Shared.HunterImplementationGuide` (ModuleScript, docs-only, `return {}`) — mental model, folder layout, full manifest schema, server + client runtime APIs, shared-module catalog, wiring recipe, and pointers to Dust/Fortuna as templates. **Point every "how do I add a hunter?" question at this file** rather than re-deriving. Vault: `LocalRedwaterCanyon/ReplicatedStorage/Hunters/Shared/HunterImplementationGuide.md`.

## What lives in Hunters.Shared

Check the folder itself before trusting this list — it has kept growing (`HunterStatusEffects`, `BulletPenetration`, `AimAssistController` all landed later).

- `HunterManifest` — schema + `Validate()` for fail-fast wiring errors.
- `HunterServerRuntime` / `HunterClientRuntime` — `Start(manifest)` → a runtime handle carrying remotes, folders, hit pipeline, charge service, viewmodel template. The client one yields forever if you're not that hero.
- `HunterHitPipeline` — the whole post-hit chain (damage → damage direction → health-bar reveal → hit confirm → charge award → kill feed → kill cam), including the red hit-flash.
- `UltimateChargeService` — per-source charge tracking, with block predicates.
- `HunterPositionHistory` — snapshot loop + ping-rewind lookup; each hero plugs in its own capture/resolution math.
- `HunterWorldModel` — third-person cosmetic lifecycle (clone, hand resolve, Motor6D/Weld attach, idle anim, watchdog, invisibility). **See [[project_hunter_world_cosmetic_attach]] — `_attach` takes `(player, character)` and the one-arg call silently starved every hunter of its world gun.**
- `HunterViewModelMotion` — per-frame compositor (sway/strafe/bob always on; jump-land, dash, recoil opt-in; extra-CFrame slots).
- `HunterCharacterUtil` — hit-target / headshot / accessory / enemy resolution. `ShouldIgnoreCombatPart` is the shared "is this a real body part" filter.
- `HunterGate` — client hero gate (`GetSelectedHero` / `IsHero` / `RunForHero` / `ConnectHeroChanged`).
- `HunterMobileAbilityButton` — OOP mobile button supporting both the known-frame and lazy-resolve patterns.
- `HunterRemoteSetup` + `Hunters.Shared.Remotes` — cross-hero remote folder (HitConfirm, HealthBarReveal, DamageDirection, KillFeed, KillCam).

## Decisions locked in

- Shared folder is `ReplicatedStorage.Hunters.Shared/`; naming prefix is `Hunter*`.
- Headshot is unified on `HitboxType == "Head"`.
- Server has folder authority over client-internal bindables too (manifest `Client.ClientEvents`); the client runtime's ensure call is an idempotent no-op.
- Hero-specific server code lives in `ServerScriptService.Hunters.<Hero>Server/`, hero-specific client code in `StarterPlayerScripts.<Hero>/`. Hero-agnostic code stays at the root (`CharacterStateLockServer`, `HitMarkScript`).
- Refactor was in-place, module-by-module, with a playtest between each.
- **Studio MCP changes persist only after a manual save (Ctrl+S).** Learned the hard way when `HunterWorldModel` vanished mid-session.

## Still open (all minor, none blocking)

- `HighNoonChargeAward` BindableEvent is orphaned — still created by `RevolverRemoteSetup` and listed in its `DEFAULT_SERVER_EVENTS`, but nothing fires or listens to it. Safe to drop from the list.
- `HunterFirstPersonClient` still uses an inline `waitForSelectedHero` because it branches on the value rather than gating on it; could move to `HunterGate.GetSelectedHero`.
- `FortunaCardsFXClient`, `FortunaCardsWorldIdleClient`, `FortunaCardsWorldVisibilityClient` still sit at `StarterPlayerScripts/` root instead of under `Fortuna/`. They observe all players, so they're cross-hero by design, but they only render Fortuna visuals. Deferred deliberately — and note [[project_hunter_switch_midmatch]] leaves these ungated global FX scripts *out* of the swap teardown cycle on purpose.
- `HunterHudKit` (charge bar + cooldown chip widgets) deferred until a hunter forces the abstraction.
- Default spawn hero is a knob, not a decision — see [[project_vesper_hunter]] for the `DEFAULT_HUNTER` / `STUDIO_TEST_HUNTER` split that replaced the old temp-flip workflow.

Related: [[project_vesper_hunter]], [[project_bram_hunter]], [[project_hunter_switch_midmatch]], [[feedback_never_partial_overwrite]].
