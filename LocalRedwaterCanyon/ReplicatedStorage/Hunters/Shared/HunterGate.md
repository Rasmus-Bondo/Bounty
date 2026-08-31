---
tags: [shared, modulescript, client, hunter-gate]
path: game.ReplicatedStorage.Hunters.Shared.HunterGate
type: ModuleScript
lines: 83
---

# HunterGate

Tiny client-side utility module for the standard "wait for `SelectedHunter` attribute, then early-return if not on this hunter" pattern used by every hunter-specific LocalScript. Replaces ~15-line inline `waitForSelectedHunter` copies and fixes scripts that `WaitForChild` on hunter-specific remotes without gating (e.g. `DashCooldownStarted`) and yield forever for cross-hunter players.

## What it does
1. `.GetSelectedHunter(player, timeoutSeconds?)` — returns `player:GetAttribute("SelectedHunter")`; if not yet set, yields up to `timeoutSeconds` (default 10) for it to be set, racing `GetAttributeChangedSignal("SelectedHunter")` against `task.delay` via a single-resume coroutine pattern. Returns nil on timeout
2. `.IsHunter(player, hunterName, timeoutSeconds?)` — equivalent to `GetSelectedHunter(...) == hunterName`. The standard top-of-script guard for hunter-specific behavior
3. `.RunForHunter(player, hunterName, fn)` — convenience: if `IsHunter` returns true, calls `fn()`; otherwise returns silently
4. `.ConnectHunterChanged(player, callback)` — returns an RBXScriptConnection that fires `callback(newHunter)` on `SelectedHunter` attribute change; used by scripts that need to react to mid-session hunter swaps

## Dependencies
- **Requires:** Nothing
- **Required by:** HunterClientRuntime (composes IsHunter + ConnectHunterChanged into the runtime handle), HighNoonClient (Dust-only ultimate), JumpImpact (Dust-only dash impact listener), HighNoonViewModelOrbit, HideLocalWorldRevolver, WorldRevolverAimIdleClient, CardsWorldVisualClient (all migrated from inline `waitForSelectedHunter` blocks in Phase 3), WorldAnimationPrewarmClient (plain text: that script's own file declares the require, and a wikilink here would point dependency → dependent)

## Connections
### RemoteEvents
None

### BindableEvents
None

### Direct require()
None
