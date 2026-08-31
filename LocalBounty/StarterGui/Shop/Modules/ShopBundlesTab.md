---
tags: [client, modulescript, ui, shop, trading-post, bundles]
path: game.StarterGui.Shop.Modules.ShopBundlesTab
type: ModuleScript
lines: 453
---

# ShopBundlesTab

The BUNDLES tab of the Trading Post — the row of bundle cards, the detail panel on the right, and the discount a part-owned bundle gets. Every bundle sells once per account.

## What it does
1. API: `show / transitionOut / hideRoot / isBusy / isVisible`
2. The cards are hand-authored instances, not template clones: posed rigs in a WorldModel, a per-card viewport camera and its own background art. `BundleConfig.Card` ties a card to the bundle it sells; an authored card with no config entry is hidden rather than sold, and a config entry with no card warns
3. Card and panel prices both come from `BundleConfig.priceFor`, fed `ShopState.ownsSkinRecord` — the raw profile buckets, so the number shown is the number BundleService will charge. A bundle reads OWNED on the card and swaps the buy button for `OwnedButton` for either of two reasons, and the footnote names which: the account has already bought it (`ShopState.isBundlePurchased`, the one-per-account rule BundleService enforces), or every item in it is already owned
4. The panel writes the bundle title, its description plus a line per grant with the ones already owned marked, the discounted price, and a footnote naming how many of the items are already owned when the price has dropped
5. The buy button is the purple `BuyButtonTokens` (UI_STYLE_GUIDE 5.4b — the button family is colour-coded by currency and magenta is Tokens); the gold `BuyButtonCash` sibling is hidden once at load because bundles are sold for Tokens only. Purchase fires `PurchaseBundleEvent(id, price)`, shows PURCHASING… and re-arms on the next `skins` or `bundles` push, the `purchaseSuccess` cue, or a 5 s timeout
6. `fitBundleRow` is the horizontal counterpart of `Core.fitGridCanvas`: the authored card is 0.30 of BundlesCanvas and three of them are wider than the row, so the cards shrink to fit while that keeps them near their authored size and only scroll past that point. The scrollbar is taken away when the row fits, because ScrollingDirection XY otherwise draws a full-width bar with no travel in it
7. A viewport camera is built only where the card authored a `BundleCameraCFrame` attribute — the starter pack has none and keeps the engine's own auto-fit, which is what it was framed against

The prototype's `BundleViewportController` was dropped on import; its camera binding is step 7 here.

## Dependencies
- **Requires:** [[ShopCore]], [[ShopState]], [[BundleConfig]]
- **Required by:** ShopController

## Connections
### RemoteEvents
| Remote | Direction | Other script |
|--------|-----------|-------------|
| `PurchaseBundleEvent` | → Server | [[BundleService]] buy the selected bundle |

### BindableEvents
None

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[ShopCore]] | `bindCard / bindPurchaseHover / ripple / tweenFade / stroke / formatCash` | presentation |
| [[ShopState]] | `ownsSkinRecord / isBundlePurchased / on / fire` | ownership, the one-per-account record, repaints and the purchase remote |
| [[BundleConfig]] | `list / get / priceFor / labelOf / isOwnable` | catalog and the discount rule |
