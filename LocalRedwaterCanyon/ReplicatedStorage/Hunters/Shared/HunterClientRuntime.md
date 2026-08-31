---
tags: [shared, modulescript, hunter-runtime, client]
path: game.ReplicatedStorage.Hunters.Shared.HunterClientRuntime
type: ModuleScript
lines: 137
---

# HunterClientRuntime

Client mirror of HunterServerRuntime. Consumes the same [[HunterManifest|manifest]] table (reading the optional `Client = { ViewmodelTemplate, ClientEvents, ViewmodelConfig }` section) and returns a runtime handle with everything a hunter LocalScript entry needs that is not hunter-specific gameplay. Phase 3 of the hunter shared-modules refactor.

## What it does
1. `Start(manifest)` runs once per hunter client entry script (Dust via FPSRevolverClient + HunterGuiClient; Fortuna via CardsClient + CardsHunterGuiClient):
   1. Validates the manifest via [[HunterManifest]].Validate; errors with a precise reason if malformed
   2. Calls [[HunterGate]].IsHunter(LocalPlayer, manifest.HunterName) — yields up to ~10s for the SelectedHunter attribute to replicate. **Returns nil if the local player is on a different hunter.** Replaces every inline `waitForSelectedHunter + early return` opener; callers do `if not runtime then return end`.
   3. Walks `manifest.HunterFolder` from ReplicatedStorage to locate the hunter's data folder
   4. Resolves all declared `manifest.Remotes.Events` (server-created RemoteEvents) under `<HunterFolder>/Remotes`
   5. Ensures `<HunterFolder>/ClientEvents` exists, then ensures all declared `manifest.Client.ClientEvents` BindableEvents (creates if missing — idempotent via [[HunterRemoteSetup]]); ServerEvents folder is NOT created on the client (server owns it)
   6. Resolves the 5 cross-hunter remotes from `ReplicatedStorage.Hunters.Shared.Remotes` (HitConfirm, DamageDirection, HealthBarReveal, KillFeed, KillCam)
   7. Resolves the viewmodel template at `manifest.Client.ViewmodelTemplate` path (warns and returns nil-template if missing — does not error so the rest of the runtime stays usable)
2. Returns a runtime handle exposing: `HunterName`, `IsLocalHunter` (always true if returned), `LocalPlayer`, `Manifest`, `Folders` (Hunter / Remotes / ClientEvents), `Remotes`, `ClientEvents`, `SharedRemotes`, `SharedRemotesFolder`, `Viewmodel.{Template, Config}`, `SprintController` (a fresh per-entry-script [[SprintController]] instance — only the combat client's is actually driven), `:ConnectHunterChanged(callback)` (delegates to [[HunterGate]])
3. Errors loudly if called from a server context (no LocalPlayer) or if the manifest is malformed — fail-fast

## Dependencies
- **Requires:** [[HunterManifest]], [[HunterRemoteSetup]], [[HunterGate]], [[SprintController]] (all from `ReplicatedStorage.Hunters.Shared`)
- **Required by:** FPSRevolverClient, HunterGuiClient, CardsClient, CardsHunterGuiClient, SunspikeClient, VesperScopeController, VesperHunterGuiClient, GrudgekeeperClient, BramHunterGuiClient

## Connections
### RemoteEvents
None directly — resolves and exposes the hunter's RemoteEvents per manifest

### BindableEvents
None directly — ensures and exposes the hunter's BindableEvents per manifest

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[HunterManifest]] | `.Validate()` | Fail-fast manifest validation |
| [[HunterRemoteSetup]] | `.EnsureFolder()`, `.EnsureBindableEvents()` | Idempotent folder + bindable creation |
| [[HunterGate]] | `.IsHunter()`, `.ConnectHunterChanged()` | Local hunter gate + change subscription |
| [[SprintController]] | `.new()` | Per-player sprint state machine exposed as `runtime.SprintController` |
