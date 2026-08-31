---
tags: [client, localscript, ui, shop, trading-post, menu]
path: game.StarterGui.Shop.ShopController
type: LocalScript
lines: 494
---

# ShopController

Entry script of the Trading Post (`StarterGui.Shop`, shipped 2026-08-23 in place of `ReworkReworkedBuyMenu`) — owns open/close, the tab row, the Content fit, the top-bar currency chips and every hand-off to the lobby menu.

## What it does
1. `StarterGui.Shop` is `Enabled = false` at rest (`DisplayOrder 0`, `ScreenInsets.None`, `IgnoreGuiInset`). MenuHandlerScript enables it for the TRADING POST tab and disables it for any other; this script reacts to `Enabled` (`onEnabled` / `onDisabled`) and never enables itself. Tree: `Canvas` (full-screen gradient backdrop) → `Canvas.Content` (the 16:9 band that holds `TopFrame`, `FeaturedCanvas`, `HuntersCanvas`, `WeaponsCanvas`, `ExtrasCanvas`, `BundlesCanvas`); `Templates` (card templates the tabs clone, authored `Visible = false`); `Modules` (the nine ModuleScripts this requires)
2. **Content fit** (`updateContentFit`): `Content` is sized to `h = min(vh, vw / (16/9))` and centred, then shrunk/pinned so the STORE bar top (`0.0785·h`) clears `GuiService:GetGuiInset().Y` and the draw bottom (`0.761·h`) clears the bottom-nav line (`0.80·vh − 2px`). Re-run on `ViewportSize`. This is what keeps the phone bar from sliding under the topbar and stops 4:3 tablets squashing the tiles
3. Tabs `1FEATURED` `2HUNTERS` `3WEAPONS` `4EXTRAS` `5BUNDLES` — hover/selection glow via ShopCore hitboxes, click runs `leaveCurrentShopContent` (the current tab's `transitionOut`) then the next tab's `show`
4. `openShop(targetIndex)` / `closeShop(instant)` / `prepareClosedState` — staggered reveal of the chrome, tab row and the requested tab; everything tweens 0.85× faster than the prototype
5. **Top-bar chips** are live: balances bound to `leaderstats.Cash` / `.Tokens` via ShopCore; the `+` buttons call `requestVault(mode)` → ShopVaultController. The `CurrencyVaultRequested` bindable on `CurrencyHudGui` is answered here only while the shop is `Enabled` (MenuHandlerScript answers it otherwise, mutually exclusive guards)
6. `Vault.onBack`: with a `VaultReturnMenuFrame` attribute → fire `MenuNavigateRequested(frame)` (the player came from Home / Bounty Pass); else `Vault.closeToShop` back to the tab it left
7. `onEnabled` consumes **attributes on this ScreenGui, cleared on read**: `VaultOnOpen` (`Cash`/`Tokens`) + `VaultReturnMenuFrame` (MenuHandlerScript, a `+` pressed outside the shop → straight into the vault, no reveal); `TradingPostRequestedTab` (`1Featured`/`2Hunters`/`3Skins`/`4Emotes`/`5Bundles` — the OLD tab names, mapped here) + `AccessoryModeRequest` + `RequestedHunter/RequestedHunterSkin/RequestedWeaponHunter/RequestedWeaponSkin/RequestedTitle/RequestedEmote` (CollectionGuiController's Shop module deep links), forwarded to the tab's `requestDeepLink`
8. `onDisabled` → instant close + `Vault.teardown`; `BlackBarMenuCovered` → `Vault.teardown`; `MainMenuGui.Enabled = false` → disables the shop
9. Plays `SFX.UIButtonClick.UIPurchaseSucces` on every `purchaseSuccess` signal (ShopState) while open
10. **Stand + camera** (`applyStandForTab`, via ShopStandDisplay): every `showTab` moves the camera for the tab (`CameraPartHunterCloseup` for HUNTERS / WEAPONS, `CameraPartFeaturedCloseup` otherwise) and, off tabs 2–4, puts Fortuna back on the stand; the item tabs place their own selection and EXTRAS places the equipped hunter (`ShopExtrasTab.show`). An ordinary `onEnabled` calls `Stand.assumeFeatured()` (the entry cinematic left Fortuna there), the vault entry `Stand.forget()`, `prepareClosedState` → `Stand.release()`; `Vault.onBack` re-applies the item close-up instantly under the bars

## Dependencies
- **Requires:** [[ShopCore]], [[ShopState]], [[ShopFeaturedTab]], [[ShopHuntersTab]], [[ShopWeaponsTab]], [[ShopExtrasTab]], [[ShopBundlesTab]], [[ShopVaultController]], [[ShopStandDisplay]]
- **Required by:** Nobody (top-level LocalScript)

## Connections
### RemoteEvents
None directly — every remote goes through ShopState.

### BindableEvents
| Bindable | Direction | Other script |
|----------|-----------|-------------|
| `MenuNavigateRequested` | → | [[MenuHandlerScript]] vault GO BACK returning to Home / Bounty Pass |
| `BlackBarMenuCovered` | ← | [[MenuHandlerScript]] tears the vault down under a covered transition |
| `CurrencyVaultRequested` | ← | [[CurrencyHudController]] `+` pressed while the shop is already open |

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[ShopCore]] | `Core.*` | hitboxes, fades, sounds, chips |
| [[ShopState]] | `State.on("purchaseSuccess")` | success SFX |
| [[ShopFeaturedTab]] | `show / transitionOut / hideRoot / revealOnOpen / park` | tab 1 |
| [[ShopHuntersTab]] | `show / transitionOut / hideRoot / requestDeepLink` | tab 2 |
| [[ShopWeaponsTab]] | `show / transitionOut / hideRoot / requestDeepLink` | tab 3 |
| [[ShopExtrasTab]] | `show / transitionOut / hideRoot / requestDeepLink / onShopOpened / onShopClosed` | tab 4 |
| [[ShopBundlesTab]] | `show / transitionOut / hideRoot` | tab 5 |
| [[ShopVaultController]] | `Vault.open / request / teardown / closeToShop / onBack` | currency vault |
| [[ShopStandDisplay]] | `focusForTab / showFeatured / assumeFeatured / forget / release` | the stand model and camera per tab |
