# 114 — Bundle ProcessReceipt is unproven against a real purchase

**Area:** Store / Bounty · **Sev:** P1 · **Status:** CLOSED 2026-08-15 (never verified)
**Raised:** 2026-08-14, Update 1

**Closed 2026-08-15 — owner decision. No purchase has been observed.** Closed one day after the
product opened, so the receipt branch is still unproven against real Robux; this is a decision to
stop tracking it, not a finding that it works. **The rollback hazard below survives the closure** —
deactivate product `3708064902` on the Creator Hub before any rollback of Update 1. If a buyer
reports paying and receiving nothing, that is a **new id**, at P1.

## Symptom

None observed — this is an unexercised path, not a defect. The "Let the Hunt Begin" bundle
(product `3708064902`) grants Frostveil Vesper and the Frostpiercer rifle skin through a new branch
in `StoreService.processReceipt`. Every other part of the card is owner-playtested on PC, mobile and
tablet; the grant itself has never run against a genuine Robux transaction.

Sev is P1 because the failure mode costs a player real money: a receipt that errors or returns the
wrong `ProductPurchaseDecision` either charges without granting, or re-grants on every retry.

## Repro

Not reproducible in Studio. **Studio does not charge the place owner**, so the receipt callback
cannot be driven end to end there — which is precisely why this item exists.

## The test that closes it

Buy the bundle on live, with a real account and real Robux, and confirm in one pass:

1. Both items appear — `FrostveilVesper` equippable on Vesper, `Frostpiercer` equippable as her
   weapon skin — without a rejoin.
2. The card disappears for that account and stays gone across a rejoin (the ownership gate reads
   `SkinDataEvent`).
3. The Robux is debited exactly once, and the server log shows no `processReceipt` error.
4. A second purchase attempt is not offered (the product is one-time by ownership, not by
   `PurchaseHistory`).

Watch the **first** live purchase specifically — a receipt that fails is retried by Roblox on a
schedule, so a bad branch compounds rather than failing once.

## Rollback note

This item carries the release's revert hazard: **reverting Bounty leaves the product live on the
Creator Hub with no receipt handler**, so buyers pay and get nothing. Deactivate product
`3708064902` on Creator Hub before any rollback of Update 1.

## Release entry

2026-08-14 — *"Let the Hunt Begin" Robux bundle, product `3708064902`*.
