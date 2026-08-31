---
tags: [client, modulescript, ui, character-select, carousel, raycast]
path: game.StarterPlayer.StarterPlayerScripts.CollectionClient.Reel
type: ModuleScript
lines: 306
---

# Reel

All carousel button state and rendering. Generates one part/model per skin slot under `SkinMenu.Buttons`, smooths position/scale/transparency every frame against the carousel position, handles raycast-to-index click selection, and animates the whole reel in or out.

## What it does
1. `Reel.new(opts)` captures the SkinMenu template, buttons folder, pivot, name-gui parent + template, a `getDisplayName(character, skin)` function, and a `shouldKeepGuiEnabled()` predicate (used by hide animations to decide whether to disable a name GUI after fading)
2. Caches the template's original Size and its CFrame relative to the pivot so per-frame placement is a single ring-angle multiplication
3. `:build(skins, characterName, carouselPosition)` clones the template per slot, sets attributes (CharacterName, SkinName, Subfolder, ModelName, RealSkinIndex, SlotIndex, VisualIndex), places the clone, creates a [[NameGui]] for each, and hides the original template
4. `:update(dt, carouselPosition, canMutateVisuals)` per-frame: for every button computes circular distance, moves it to its target CFrame on the ring, exponentially smooths transparency (TRANSPARENCY_SMOOTHING = 12) and scale toward [[CarouselMath]]'s target curves, applies the selected-button bounce shrink while bounceTime > 0, mutates BasePart Transparency / CanQuery / CanTouch (gated by `canMutateVisuals`) and the name-gui transparency
5. `:playBounce(index)` arms the bounce shrink for the button at `index` for `Config.bounceDuration`
6. `:setVisible(isVisible)` fades the whole reel in/out via [[Tween]] (Transparency tweens on each BasePart, toggles CanQuery/CanTouch, fades the name GUIs to 1 and disables them after the close duration if `shouldKeepGuiEnabled()` returns false)
7. `:raycastIndex(screenPosition, camera)` runs a `Workspace:Raycast` with an Include filter on the buttons folder and walks up the ancestor chain to map the hit instance back to its slot index
8. `:clear()` destroys all current buttons + name GUIs and resets all internal tables; called by `:build` so rebuilds are clean

## Dependencies
- **Requires:** [[CarouselMath]], [[Config]], [[NameGui]], [[Tween]]
- **Required by:** CollectionClient

## Connections
### RemoteEvents
None

### BindableEvents
None

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[CarouselMath]] | `signedCircularOffset`, `circularDistance`, `targetTransparency`, `targetScale`, `applyBounce`, `clamp` | Per-frame slot placement and visual targets |
| [[Config]] | `angleSpacing`, `visibleRange`, `normalScale`, `selectedScale`, `bounceDuration`, `bounceShrinkAmount`, surface durations | Layout + animation params |
| [[NameGui]] | `create()`, `setTransparency()` | Per-button skin-name overlay |
| [[Tween]] | `Tween.run()` | Cancel-on-replace tween of part Transparency for show/hide |
