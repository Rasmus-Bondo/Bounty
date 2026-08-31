---
tags: [client, modulescript, ui, collection, hunters]
path: game.StarterGui.CollectionGui.CollectionGuiController.HuntersTab
type: ModuleScript
lines: 115
---

# HuntersTab

The hunter grid on the left canvas, and the selection everything else on the right canvas hangs off.

## What it does
1. `build()` — the four tiles are **AUTHORED in Studio** (`1Dust`, `2Vesper`, `3Bram`, `4Fortuna`) rather than generated. This fills them in, strips the digit prefix off the name, renders a closeup viewport, and **hides any tile whose hunter has no model** in `ReplicatedStorage.Characters`. Also hooks `Owns<Hunter>` attribute changes to the lock refresh, since DataService flips those on purchase. Card sizing is `TileVisuals.fitLeftGrid`, shared with BOOSTS and EMOTES
2. `select(hunterName, forcedSkin)` — sets the hunter and derives the skin, gun skin and title from what is equipped, falling back to Default / the first gun when the equipped one has no model. Publishes `AbilitiesSelectedHunter` on the ScreenGui, which AbilitiesPanelClient reads (an attribute, not a code link)
3. `resetToEquipped()` — defaults the selection to the equipped hunter, falling back to Dust if it has no model. Runs on every menu open
4. `updateSelection()`, `refreshLocks()` — registered with [[EquipButton]]

⚠ `HuntersTab.rebuildRight` is **injected** by Panels. Selecting a hunter has to rebuild whichever right-hand view is showing, but choosing between the skins grid and the titles list is panel-level dispatch. **This module deliberately does NOT require either of those tabs** — doing so would make the hunter grid depend on every tab it can hand off to.

## Dependencies
- **Requires:** [[Refs]], [[State]], [[Catalog]], [[Viewport]], [[TileVisuals]], [[EquipButton]], [[Preview]]
- **Required by:** CollectionGuiController, Panels

## Connections
### RemoteEvents
None — this tab fires no remotes; equipping a skin is the skins tab's job

### BindableEvents
None

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[Refs]] | `hunterScroll`, `screenGui`, `localPlayer` | The grid, the attribute publish target |
| [[State]] | selection + equipped fields, `isHunterOwned()` | What is selected and owned |
| [[Catalog]] | `getHunterTemplate()`, `getSkinTemplate()`, `getWeaponSkinTemplate()`, `getWeaponSkinList()` | Validating the derived selection |
| [[Viewport]] | `renderHunter()` | The tile closeups |
| [[TileVisuals]] | `setTileSelected()`, `applyTileLockState()`, `fitLeftGrid()` | Selection, lock look, card sizing |
| [[EquipButton]] | `refresh()`, `registerLockRefresh()` | Button state and its own lock refresher |
| [[Preview]] | `show()`, `model` | Re-preview on selection change |
