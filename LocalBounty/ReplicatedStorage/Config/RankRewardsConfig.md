---
tags:
  - shared
  - modulescript
  - ranked
  - leaderboard
  - economy
path: game.ReplicatedStorage.Config.RankRewardsConfig
type: ModuleScript
lines: 106
---

# RankRewardsConfig

The ranked-season payout ladder: what each finishing place on the RP leaderboard is paid when a season closes.

## What it does
1. Holds `Brackets` — six ordered, inclusive rank ranges paying Tokens, the top three also carrying a `titlePlace`. `#1` 2000, `#2` 1200, `#3` 800, `#4-10` 300, `#11-30` 200, `#31-100` 100; 17,100 Tokens per season in total
2. `LAST_PAID_RANK = 100`, matching RankLeaderboardService's `TOP_N` — the board serves exactly one OrderedDataStore page and that page is exactly the paid range
3. `bracketFor(rank)` walks the brackets in order and returns the first containing the rank, or nil outside the paid range. Brackets must stay **contiguous from 1**: a gap silently pays nothing for the ranks inside it rather than erroring
4. `rewardFor(season, rank)` → `{ tokens, titleIds }`. `titleIds` is every hunter's copy of that place's season title, resolved through [[TitlesConfig]]; empty for brackets that pay Tokens alone
5. `displayRows()` → `{ label, tokens, hasTitle }` per bracket, with `label` collapsed to `#1` or `#4-10`. This is what the lobby flyout draws
6. **One table, two readers.** RankSeasonRewardService pays from it and RankLeaderboardClient advertises it, so the panel can never promise a number the payout does not honour
7. **BOUNTY-ONLY** — deliberately not a mirrored module. Redwater and Frostbite neither pay out nor draw the flyout, so a copy there would be a file to keep in sync for no reader. Same call as SkinCatalog. The mirrored pieces of this feature are TitlesConfig (the season titles) and Wallet (the `rank_season_reward` reason)

## Dependencies
- **Requires:** [[TitlesConfig]]
- **Required by:** RankSeasonRewardService, RankLeaderboardClient

## Connections
### RemoteEvents
None

### BindableEvents
None

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[TitlesConfig]] | `SeasonTitleIds(season, place)` | Every hunter's copy of a podium place's season title |
