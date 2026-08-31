# 130 — Buying a bundle has never been executed end to end

[Open items index](../OPEN-ITEMS.md) · [Conventions](../CONVENTIONS.md)

**Status:** DEFERRED · **Sev:** P2 · **Area:** Bounty — `PlayerServices.BundleService`, `Shop.Modules.ShopBundlesTab`

**Raised 2026-08-29.** What the tab is and how the discount is computed is in the Unreleased entry.

**The page is signed off.** The owner confirmed the layout across platforms on 2026-08-29, and the
discount arithmetic, the shop-vs-server price agreement and every instance path were verified in
edit mode.

**What has never run: the purchase itself.** `PurchaseBundleEvent` has never been fired by a real
client. Everything downstream of it is therefore unexercised — the `Wallet.spend` Token debit under
the two new `bundle_tokens` / `bundle_cash` reasons, `DataService.GrantHunterSkin` /
`GrantWeaponSkin` landing the cosmetics, `BoostService.grantBoost` on the starter pack, and the
panel repainting off the server's `SkinDataEvent` / `ShopPurchaseSuccessEvent` push rather than off
the 5 s client timeout.

**Two paths are specific to this feature and are the ones to watch.**

*The quoted-price rail.* `BundleService` refuses a sale whose real price has risen above the price
the button was showing. It cannot be hit by playing normally — it needs the panel open on a bundle
while an item in it is bought elsewhere — and a bug there presents as a buy button that does
nothing, silently, because there is no failure remote.

*The starter pack's re-arm.* It grants no skins, so it pushes no `skins` signal; the button relies
on `purchaseSuccess` alone. If that cue does not arrive the button sits on `PURCHASING...` for five
seconds and then re-arms, which reads as a failed purchase that actually succeeded.

**Test that closes it:** on a published DEV server, buy each of the three bundles. Confirm the
Tokens leave, every listed item appears in the Collection without a rejoin, the panel flips to OWNED
by itself, and the starter pack's boosts land in the boost inventory and can be activated. Then buy
one item of a frost bundle on its own and confirm the bundle's card and panel both drop to the
discounted price — that is the whole point of the feature and it is the assertion that only a live
profile can make.
