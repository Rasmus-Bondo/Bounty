---
tags: [client, modulescript, ui, collection, skins, weapon-skins]
path: game.StarterGui.CollectionGui.CollectionGuiController.SkinsTab
type: ModuleScript
lines: 266
---

# SkinsTab

The SKINS and WEAPON views on the right canvas. They are **ONE authored ScrollingFrame** shared between both tabs, so they share the tile template, the lock states and the scrollbar handling — only the catalog they list and the viewport renderer differ.

## What it does
1. `init()` — hides the authored `1Default` / `2Skin` design placeholders (they are the templates this grid clones from, never shown as themselves), and on touch sets `ScrollBarThickness = 0`
2. `rebuild()` — one tile per skin (Default + `Characters.<Hunter>.Skin` children, alphabetical) or per gun-skin Model in `WeaponSkins.<Hunter>` (default gun first), with a prettified caption, a viewport, and the lock tint. Writes the `MenuInfo` header
3. `select()` / `selectWeapon()`, `updateSelection()`, `clear()`
4. `refreshLocks()` — registered with [[EquipButton]]. A tile can be either a hunter skin or a gun skin, told apart by which attribute it carries
5. Registers **both** the `"Skins"` and `"Weapon"` EQUIP pairs, since both are this one grid

**On touch the scrollbar is hidden:** a finger drags the grid directly, and with the authored `ScrollBarInset.None` the 12px bar draws **on top of** the right-hand tiles rather than beside them, so on mobile it was a slider sitting over the art. Desktop keeps it — a mouse has nothing else to grab.

A borrowed fallback gun (a hunter with no `WeaponSkins` folder) always reads EQUIPPED and never fires the equip remote, because there is nothing to equip server-side. Per-hunter weapon framing comes from the shared WeaponDisplayConfig, which this tab reaches only through [[Viewport]] — it does not require that config itself.

## Dependencies
- **Requires:** [[Refs]], [[State]], [[Catalog]], [[Viewport]], [[TileVisuals]], [[EquipButton]], [[Preview]], [[Shop]]
- **Required by:** CollectionGuiController, Panels

## Connections
### RemoteEvents
| Remote | Direction | Other script |
|--------|-----------|-------------|
| `CharacterSelectEvent` | → Server | [[PartyService]] swaps the lobby dummy model |
| `EquipSkinEvent` | → Server | [[DataService]] persists EquippedCharacter/EquippedSkin |
| `EquipWeaponSkinEvent` | → Server | [[DataService]] persists the equipped gun skin per hunter |

### BindableEvents
None

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[Refs]] | `skinScroll`, `skinMenuInfo`, `skinTileTemplate`, the three equip remotes | The grid and what it fires |
| [[State]] | selection/equipped fields, `isSkinOwned()`, `isWeaponSkinOwned()`, `isHunterOwned()` | Lock and EQUIPPED state |
| [[Catalog]] | `getSkinList()`, `getWeaponSkinList()`, `getSkinTemplate()`, `hasOwnWeaponFolder()`, `prettySkinName()` | What to list, and whether the gun is borrowed |
| [[Viewport]] | `renderHunter()`, `renderWeapon()` | The tile art |
| [[TileVisuals]] | `setTileSelected()`, `applyTileLockState()`, `playShopSound()` | Selection, lock look, equip SFX |
| [[EquipButton]] | `register()`, `registerLockRefresh()`, `refresh()` | Both EQUIP pairs |
| [[Preview]] | `show()`, `model` | Re-preview on selection change |
| [[Shop]] | `skinUnlock()`, `activateSkinUnlock()` | The locked-item hand-off — `skinUnlock` for the button wording, `activateSkinUnlock` for the click (never `navigate` directly: a group perk opens a join prompt in place instead of navigating) |
