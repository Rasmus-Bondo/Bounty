---
tags: [server, modulescript, lootbox, economy, data]
path: game.ServerScriptService.PlayerServices.LootboxService
type: ModuleScript
lines: 873
---

# LootboxService

Server half of the lootbox chests (LOOTBOX_SPEC.md). Owns `profile.Lootboxes`, sells the 100-Token chest, rolls and grants what a chest contains, and replies with the resolved list the client replays. **The client never decides loot.**

## What it does
1. Creates five remotes in `ReplicatedStorage.Events` and so **starts in Main's upper block** beside BoostService / CollectionService / BundleService — the chest client `WaitForChild`s on them and its join-state listener has to exist before the profile-load push
2. **Join handshake:** pushes `LootboxStateEvent` (`unopened`, `superUnopened`, `superPending`, `level`, `xpInto` / `xpNeeded`, `restricted`, pity counters, `price`, `tokens`, `launched`) once the profile loads, and answers `RequestLootboxState` — never empty, never debounced away (the SkinDataEvent lesson). A state push is idempotent
3. **Free chests:** `syncFreeChests` computes `owed = Level - LevelClaimed` from persisted XP on every push, so a level earned in Redwater pays on the next lobby push with no match-place hook. Hooked to `PlayerStats.XP.Changed`, which every lobby XP writer reaches through `DataService.updateLeaderstats`. **Gated on the `LootboxLaunchV1` stamp** — until the launch migration has reset a profile to level 1 there is no baseline, and `Level - 0` chests to an unmigrated veteran would be a silent handout. Level 1 never pays. Since 2026-09-07 `syncFreeChests` also takes the player and remembers what it banked in a weak-keyed `arrivalPending`, sent out as `earnedPending` on **every** state push until `ChestArrivalSeen` retires it: the push that banks the chests routinely lands before [[ChestArrivalClient]] is listening, so a one-shot field on the banking push would be dropped. Held in memory, never on the profile — a disconnect mid-flight costs an animation, never a chest — and the ack is subtractive, so a level earned while chests are flying keeps its own
4. **Region gate:** `PolicyService:GetPolicyInfoForPlayerAsync(player).ArePaidRandomItemsRestricted`, read once per player on join (first use of PolicyService in the codebase), cached, **fails closed**. Blocks only the Token purchase; free and super chests are not paid random items. Enforced in the spend handler — the client's UNAVAILABLE IN YOUR REGION label is presentation
5. **Purchase:** policy gate, then `Wallet.spend(Tokens, PRICE, "lootbox_tokens")` — two returns, `false` when too poor with nothing deducted — then `Unopened += 1` and a push carrying `purchaseResult` (`ok` / `poor` / `restricted`). A click the busy flag or `REMOTE_COOLDOWN` rejects is **answered too** (`purchaseResult = "cooldown"`), because the client holds its own busy flag until a push carrying `purchaseResult` arrives
6. **Open** (`boxType` `"standard"` / `"super"`; the server validates the matching counter, the client's word only picks which): `rollTier` applies and advances the pity counters, `rollStandardItems` walks `LootboxConfig.DROPS`, each item rolled by weighted category then uniformly within (`rollItem`). The super chest rolls one weapon skin from `SUPER_WEAPON_SKINS` **preferring an unowned one** plus three skin-free fillers, and always reports stage 5. Then grant, `updateLeaderstats`, one `Telemetry.log("LootboxOpen", 1, tier, "Standard" | "PityEpic" | "PityLegendary" | "Super")`, and `LootboxResultEvent` `{ ok, boxType, tier, stage, items, forced }`. A rejected open (cooldown / empty / no data) is still **answered** with `ok = false` + reason, because the client is waiting on that reply
7. **Grant-time asserts:** every cosmetic candidate is re-checked against the catalog's exclusion predicates — `GroupPerkConfig.isGroupSkin`, `BattlePassConfig.isExclusiveSkin`, `StoreConfig.isBundleExclusive`, `LimitedStockConfig.findForWeaponSkin`, `SkinCatalog` `CodeOnly` / no `TokenPrice`, `TitlesConfig` non-purchase or `hiddenUntilOwned`, `EmoteConfig.isPurchasable` — and a refused entry is dropped from the candidates with a `warn`, so a catalog change cannot leak a pass skin into a chest
8. **Duplicates** are rolled: an owned title / emote / hero skin / weapon skin converts to `floor(shopPrice * 0.35)` in its own currency via `Wallet.award(..., "lootbox_duplicate", id)`. Floored **here** because Wallet rounds half-up (87.5 → 88). Ownership is re-read per item, so two rolls of one skin in a box grant once and refund once. Cash / Tokens / potions stack (`Wallet.award(..., "lootbox_reward")`, `BoostService.grantBoost`)
9. Grants route through the existing APIs: `DataService.GrantHunterSkin` / `GrantWeaponSkin`, `CollectionService.grantTitle` / `grantEmote`, `BoostService.grantBoost`, and Wallet for every currency movement — never a raw `data.Cash` / `data.Tokens` write
10. Per-player `busy` flag plus `REMOTE_COOLDOWN` on both mutating remotes; caches cleared on `PlayerRemoving`
11. Two entry points bank standard chests earned outside the LOOT tab, both over one `bankChests` body that normalises the counters, adds to `Unopened`, pushes state and returns how many landed. `grantChests(player, data, count)` is the paid path — the Trading Post's OUTLAW STARTER PACK — and **returns 0 for a player the region gate covers**: a restricted account still buys the pack and still gets its Cash and boosts, the chests alone are withheld. `grantFreeChests(player, data, count)` skips that gate for chests nobody paid for (redemption codes), the same reading that leaves the free per-level and tutorial super chests ungated. The gated one keeps the plain name so a caller that never considers the policy fails closed; `isPaidRandomRestricted` is exposed alongside them
12. **BOUNTY+ boost on the cash roll** (2026-09-06) — `grantItem` boosts `item.amount` for `kind == "cash"` only (the Tokens roll shares the branch and stays bare), resolved BEFORE `resolved` is built so both `amount` and `label` carry the boosted number. `labelFor` gained an optional amount override for this: it formats `"%d CASH"`, so boosting the award alone would have banked 110 while the reveal card said 100

## Dependencies
- **Requires:** [[LootboxConfig]], [[BoostConfig]], [[TitlesConfig]], [[EmoteConfig]], [[SkinCatalog]], [[BattlePassConfig]], [[StoreConfig]], [[GroupPerkConfig]], [[LimitedStockConfig]], [[DataService]], [[Wallet]], [[BoostService]], [[CollectionService]], [[Telemetry]], [[BountyPlusConfig]]
- **Required by:** Main, BundleService, CodeRedemptionService, BattlePassService (pass `chest` rewards)

## Connections
### RemoteEvents
| Remote | Direction | Other script |
|--------|-----------|-------------|
| `RequestLootboxState` | ← Client | [[ChestController]] pulls the join state once its listener is connected |
| `LootboxStateEvent` | → Client | [[ChestController]] counters, XP-to-next-chest, restricted flag, pity, price |
| `PurchaseLootboxEvent` | ← Client | [[ChestController]] buys one chest (banks it) |
| `OpenLootboxEvent` | ← Client | [[ChestController]] opens a standard or super chest |
| `LootboxResultEvent` | → Client | [[ChestController]] replays the resolved tier and items |
| `LootboxStateEvent` | → Client | [[ChestArrivalClient]] `earnedPending`, the chests to fly into the LOOT tab |
| `RequestLootboxState` | ← Client | [[ChestArrivalClient]] its own pull, so it does not depend on the chest GUI loading |
| `ChestArrivalSeen` | ← Client | [[ChestArrivalClient]] retires the flown chests from `arrivalPending` |

### BindableEvents
None

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[LootboxConfig]] | tables | Price, odds, pity, drops, pools, refund rate, cooldown |
| [[DataService]] | `getPlayerData()`, `getLevelFromXP()`, `getLevelProgress()`, `updateLeaderstats()`, `GrantHunterSkin()`, `GrantWeaponSkin()`, `SkinGrantExists()` | Profile access, level maths, skin grants and the catalog-existence predicate |
| [[Wallet]] | `spend()`, `award()` | The chest Sink and every reward / refund / Source |
| [[BoostService]] | `grantBoost()` | Potion rewards into `Boosts.Inventory` with the state push |
| [[CollectionService]] | `grantTitle()`, `grantEmote()` | Title / emote rewards with their state pushes |
| [[Telemetry]] | `log()` | One `LootboxOpen` row per open |
| [[BoostConfig]] | `get()` | Potion validity and labels |
| [[TitlesConfig]] | `EntryById`, `UnlockOf()`, `IsHiddenUntilOwned()`, `LabelById` | Title asserts, refund price and labels |
| [[EmoteConfig]] | `list()`, `isPurchasable()`, `get()` | The emote pool, asserts, refund price and labels |
| [[SkinCatalog]] | `getSkin()`, `getWeaponSkin()`, `defaultWeaponSkinName()` | Skin price, `CodeOnly`, default-skin exclusion and labels |
| [[BattlePassConfig]] | `isExclusiveSkin()` | Pass-skin exclusion |
| [[StoreConfig]] | `isBundleExclusive()` | Bundle-exclusive skin exclusion |
| [[GroupPerkConfig]] | `isGroupSkin()` | Group-perk skin exclusion (Dust `Wraith`) |
| [[LimitedStockConfig]] | `findForWeaponSkin()` | Limited-run exclusion (Fortuna `PrestigeCard`) |
