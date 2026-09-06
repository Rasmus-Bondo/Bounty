---
tags: [server, modulescript, shop, trading-post, bundles, economy, purchase]
path: game.ServerScriptService.PlayerServices.BundleService
type: ModuleScript
lines: 273
---

# BundleService

Server side of the Trading Post's BUNDLES tab: validates a bundle purchase, prices it from the player's own profile, spends the Tokens, applies every grant and records the sale so no bundle is ever sold to the same account twice.

## What it does
1. `Start()` validates the whole catalog once (every ownable grant against `DataService.SkinGrantExists`, every boost id against `BoostConfig`, every Cash amount, every Chest count) and caches a per-bundle sellable flag — a bundle naming a missing cosmetic goes off sale with a warning instead of selling something it cannot deliver
2. Creates `PurchaseBundleEvent`, `RequestBundleState` and `BundleStateEvent` and resolves `ShopPurchaseSuccessEvent`; started early in Main alongside BoostService and CollectionService because the shop client blocks on the remote
3. `purchaseBundle(player, bundleId, quotedPrice)` recomputes the discounted price with `BundleConfig.priceFor`, fed ownership straight out of `data.OwnedSkins` / `data.OwnedWeaponSkins` — the client's arithmetic is never trusted, only mirrored
4. `quotedPrice` is a safety rail, not an input: if the real price has risen since the panel drew it (an item was bought in another tab meanwhile), the sale is refused rather than charging more than the button said. A forged low quote only refuses; a forged high one still pays the real price
5. Spends through `Wallet.spend(..., "Tokens", price, "bundle_tokens", bundleId)`, then applies grants — hunter and weapon skins via `DataService.GrantHunterSkin / GrantWeaponSkin` (idempotent, and each re-pushes SkinDataEvent), Cash via `Wallet.award(..., "bundle_cash", ...)`, boosts via `BoostService.grantBoost`, chests via `LootboxService.grantChests` — then updates leaderstats and fires the purchase-success cue
6. Refuses a fully-owned bundle and a zero price outright, and holds a per-player busy flag so a double click cannot double-charge
7. One per account: the sale is stamped into `data.PurchasedBundles[bundleId]` the instant the Tokens move — before the grants, so a grant that throws cannot reopen the sale — and a bundle already in that set is refused with a re-push. The two skin bundles were already unrepeatable by accident (owning every skin in one drives `priceFor` to 0); the starter pack grants nothing ownable, so the record is the only thing that ever retires it
8. `sendBundleState` pushes `{ purchased = { [bundleId] = true } }` on join and on `RequestBundleState`, waiting up to 20 s for a profile still loading behind a teleport session lock (one waiter per player, so a spammed pull cannot stack coroutines). Ids the catalog no longer sells are left out of the push but stay in the profile

## Dependencies
- **Requires:** [[BundleConfig]], [[BoostConfig]], [[DataService]], [[BoostService]], [[LootboxService]], [[Wallet]]
- **Required by:** Main

## Connections
### RemoteEvents
| Remote | Direction | Other script |
|--------|-----------|-------------|
| `PurchaseBundleEvent` | ← Client | [[ShopBundlesTab]] buy the selected bundle |
| `RequestBundleState` | ← Client | [[ShopState]] pull the purchased set on load |
| `BundleStateEvent` | → Client | [[ShopState]] `{ purchased }` push on join and after a sale |
| `ShopPurchaseSuccessEvent` | → Client | [[ShopState]] purchase cue, re-arms the buy button |

### BindableEvents
None

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[BundleConfig]] | `list / get / priceFor / isOwnable / isPurchased` | catalog, the discount rule and the one-per-account test |
| [[BoostConfig]] | `get` | boot-time check that a boost grant names a real potion |
| [[DataService]] | `getPlayerData / SkinGrantExists / GrantHunterSkin / GrantWeaponSkin / updateLeaderstats` | profile, catalog check, cosmetic grants |
| [[BoostService]] | `grantBoost` | boost grants into the inventory |
| [[LootboxService]] | `grantChests` | the starter pack's three chests, withheld from a region-restricted account |
| [[Wallet]] | `spend / award` | the Token sink and the starter pack's Cash source |
