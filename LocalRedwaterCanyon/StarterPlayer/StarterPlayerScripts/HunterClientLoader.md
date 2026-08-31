---
tags: [client, localscript, hunter-switch]
path: game.StarterPlayer.StarterPlayerScripts.HunterClientLoader
type: LocalScript
lines: 97
---

# HunterClientLoader

Client half of mid-match hunter switching. The server (HunterSwitchService) flips the `SelectedHunter` attribute and respawns the player as the new hunter, but the per-hunter client entry scripts gate to one hunter at boot and never re-run, so nothing would spin up the new hunter's viewmodel/HUD/input. This loader closes that gap: on a genuine `SelectedHunter` change it tears down the old hunter's client stack (via [[HunterClientState]]) and re-runs every hunter entry script — the new current hunter boots, the others gate straight back out.

This script lives directly under `StarterPlayerScripts` (not a per-hunter folder) so it persists across switches and is never torn down.

## What it does
1. Establishes the INITIAL hunter without treating the join-time boot as a swap — `HunterGate.GetSelectedHunter(player, 30)` yields until the attribute replicates, so `lastHunter` is the hunter the player actually spawned as
2. On `player:GetAttributeChangedSignal("SelectedHunter")`, if the value genuinely changed, runs `performSwap()`
3. `performSwap()` — guarded by a `swapping` flag: (1) calls [[HunterClientState]]`.teardown()` (runs every registered cleanup, bumps generation), then (2) disables every collected entry script, yields a frame, and re-enables them. Toggling `Disabled` false→true→false restarts a LocalScript from the top, forcing its hunter gate to re-evaluate
4. `collectEntryScripts()` — gathers every enabled `LocalScript` under the per-hunter folders in `HUNTER_FOLDERS` (`Dust`, `Vesper`, `Bram`, `Fortuna`) plus the top-level scripts named in `EXTRA_ENTRY_SCRIPT_NAMES` (`HunterFirstPersonClient`, listed last so it re-runs after the folders — its `ClientViewModel` ChildAdded is what per-hunter animation scripts bind to). Authored-disabled helpers (e.g. Fortuna's `CardsClientDebug`) are skipped so the disable/re-enable cycle never forces them ENABLED on a swap

## Dependencies
- **Requires:** [[HunterClientState]] (`.teardown()`), [[HunterGate]] (`.GetSelectedHunter()`)
- **Required by:** Nobody

## Connections
### RemoteEvents
None

### BindableEvents
None

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[HunterClientState]] | `.teardown()` | Run every booted hunter's cleanup before re-running the entry scripts |
| [[HunterGate]] | `.GetSelectedHunter()` | Read the initial hunter so join-time boot isn't mistaken for a swap |
