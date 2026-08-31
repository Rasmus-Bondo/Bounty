---
tags:
  - server
  - modulescript
  - ranked
  - progression
path: game.ServerScriptService.PlayerServices.RankedService
type: ModuleScript
lines: 170
---

# RankedService

Awards Rank Points (RP) at round end — a skill/performance score kept separate from the XP/Cash economy. Strictly additive within a season; the one thing that lowers it is a season reset, which this module also owns.

## What it does
1. Owns the tunable RP weights: `PerKill=2`, `PerAssist=1`, `PerHeadshot=1`, placement bonus `{1st=10, 2nd=7, 3rd=4, top-half=2}`, and a kill-streak bonus of `max(0, bestStreak-2) * 1` — trimmed ~33% on 2026-07-29 because players were climbing too fast
2. `computeRoundRP(stats, placement, totalPlayers)` — pure, side-effect-free RP calculation from an already-tallied stat entry; floored at 0 so a bad round awards exactly 0 and nothing is ever lost
3. Pays the placement bonus at every lobby size — there is no minimum-player guard (removed 2026-07-29). The arena holds a floor of `BotConfig.MinBots` fighters, so there is always a field to place against and no such thing as an empty-server round
4. `awardRound(player, stats, placement, totalPlayers)` — computes the round's RP, adds it to the player's persistent `RankPoints` total via [[DataService]], sets a `RankPoints` attribute on the player, and returns `{ gained, total }`
5. Mirrors each player's new running RP total to **this season's** global OrderedDataStore once per round end (write skipped when 0 RP gained) — the Bounty-lobby leaderboard reads the same store. The handle is resolved per award and cached by name rather than taken once at require time, because a season can roll over inside the lifetime of a single server and a startup handle would keep writing into the previous season's board. DataStore write is wrapped in pcall/task.spawn so it never blocks the round flow
6. `ensureSeason(player, data, season)` — **the entire ranked season reset**. Compares the profile's `RankSeason` against the current season from [[GameEnvironment]] and, on a mismatch, copies `RankPoints` into `LastSeasonRankPoints`, zeroes `RankPoints`, stamps the new season, and clears the player's `RankPoints` attribute. Idempotent: a profile already on the season is left alone, so RP earned after the boundary is not re-wiped every round
7. There is no bulk pass over stored data because there cannot be one — profile keys are not enumerable, so offline players are unreachable by definition. Each profile instead corrects itself on its first award of a new season, while the board players actually look at reads empty from the boundary onward because it is a brand-new store. A player who never returns keeps a stale number in a field nothing reads
8. The check runs at award time only. `RankPoints` has exactly one reader across both places (this module), so a stale value has nowhere to leak before it is corrected, and keeping the check here avoids a DataService → RankedService circular require. `awardRound` resolves the season ONCE and uses it for both the reset and the store handle, so an award landing on the boundary cannot zero against one season and publish into the other's board

## Dependencies
- **Requires:** [[DataService]], [[GameEnvironment]]
- **Required by:** RoundController

## Connections
### RemoteEvents
None

### BindableEvents
None

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[DataService]] | `getPlayerData()` | Read/write the player's persistent `RankPoints` total |
| [[GameEnvironment]] | `getRankSeason()`, `getRankStoreName()` | Current ranked season, and the name of that season's leaderboard store |
