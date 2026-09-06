---
tags: [client, localscript, ui, collection, notifications]
path: game.StarterGui.CollectionGui.NewItemClient
type: LocalScript
lines: 468
---

# NewItemClient

The COLLECTION dot chain: a plain red bubble on the bottom-bar COLLECTION button, on each of the six tabs, on a hunter tile and on the individual item tile, so following the bubbles always ends on the item and never on a dead end.

## What it does
1. **Owns the whole feature as a sibling layer — no tab module knows it exists.** It finds tiles by the attributes the tab modules already set (`SkinName`, `WeaponSkinName`, `TitleId`, `BoostId`, `EmoteId`) and by the hunter grid's `<digit>Name` frame names, and reads view state off the `AbilitiesSelectedHunter` / `AbilitiesLeftMode` attributes Panels and HuntersTab already publish. Six modules with load-bearing require order therefore stayed untouched. CollectionSoundClient is the same shape of layer, one script over
2. An item becomes seen the instant the cursor enters its tile, or on tap on a touchscreen. Both `MouseEnter` and `Activated` are bound unconditionally rather than behind a device test, so a hybrid laptop gets both
3. The item kind is re-read from the tile at hover time rather than captured at bind time, so a tile the grid rebuilds under a different hunter can never mark the wrong item seen
4. **Parent bubbles are derived, never marked.** A tab bubble is the OR of its children; the hunter tile's single bubble means "this hunter, or anything under her", so hovering her clears only her own flag and the bubble survives while a skin of hers is still unseen
5. The right tab row is **scoped to the selected hunter**, because that is what the grids under it show — Vesper having a new skin belongs on Vesper's tile, not on `1Skins` while Dust is selected. `1Hunters` aggregates Skins, Weapon and Titles across all hunters, because Panels hides the whole right tab row outside HUNTERS mode and the chain would otherwise dead-end there
6. Marks are cleared locally on hover (optimistic, so the bubble goes with no round trip) and flushed as a batch on a 0.5s heartbeat and on menu close, keeping a cursor swept across a grid to one fire rather than one per tile
7. Re-asks for state whenever an ownership push arrives, which is how a mid-session grant — a purchase, a chest, a battle-pass claim — gets its bubble without this script knowing any of those systems exist
8. **Geometry lives entirely on the authored templates.** `NewItemDot` for tiles and tabs, `NewItemDotTitle` for title rows: a title row is full-width but only ~46px tall and the aspect constraint clamps to the shorter axis, so one size cannot serve both. Re-typing size in code is what made the first draft render rectangles instead of circles
9. Every bubble is presence-only — no glyph, no count. The `TextLabel` is deleted from all of them

## Dependencies
- **Requires:** [[TitlesConfig]]
- **Required by:** Nobody (top-level LocalScript)

## Connections
### RemoteEvents
| Remote | Direction | Other script |
|--------|-----------|-------------|
| `NewItemStateEvent` | ← Server | [[NewItemService]] the unseen set |
| `RequestNewItemState` | → Server | [[NewItemService]] pull half of the handshake, plus a re-ask on every ownership change |
| `MarkItemsSeen` | → Server | [[NewItemService]] batched hovered items |
| `SkinDataEvent` | ← Server | [[DataService]] listened to only as a signal that ownership moved; triggers a re-ask |
| `TitleStateEvent` | ← Server | [[CollectionService]] same, for titles |
| `EmoteStateEvent` | ← Server | [[CollectionService]] same, for emotes |
| `BoostStateEvent` | ← Server | [[BoostService]] same, for boosts |

### BindableEvents
None

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[TitlesConfig]] | `HunterOf()` | Titles are stored by id alone but are hunter-locked, so this is the only way to attribute one to a hunter — without it the hunter tile could not aggregate its titles |
