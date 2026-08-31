---
tags:
  - server
  - script
  - ranked
  - leaderboard
  - datastore
  - economy
path: game.ServerScriptService.RankSeasonRewardService
type: Script
lines: 260
---

# RankSeasonRewardService

Pays the ranked-season ladder to the top 100 of every closed season — Tokens through the Wallet, plus a season title for the top 3.

## What it does
1. **No scheduler, by design.** Roblox has nothing to run a job at a season boundary, and a "one server does the payout" lock would make the payout depend on a server being awake at 20:00 CEST. Payouts resolve **lazily on join**: a winner is paid the next time they open the lobby, however long that takes. Offline winners need no GlobalUpdate for the same reason — the reward is only visible in Bounty anyway
2. **Safe because a closed season's store is immutable.** A season reset works by pointing at a NEW OrderedDataStore name, so the previous season's store is never written again. Final standings are readable forever and the payout cannot race the reset — which is also why the standings cache never expires
3. `payableSeasons()` returns closed seasons from `FIRST_REWARDED_SEASON` (4) up to `currentSeason - 1`, bounded by `MAX_SEASON_LOOKBACK` (6 seasons, ~3 months). Seasons 1-3 closed before the ladder existed and are never paid retroactively
4. `fetchStandings(season)` does one `GetSortedAsync(false, 100)` per season per server and returns `(map, ok)`. The success flag is separate on purpose: a failed read and a genuinely empty season both produce an empty map, and treating a failure as "nobody placed" would silently pay the whole season nothing. **Only successful reads are cached**, so a failure retries on the player's next join
5. `paySeason` marks `data.RankRewards[season]` **before** granting. A half-applied grant is recoverable by hand; paying 2000 Tokens twice because the server died between the award and the write is not
6. Tokens go through `Wallet.award` with reason `rank_season_reward`, followed by `DataService.updateLeaderstats`. Titles go through `CollectionService.grantTitle`, once per hunter's copy of that place's title
7. Idempotency lives in the profile and is **lazily initialised** rather than added to `PROFILE_TEMPLATE`, so this needs no profile schema bump. Only seasons that actually paid are recorded — a player who did not place is never written, so re-checking them is a cache hit and profiles do not grow a key per season for everyone in the game
8. Runs for players already present at server start as well as on `PlayerAdded`, and polls up to 30s for ProfileService to finish loading. A timeout costs nothing permanent: the payout retries on the next join

9. **Fires `GiftNotice` on every grant**, reusing the lobby's existing reward card (`StarterGui.GiftGui`) rather than adding a second popup — that card is already payload-driven, already held behind `BountyIntroComplete` so it cannot open over the loading screen or mid intro-pan, and already modal and close-button-only. Payload sets `heading` to `SEASON <n>`, `message` to the finishing rank, the badge to the Token amount, and `detail` to the podium title's label. Every id in `titleIds` is the same title once per hunter, so the card names it once
10. **Live rollover** — a season boundary is a scheduled event, so players are in the lobby waiting for it rather than rejoining to collect. A poller re-reads `getRankSeason()` every 15s (it resolves from the wall clock on every call, so a running server rolls over with no restart) and pays everyone present when the number changes. **Not at boundary+0:** a Redwater round that ended seconds before the boundary is still writing RP to the closing season's store and `GetSortedAsync` is eventually consistent, so an instant read risks paying from an incomplete top 100 — and since the standings cache never expires, a bad read would be the one this server keeps for its whole life. `SETTLE_DELAY` (120s) plus up to 60s of jitter covers both, the jitter also keeping every server in the universe off the same second. The rollover path shares `paySeason` with the join path, so the profile mark is the same idempotency: paid-live-then-rejoining is not paid twice. Players in a match at the boundary are paid when they next reach the lobby
## Dependencies
- **Requires:** [[GameEnvironment]], [[RankRewardsConfig]], [[TitlesConfig]], [[DataService]], [[Wallet]], [[CollectionService]]
- **Required by:** Nobody (standalone Script)

## Connections
### RemoteEvents
| Remote | Direction | Other script |
|--------|-----------|-------------|
| `GiftNotice` | → Client | [[GiftPopupClient]] draws the reward card; `heading` + `detail` distinguish it from the developer gift |

### BindableEvents
None

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[GameEnvironment]] | `getRankSeason()`, `getRankSeasonEnd()`, `getRankStoreName()`, `getRankSeasonDisplay()` | Which seasons are closed, the store holding each one's final standings, and the player-facing season number on the reward card |
| [[RankRewardsConfig]] | `rewardFor(season, rank)`, `LAST_PAID_RANK` | The ladder — Tokens and title ids owed to a finishing rank |
| [[DataService]] | `getPlayerData()`, `updateLeaderstats()` | The profile, and the leaderstat sync after a Token award |
| [[Wallet]] | `award()` | Sole currency mutator; logs the economy Source event |
| [[CollectionService]] | `grantTitle()` | Writes the season title into `profile.OwnedTitles` |
| [[TitlesConfig]] | `LabelById` | The podium title's display label, for the reward card |
