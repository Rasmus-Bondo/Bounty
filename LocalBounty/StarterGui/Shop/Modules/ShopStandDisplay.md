---
tags: [client, modulescript, ui, shop, trading-post, stand, camera]
path: game.StarterGui.Shop.Modules.ShopStandDisplay
type: ModuleScript
lines: 542
---

# ShopStandDisplay

The Trading Post's 3D preview on the lobby's featured stand (`workspace.FeaturedItems.Stand`) and the camera that frames it — the old shop's "selected skin in the centre of the screen", brought back after the 2026-08-23 playtest.

## What it does
1. `showHunter(hunter, skin)` — clones `ReplicatedStorage.Characters.<Hunter>.Default.*` / `.Skin.<Skin>`, strips scripts, anchors the root only, faces `CameraPartFeatured`, grounds it with the per-hunter `HUNTER_STAND` offsets (Dust −4.75 / Fortuna −4.95 from the feet; Vesper / Bram −4.8 from the bounding box — copied from the old HuntersBuyController HUNTERS table), parents it to the Stand and plays the shop idle (`rbxassetid://507766666`) through AnimationLoader (real fetch status, seeded time offset)
2. `showWeapon(hunter, skin)` — clones `ReplicatedStorage.WeaponSkins.<Hunter>.<Skin>`, normalises to `WeaponDisplayConfig.displayScale`, poses it by `explicitOrient` or the shared look-at pose (+ `rotationOffset`, Fortuna's cards near edge-on), heights it by `standCenterOffset` or bottom + `standRaise`, Dust nudged 1.25 studs left, then bobs it on RenderStepped and re-bases the pivot on the bounding-box centre so drag-to-spin turns like a turntable
3. `showFeatured()` — Fortuna back on the stand via `FeaturedSequence.ShowDefaultFortuna()`; a no-op while `standState` already reads `"featured"`. Both show* calls run `FeaturedSequence.Cleanup()` first (removes the cinematic's Fortuna and props; it never touches camera or lighting)
4. Camera: `focusItems` → `CameraPartHunterCloseup`, `focusFeatured` → `CameraPartFeaturedCloseup`, `focusForTab(index, instant)` picks by tab (2 / 3 = items); 0.42 s Quint tween or instant (used under black bars)
5. Lifecycle: `clear()` destroys only this module's model (Fortuna is FeaturedSequence's); `release()` = clear + cancel the camera tween (shop close — a tween still in flight would fight MenuHandlerScript's snap under its bars); `assumeFeatured()` marks the Fortuna the entry cinematic left so the FEATURED landing does not re-place her; `forget()` for the vault entry where nothing is known to be on the stand
6. `playEmote(animationId)` / `stopEmote()` — an Action-priority looped clip on the stand hunter (EXTRAS > EMOTES) over the idle, loaded through AnimationLoader on its own thread with a token + model check on return; `clear()` stops it. `makePreviewRig(hunter, skin)` hands out a cleaned, unparented hunter clone for a ViewportFrame WorldModel (the EXTRAS emote cards). The EXTRAS tab keeps the equipped hunter on the stand for as long as it is up (ShopExtrasTab.show; ShopController's `applyStandForTab` skips tab 4)
7. Drag-to-spin: `UserInputService.InputBegan/Changed/Ended` (mouse button 1 / one touch, 0.45° per px), ignored when `gameProcessedEvent` (a card or button press) or while the shop is closed

## Dependencies
- **Requires:** [[ShopCore]], [[WaitForRequired]], [[AnimationLoader]], [[FeaturedSequence]], [[WeaponDisplayConfig]]
- **Required by:** ShopController, ShopHuntersTab, ShopWeaponsTab, ShopExtrasTab

## Connections
### RemoteEvents
None

### BindableEvents
None

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[ShopCore]] | `Core.isOpen / Core.gui` | drag gate |
| [[WaitForRequired]] | `(workspace, "FeaturedItems")`, `(featuredItems, "Stand")`, `(workspace, "CameraFolder")` | the Stand is Persistent inside a plain Folder, so it lands after its container |
| [[AnimationLoader]] | `load(animator, id, {Priority, Looped})` | the stand idle and the EMOTES clip, with a real fetch status |
| [[FeaturedSequence]] | `Cleanup / ShowDefaultFortuna` | hand the stand between the cinematic's Fortuna and this module's model |
| [[WeaponDisplayConfig]] | `get(hunter)` | gun pose / scale / height on the stand (shared with the Collection menu) |
