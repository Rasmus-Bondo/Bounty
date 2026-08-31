---
tags: [client, modulescript, ui, shop, trading-post, remotes]
path: game.StarterGui.Shop.Modules.ShopState
type: ModuleScript
lines: 307
---

# ShopState

The Trading Post's one client-side mirror of ownership state and its one remote table — every tab reads from here and fires through here.

## What it does
1. Resolves every remote it needs in `ReplicatedStorage.Events` (and `Events.SettingsEvents`) on background `WaitForChild` threads — most are created at runtime by the server, so nothing here yields the caller. `State.fire(name, ...)` returns false (and warns) if that remote is not resolved yet
2. Signals via `State.on(name, cb)`: `skins`, `titles`, `emotes`, `bundles`, `limited`, `hunters`, `purchaseSuccess`, `redeem`
3. Listens: `SkinDataEvent(ownedSkins[h][s], equippedHunter, equippedSkin, ownedCharacters, ownedWeaponSkins[h][s], equippedWeaponSkins[h])`, `TitleStateEvent{owned}`, `EmoteStateEvent{owned, equipped}`, `BundleStateEvent{purchased}`, `LimitedStockEvent{itemId = remaining}`, `ShopPurchaseSuccessEvent()` (cash/token buys) or `(kind, amount, productId)` (Robux receipts), `SettingsEvents.RedeemCodeResponse{success, message}`; hunter ownership is the `Owns<Hunter>` player attribute (`hunters` signal)
4. Queries: `ownsHunter / isSkinOwned / isWeaponSkinOwned / equippedWeaponSkin / isTitleOwned / isEmoteOwned / isBundlePurchased / limitedRemaining / hasSkinData`, plus `ownsSkinRecord(kind, hunter, skin)` — raw ownership out of the last push, without `isSkinOwned`'s "you must own the hunter first" gate and without `isWeaponSkinOwned`'s free-default shortcut. BUNDLES prices itself off this because the server prices off exactly those two profile buckets, and the two shortcuts would part the numbers
5. `requestAll` pulls `RequestSkinData`, `RequestTitleState`, `RequestEmoteState`, `RequestBundleState`, `RequestLimitedStockEvent` once each remote resolves — the join-time pushes can land before this LocalScript connected (join-state handshake rule)

## Dependencies
- **Requires:** [[StoreConfig]], [[EmoteConfig]], [[SkinCatalog]]
- **Required by:** ShopController, ShopFeaturedTab, ShopHuntersTab, ShopWeaponsTab, ShopExtrasTab, ShopBundlesTab, ShopVaultController

## Connections
### RemoteEvents
| Remote | Direction | Other script |
|--------|-----------|-------------|
| `SkinDataEvent` | ← Server | [[DataService]] owned skins / hunters / gun skins push |
| `RequestSkinData` | → Server | [[DataService]] resend pull on load |
| `TitleStateEvent` | ← Server | [[CollectionService]] `{ owned }` |
| `RequestTitleState` | → Server | [[CollectionService]] |
| `EmoteStateEvent` | ← Server | [[CollectionService]] `{ owned, equipped }` |
| `RequestEmoteState` | → Server | [[CollectionService]] |
| `BundleStateEvent` | ← Server | [[BundleService]] `{ purchased }` — bundles this account has bought |
| `RequestBundleState` | → Server | [[BundleService]] pull on load |
| `LimitedStockEvent` | ← Server | [[LimitedStockService]] remaining units |
| `RequestLimitedStockEvent` | → Server | [[LimitedStockService]] pull on load |
| `ShopPurchaseSuccessEvent` | ← Server | [[DataService]] / [[CollectionService]] / [[BundleService]] cash & token buys; [[StoreService]] Robux receipts `(kind, amount, productId)` |
| `RedeemCodeResponse` | ← Server | [[CodeRedemptionService]] `{ success, message }` |

The purchase remotes (`PurchaseHunterEvent`, `PurchaseSkinWithTokensEvent`, `PurchaseWeaponSkinWithTokensEvent`, `PurchaseTitleEvent`, `PurchaseEmoteEvent`, `PurchaseBundleEvent`, `RequestLimitedPurchaseEvent`, `RedeemCodeRequest`) are resolved here but fired by the tab modules; their rows live in those files.

### BindableEvents
None

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[StoreConfig]] | `FreeCharacters` | free hunters count as owned |
| [[EmoteConfig]] | `list()` | emote id set |
| [[SkinCatalog]] | `HunterOrder / defaultWeaponSkinName` | default ownership |
