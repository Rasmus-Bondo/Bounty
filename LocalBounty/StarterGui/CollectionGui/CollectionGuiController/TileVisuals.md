---
tags: [client, modulescript, ui, collection, layout, sfx]
path: game.StarterGui.CollectionGui.CollectionGuiController.TileVisuals
type: ModuleScript
lines: 303
---

# TileVisuals

How the menu FEELS: the tween helper every animation goes through, hover/click SFX, selection and lock states on a grid tile, tab highlighting, and the left-grid cell sizing pass.

## What it does
1. `playShopSound` — clones from `SFX.ShopMenuSFX` and **sets `SoundGroup = SoundService.SFX` explicitly**, so it obeys the player's SFX + Master sliders. There is no `SoundService.Volume` and "Master" is faked by multiplying into each group, so an ungrouped Sound escapes all four settings sliders
2. `tween` — **one tween per instance**: a second tween on the same object cancels the first, so a fast hover/unhover cannot leave two tweens fighting over one property
3. `baseThickness` — memoizes a stroke's AUTHORED thickness so a bump is always relative to the design value rather than to whatever the stroke happens to be showing mid-tween
4. `getOrCreateScale`, `setTileSelected` (gradient swap + stroke bump + slight grow), `applyTileLockState` (dimmed viewport + faded caption)
5. `setTabSelected` / `highlightMenuTab` — a tab's gold highlight is its `BackgroundFrame` UIGradient. The designer only baked gold into the **first** tab of each menu row, so the gradient colour is swapped for the highlight to follow whichever tab is selected. `TAB_SELECTED_GRADIENT` must stay identical to the gold authored on those tabs and on the EQUIP button, which no code touches — nothing enforces it, so a drift shows as two different golds on screen
6. `fitLeftGrid` — **one pass for all three left tabs.** HUNTERS, BOOSTS and EMOTES are the same authored ScrollingFrame (the latter two are clones), so one function sizes all three and a card is the same size whichever tab you are on

⚠ **NEVER ASSIGN AN ABSOLUTE `UIStroke.Thickness` IN THIS GUI.** The authored value on `IconDisplay` is `0.03` — setting one to `2` renders a ~300px ring that swallows the whole canvas.

### fitLeftGrid, in detail
Nothing in Studio is edited — the authored cell stays `0.4 × 0.125` scale and the canvas stays `2`; this overrides both at runtime, so the authored file is still the design source and the panel adapts per screen. It fixes two things the authored setup gets wrong on a real display:
- **A scale cell resolves against the CANVAS, not the visible window,** and the canvas is authored two screens tall to hold four hunters. So `0.125` drew each card at a *quarter* of the panel height and `0.4` at 40% of its width. Converting the cell to pixels off the window lands at ~96% width and a **+35% card area**
- **That two-screen canvas also let the player drag four hunters clean off the top** of the frame into the empty half below, leaving a blank panel with a scrollbar. Fitting the canvas to real content height means a grid that fits cannot be scrolled at all

**Cell size derives from the window's WIDTH and the canvas from the content's HEIGHT, so neither feeds back into the other** — that is the trap, and the reason the emote-only ancestor of this function existed. Three load-bearing details: height is `1.08 ×` the cell *width* (never the panel height, since `IconDisplay` is `RelativeXX`); the scrollbar lane is reserved whether or not the bar shows (reserving it only when *visible* is a **loop** — hiding it widens the cells, which grows the content, which brings the bar back), but the lane is given up whenever keeping it would cost the second column — both candidates are measured from the same settled window width, so that choice cannot oscillate; and the grid drops to **one column** rather than let a tap target fall under 44px on the smallest handsets.

## Dependencies
- **Requires:** [[Refs]]
- **Required by:** CollectionGuiController, HuntersTab, SkinsTab, TitlesTab, BoostsTab, EmotesTab, Panels

## Connections
### RemoteEvents
None

### BindableEvents
None

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[Refs]] | `shopMenuSFX`, `SoundService`, `TweenService`, `LOCKED_TINT`, `isTouchOnly` | Sound source, tween service, lock tint, touch detection |
