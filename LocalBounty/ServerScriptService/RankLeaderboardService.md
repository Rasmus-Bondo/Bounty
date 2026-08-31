---
tags:
  - server
  - script
  - ranked
  - leaderboard
  - datastore
path: game.ServerScriptService.RankLeaderboardService
type: Script
lines: 235
---

# RankLeaderboardService

Serves the global Rank Points leaderboard to the Bounty lobby UI. Read-only.

## What it does
1. Reads the same per-season **OrderedDataStore** that Redwater Canyon's `RankedService` writes to (DataStores are shared across places in one universe), so the lobby shows cross-place RP totals. The store name is resolved through the shared season table in [[GameEnvironment]] — season 1 is `RankPoints_v1`, the store this board has read since it was built, so nothing about season 1 moves. Read-only: this place never writes RP
2. `GetSortedAsync(false, 100)` → the top 100 entries in a **single** call (OrderedDataStore page size maxes at 100, so top-100 costs the same one DataStore request as top-10). Uncached UserIds are resolved to **display names** in ONE batched `UserService:GetUserInfosByUserIdsAsync` call (`info.DisplayName`, falling back to `info.Username`); per-user fallback also goes through `GetUserInfosByUserIdsAsync` (single-id) rather than `GetNameFromUserIdAsync`, since that API only returns the username; names cached, and the whole top list is cached for 30s and shared by all requesters
3. `GetAsync(userId)` → the requesting player's own RP total (cached per-player 30s), plus their rank if they appear in the top 100
4. On the `RankLeaderboardRequest` RemoteEvent from a client, replies (`FireClient`) with `{ top, ownRP, ownRank }`. Requests are throttled to once per 5s per player, but a throttled request is **still answered** — `sendTo(player, cacheOnly)` serves it purely from cache (`getTop`/`getOwnRP` take a `cacheOnly` flag and never touch the DataStore), which is all the cooldown exists to protect. Every request getting a reply matters to the client: [[RankLeaderboardClient]] holds its open animation until data arrives, so silently dropping a request left the board waiting on a reply that was never coming
5. Also pushes one update ~2s after a player joins so the board populates without waiting for the first client request
6. All DataStore calls are pcall-guarded so a disabled API / transient error degrades to an empty board rather than erroring
7. `syncSeason()` drops every cached row when the season rolls over, which can happen inside the lifetime of a single lobby server. It runs on **every** request rather than only on DataStore misses, because a cache HIT is precisely the case that would otherwise keep serving the previous season's top 100 for up to 30s past the reset — a leaderboard meant to be empty, still listing names

## Dependencies
- **Requires:** [[GameEnvironment]]
- **Required by:** Nobody (standalone Script)

## Connections
### RemoteEvents
| Remote | Direction | Other script |
|--------|-----------|-------------|
| `RankLeaderboardRequest` | ← Client / → Client | [[RankLeaderboardClient]] requests the board; server replies with top list + own RP/rank |

### BindableEvents
None

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[GameEnvironment]] | `getRankSeason()`, `getRankStoreName()` | Current ranked season, and the name of that season's leaderboard store |
