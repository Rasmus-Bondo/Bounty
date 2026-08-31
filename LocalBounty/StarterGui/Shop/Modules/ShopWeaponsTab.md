---
tags: [client, modulescript, ui, shop, trading-post, weapons, skins]
path: game.StarterGui.Shop.Modules.ShopWeaponsTab
type: ModuleScript
lines: 662
---

# ShopWeaponsTab

The WEAPONS tab of the Trading Post — one gun per hunter, its skin grid, the token purchase panel and the Prestige Card limited path.

## What it does
1. API: `show / transitionOut / hideRoot / isBusy / isVisible / requestDeepLink(hunter, skin)`
2. Weapon cards per `SkinCatalog.HunterOrder`; `putWeapon` auto-orients the world model in the card viewport and frames it from its **world-axis extents** (`worldExtents` — `GetBoundingBox` reports size in the model's own axes, which put Bram's shotgun half out of the card), with a 45 % height budget on cards (the viewport spans the whole card behind the name / rarity / price pill) and 77 % on the selected header, re-fitted on `AbsoluteSize`. Skin grid cloned from `Templates.WeaponSkinDefault / WeaponSkin` (index 1 of `SkinCatalog.WeaponSkins[h]` is the default), unlock kinds as ShopHuntersTab plus `limited` and `code` (a `SkinCatalog.CodeOnly` skin, checked ahead of `TokenPrice` so the flag wins outright: card strip `CODE ONLY`, rarity `CODE`, buy button `CODE ONLY` and disabled — without the branch it fell through to `LOCKED` / `UNAVAILABLE` and the rarity chip, computed from the price, dropped to `RARE`); canvas fitted to its rows (`Core.fitGridCanvas`)
3. Purchase panel: `PURCHASE` → `PurchaseWeaponSkinWithTokensEvent(hunter, skin)`; the Prestige Card (`LimitedStockConfig.Items.PrestigeCard`) fires `RequestLimitedPurchaseEvent(itemId)` instead, locks for 12 s, shows `n/100 LEFT` from the `limited` signal and `SOLD OUT` at zero
4. Statuses refresh on `skins` / `limited`
5. **Stand preview** (ShopStandDisplay): the weapon list shows the equipped hunter's equipped gun on the lobby stand; `selectWeaponSkinCard` puts the selected gun there. The limited Robux BUY shows an icon + number row (`setRobuxPrice`)

## Dependencies
- **Requires:** [[ShopCore]], [[ShopState]], [[ShopStandDisplay]], [[SkinCatalog]], [[StoreConfig]], [[BattlePassConfig]], [[LimitedStockConfig]]
- **Required by:** ShopController

## Connections
### RemoteEvents
| Remote | Direction | Other script |
|--------|-----------|-------------|
| `PurchaseWeaponSkinWithTokensEvent` | → Server | [[DataService]] buy a gun skin with Tokens |
| `RequestLimitedPurchaseEvent` | → Server | [[LimitedStockService]] reserve a Prestige Card unit, server opens the Robux prompt |

### BindableEvents
| Bindable | Direction | Other script |
|----------|-----------|-------------|
| `MenuNavigateRequested` | → | [[MenuHandlerScript]] BOUNTY PASS button on a pass-exclusive gun skin |

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[ShopCore]] | `bindCard / bindPurchaseHover / setCardStatus` | presentation |
| [[ShopState]] | `isWeaponSkinOwned / limitedRemaining / equippedHunterSkin / equippedWeaponSkin / on / fire` | state + remotes |
| [[ShopStandDisplay]] | `showWeapon / hasWeaponTemplate` | the selected / equipped gun on the lobby stand |
| [[SkinCatalog]] | `WeaponSkins / getWeaponSkin / defaultWeaponSkinName` | card data |
| [[StoreConfig]] | `isBundleExclusive` | bundle-only skins |
| [[BattlePassConfig]] | `isExclusiveSkin` | pass-exclusive skins |
| [[LimitedStockConfig]] | `Items.PrestigeCard` | cap, product, character/skin name |
