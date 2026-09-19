---
tags: [shared, modulescript, battlepass, config]
path: game.ReplicatedStorage.Config.BattlePassConfig
type: ModuleScript
lines: 607
---

# BattlePassConfig

Single source of truth for the battle pass: every season's quest sets and reward tracks, the shared XP/level constants, and which season is live right now. Mirrored byte-for-byte in all three places.

## What it does
1. **Seasons are blocks in a `SEASONS` list** (oldest first). Each block carries `SEASON_ID`, `SEASON_NUMBER`, `SEASON_NAME`, `SEASON_START`, `TEST_ALL_WEEKS_UNTIL`, `QUEST_PROGRESS_TOKEN`, `WEEKS`, `PAID` and `FREE`. Currently: Season 1 *Dead Man's Hand* (`S6`) and Season 2 *Trial by Fire* (`S7`, starts 2026-09-19 18:00 UTC / 20:00 CEST).
2. **`Config.<season field>` resolves to the LIVE season at read time**, through a metatable `__index` — those keys are not real fields of `Config`. The live season is the newest whose `SEASON_START` has passed; **a DEV-universe server always runs the newest season** (`GameEnvironment.env == "Dev"`, explicitly — Studio on the live place and unpublished places follow the live schedule). So a season is published ahead of its start and turns over by itself, on running servers, with no second publish. Callers must read these through the module table; a local copy freezes on the boot-time season.
3. Shared constants, real fields: `WEEK_SECONDS`, `TOTAL_WEEKS` (3), `XP_PER_LEVEL` (2,500), `TOTAL_LEVELS` (30), `FULL_PASS_PRICE` (800 Tokens), `XP_SOURCES` (gameComplete 25, kill 4, assist 2, becomeBounty 20, killBounty 10 — consumed by Redwater's BattlePassService), `ICONS` (flat card art per kind: cash / tokens / emote / chest).
4. `WEEKS` — 3 quest sets of 7, 21,500 XP each; `type` must match an event reported through `QuestEvents.track`. Season 2's weeks are *Ride Out*, *Wanted* (bounty week — `bountyClaim`, `bountyTime`, `podium`) and *The Whole Roster* (Domination + `killAs` per free hunter).
5. `PAID` (levels 1..30, Full Pass required) and `FREE` (arbitrary levels, claimable by everyone). Row kinds: `title`, `emote`, `boost`, `cash`, `tokens`, `chest`, `hunterSkin`, `gunSkin`; `count` stacks `boost` and `chest` rows. A FREE row repeating the PAID row at its level is one claim for a pass owner (BattlePassService `tryGrantBoth`).
6. **Season 2 has two ART PENDING rows left, commented out** — emotes at L13 and L18 (also free). The other six filled on 2026-09-19: hunter skins `DesertNomadBram` L10 (also free), `BonewhiteDust` L20 and `NightshadeVesper` L30, and emotes `good_vibes` L3, `attitude` L24 and `coffin_dance` L28 — each skin Model copied into all three places, each emote id added to `EmoteConfig`. A missing row claims nothing and BattlePassClient captions the card COMING SOON. Chests at paid L4 (1), L9 (1), L16 (2), L23 (2), L26 (3) and free L13, L25. Lava gun skins: `CinderSix-Shooter` (Dust) L15, `MoltenGrudgekeeper` (Bram) L29.
7. `levelFromXP(xp)`; `currentWeek(now?)` for the live season (0 before its start; `TOTAL_WEEKS` while inside `TEST_ALL_WEEKS_UNTIL` in Studio or off-live); `activeSeasonNumber(now?)` — read by TitlesConfig to badge past-season pass titles and hide upcoming ones.
8. `questById` per season (resolves to the live season's, so an ended season's quest id finds nothing).
9. `exclusiveSkins` / `isExclusiveSkin(character, skinName, kind?)` — built from **every** season block, so a pass skin stays out of the shop and chest pools before its season starts and after it ends. Deleting an old season block would un-exclude its skins.

## Dependencies
- **Requires:** [[GameEnvironment]]
- **Required by:** BattlePassService, BattlePassClient, QuestClient, TitlesConfig, DataService, LootboxService, Shop, ShopHuntersTab, ShopWeaponsTab, HuntersBuyController

## Connections
### RemoteEvents
None

### BindableEvents
None

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[GameEnvironment]] | `env`, `isLive` | DEV runs the newest season; the pre-launch week preview is honoured only off-live |
