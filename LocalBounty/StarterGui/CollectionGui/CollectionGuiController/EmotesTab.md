---
tags: [client, modulescript, ui, collection, emotes, viewport, performance]
path: game.StarterGui.CollectionGui.CollectionGuiController.EmotesTab
type: ModuleScript
lines: 903
---

# EmotesTab

The EMOTES view. The left grid shows every emote as the **equipped hunter performing it**; the right panel fills with one full-body looping viewport per unlocked skin of that hunter.

## What it does
1. `build()` — clones `HuntersFrame` → `EmotesFrame` (retitled "EMOTES"), captures the pre-built right `EmoteFrame` tile as a template, and builds the locked-emote shop button. Publishes the frame and that button for Panels and the EQUIP registration
2. **The figure IS the tile.** Each tile renders the equipped hunter+skin **frozen on a signature frame** of that emote — seeked to `0.45` of the clip length, past the wind-up and inside the recognisable part — over a warm top-lit dust disc. This replaced flat purple circles with two-letter initials, which made 18 emotes indistinguishable; the initials survive only as a low-opacity watermark shown while a tile has no rig. Camera factor is `0.64` vs the right panel's `0.62`, measured against the four hunters' ~5.9-6.0 stud resting height: framing is computed from the **resting** box (the pose has not loaded yet), so it needs slack for poses that reach past it — a best-fit 0.58 clips an overhead lasso throw, and past ~0.72 the figure is too small to tell two emotes apart
3. **Rig render window.** A full rig per tile × 18 emotes is too much for a phone, so **only tiles within one row's margin of the visible scroll window own a viewport**; the rest fall back to disc + watermark. Recomputed off `CanvasPosition`, coalesced to one pass per frame, and re-cut whenever `fitLeftGrid` resizes the cells (resizing moves every tile). `noRig` latches a failed template lookup so a missing model is not retried every scroll frame
4. **Animation on demand.** Only the **selected** tile and the one under the **cursor** play; every other rig holds its pose. Touch has no hover, so there selection alone drives playback
5. `select()` — rebuilds the right scroll with one looping viewport per unlocked skin; selecting a skin points the middle in-world dummy at that hunter/skin, which plays the emote live
6. `renderGrid()`, `updateInfo()`, `clearViewports()`, `resetWindow()`, `playRipple()` / `cancelRipple()`
7. Registers the `"Emotes"` EQUIP pair, the `EmoteStateEvent` handler and the startup warm-up

⚠ **`playing` is the set of tracks allowed to run, and `freezePose` CONSULTS it.** The deferred pose-seek waits on the asset load and could otherwise resolve *after* a tile has been told to play — freezing the very tile being shown off. Keep that set in sync anywhere a track is created, recycled, hovered or selected.

**Lock look:** a locked emote's figure is dimmed to `(122, 118, 112)`, deliberately **lighter** than the shared `LOCKED_TINT (70, 70, 70)`: 16 of the 18 emotes are locked, and at the shared value the whole grid went to near-black blobs with the poses — the only thing telling two emotes apart — unreadable.

**Corner badge:** one slot at the tile's top-right (outside the 0.85-scale circle, clear of the caption) shows the Cash icon + price when locked and purchasable, a **BOUNTY PASS** text pill (no currency icon — there is no price, and a Cash badge would be a lie) when pass-exclusive, or a gold **EQUIPPED** pill. An emote can never be both.

**Shop hand-off button:** a locked emote gets a second button directly under EQUIP, a clone of `PreviewButton` (which keeps the authored gradient/stroke/shadow and avoids assigning a `UIStroke.Thickness` by hand). It **borrows PREVIEW's slot**, which is free because PREVIEW is hidden on this tab — so the two can never both be visible.

⚠ **No `UIStroke` is created anywhere in the tile code.** The authored thickness in this GUI is `0.03`, so a plain `1` renders a ring hundreds of pixels thick.

## Historical note
The payload and the grid helpers used to share one `emoteState` table, because the old single-file controller had no top-level locals left. That came with a standing warning that the `EmoteStateEvent` handler must assign **fields** and never replace the table — replacing it silently dropped `freezePose`/`queueWindow`/`resetWindow` and the tab would keep rendering but stop posing and recycling rigs. The payload now lives on [[State]] and the helpers are ordinary module locals, so that hazard is gone.

## Dependencies
- **Requires:** [[Refs]], [[State]], [[Catalog]], [[Viewport]], [[TileVisuals]], [[EquipButton]], [[Preview]], [[Shop]], [[EmoteConfig]]
- **Required by:** CollectionGuiController, Panels

## Connections
### RemoteEvents
| Remote | Direction | Other script |
|--------|-----------|-------------|
| `EquipEmoteEvent` | → Server | [[CollectionService]] equips the selected emote |
| `RequestEmoteState` | → Server | [[CollectionService]] asks for a fresh owned/equipped state on open / entering EMOTES / at startup |
| `EmoteStateEvent` | ← Server | [[CollectionService]] pushes `{ owned, equipped }`; re-renders the grid + equip button |

### BindableEvents
None

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[Refs]] | `huntersFrame`, `emoteFrame`, `previewButtonFrame`, the three emote remotes | The frames it clones and what it fires |
| [[State]] | `isEmoteOwned()`, `emoteEquipped`, `selectedEmote`, equipped hunter/skin | Which hunter performs, and lock state |
| [[Catalog]] | `getSkinList()`, `getSkinTemplate()`, `prettySkinName()` | The unlocked-skin list for the right panel |
| [[Viewport]] | `cleanModel()`, `playEmoteAnim()`, `playIdle()`, `clear()` | Rig preparation and posing |
| [[TileVisuals]] | `fitLeftGrid()`, `setTileSelected()`, `tween()`, `playShopSound()` | Card sizing, selection, SFX |
| [[EquipButton]] | `register()`, `refresh()` | The EQUIP / LOCKED pair and the shop button's visibility |
| [[Preview]] | `show()` | The middle dummy plays the emote live |
| [[Shop]] | `navigate()` | The locked-emote hand-off |
| [[EmoteConfig]] | `list()`, `get()`, `isValid()`, `isDefaultOwned()`, `isPurchasable()`, `unlockTextOf()` | Catalog order, display name, animation, badge text |
