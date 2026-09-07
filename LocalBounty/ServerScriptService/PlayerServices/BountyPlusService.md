---
tags: [server, modulescript, bountyplus, gamepass, economy, monetisation]
path: game.ServerScriptService.PlayerServices.BountyPlusService
type: ModuleScript
lines: 324
---

# BountyPlusService

Owns the BOUNTY+ game pass in the lobby: resolves ownership, stamps the profile, sets the attribute every other surface reads, and pays the one-time grant. Bounty-only and NOT mirrored — the purchase prompt and the chest grant exist only here, so a mirrored copy would be dead code in the match places.

## What it does
1. On profile load (`PlayerAdded` plus players already present) resolves ownership: trusts the profile stamp first, and only asks `MarketplaceService:UserOwnsGamePassAsync` when the stamp is absent
2. Retries the web call up to 3 times with doubling backoff, but only on an ERROR — a successful `false` is a real answer and re-asking it just delays the join
3. Moves ownership nil/false → true ONLY. A pass is permanent short of a Roblox refund, so a failed call is never treated as revocation
4. Sets the `OwnsBountyPlus` player attribute: `true` when owned, `false` on a definitive negative, and left NIL when the question went unanswered — the panel needs that difference
5. Pays the one-time grant: 1000 Tokens through the Wallet, 5 chests through `LootboxService.grantChests` (the region-gated entry point, correct here because these chests are Robux-bought — an account `ArePaidRandomItemsRestricted` covers is banked 0 and keeps the Tokens, the boosts and the title), and all four GOLDEN OUTLAW title ids
6. Marks each part of the grant as it lands (`TokensPaid` / `ChestsPaid` / `TitlesPaid`) and only then sets `Granted`. A single end-stamp would retry a half-failure by re-paying the Tokens; per-part marks make the retry finish only what is missing
7. Holds an in-memory busy flag so the join back-fill and a purchase landing in the same instant cannot both pay
8. Fires `GiftNotice` once the grant completes, so a back-filled player (bought on the website, or before this shipped) is told where 1000 Tokens and five chests came from. Since 2026-09-07 the detail line names chests only when chests were actually banked — a restricted buyer reads "GOLDEN OUTLAW unlocked", because this popup is the only account of what arrived. The count is read from the region gate rather than from `grantChests`' return value: on a RETRIED grant the chest step is skipped as already paid, and a skipped step has no count to report
9. On `PromptGamePassPurchaseFinished` with `wasPurchased`, trusts that answer instead of re-asking the web — an immediate `UserOwnsGamePassAsync` can return false off a stale ownership cache and skip the grant just paid for
10. Serves the panel's state over `BountyPlusStateEvent`, paired with a `RequestBountyPlusState` pull so a push landing before the listener exists is not lost
11. Exposes `owns(player)` for callers that hold a player but not their profile

## Dependencies
- **Requires:** [[BountyPlusConfig]], [[TitlesConfig]], [[DataService]], [[Wallet]], [[LootboxService]], [[CollectionService]]
- **Required by:** Main (started after DataService and LootboxService)

## Connections
### RemoteEvents
| Remote | Direction | Other script |
|--------|-----------|-------------|
| `BountyPlusStateEvent` | → Client | [[ChestController]] draws the panel's owned/granted state |
| `RequestBountyPlusState` | ← Client | [[ChestController]] pulls state on join |
| `GiftNotice` | → Client | GiftGui's reward card, fired once when the grant is paid |

### BindableEvents
None

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[BountyPlusConfig]] | `GamePassId`, `Attribute`, `Grant`, `dataOwns` | Pass id, attribute name, grant amounts, ownership shape |
| [[TitlesConfig]] | `BountyPlusTitleIds`, `LabelById` | The four GOLDEN OUTLAW ids and the label for the gift card |
| [[DataService]] | `getPlayerData`, `updateLeaderstats` | Profile access and the leaderstat sync after the Token award |
| [[Wallet]] | `Wallet.award` | The 1000-Token grant, reason `bountyplus_grant` |
| [[LootboxService]] | `grantChests` | The five-chest grant, through the region-gated entry point |
| [[CollectionService]] | `grantTitle` | Unlocks each of the four GOLDEN OUTLAW ids |
