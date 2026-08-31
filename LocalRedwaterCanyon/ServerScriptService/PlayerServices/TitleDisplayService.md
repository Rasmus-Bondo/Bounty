---
tags:
  - server
  - modulescript
  - cosmetics
path: game.ServerScriptService.PlayerServices.TitleDisplayService
type: ModuleScript
lines: 122
---

# TitleDisplayService

Publishes each player's equipped cosmetic title to a replicated `EquippedTitle` player attribute so Redwater's UI surfaces can show it without touching profile data.

## What it does
1. Titles are equipped **per hunter** in Bounty (`profile.EquippedTitles[hunter]` → title id). In Redwater a player's hunter is fixed for the match (the `SelectedHunter` attribute), so `resolveLabel` reads that hunter's equipped id from `DataService.getPlayerData(player).EquippedTitles` and resolves it to display text via [[TitlesConfig]]'s `LabelById`. `""` means no title equipped
2. `applyTitle` writes the resolved label to the player's `EquippedTitle` attribute **and the raw title id to a companion `EquippedTitleId` attribute** (server-set → replicates to all clients). Returns false while the profile is still loading so the caller can retry
3. `EquippedTitleId` is what the client-side TitleRenderer uses to pick the title's cosmetic STYLE (fire, smoke, glow, …) — an attribute read, not a code-level link. It is an optimisation, not a requirement — the renderer falls back to resolving a style from the label text — so the label stays authoritative for display
4. On join (`setupPlayer`): seeds both attributes to `""` immediately so consumers always read a string; then spawns a retry loop (up to ~20s) that publishes the real values once the ProfileService handoff after the teleport completes
5. Re-resolves and republishes whenever the player's `SelectedHunter` attribute changes (`GetAttributeChangedSignal`)
6. `Start()` (called from Main right after `DataService.Start()`) wires existing players + `PlayerAdded`, and cleans up the per-player hunter-changed connection on `PlayerRemoving`

The published `EquippedTitle` / `EquippedTitleId` attributes are consumed **implicitly** (attribute read, not a code-level link) by the three Redwater title surfaces: VictoryShowcaseClient (match summary), HealthBarController (overhead health bar), and KillCamClient (kill cam).

## Dependencies
- **Requires:** [[DataService]] (`getPlayerData`), [[TitlesConfig]] (`LabelById`)
- **Required by:** Main

## Connections
### RemoteEvents
None

### BindableEvents
None

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[DataService]] | `DataService.getPlayerData()` | Read `EquippedTitles` (per-hunter equipped title id) from the player's profile |
| [[TitlesConfig]] | `TitlesConfig.LabelById` | Resolve an equipped title id to its display label |
