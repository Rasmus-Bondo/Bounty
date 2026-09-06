---
tags: [shared, modulescript, config, shop, trading-post, bundles, economy]
path: game.ReplicatedStorage.Config.BundleConfig
type: ModuleScript
lines: 216
---

# BundleConfig

Catalog for the Trading Post's BUNDLES tab: what each bundle contains, its sticker price in Tokens, and the rule that lowers that price when the player already owns part of it.

## What it does
1. `Bundles` keyed by id, each carrying `Card` (the authored frame name under `BundlesCanvas.Bundles`), `Title`, `Description`, `Price` (Tokens) and `Grants`. Grant kinds: `HunterSkin` / `WeaponSkin` (ownable, `Character` + `SkinName`), `Cash` (`Amount`), `Boost` (`BoostId` + `Count`) and `Chest` (`Count` standard lootbox chests). Only the skin kinds are ownable, so Cash, boosts and chests never move the price
2. Three bundles ship: `OutlawStarterPack` (250 Tokens: 2,500 Cash + 1x `xp_25_30` + 2x `cash_25_30` + 3 chests), `FrostHunterBundle` (1,200) and `FrostWeaponBundle` (1,800)
3. `priceFor(bundle, isOwned)` is the discount rule and the only place it exists: `rate = Price / fullValue`, then `price = rate x (value of the items NOT already owned)`, floored to a round 10. Owning none returns the sticker verbatim; owning everything returns 0, which the shop draws as OWNED. Callers supply `isOwned` — the client from `ShopState.ownsSkinRecord`, the server from the profile — so both sides land on the same number
4. Item values are read from `SkinCatalog.TokenPrice` rather than restated, so repricing a skin reprices every bundle holding it. An item with no `TokenPrice` is still granted but contributes nothing to the discount
5. `list()` (ordered ids, with stragglers appended), `get`, `isOwnable`, `valueOf`, `fullValue`, `labelOf` (display name for the panel's contents list)
6. `isPurchased(purchased, bundleId)` is the one-per-account test both surfaces share: no bundle sells twice. The skin bundles were already unrepeatable by accident (owning every skin in one drives `priceFor` to 0), but the starter pack grants nothing ownable, so the purchase record BundleService keeps in `data.PurchasedBundles` is the only thing that retires it
7. `Slot` on a grant names the authored label inside the card's ViewportFrame that shows its amount, so the card art cannot disagree with the grant
8. A bundle's `Description` never names its chests. The panel already lists every grant, and a region-restricted account has both the chest line and the card's chest viewport taken away — a description that promised them would survive both

Bounty-only — not mirrored. Redwater sells nothing.

## Dependencies
- **Requires:** [[SkinCatalog]]
- **Required by:** ShopBundlesTab, BundleService

## Connections
### RemoteEvents
None

### BindableEvents
None

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[SkinCatalog]] | `getSkin / getWeaponSkin` | each item's own Token price, for the discount arithmetic |
