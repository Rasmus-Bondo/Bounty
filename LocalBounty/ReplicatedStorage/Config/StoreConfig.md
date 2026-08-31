---
tags: [shared, modulescript]
path: game.ReplicatedStorage.Config.StoreConfig
type: ModuleScript
lines: 96
---

# StoreConfig

Static config table for all purchasable products in the lobby store.

## What it does
1. Defines `DeveloperProducts`: Fortuna bundle (ProductId 3605676843, 400 token bonus) and FortunaHunter standalone (ProductId 3606060477)
2. Defines `TokenProducts`: six token pack tiers (250 → 12 000 tokens, ProductIds 3605730604–3605730979)
3. Defines `CashProducts`: six cash pack tiers (1 000 → 40 000 Cash, ProductIds 3611384860–3611385405)
4. Defines `HunterCashPrices`: Fortuna costs 4 000 Cash
5. Defines `FreeCharacters`: Dust, Vesper, and Bram are free
6. Defines `BundleProducts`: Robux bundles that grant cosmetics rather than a hunter, so they cannot ride `DeveloperProducts` (whose only verb is `GrantCharacter`). Each entry carries a `ProductId`, a `Title` and an ordered `Grants` list of `{ Kind, Character, SkinName }`. `LetTheHuntBegin` (ProductId 3708064902) grants the `FrostveilVesper` hunter skin and the `Frostpiercer` weapon skin, both flagged `SoldSeparately`
7. `getBundleByProductId(productId)` — reverse lookup for `ProcessReceipt`, which only receives a product id
8. `isBundleExclusive(characterName, skinName, kind)` — is this cosmetic sold only inside a bundle? Derived from the `Grants` lists rather than a second table, so a new bundle cannot forget to register. Bundle cosmetics sit in the ordinary catalog folders, so without this check they reach `PurchaseSkinEvent`'s 1 000-Cash default. A grant flagged `SoldSeparately` opts out: the bundle still grants it, but it is also on the shelf on its own, so calling it exclusive would make the shop draw BUNDLE over a price the server will happily take (both `LetTheHuntBegin` grants are flagged since 2026-08-29)

## Dependencies
- **Requires:** Nothing
- **Required by:** TradingPostController, HuntersBuyController, StoreService, DataService, BundleHomeController, State

## Connections
None — pure data module.
