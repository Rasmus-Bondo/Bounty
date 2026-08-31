---
tags: [server, modulescript, store, monetization, analytics]
path: game.ServerScriptService.PlayerServices.StoreService
type: ModuleScript
lines: 176
---

# StoreService

Handles Robux developer-product purchases via `MarketplaceService.ProcessReceipt` — hunter/character unlocks, cosmetic bundles, Token bundles, and a legacy Cash product.

## What it does
1. Sets `ProcessReceipt` to grant purchases: character products (`GrantCharacter` + optional bundled `TokenBonus`), Token products (`AddTokens`), and Cash products (`AddCash`)
   - **The legacy Cash product branch (`3601170442`) was deleted 2026-08-03.** It returned `PurchaseGranted` while never calling `AddCash`, so it consumed the receipt permanently and granted nothing. Both client ends had already gone with the old `ShopMenuGui` — the LocalScript that prompted the product, and the `PlayCurrencyCounter` remote it listened on (remote deleted in the same pass)
   - An unrecognised product id now falls through to `NotProcessedYet`, which Roblox retries indefinitely rather than finalising. **Product `3601170442` must stay deactivated on the Creator Hub** — reactivating it without restoring a handler would leave buyers in permanent receipt limbo
2. Looks up products in [[StoreConfig]] `DeveloperProducts` / `TokenProducts` by `ProductId`
3. Awards currency through [[DataService]] `AddTokens` / `AddCash(player, amount, reason, itemSku)`, tagging the IAP economy Source with a **human-readable SKU** (never the raw product id): `iap_char_bonus` SKU `<Character>_TokenBonus` for a character's bundled tokens, `iap_token_bundle` SKU `Tokens_<amount>` (e.g. `Tokens_250`) for a token pack, `iap_cash_bundle` SKU `Cash_<amount>` (e.g. `Cash_1000`) for a cash pack
4. Grants cosmetic bundles from [[StoreConfig]] `BundleProducts`, matched by `getBundleByProductId`. Walks the bundle's `Grants` list, calling [[DataService]] `GrantHunterSkin` / `GrantWeaponSkin` per entry; any failure returns `NotProcessedYet` rather than banking a half-bundle. Both grant calls are idempotent, so a re-buy and a Roblox retry land on the same owned state. The only bundle today is `LetTheHuntBegin` (product `3708064902`)
5. Routes limited-run products to [[LimitedStockService]] `handleReceipt`, matched by [[LimitedStockConfig]] `getByProductId`. The stock check already happened at reserve time, before the prompt opened — returning `NotProcessedYet` on a full run would charge the player for nothing
6. Starts [[LimitedStockService]] before installing `ProcessReceipt`, since a limited receipt routes straight into it
7. Refreshes each player's `RegionalPriceLevel` attribute via `MarketplaceService:GetUsersPriceLevelsAsync`
8. Fires `ShopPurchaseSuccessEvent` to the client on a granted purchase, tagged with the currency kind (`Character`, `Bundle`, `LimitedItem`, `Tokens`, `Cash`)

## Dependencies
- **Requires:** [[DataService]], [[StoreConfig]], [[LimitedStockConfig]], [[LimitedStockService]]
- **Required by:** Main

## Connections
### RemoteEvents
| Remote | Direction | Other script |
|--------|-----------|-------------|
| `ShopPurchaseSuccessEvent` | → Client | Success FX signal (event created/shared by [[DataService]]); fired to the shop UI |

### BindableEvents
None

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[DataService]] | `OwnsCharacter()`, `GrantCharacter()`, `AddTokens()`, `AddCash()`, `GrantHunterSkin()`, `GrantWeaponSkin()` | Grant purchased characters, bundle cosmetics, and award Token/Cash bundles (with IAP economy tagging) |
| [[StoreConfig]] | `DeveloperProducts`, `TokenProducts`, `CashProducts`, `BundleProducts`, `getBundleByProductId()` | Product id → reward lookup |
| [[LimitedStockConfig]] | `getByProductId()` | Recognise a limited-run product id in the receipt |
| [[LimitedStockService]] | `Start()`, `handleReceipt()` | Grant the limited item and count the sale |
