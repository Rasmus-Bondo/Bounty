---
tags: [server, modulescript, battlepass]
path: game.ServerScriptService.PlayerServices.BattlePassService
type: ModuleScript
lines: 449
---

# BattlePassService

Bounty-side battle-pass server. Owns the profile data guards + season rollover, streams pass state to the client panel, validates reward claims on **both tracks** plus **weekly quest claims**, and sells the Full Pass (Upgrade Pass). XP is *earned* in Redwater Canyon; this place only displays progress, lets players *claim* rewards and quest XP, and lets them *purchase* the pass. Only `ensureData` is mirrored in Redwater's BattlePassService — keep those two in sync. `grantReward` is **not** mirrored: Redwater earns BP XP and quest progress but never claims, so claiming lives here and nowhere else.

## What it does
1. `ensureData(data)` — idempotent guard run on every entry point: initializes `Tokens`/`Boosts`/`Cosmetics` buckets and the `BattlePass` sub-table, then handles **season rollover** — if `data.BattlePass.seasonId ~= Config.SEASON_ID` it forfeits unclaimed rewards and resets xp/claimed/quests/ownsFullPass while KEEPING the token wallet and cosmetic inventory. Recomputes `level` from xp. Also carries the one-time **manual-claim migration** (`bp.questClaimMigrated`): quests completed under the old auto-grant rule already paid their XP, so they are stamped `claimed = true` once — without it every historic completion would show up as claimable and pay twice. Mirrored verbatim in Redwater's copy
1b. `ensureData` also carries the **quest-progress reset lever**: if `bp.questProgressToken ~= Config.QUEST_PROGRESS_TOKEN` it clears `bp.quests` and stamps the new token, once per token value per profile. This wipes weekly quest progress and nothing else — `bp.xp`, `level`, `ownsFullPass` and the reward-track claims all survive, which is what makes it safe to pull mid-season when a quest's goal or label changes. The alternative, a `SEASON_ID` bump, would take the entire pass down with it. Mirrored verbatim in Redwater's copy
2. `grantReward(player, data, reward) -> boolean` — hands each `kind` to the system that **owns that inventory**, because every kind stores ownership somewhere different and the owning system is what the UI reads: `title` → `data.Cosmetics.Titles` (which [[CollectionService]] `titleOwned` reads alongside `OwnedTitles`); `emote` → [[CollectionService]] `grantEmote` → `data.OwnedEmotes`; `hunterSkin` → [[DataService]] `GrantHunterSkin` → `data.OwnedSkins[character][skin]`; `gunSkin` → [[DataService]] `GrantWeaponSkin` → `data.OwnedWeaponSkins[character][skin]`; `boost` → adds `reward.count or 1` to `Boosts.Inventory[reward.boostId]` (boosts are the only stacking reward kind); `tokens` / `cash` via [[Wallet]] `award` (Token/Cash economy **Source**, reason `battlepass`) — these are read off the row generically, so a bundle on a cosmetic row *would* pay out silently; [[BattlePassConfig]] 4c is why none exists. **`Cosmetics.Emotes` / `HunterSkins` / `GunSkins` are vestigial** — nothing reads them, so writing there (as this did before the S3 art pass) silently lost the reward while still consuming the claim; they are kept only so pre-S3 profiles load
2b. **Every id is validated against the catalog that owns it, and the return value gates the claim.** `title` against [[TitlesConfig]] `EntryById`, `boost` against [[BoostConfig]] `get`, `emote`/`hunterSkin`/`gunSkin` by the owning grant function's own false return, currency by requiring a non-zero amount, and any unrecognised `kind` fails outright. A false return means the reward could not be delivered and `tryGrant` leaves the level **unclaimed**. This is the fix for the S3 hunter/gun skins, which were consumed-but-never-granted because the claim was stamped whether or not the grant landed and a `warn()` was the only trace. **The cosmetic is granted BEFORE any bundled currency is paid** — order is load-bearing, since a failed claim stays retryable and paying first would turn that retry into a currency farm
3. **Two-track claims.** `getReward(track, level)` returns `Config.PAID[level]` or `Config.FREE[level]`; claims are keyed `"p<level>"` / `"f<level>"` in `bp.claimed`. `tryGrant` grants a single (track, level) if reached, tier-eligible (paid ⇒ needs `ownsFullPass`; free ⇒ always), and unclaimed
3b. **`tryGrantBoth` links the tracks for a Full Pass owner** — claiming either card at a level also claims the other. Several levels put the same cosmetic on both sides (L7 `gunhand`, L10 `SummerDust`, L18 `lasso_dance`) and others deliberately split one amount across them (L1 75+75, L23 200+200), so without this a pass owner is asked to tap the same level twice, the second tap re-granting a title they already own. The `ownsFullPass` guard is what makes it safe: a player **without** the pass claims only the free card and the paid one stays unclaimed, so upgrading later still pays out every level they walked past. Grants are idempotent, so the duplicated cosmetic rows cost nothing
4. `onClaimReward(player, track, level)` — validates + grants via `tryGrantBoth`, then updates leaderstats + re-sends state. **Re-sends state on a refused claim too**: [[BattlePassClient]] stamps the card claimed optimistically the instant it is tapped, so a refusal that went unanswered would leave the card lying about a reward the player never received
5. `onClaimAll(player)` — **CLAIM ALL**: iterates every level on both tracks, grants all reached/eligible/unclaimed rewards, then one leaderstats sync + one state send. It sweeps both tracks already, so it needs no cross-track linking of its own
6. `onClaimQuest(player, questId)` — **weekly quest claim**, separate from the reward track. Redwater only marks a quest `completed`; this grants its `xp` into `bp.xp`, stamps `bp.quests[questId].claimed = true`, recomputes `bp.level`, and re-sends state. Validates the quest id against `Config.questById`, that its week is `<= currentWeek()`, and that it is completed and unclaimed — so a quest from any already-unlocked week stays claimable for the rest of the season, and a double-fire pays once. No leaderstat sync (BP XP is not a leaderstat)
7. `onUpgrade(player)` — **Upgrade Pass purchase**: if not already owned, spends `Config.FULL_PASS_PRICE` (800) Tokens via [[Wallet]] `spend` (Token Sink, reason `battlepass`, SKU `UpgradePass_<seasonId>` e.g. `UpgradePass_S3`); on success sets `ownsFullPass`, syncs, and fires `BattlePassPurchaseResultEvent(true)`; on failure fires it with `false` + reason (`insufficient`/`owned`)
8. `sendState(player)` — fires `BattlePassDataEvent` with a compact payload (seasonId/name, xp, level, ownsFullPass, tokens, fullPassPrice, current week, claimed map, quest progress incl. per-quest `claimed`); consumed by [[BattlePassClient]] and by [[QuestClient]] (weekly tab)
9. `grantFullPass(player)` — free (no-cost) grant hook kept for testing premium claims
10. On player join, polls `DataService.getPlayerData` until the profile loads, runs `ensureData`, then sends initial state
11. Creates its RemoteEvents in ReplicatedStorage on `Start()` if missing

