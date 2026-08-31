---
tags: [shared, modulescript, client, hunter-switch]
path: game.ReplicatedStorage.Hunters.Shared.HunterClientState
type: ModuleScript
lines: 51
---

# HunterClientState

Shared per-client registry that makes mid-match hunter switching possible. The per-hunter client entry scripts (`StarterPlayerScripts.<Hunter>/*`) gate to ONE hunter at boot and never re-run on their own, so to switch hunters live the HunterClientLoader must (1) tear down whatever the currently-booted hunter set up, then (2) re-run the entry scripts so the new hunter boots. This module is the hand-off point between them. ModuleScripts are cached per client environment, so every client LocalScript that requires this shares the SAME table.

## What it does
1. `.registerCleanup(fn)` — a booted hunter entry script calls this right after it finishes booting (and only when it is the local hunter) to register a teardown closure. `fn` must fully undo everything the script created: disconnect every connection, `UnbindFromRenderStep` every named bind, destroy the viewmodel / GUIs / mobile buttons it made, and `:Destroy()`/`:Stop()` its sub-controllers
2. `.teardown()` — called by HunterClientLoader immediately before it re-runs the entry scripts. Runs + clears every registered cleanup (most-recent-first, each pcall-guarded) and bumps `.generation`
3. `.generation` — an integer bumped on every teardown. A booted hunter captures it at boot; any stray long-lived callback that outlives a teardown compares against it and no-ops. This is the safety net for any connection a cleanup misses

## Dependencies
- **Requires:** Nothing
- **Required by:** HunterClientLoader (calls `.teardown()` on a swap); and every per-hunter client entry script that registers a cleanup — Dust: FPSRevolverClient, HunterGuiClient, HighNoonClient, HighNoonViewModelOrbit, WorldRevolverAimIdleClient, HideLocalWorldRevolver, WorldRevolverShotSoundClient; Vesper: SunspikeClient, VesperScopeController, VesperHunterGuiClient, VesperViewModelAnimationClient, VesperScopeDepthOfFieldClient, HideLocalWorldSniper; Bram: GrudgekeeperClient, BramHunterGuiClient; Fortuna: CardsClient, CardsHunterGuiClient, CardsWorldVisualClient; shared fallback: HunterFirstPersonClient

## Connections
### RemoteEvents
None

### BindableEvents
None

### Direct require()
None
