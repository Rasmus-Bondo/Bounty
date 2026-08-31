---
tags: [shared, modulescript, environment, config, release]
path: game.ReplicatedStorage.Config.GameEnvironment
type: ModuleScript
lines: 221
---

# GameEnvironment

Single source of truth for which universe a server is in and where its sibling places live. Identical copy must exist in all three places (universe mirror) — edit them together and verify with `/mirror universe`.

## What it does
1. Exports `version` — the human release name ("Launch", "Update N", "Hotfix N.1"), bumped as part of the publish ritual
2. Holds an `ENVIRONMENTS` table keyed by PlaceId; each universe declares ONE siblings table (`bounty`/`redwater`/`frostbite`) shared by its rows, so a new map cannot be forgotten on some row. **Two universes as of 2026-08-14: Live and the DEV universe** (GameId 10696738139, a separate experience — DataStore/MemoryStore isolation from live is free by construction, no store-name suffixing anywhere). Dev places get their content by publishing a live place AS its dev twin; this module rides along and the dev place resolves itself off its own PlaceId
3. Resolves the current row from `game.PlaceId` and exports `env` ("Live" | "Dev" | "Unknown"), `place`, `isLive`, `bountyPlaceId`, `redwaterPlaceId`, `frostbitePlaceId`
4. Falls back to the live ids with `env = "Unknown"` and a loud `warn` when a PlaceId has no row, preserving the old inline-table behaviour of labelling unrecognised places "Unknown"
5. `buildString()` — combines `version` with the live `game.PlaceVersion` into the tag shown on screen, suffixing non-live environments so a DEV screenshot can never be mistaken for a live one. Reads `PlaceVersion` inside a `pcall` so a client-side failure cannot take its caller down
6. Owns the **ranked season table**: `RANK_SEASONS` is an ascending list of UTC epoch seconds at which each season begins (season 1 starts at 0, so every timestamp resolves to some season). `getRankSeason()` returns the current season number from the wall clock; `getRankStoreName(season)` maps it to that season's leaderboard OrderedDataStore name, `RankPoints_v<season>`, defaulting to the current season. Both are resolved live from `os.time()` on every call rather than cached at require time, so a server that booted before a boundary rolls over on its own with no restart and no republish. Scheduling the next RP reset is one appended epoch plus a republish of both places `getRankSeasonEnd(season)` returns the epoch at which a season **ends** — `RANK_SEASONS[season + 1]`, or nil for the last row, which runs forever until another is appended. The lobby rewards flyout counts down to it, and RankSeasonRewardService treats a non-nil result as its proof that a season is closed and safe to pay out. Season 5 (2026-09-12 20:00 CEST, epoch 1789236000) was appended so that Season 4 has an end and can be paid.
7. The season number doubling as the store suffix is what makes an RP reset possible at all: per-player RP lives in un-enumerable profile keys and an OrderedDataStore has no clear-all, so nothing can be bulk-zeroed in place. Pointing at a **new** store name instead yields a board that is empty by construction, and the previous season's store is never touched — a reset destroys nothing and is undone by deleting its row here

8. **DEV-only mock season schedule** (2026-08-27, **test fixture — see open item 129**). `DEV_RANK_SEASONS` is a second table carrying two rows the live one does not: season 4 opening at `1787788800` (already past) and season 5 at `1788019200` = 2026-08-29 18:00 CEST, the boundary that closes season 4 so `RankSeasonRewardService` pays it out — a dry run so the first real payout on 09-12 is not the first time the path has ever run. `seasonTable()` picks the table and is gated on `env == "Dev"` **explicitly, never on `not isLive`**: an unpublished Studio place resolves to `"Unknown"` through the ENVIRONMENTS fallback, and `not isLive` would hand it the mock schedule and pay a season that never happened. Verified across all three env values — `Live` and `Unknown` both enumerate the unchanged four live boundaries with nothing payable, only `Dev` sees the mock. DEV season numbers are shifted **+2** against live until the fixture is removed.
9. **Player-facing season numbering.** `RANK_SEASON_DISPLAY_OFFSET = 3` and `getRankSeasonDisplay(season)` return the number players see, which is the code number minus the offset, clamped at 1. Code seasons 1-3 ran before the reward ladder existed — no payout, no titles, nothing anyone was told about — so the first *rewarded* season (code 4) reads as **SEASON 1**. Every player-facing surface resolves it here rather than subtracting its own: the rewards flyout, the season title labels and their wardrobe badges, and the reward card. The code number stays the authority everywhere else — it is the OrderedDataStore suffix, the profile's `RankRewards` key and the title ids. **The offset is fixed once the first rewarded season closes**: players will have screenshots of "SEASON 1 CHAMPION", so a shipped season cannot be renumbered afterwards.
## Why it exists
Teleport destinations used to be hardcoded live PlaceIds. Copying a place into a DEV universe with those constants intact would send testers into live matches with real player data. Editing the constants per environment is worse, because every promotion then depends on remembering to flip them back. Resolving siblings from the server's own PlaceId means a DEV server can only reach DEV and a live server only live, so promotion is a pure copy.

## Dependencies
- **Requires:** Nothing
- **Required by:** Wallet, TesterGrantService, Telemetry, TitlesConfig, PartyService, MatchmakingService, FriendJoinService, VersionTagController, SoftShutdown, RankLeaderboardService

## Connections
### RemoteEvents
None

### BindableEvents
None

### Direct require()
None
