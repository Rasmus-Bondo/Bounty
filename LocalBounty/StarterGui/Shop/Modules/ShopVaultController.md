---
tags: [client, modulescript, ui, shop, trading-post, currency, vault]
path: game.StarterGui.Shop.Modules.ShopVaultController
type: ModuleScript
lines: 994
---

# ShopVaultController

The currency vault — the kept door cinematic and coin piles with `StarterGui.CurrencyShop` as the overlay, and the Robux offer steppers with a BUY button.

## What it does
1. API: `Vault.open(mode, returnTab) / request(mode) / teardown() / closeToShop(cb) / isOpen / isBusy / isEntered`, `Vault.onBack` (set by ShopController), `Vault.returnTab`
2. Cinematic moved verbatim from the old TradingPostController: black bars, vault door animation (`81446915207239`), fade push, coin piles, sprinkle FX on Cash / Tokens `purchaseSuccess`. Chrome snapshot hides `CanvasBottom`, `Fade`, `InviteFriendsGui.Canvas`, `BattlepassGui.Canvas` and the shop canvas while inside and restores them on any exit (shop close, `BlackBarMenuCovered`, re-open all bump a generation counter)
3. Overlay: `CurrencyShop.Canvas` — `SideFrame` (chips + `ReturnFrame` GO BACK), `BottomFrame` (offer steppers + `BuyButton`, a clone of the prototype's `BuyButtonRobux`). Reveal order side → row → BUY; steppers clamp, no wrap, dim at the ends (`setStepperDimmed`); offers from `StoreConfig.TokenProducts` (`1Offer`..`6Offer`) / `CashProducts` **The overlay is squashed on a tablet, and only there** (`fitOverlayShape`): each pill pairs a `RelativeYY` icon with an amount label placed by a fraction of the pill’s WIDTH, and `CurrencyShop.Canvas` is a bare full-screen frame with no aspect lock — so at 4:3 the box comes out 25 % narrower for its height and the coin closes on the first digit. `SideFrame` and `BottomFrame` have their Y scale multiplied by `min(1, aspect / (16/9))` on every `ViewportSize` change, which holds the whole column — pills, the `+`/`-` buttons, GO BACK, BUY and the gaps between them — at its 16:9 proportions. Same clamp `ShopController.updateContentFit` puts on the shop’s own `Content`, which is why the shop’s chips need nothing of their own. `min()`, so phones and 16:9-or-wider desktops get the authored size unchanged; Size is owned here, Position belongs to the reveal
4. BUY → `MarketplaceService:PromptProductPurchase(offer.ProductId)` + `UIPurchaseButtonPrompt`; the success SFX and the sprinkle ride the `ShopPurchaseSuccessEvent` (via ShopState)
5. `waitForRequired` guards the Camera / CameraPart / door instances under streaming

## Dependencies
- **Requires:** [[ShopCore]], [[ShopState]], [[StoreConfig]], [[WaitForRequired]]
- **Required by:** ShopController

## Connections
### RemoteEvents
None directly — `purchaseSuccess` arrives via ShopState.

### BindableEvents
None

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[ShopCore]] | `bindPlusButtonHover / bindReturnButtonHover / bindPurchaseHover / tweenFade / playUISound` | presentation |
| [[ShopState]] | `on("purchaseSuccess")` | sprinkle + SFX |
| [[StoreConfig]] | `TokenProducts / CashProducts` | offers |
| [[WaitForRequired]] | `waitForRequired` | streamed instances |
