---
tags: [server, modulescript, economy, analytics]
path: game.ServerScriptService.PlayerServices.Wallet
type: ModuleScript
lines: 160
---

# Wallet

The single choke point for Cash / Token movement and the only place Roblox economy analytics events are logged. Mirrored VERBATIM in Bounty and Redwater Canyon — `LogEconomyEvent` limits (5 currencies, 20 transaction types, 100 SKUs) are per-experience, so both places must share one taxonomy. Edit both together.

## What it does
1. `award(player, data, currency, amount, reason, itemSku?)` — adds a positive `amount` to `data[currency]`, logs an `AnalyticsService:LogEconomyEvent` **Source**, returns the new balance
2. `spend(player, data, currency, amount, reason, itemSku?)` — if the balance covers `amount`, subtracts it, logs a **Sink**, and returns `true, newBalance`; otherwise returns `false, balance` without mutating
3. `logSource` / `logSink(player, currency, amount, endingBalance, reason, itemSku?)` — log-only helpers for a call site that must mutate the balance itself before logging (kept for future external-mutation cases; no current caller — Wallet is the sole mutator)
4. Maps each `reason` to a `transactionType` (Gameplay / TimedReward / Shop / IAP / custom `BattlePass`) via an internal table; the granular reason rides in `CustomField01`, the place name in `CustomField02`. The `daily_reward` reason (→ TimedReward) is defined for the daily play-streak claim; it is only fired from Bounty's DailyRewardService (kept in this Redwater copy for the verbatim mirror). Likewise `admin_grant` (→ TimedReward), a manual/developer offline currency gift, is only used in Bounty (kept here for the verbatim mirror). The `iap_cash_bundle` (→ IAP), `emote_cash` (→ Shop), `title_cash` / `title_tokens` (→ Shop, cosmetic-title purchases from the lobby Collection panel) and `refund` (→ Shop) reasons are also Bounty-only and are carried in this copy so the two tables stay byte-identical `rank_season_reward` (→ TimedReward, 2026-08-27), the ranked-season leaderboard payout, is likewise Bounty-only and carried here for the verbatim mirror.
5. Detects the place from `game.PlaceId` for the CustomField02 breakdown; wraps every `LogEconomyEvent` in `pcall` so analytics never breaks gameplay
6. **The custom-field keys must be the `.Name` STRINGS** (`"CustomField01"`), not the `Enum.AnalyticsCustomFieldKeys` EnumItems. The engine looks these keys up by string, and an EnumItem key stringifies to `"Enum.AnalyticsCustomFieldKeys.CustomField01"`, which never matches. It does **not** error — `LogEconomyEvent` accepts the table and silently drops the fields. **Fixed 2026-07-27.** From 2026-07-09 until then every economy event logged its currency, amount, ending balance, transactionType and SKU correctly but carried **no reason and no place breakdown at all**; confirmed by the Creator Hub offering no CustomField01/02 filter option, because no value had ever been recorded. Nothing appeared in the live error report either, since the call never threw. Do not "simplify" these back to the EnumItems
6. Callers stay responsible for their own leaderstat sync (`DataService.updateLeaderstats`)
7. Reason map includes `tutorial_complete = "Onboarding"` (2026-08-09) — the onboarding tutorial's flat once-per-account completion award, paid by TutorialDirector in Redwater before the return teleport and guarded by `profile.Tutorial.BonusPaid`

## Domination reasons (2026-08-22)

Three `Gameplay`-type reasons added to `TRANSACTION_TYPE`, in every place: `domination_capture`,
`domination_neutralise`, `domination_defend` (DOMINATION_SPEC 12.1).

## DEV tester reason (2026-08-23)

`dev_tester_grant` (→ `TimedReward`) is the DEV-universe playtester top-up, awarded by
TesterGrantService on join. It is in every copy because Wallet is mirrored verbatim, but it can
only ever fire on a DEV server — the gate is `GameEnvironment.env == "Dev"`. Mapped rather than
left to the unmapped-reason fallback so a DEV economy breakdown separates it from the real
`admin_grant` offline gifts.

## Dependencies
- **Requires:** [[GameEnvironment]] (plus the `AnalyticsService` service)
- **Required by:** ProgressionService, CodeRedemptionService, TesterGrantService, DataService (the `LootboxLaunchV1` migration's Token grant only)

## Connections
### RemoteEvents
None

### BindableEvents
None

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[GameEnvironment]] | `GameEnvironment.place` | Which physical place this server is, for the CustomField02 breakdown — replaces the old inline PlaceId table |

## Bundle reasons (2026-08-29)

Two `Shop`-type reasons added to `TRANSACTION_TYPE`, in every place because Wallet is mirrored:
`bundle_tokens` (the Sink for a Trading Post bundle) and `bundle_cash` (the Source the Outlaw
Starter Pack pays back out). Two reasons rather than one so the breakdown separates what the
player spent from what the same purchase handed back. Only Bounty fires them (BundleService);
Redwater and Frostbite carry them so the mirror stays byte-identical.

## Lootbox reasons (2026-09-03)

Four reasons added to `TRANSACTION_TYPE`, in every place because Wallet is mirrored verbatim:
`lootbox_tokens` (→ `Shop`, the Sink for a 100-Token chest, fired by LootboxService in Bounty) and
three `TimedReward` Sources — `lootbox_reward` (the Cash / Tokens a chest pays out directly),
`lootbox_duplicate` (the 35% shop-price refund a duplicate cosmetic converts to, with the item id as
the SKU) and `lootbox_launch_grant` (the 200 Tokens DataService's one-way `LootboxLaunchV1`
migration pays veterans). The last one fires in **whichever place loads the profile first**, which
is why a lobby-only feature still needs its reasons in the match places' copies.
