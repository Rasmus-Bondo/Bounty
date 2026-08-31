---
tags: [shared, modulescript, hunter-runtime]
path: game.ReplicatedStorage.Hunters.Shared.HunterServerRuntime
type: ModuleScript
lines: 338
---

# HunterServerRuntime

Phase 2 hunter framework. Consumes a [[HunterManifest|manifest]] and a behavior-opts table, returns a runtime handle with all the wiring that every hunter does identically: folder resolution, remote setup, shared cross-hunter remote resolution, RoundStats fallback, [[UltimateChargeService]] construction, [[HunterHitPipeline]] construction, hunter gate. Replaces ~150 lines of duplicated boilerplate at the top of each hunter's server entry.

## What it does
1. `Start(manifest, behaviorOpts?)` runs once per hunter entry script (Dust via RevolverModule, Fortuna via CardsServer):
   1. Validates the manifest via [[HunterManifest]].Validate; errors with a precise reason if malformed
   2. Resolves [[HunterSelectionService]] from `ServerScriptService.PlayerServices`; resolves [[RoundStatsService]] and [[ProgressionService]] with graceful nil fallbacks (each warns once if missing — ProgressionService is used by [[HunterHitPipeline]] to award assist XP/Cash); resolves `ReplicatedStorage.RoundActive`
   3. Walks `manifest.HunterFolder` from ReplicatedStorage (e.g. `{"Revolver"}` for Dust, `{"Hunters","Fortuna","Cards"}` for Fortuna) to locate the hunter's data folder
   4. Ensures `Remotes/` sub-folder + all declared RemoteEvents via [[HunterRemoteSetup]]; ensures `ServerEvents/` sub-folder + Bindables only if any are declared (Fortuna declares none — its client-internal bindables live under `Hunters/Fortuna/ClientEvents` and are now ensured below). Also ensures `<ClientEventsFolder>/` (default "ClientEvents") + all `manifest.Client.ClientEvents` BindableEvents if declared — this is what used to be owned by the (now-deleted) `CardsRemoteSetup` script, giving the server folder authority over Fortuna's client-internal bindables.
   5. Resolves the 5 cross-hunter remotes from `ReplicatedStorage.Hunters.Shared.Remotes` (HitConfirm, DamageDirection, HealthBarReveal, KillFeed, KillCam — created by HunterSharedRemoteSetup)
   6. Optionally requires `manifest.ConfigModule` and exposes as `runtime.Config` (neither hunter currently uses this — they require their hero-specific configs directly)
   7. If `manifest.UltimateCharge` is present: constructs [[UltimateChargeService]] with manifest's Sources / MaxCharge / PassiveChargePerSecond / DisplayPrecision, ChargeUpdateRemote resolved from declared events, and a `BlockPredicate` that always returns true when `IsHunter(player)` is false plus any predicates passed via `behaviorOpts.ChargeBlockPredicate` or registered later via `runtime:AddChargeBlockPredicate(fn)`. Auto-calls `:Start()` on the charge service so callers never need to.
   8. Constructs [[HunterHitPipeline]] with the 5 cross-hunter remotes + RoundStats + ProgressionService + the (optional) ChargeService + `DefaultWeaponName = manifest.KillFeedWeaponName`
2. Returns a runtime handle exposing: `HunterName`, `KillFeedWeaponName`, `Manifest`, `Config`, `Folders` (Hunter / Remotes / ServerEvents / ClientEvents), `Remotes`, `ServerEvents`, `ClientEvents`, `SharedRemotes`, `SharedRemotesFolder`, `HunterSelection`, `RoundStats`, `ProgressionService`, `RoundActive`, `HitPipeline`, `ChargeService`, `IsHunter(player)`, `AddChargeBlockPredicate(fn)`, `Destroy()`
3. `IsHunter` is the unified hunter gate: returns true if `HunterSelectionService.IsHunter(player, hunterName)` OR `player:GetAttribute("SelectedHunter") == hunterName` — handles the spawn-race fallback that used to be implemented ad-hoc in each hunter
4. `AddChargeBlockPredicate(fn)` lets a behavior module register an additional block predicate after construction — used by HighNoonModule to block charge accumulation while High Noon is winding up or active
5. Registers the hunter's authored resting walk speed as the `Passive` movement base on [[HunterMovement]] for each of its characters at spawn, gated by `IsHunter`. Value comes from `behaviorOpts.PassiveWalkSpeed`, defaulting to 16 — Fortuna passes 24 from CardsServer since its passive differs. Everything else that touches movement speed (scopes, ultimates, slows, sprint) is a modifier layered over this base, so nothing snapshots a live WalkSpeed and no effect can capture another one's output
6. Resets this hunter's ultimate charge (`ChargeService:Set(player, 0)`) whenever the player's `SelectedHunter` attribute changes — i.e. a mid-match hunter switch via HunterSwitchService (the switch is death-gated, so `SetSelection` flips the attribute at the respawn). Every hunter's runtime does this, so a swap zeroes both sides: the hunter being left (nothing parks for a later swap-back) and the hunter being joined (starts fresh). `GetAttributeChangedSignal` only fires on a real value change, so an ordinary death/respawn — which never changes the selection — keeps charge intact. No-op if the manifest declared no `UltimateCharge` (`chargeService` is nil)

## Dependencies
- **Requires:** [[HunterManifest]], [[HunterRemoteSetup]], [[UltimateChargeService]], [[HunterHitPipeline]], [[HunterMovement]] (all from `ReplicatedStorage.Hunters.Shared`); [[HunterSelectionService]] + [[RoundStatsService]] + [[ProgressionService]] (resolved at runtime from `ServerScriptService.PlayerServices`; RoundStats and ProgressionService degrade gracefully if missing)
- **Required by:** RevolverModule, CardsServer, SunspikeModule, GrudgekeeperModule

## Connections
### RemoteEvents
None directly — creates and exposes the hunter's RemoteEvents per manifest

### BindableEvents
None directly — creates and exposes the hunter's BindableEvents per manifest (if any declared)

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[HunterManifest]] | `.Validate()` | Fail-fast manifest validation |
| [[HunterRemoteSetup]] | `.EnsureFolder()`, `.EnsureRemoteEvents()`, `.EnsureBindableEvents()` | Idempotent folder + event creation |
| [[UltimateChargeService]] | `.new()`, `:Start()` | Per-hunter ultimate-charge service |
| [[HunterHitPipeline]] | `.new()` | Per-hunter post-hit feedback chain |
| [[HunterSelectionService]] | `.IsHunter()` | Underlying hunter gate |
| [[RoundStatsService]] | (passes to HitPipeline) | Optional, degrades to nil |
| [[ProgressionService]] | `awardAssist()` (via HitPipeline) | Optional, degrades to nil |
