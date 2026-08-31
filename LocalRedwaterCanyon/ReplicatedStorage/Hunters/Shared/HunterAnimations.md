---
tags: [shared, modulescript, animation]
path: game.ReplicatedStorage.Hunters.Shared.HunterAnimations
type: ModuleScript
lines: 268
---

# HunterAnimations

The one home of every hunter animation clip id: resolves ids out of each hunter's `Config.Manifest.Animations` table for every loader in the game.

## What it does
1. Reads clip ids from the `Animations` table each hunter's manifest declares — `Viewmodel = { [clip] = id }`, `World = { [clip] = id }`, and `Skins = { [skinName] = { Viewmodel/World = { [clip] = id } } }` for explicit per-skin overrides. The rig `Animation` instances and the `ViewmodelAnimations` drop-zone folders are unread leftovers until Phase 2 of the animation-system migration deletes them (`HUNTER_ANIMATION_SYSTEM_SPEC.md`)
2. `id(hunterName, kind, clipName, skinName?)` resolves one clip id — a skin override wins over the base table; a default/unknown skin name simply falls through. Plain table reads: never yields, never errors, returns nil for an unknown hunter, kind or clip
3. `set(hunterName, kind, skinName?)` returns the whole resolved set with overrides folded in, as a fresh table. A hunter with no `Animations` table returns empty rather than erroring, so a fifth hunter mid-build cannot break callers
4. `allIds()` returns every id in the universe, deduped, skin overrides included — hunters are discovered off the `Hunters` folder (anything with a `Config.Manifest`), not a hardcoded list. This is what WorldAnimationPrewarmClient's tail tier warms
5. `loadSet(animator, hunterName, kind, skinName?, opts?)` builds every track in a set on one animator, prewarming the whole set in ONE `AnimationLoader.prewarm` pass first — loading one clip at a time is what makes a cold client pay N sequential fetches. `opts.Blocking = false` (default) uses `AnimationLoader.loadCached` and never yields (spawn-path safe); `true` uses `.load` and is authoritative. A clip that fails is absent from the result after one WARN naming hunter, kind and clip
6. Manifests are required lazily and cached — success only, so a lookup that runs before the hunter folder replicates on a client is retried rather than permanently cached as missing
7. Track priority and looped stay at the call site by design: they are behaviour, not identity, and the Core < Idle < Movement < Action ordering is load-bearing there
8. `animations(hunterName)` returns the **raw** `Animations` table — the declaration rather than the resolved set, which is what an audit needs to check each override against the base table it overrides. Returned as-is rather than copied: read it, never mutate it
9. `hunterNames()` lists every hunter that ships a manifest, sorted, read off the `Hunters` folder for the same reason `allIds()` is — a fifth hunter is audited and prewarmed the day its manifest lands

## Dependencies
- **Requires:** [[AnimationLoader]] (lazily, in `loadSet` only — from `ReplicatedStorage.Modules`); each hunter's [[Manifest]] (lazily, via `pcall(require)` on `Hunters.<Name>.Config.Manifest`)
- **Required by:** RevolverViewModel, HighNoonGunFX, CardsClient, GrudgekeeperClient, VesperViewModelAnimationClient, WorldRevolverAimIdleClient, BramWorldIdleClient, VesperWorldIdleClient, FortunaCardsWorldIdleClient, WorldAnimationPrewarmClient, BotController, GrudgekeeperWorldVisualServer, CardsWorldVisualServer, VesperWorldVisualServer, RevolverWorldModelServer, HunterViewmodelContract

## Connections
### RemoteEvents
None

### BindableEvents
None

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[AnimationLoader]] | `AnimationLoader.prewarm/load/loadCached` | Guarded track builds in `loadSet` |
| [[Manifest]] | (table return, all four hunters) | The `Animations` tables the ids live in |
