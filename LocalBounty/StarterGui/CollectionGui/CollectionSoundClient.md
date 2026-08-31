---
tags: [client, localscript, ui, collection, sfx]
path: game.StarterGui.CollectionGui.CollectionSoundClient
type: LocalScript
lines: 65
---

# CollectionSoundClient

Central hover/click audio for every button in the Collection menu, authored or built at runtime.

## What it does
1. Walks `CollectionGui`'s descendants and binds every `GuiButton`, then keeps binding via `DescendantAdded` — which is why the runtime-generated grids (boost tiles, emote tiles, title rows) get audio without any tab module wiring it
2. Plays `Unhover` on `MouseEnter` (with a ±4% random `PlaybackSpeed` so a fast sweep across a grid does not sound like one repeated click) and `TabsSelect` on `Activated`
3. **Skips the EQUIP button on click** — a successful equip plays its own validated `Equip` sound from the tab that performed it, so this would double up on a real equip and would also play on a *refused* one
4. Honours a `CollectionSoundSilent` attribute on any button that wants to opt out, and marks what it has bound with `CollectionSoundBound`
5. Sets `SoundGroup = SoundService.SFX` on every clone, so the audio obeys the player's SFX + Master sliders. There is no `SoundService.Volume` and "Master" is faked by multiplying into each group, so an ungrouped Sound escapes all four settings sliders
6. Gates everything on `screenGui.Enabled`, so a button bound while the menu is hidden cannot fire

Uses a weak-keyed table for bound buttons, so destroyed tiles are collected rather than leaking as the emote grid recycles rigs.

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
