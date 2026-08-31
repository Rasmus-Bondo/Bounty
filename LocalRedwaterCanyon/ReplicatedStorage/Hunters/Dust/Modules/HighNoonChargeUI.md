---
tags: [client, modulescript, ui, ultimate]
path: game.ReplicatedStorage.Hunters.Dust.Modules.HighNoonChargeUI
type: ModuleScript
lines: 177
---

# HighNoonChargeUI

OOP controller for the ultimate charge meter UI, displaying charge progress and ready state.

## What it does
1. Tracks ultimate charge (0-100) and ready state
2. Finds UI elements in `PlayerGui.TemplateGameGui.Canvas.UltimateFrame.MainFrame` (Dust clones `ReworkedHunterGui` and renames it `TemplateGameGui`, so the name is the old one but the shape is the reworked one)
3. Updates `CooldownBar` size to show charge progress as a shrinking overlay
4. Updates `Cooldown` text to show percentage, hidden when fully charged
5. Drives the [[UltimateReadyFX]] ember halo from `IsReady`. This is Dust's **only** ready signal — step 4 hides the label outright at full charge, so before the halo existed a charged High Noon looked identical to an empty one. The fx is rebuilt inside `GetUI` alongside the cached parts, since reaching that path means the HUD was recreated and the previous instance is holding destroyed instances. Note `GetUI` resolves `PlayerGui.TemplateGameGui` by name, so this never attaches to another hunter's HUD
6. Pops the tile via [[HunterHudBump]] on the **rising edge** to full charge. `Update` runs on every charge push, so the previous `IsReady` is captured before it is overwritten and the bump fires only on the transition. Rebuilt inside `GetUI` alongside the fx, for the same reason; because `self` is not recreated on respawn, a player who respawns already holding a charged High Noon does not get a second pop
7. `Initialize` retries UI lookup up to 30 times with 0.25s delay for late-loading GUIs

Dust needs the pop more than the other three: step 4 blanks the label at full charge, so without it the only thing marking the transition is a border fading in behind the tile.

## Dependencies
- **Requires:** [[UltimateReadyFX]], [[HunterHudBump]]
- **Required by:** HighNoonClient

## Connections
### RemoteEvents
None

### BindableEvents
None

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[UltimateReadyFX]] | `.new()`, `:SetReady()`, `:Destroy()` | Ember border on the ult icon at full charge |
| [[HunterHudBump]] | `.new()`, `:Play()`, `:Destroy()` | Pops the ult tile on the rising edge to full charge |
