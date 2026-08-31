# 93 — Legacy Cash Developer Product `3601170442` retired — deactivated on the Creator Hub

[Open items index](../../OPEN-ITEMS.md) · [Conventions](../../CONVENTIONS.md)

---

**Legacy Cash Developer Product `3601170442` retired — deactivated on the Creator Hub.**
*(found by analysis 2026-08-03 during the dead-UI purge; branch deleted the same day, product
deactivated by the owner 2026-08-03. The pre-publish blocker is cleared.)*

*What was wrong:* `StoreService:133-141` matched that product id, fired `ShopPurchaseSuccessEvent`
claiming 20,000 Cash, and returned `PurchaseGranted` — **without ever calling
`DataService.AddCash`**. `PurchaseGranted` consumes the receipt permanently, so a buyer paid, saw
the success FX, and got nothing, with no retry. It bypassed `Wallet`, so nothing reached economy
analytics either. The id is absent from `StoreConfig`, so `findCashAmountForProduct` did not catch
it first — the branch was genuinely reachable, not dead code. It had lost its `AddCash` somewhere
in the shop rework: both client ends were already gone with the old `ShopMenuGui` (the LocalScript
that prompted it, and the `PlayCurrencyCounter` remote it listened on), which is why nothing
in-game had prompted it for some time. A Developer Product stays purchasable by direct link
regardless of whether any UI offers it, which is why deactivation — not just deleting the UI —
was the actual close.

*What changed:* the whole branch and both `LEGACY_CASH_*` constants are gone; `StoreService` is
163 → 151 lines and compiles. An unrecognised product id now falls through to `NotProcessedYet`.
The code half shipped in [Hotfix 5](../../2026-08-03-hotfix-5.md) (`Bounty r2295`); the ordering
requirement it carried is satisfied, because the product went inactive first.

**One thing that is still true and easy to get wrong:** deactivating does not clear receipts that
were already pending from before the rework. `NotProcessedYet` is not a rejection — Roblox
re-delivers indefinitely. If a player ever reports a stuck purchase for this product, the fix is
to restore a *granting* branch (one that actually calls `Wallet`), **not** to re-add the old one.
