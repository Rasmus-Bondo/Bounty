---
tags: [client, modulescript, ui, character-select]
path: game.StarterPlayer.StarterPlayerScripts.CollectionClient.HunterList
type: ModuleScript
lines: 133
---

# HunterList

Hunter (character) list panel. Renders one viewport icon per character frame in the ScrollingFrame, wires SelectButton clicks to an onSelect callback, and animates the selected entry's stroke + scale.

## What it does
1. `HunterList.new(scrollingFrame, charactersFolder, selectedStroke, onSelect)` iterates ScrollingFrame children, strips a leading number from each frame name to find the character (e.g. "1Dust" → "Dust"), and for each match builds an entry record
2. For each entry: finds `IconDisplay`/`Icon Display`, finds `SelectButton`, finds the character's Default model in ReplicatedStorage.Characters; renders the model into the icon via [[ViewportIcon]]
3. Stores `entries[characterName] = { Frame, IconDisplay, SelectButton, Scale (UIScale, lazily created) }`
4. Wires `selectButton.MouseButton1Click` → `onSelect(characterName)` if the caller supplied a callback
5. `:updateSelection(currentCharacterName)`: for every entry, looks up the icon's UIStroke, toggles its `SelectGradient` / `UIGradient`, tweens stroke thickness between `HUNTER_STROKE_NORMAL_THICKNESS` and `HUNTER_STROKE_SELECTED_THICKNESS` (via [[Tween]] + `Config.hunterStrokeTweenInfo`), tweens the entry's UIScale to 1.04 if selected or 1.0 otherwise, and disables the panel-level `selectedStroke`

## Dependencies
- **Requires:** [[Config]], [[Tween]], [[ViewportIcon]]
- **Required by:** CollectionClient

## Connections
### RemoteEvents
None

### BindableEvents
None

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[Config]] | stroke thicknesses + `hunterStrokeTweenInfo` | Selected-stroke animation params |
| [[Tween]] | `Tween.run()` | Cancel-on-replace stroke + scale tweens |
| [[ViewportIcon]] | `render()` | Draw character model into each entry's IconDisplay |
