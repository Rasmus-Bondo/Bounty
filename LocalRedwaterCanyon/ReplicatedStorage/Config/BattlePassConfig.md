---
tags: [shared, modulescript, battlepass, config]
path: game.ReplicatedStorage.Config.BattlePassConfig
type: ModuleScript
lines: 605
---

# BattlePassConfig

Single source of truth for the battle pass: every season's quest sets and reward tracks, the shared XP/level constants, and which season is live right now. Mirrored byte-for-byte from Bounty (and into Frostbite Claim).

## What it does
1. **Seasons are blocks in a `SEASONS` list** (oldest first), each with `SEASON_ID`, `SEASON_NUMBER`, `SEASON_NAME`, `SEASON_START`, `TEST_ALL_WEEKS_UNTIL`, `QUEST_PROGRESS_TOKEN`, `WEEKS`, `PAID`, `FREE`. Currently Season 1 (`S6`) and Season 2 *Trial by Fire* (`S7`, starts 2026-09-19 18:00 UTC / 20:00 CEST).
2. **`Config.<season field>` resolves to the LIVE season at read time** through a metatable `__index`. Live = the newest season whose `SEASON_START` has passed; a DEV-universe server always runs the newest. A match server that booted before the boundary switches by itself: the next `ensureData` rolls the player over and quest tracking moves to the new `WEEKS`.
3. Shared constants: `WEEK_SECONDS`, `TOTAL_WEEKS`, `XP_PER_LEVEL`, `TOTAL_LEVELS`, `FULL_PASS_PRICE`, `XP_SOURCES` (the BP XP this place awards per event), `ICONS` (unused here — this place has no pass UI).
4. `WEEKS` — the quests this place tracks (`BattlePassService.trackQuest`) and marks completed; the XP is claimed in Bounty. `PAID` / `FREE` are claimed in Bounty only.
5. `levelFromXP`, `currentWeek(now?)` (live season), `activeSeasonNumber(now?)` (read by TitlesConfig), `questById`, `exclusiveSkins` / `isExclusiveSkin` (built from every season block).

## Dependencies
- **Requires:** [[GameEnvironment]]
- **Required by:** BattlePassService, TitlesConfig

## Connections
### RemoteEvents
None

### BindableEvents
None

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[GameEnvironment]] | `env`, `isLive` | DEV runs the newest season; the pre-launch week preview is honoured only off-live |
