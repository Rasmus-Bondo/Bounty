---
tags: [shared, modulescript, store, monetization, limited]
path: game.ReplicatedStorage.Config.LimitedStockConfig
type: ModuleScript
lines: 60
---

# LimitedStockConfig

Catalog of items sold in a capped, globally-limited run — currently only Fortuna's Prestige Card (100 units, Robux).

## What it does
1. Declares `Items[itemId]` with `Cap`, `Kind`, `Character`, `SkinName`, `ProductId` and `Title`; `PrestigeCard` is Cap 100, product `3612243340`
2. `Cap` is the restock lever — raising it reopens the item, since the DataStore counter keeps counting from where it stopped
3. `getByProductId(productId)` reverse lookup for `ProcessReceipt`, which only receives a product id
4. `findForWeaponSkin(character, skinName)` tells the shop whether a gun-skin entry is a limited item, keyed by the same pair the weapon-skin catalog already uses
5. `ReservationSeconds` (180) bounds how long a unit is held between pressing BUY and the receipt landing

## Notes
Bounty-only — Redwater has no `StoreConfig` either and never sees stock, reading ownership straight off the profile's `OwnedWeaponSkins`. **Not** on the mirrored-module list; do not copy it to Redwater.

## Dependencies
- **Requires:** Nothing
- **Required by:** LimitedStockService, StoreService, HuntersBuyController

## Connections
### RemoteEvents
None

### BindableEvents
None

### Direct require()
None
