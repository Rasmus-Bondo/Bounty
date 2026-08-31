---
tags: [client, modulescript, ui, collection, references]
path: game.StarterGui.CollectionGui.CollectionGuiController.Refs
type: ModuleScript
lines: 127
---

# Refs

Every instance the Collection menu touches, resolved once, plus the menu's tuning constants. Lookup only — no behaviour, no state, no connections.

## What it does
1. Resolves the services, `localPlayer` / `playerGui`, and the whole authored GUI tree under `CollectionGui` (both canvases, both menu-tab rows, `SkinFrame` / `EmoteFrame`, the EQUIP and PREVIEW buttons, the `1Default` / `2Skin` design placeholders)
2. Resolves `ReplicatedStorage.Characters`, `ReplicatedStorage.WeaponSkins`, the `ShopMenuSFX` folder, and `CameraFolder.CameraPartActualCollection` (a Persistent model, so streaming-safe)
3. Resolves every remote. **The skin/character remotes use a plain `WaitForChild`** because DataService always creates them; **the boost, emote and title remotes use a 10s timeout** so a service that failed to start can never block the hunters/skins side of the menu from opening — every reader of those three groups nil-checks
4. Holds the tuning constants: `REVEAL_DELAY` (1.8, matching MenuHandlerScript's `CAMERA_MOVE_DURATION`), `IDLE_ANIMATION_ID`, the weapon-preview distance band, `WEAPON_FALLBACK_HUNTER`, `LOCKED_TINT` and `LOCKED_TEXT_TRANSPARENCY`
5. `isTouchOnly` — true on a phone/tablet with no keyboard. Several grids drop their scrollbar there: a finger drags the grid directly, and the authored `ScrollBarInset.None` would draw the bar on top of the tiles rather than beside them

⚠ **The right canvas's middle tab DISPLAYS "WEAPONS" but is named `2Weapon`,** and `"Weapon"` is the key Panels, EquipButton and SkinsTab all branch on. The label and the identifier are deliberately different — renaming the instance to match the text breaks `Refs.weaponTab` and takes the tab with it.

**Requiring this module is what blocks on the authored tree existing**, so everything else can assume its references are present. Do not move a `WaitForChild` out of here into a tab module — State's prefetch has to connect ahead of the heavy startup work (the four hunter viewports), not ahead of the tree lookups.

## Dependencies
- **Requires:** [[WaitForRequired]]
- **Required by:** every other Collection module

## Connections
### RemoteEvents
None (resolves the instances; the tabs do the firing)

### BindableEvents
None

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[WaitForRequired]] | `waitForRequired(workspace, "CameraFolder")` | Resolve the Persistent camera model without the engine's 5s "Infinite yield possible" warning. `CameraPartActualCollection` beneath it needs no helper — a Persistent model's descendants arrive with it |