## Dependencies
- **Requires:** [[DataService]], [[Wallet]], [[CollectionService]], [[BattlePassConfig]], [[BoostConfig]], [[TitlesConfig]]
- **Required by:** Main

## Connections
### RemoteEvents
| Remote | Direction | Other script |
|--------|-----------|-------------|
| `BattlePassDataEvent` | → Client | [[BattlePassClient]] (panel) + [[QuestClient]] (weekly tab) receive full pass state |
| `ClaimBattlePassRewardEvent` | ← Client | [[BattlePassClient]] fires `(track, level)` to claim one reward |
| `ClaimAllBattlePassRewardEvent` | ← Client | [[BattlePassClient]] fires on CLAIM ALL |
| `UpgradeBattlePassEvent` | ← Client | [[BattlePassClient]] fires on UPGRADE PASS to buy the Full Pass |
| `BattlePassPurchaseResultEvent` | → Client | [[BattlePassClient]] gets `(ok, reason)` after a purchase attempt |
| `RequestBattlePassDataEvent` | ← Client | [[BattlePassClient]] + [[QuestClient]] eager-fetch state |
| `ClaimBattlePassQuestEvent` | ← Client | [[QuestClient]] fires `(questId)` to claim one weekly quest's XP |

### BindableEvents
None

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[DataService]] | `getPlayerData()`, `updateLeaderstats()`, `GrantHunterSkin()`, `GrantWeaponSkin()` | Read/write the profile, sync the Tokens leaderstat after a claim/purchase, and unlock skin rewards into the per-hunter ownership tables |
| [[Wallet]] | `award()`, `spend()` | Award reward currency (Source); spend Tokens for the Full Pass (Sink), reason `battlepass`, SKU `UpgradePass_<seasonId>` |
| [[CollectionService]] | `grantEmote()` | Unlock an `emote` reward into `data.OwnedEmotes` and push the EMOTES-tab state to the client |
| [[BattlePassConfig]] | `PAID`, `FREE`, `SEASON_ID`, `FULL_PASS_PRICE`, `questById`, `levelFromXP()`, `currentWeek()` | Reward definitions, season identity, price, weekly quest lookup for claims, level and week math |
| [[BoostConfig]] | `get()` | Validate a `boost` reward's `boostId` before granting it, so an unknown id refuses the claim instead of writing an inventory entry nothing can spend |
| [[TitlesConfig]] | `EntryById` | Validate a `title` reward id before writing `Cosmetics.Titles`, so an unknown id refuses the claim instead of recording a title no UI can render |
