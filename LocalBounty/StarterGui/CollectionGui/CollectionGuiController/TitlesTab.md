---
tags: [client, modulescript, ui, collection, titles]
path: game.StarterGui.CollectionGui.CollectionGuiController.TitlesTab
type: ModuleScript
lines: 413
---

# TitlesTab

The TITLES view on the right canvas: a vertical list of wide gold-text rows, one per title the selected hunter can wear. Titles are **hunter-locked**, so this is a flat list — nothing from another hunter appears here.

## What it does
1. `build()` — clones `SkinFrame` into `TitlesFrame` (inheriting the panel background, MenuInfo styling and scroll chrome), destroys its square icon grid and swaps in a vertical `UIListLayout`. Sets a **slim 6px bar with its own lane** (`VerticalScrollBarInset = ScrollBar` takes the width out of the canvas instead of drawing over it, so a full-width row can never end up under the slider)
2. `rebuild()` — one row per title, sized from an **offset canvas computed per hunter**. A ScrollingFrame child's Scale resolves against the *canvas*, so `AutomaticCanvasSize` can never settle on a canvas that fits scale-sized rows: it stopped short and clipped the last title. `canvasH` = rows + gaps + margins, never below 1 (a canvas shorter than the window is clamped up to it, and rows measured against the smaller figure would stretch); rows and the list gap divide by `contentH` (the canvas minus its UIPadding) while the margins divide by the whole canvas. `CanvasSize`'s own scale would resolve against the frame's *parent* — a third box again — hence offset, re-derived from a `CanvasUnits` attribute whenever `AbsoluteSize` changes
3. `makeTitleRow` — rows are **scale-based in height** (`ROW_H = 0.17`) so they shrink to fit a smaller mobile panel. Rendered through [[TitleRenderer]] so each previews in its actual cosmetic style. **No UIScale pop on selection**, unlike the skin tiles: a tile has slack around it, but a row is already as wide as the scroll allows, so a 3% grow pushed ~7px out of each side. **Rows opt OUT of the title aura** (`TitleAura = false`) — at ~18-24px the bloom is a hard word-shaped dilation that reads as a second, blurred copy behind the real title, worst on a phone. The pixel caps cannot express "none" because `strokePx` clamps *up* to `MinStrokePx`
4. `select()`, `updateSelection()`, `clear()`
5. Registers the `"Titles"` EQUIP pair, the `TitleStateEvent` handler and the startup ownership warm-up

## This is a WARDROBE, not a shop
It shows locked titles and previews them but never sells one — buying happens in the Trading Post ACCESSORIES tab. **Rows carry NO price badge:** there is one hand-off per tab and it is the shared EQUIP button ([[Shop]]). So a row does not state a price and nothing here can drift out of step with the card the button lands on. The old `RequirementBadge` and its separate route were deleted 2026-07-28.

## ⚠ The card carries the lock, the title never does (`ROW_STATE`)
Every other grid marks unowned by dimming the **item**. A title cannot be dimmed: its styling — gradient, flames, chrome — **is** the product, so fading it hides the thing being sold. The row's **chrome** carries it instead and the text renders identically in both states.

**It is a COLOUR split, not just a transparency one.** The first cut fired both states off one shared brown at different transparencies and read as too subtle. The two states now sit on **opposite sides of the panel's own background** `RGB(48,33,23)`:

| | Row colour | Fill (idle → sel) | Stroke (idle → sel) | Stroke tint |
|---|---|---|---|---|
| Owned | `RGB(92,60,32)` warm lit brown — reads *raised* | `0.18` → `0.02` | `0.35` → `0` | title accent |
| Locked | `RGB(12,11,10)` cold near-black — reads as a *hole* | `0.42` → `0.26` | `0.62` → `0.35` | accent lerped `0.7` toward `ROW_GREY` |

Four things this needs to stay correct:
- **Selection is lock-relative, not absolute.** Each state brightens by its own step; with one shared selected value, selecting a locked row would brighten it into looking owned — the marker would vanish exactly when the player is looking hardest at it
- **Applied in BOTH `makeTitleRow` and `setTitleRowSelected`,** colour included. The selection copy reads ownership **live**, so a purchase landing mid-selection is picked up — which is why the colour has to move with the transparency there too
- **`RowAccent` holds the UNBLENDED accent.** Re-deriving from `stroke.Color` would blend an already-blended colour and walk a locked row's stroke to flat grey over repeated selections
- **Colours are assigned, not tweened.** A `Color3` tween would cross-fade a locked row through mid-brown, which reads as a flicker on a fast click


**Season titles are filtered out of the rows unless owned** (2026-08-27). `rebuild()` walks `Catalog.getTitleList` and keeps an entry only when `TitlesConfig.IsHiddenUntilOwned(id)` is false or `State.isTitleOwned(id)` is true. Done **here** rather than in Catalog, which deliberately knows nothing about ownership, and **before** `#list` sizes the canvas — filtering afterwards would leave a blank row's worth of scroll per hidden title. With none owned each hunter's list is exactly what it was before season titles existed: Dust 8, Vesper 7, Bram 7, Fortuna 6.
## Dependencies
- **Requires:** [[Refs]], [[State]], [[Catalog]], [[TileVisuals]], [[EquipButton]], [[Preview]], [[Shop]], [[TitleRenderer]], [[TitlesConfig]]
- **Required by:** CollectionGuiController, Panels

## Connections
### RemoteEvents
| Remote | Direction | Other script |
|--------|-----------|-------------|
| `EquipTitleEvent` | → Server | [[CollectionService]] equips a title for a hunter (`hunter, titleId`) |
| `RequestTitleState` | → Server | [[CollectionService]] asks for a fresh owned-title set on TITLES-tab open and once at startup |
| `TitleStateEvent` | ← Server | [[CollectionService]] pushes `{ owned }`; rebuilds the rows and refreshes the button so a newly owned title flips from PURCHASE to EQUIP |

### BindableEvents
None

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[Refs]] | `skinFrame`, `rightBackground`, the three title remotes | The frame it clones and what it fires |
| [[State]] | `isTitleOwned()`, `getEquippedTitle()`, `selectedTitle` | Row state, EQUIPPED, and the ownership half of the season-title filter |
| [[TitlesConfig]] | `IsHiddenUntilOwned()` | Drops unowned season titles before the rows are built |
| [[Catalog]] | `getTitleList()` | The per-hunter catalog |
| [[TileVisuals]] | `tween()`, `baseThickness()`, `playShopSound()` | Row animation and equip SFX |
| [[EquipButton]] | `register()`, `refresh()` | The TITLES pair |
| [[Preview]] | `show()`, `model` | The nameplate preview updates on selection |
| [[Shop]] | `titleUnlock()`, `navigate()` | The locked-title hand-off |
| [[TitleRenderer]] | `apply()`, `accentOf()` | Renders each row in its cosmetic style and tints the row stroke |
