---
tags: [client, modulescript, ui, shop, trading-post]
path: game.StarterGui.Shop.Modules.ShopCore
type: ModuleScript
lines: 916
---

# ShopCore

Shared presentation toolkit of the Trading Post — the prototype's helper functions, lifted out so the five tab modules and the controller share one copy.

## What it does
1. Handles: `Core.gui / canvas / content / templates / localPlayer / playerGui`, the `isOpen` / `opening` flags, and colour constants (`ROBUX_ICON`, `OWNED_TEXT_COLOR`, `FEEDBACK_OK`, `FEEDBACK_ERR`, `CASH_COLOR` gold, `TOKENS_COLOR` magenta). The `Templates` Frames are hidden at load (they are GuiObjects in a Folder under the ScreenGui and rendered at the top-left) and `cloneTemplate(t)` un-hides each clone
2. Tweens: `tween / cancelTween(instance, props?)` keyed **per instance AND property set** (a fade on a frame no longer cancels its slide — the prototype's instance-only key left every slide-in panel at its start offset), fade maps `captureFadeTargets / setFade / tweenFade / removeFadeBranch` (alpha 0 = authored, 1 = invisible), `offset`
3. Sounds: `playUISound(name)` clones from `ReplicatedStorage.SFX.UIButtonClick` with `SoundGroup = SFX`; `playUIHover` is rate-limited to 45 ms
4. Prices: `formatCash` (comma grouping), `getProductPrice(productId)` memoises `MarketplaceService:GetProductInfoAsync`; `attachRobuxPrice(label)` draws a Robux price as `rbxasset://textures/ui/common/robux.png` + an `AutomaticSize.X` number in a centred `UIListLayout` row beside the label, mirroring the label's colour / transparency / Visible / UIStroke (`set(price|nil|string)` / `clear()`) — the  glyph renders with different metrics in Studio and the live client, so glyph-in-text prices never centred
5. Buttons: the prototype's Frames-as-buttons get a runtime `Hitbox` TextButton via `ensureHitbox`; `bindPurchaseHover(button, onActivate, {oneShot})` returns a controller `{hitbox, label, reset, disarm, isArmed, setEnabled, setText, setRobuxPrice}` driving the PurchaseableGradient / UnHoverGradient / OwnedGradient layers; `bindReturnButtonHover`, `bindActionHover`, `bindCurrencyPurchaseHover` / `bindPlusButtonHover` for the chip `+`, `setStepperDimmed`
6. Chips: `bindLeaderstat(statName, label)` with the change pop
7. Cards: `numbered(folder)` ordered card lists, `cardCanvas / worldOf / modelOf / pivotOf`, `bindCard(frame, cb, {isBusy, isSelected, dropdownSound})` with `ripple`, `restoreCardChrome / restoreSkinChrome`, `getCardState / forgetCardState`, `stroke`, `setCardStatus(frame, {kind = owned|price|text})`, `currencyIconImage`
8. `registerBusy / isAnyBusy` so a tab mid-transition blocks tab clicks
9. `fitGridCanvas(scroll, count)` — the authored card grids are `CanvasSize {0,0},{2,0}` + cells `{0.5,0},{0.25,0}` with `AutomaticCanvasSize = None`; CanvasSize scale is relative to the frame's PARENT and the cells' scale to the CANVAS, so the authored canvas holds exactly 8 cards. This keeps the card at its authored size and stretches the canvas to the rows built (`canvasScale = max(authored, rows × cardScale)`, `cellY = cardScale / canvasScale`), stashing the authored values as attributes so repeat builds do not compound
10. Scroll bar lane — at load every `ScrollingFrame` under `Content` gets `VerticalScrollBarInset = ScrollBar` (also authored on all seven), and on a touch-only device `ScrollBarThickness = 0`. The grid cells are `0.5` of the canvas, so the right column ends flush with the canvas edge and the authored `ScrollBarInset.None` drew the 5px bar across those cards. Taking the lane out of the canvas is safe here because canvas height is scale-of-parent and cannot feed back into the width; on touch the bar goes entirely and a finger drags the grid instead

## Dependencies
- **Requires:** Nothing
- **Required by:** ShopController, ShopFeaturedTab, ShopHuntersTab, ShopWeaponsTab, ShopExtrasTab, ShopVaultController, ShopStandDisplay, CurrencyHudController (the Bounty Pass chips are clones of the Trading Post pill, so its `+` binds through this module)

## Connections
### RemoteEvents
None

### BindableEvents
None

### Direct require()
None
