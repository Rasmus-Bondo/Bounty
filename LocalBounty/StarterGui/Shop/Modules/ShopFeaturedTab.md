---
tags: [client, modulescript, ui, shop, trading-post, featured, limited]
path: game.StarterGui.Shop.Modules.ShopFeaturedTab
type: ModuleScript
lines: 519
---

# ShopFeaturedTab

The FEATURED tab of the Trading Post — the Fortuna bundle panel, the Prestige Card panel and the sale countdown.

## What it does
1. API: `park / revealOnOpen(delayLeft, delayRight) / show / transitionOut / hideRoot / fadeOut / isBusy`
2. Bundle panel: `OwnsFortuna` → `OWNED`; else price via `Core.getProductPrice(StoreConfig.DeveloperProducts.Fortuna.ProductId)` (the bundle product, `TokenBonus 400`), `PURCHASE` → `MarketplaceService:PromptProductPurchase` + `UIPurchaseButtonPrompt`; a token burst plays on `purchaseSuccess` for that product id
3. Prestige panel (`LimitedStockConfig.Items.PrestigeCard`): `AmountLeft` as `n / Cap` from the `limited` signal, `PURCHASE` → `RequestLimitedPurchaseEvent(itemId)`, `OWNED` / `SOLD OUT` states; hover tween in/out (friend's review comments 1 and 3)
4. `EndSaleTimer` counts down to `DEADLINE_UNIX` (1788566400 — Sat 2026-09-05 00:00 UTC / 02:00 CEST, extended a week on 2026-08-29 from 1787961600, which had already elapsed); the Featured out-transition fades both panels before the next tab shows

## Dependencies
- **Requires:** [[ShopCore]], [[ShopState]], [[StoreConfig]], [[LimitedStockConfig]], [[AnimationLoader]]
- **Required by:** ShopController

## Connections
### RemoteEvents
| Remote | Direction | Other script |
|--------|-----------|-------------|
| `RequestLimitedPurchaseEvent` | → Server | [[LimitedStockService]] reserve a Prestige Card unit |

### BindableEvents
None

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[ShopCore]] | `bindPurchaseHover / tweenFade / getProductPrice` | presentation + price |
| [[ShopState]] | `ownsHunter / limitedRemaining / on / fire` | state + remotes |
| [[StoreConfig]] | `DeveloperProducts.Fortuna` | bundle product |
| [[LimitedStockConfig]] | `Items.PrestigeCard` | cap + product |
| [[AnimationLoader]] | `load` | featured rig idle |
