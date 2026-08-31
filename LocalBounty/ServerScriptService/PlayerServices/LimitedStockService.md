---
tags: [server, modulescript, store, monetization, datastore, limited]
path: game.ServerScriptService.PlayerServices.LimitedStockService
type: ModuleScript
lines: 429
---

# LimitedStockService

Authority for globally-capped items — owns the cross-server sold/reserved counter and opens the Robux prompt only once a unit is secured.

## What it does
1. Keeps one `LimitedStock_v1` DataStore key per item holding `{ sold = <count>, pending = { [userId] = <expiry> } }`; every mutation goes through `UpdateAsync` so two servers cannot both sell the last unit
2. `reserve(player, itemId)` prunes expired holds, checks `sold + pending < Cap`, and writes a 180s hold — a player who already holds one keeps it rather than taking a second unit
3. `release(player, itemId)` drops a hold when the prompt is declined or closed
4. `commit(player, itemId)` turns a hold into a sale; **deliberately unconditional** because the player has already paid by then — an expired hold on a full run overshoots to `Cap + 1` and warns rather than pocketing their Robux
5. `handleReceipt(player, itemId)` grants via [[DataService]] `GrantWeaponSkin` then commits; a re-purchase of something already owned releases instead of burning a second unit
6. Reserves before prompting on `RequestLimitedPurchaseEvent`, rate-limited to one attempt per player per 5s so button-mashing cannot hit the per-key DataStore write throttle
7. Broadcasts remaining counts on `LimitedStockEvent` — on join, on change, and every 30s; answers `RequestLimitedStockEvent` pulls
8. Releases the hold on `MarketplaceService.PromptProductPurchaseFinished` when the purchase did not go through

## Notes
Why reservations exist: `ProcessReceipt` fires *after* Robux leaves the account, so a stock check there would charge the 101st buyer for a sold-out item with no refund path.

## Dependencies
- **Requires:** [[LimitedStockConfig]], [[DataService]]
- **Required by:** StoreService

## Connections
### RemoteEvents
| Remote | Direction | Other script |
|--------|-----------|-------------|
| `RequestLimitedPurchaseEvent` | ← Client | [[HuntersBuyController]] BUY press; server reserves then prompts |
| `LimitedStockEvent` | → Client | Remaining-units broadcast to [[HuntersBuyController]] |
| `RequestLimitedStockEvent` | ← Client | [[HuntersBuyController]] pull on trading-post open, since the join broadcast is droppable |

### BindableEvents
None

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[LimitedStockConfig]] | `Items`, `getByProductId()`, `ReservationSeconds` | Cap, product id and grant target per item |
| [[DataService]] | `getPlayerData()`, `GrantWeaponSkin()` | Ownership check and the grant itself |
