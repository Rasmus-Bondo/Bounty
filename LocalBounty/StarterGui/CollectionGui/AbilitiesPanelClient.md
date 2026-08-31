---
tags: [client, localscript, ui, collection, hunter-abilities]
path: game.StarterGui.CollectionGui.AbilitiesPanelClient
type: LocalScript
lines: 47
---

# AbilitiesPanelClient

Shows the authored `AbilityPanelNew` frame belonging to the hunter selected on the HUNTERS tab of the Collection menu.

## What it does
1. Waits for `AbilityPanelNew` (Frame sibling of CanvasLeft/CanvasRight in CollectionGui) and indexes its four authored per-hunter child frames — `Dust`, `Fortuna`, `Vesper`, `Bram` — by name, hiding all of them
2. All panel content (ABILITIES header, passive text, and the three Q/E/F ability cards with icon, title and description) is authored in the instances — this script writes no text, it only toggles which hunter frame is visible
3. Watches two `CollectionGui` attributes set by the Collection menu (Panels sets AbilitiesLeftMode, HuntersTab sets AbilitiesSelectedHunter): `AbilitiesSelectedHunter` (string — selected hunter name) and `AbilitiesLeftMode` (string — "Hunters" | "Boosts" | "Emotes" | ""); shows the panel only when both are set and mode == "Hunters"
4. A hunter with no authored frame leaves the whole panel hidden rather than showing the previously selected hunter's abilities
5. `refreshVisibility()` is connected to both `GetAttributeChangedSignal` callbacks and also runs once at startup, in case a hunter was already selected before this script connected
6. **Owns `Visible` only — never `Position`.** Panels slides `AbilityPanelNew` in from the left alongside `CanvasLeft` and holds its home position in that module's `reveal` table, so nothing here may move the panel. Panels also defers clearing `AbilitiesLeftMode` until after its exit tween, because this script hides the panel the moment the attribute goes blank

## Dependencies
- **Requires:** Nothing
- **Required by:** Nobody (top-level LocalScript)

## Connections
### RemoteEvents
None

### BindableEvents
None

### Direct require()
None
