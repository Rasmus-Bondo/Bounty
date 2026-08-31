---
tags: [server, modulescript, dailyreward, progression]
path: game.ServerScriptService.PlayerServices.DailyRewardService
type: ModuleScript
lines: 75
---

# DailyRewardService

EARNS the daily play-streak. Finishing a round credits the current reset-day: the streak advances (or resets to 1 if a full day was skipped), that day's reward is queued for claiming in the Bounty lobby, and the passive +10% boost is toggled (streak ≥ 7). Rewards are NOT granted here — they are claimed in Bounty (mirror service). Day 1 is normally granted FREE in the lobby (see Bounty `ensureFreeFirstDay`), so this service's first real advance for a player is usually Day 2. Rules live in [[DailyRewardConfig]].

## What it does
1. `registerPlay(player)` — called once per player at round end by RoundController. Applies any lapse first (`DailyRewardConfig.applyLapse` — clears a broken streak + its unclaimed queue), then, if not already credited today, advances `DailyStreak` (continue = +1, fresh/broken = 1), appends the new day number to `DailyPending`, stamps `DailyLastPlayDay = today`, and sets `DailyPermaBoost = true` once the streak reaches 7. Idempotent per reset-day — because the free Day 1 already stamps `DailyLastPlayDay = today`, a round finished the same day the free Day 1 was taken is a no-op (Day 2 waits for the next reset)
2. On `Start()` + PlayerAdded, calls `applyLapse` for each player so the passive boost reflects a broken streak for the round they are about to play (the profile persists cross-place, so a lapse detected in Bounty is already applied by the time they reach here)
3. Writes only streak state to the shared profile; the passive `DailyPermaBoost` flag is read by BoostService `getMultiplier`. The player is notified of a waiting reward when they load into the Bounty lobby (no round-end toast)

## Dependencies
- **Requires:** [[DataService]], [[DailyRewardConfig]]
- **Required by:** Main (starts it), RoundController (calls `registerPlay` at round end)

## Connections
### RemoteEvents
None

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[DataService]] | `getPlayerData()` | Read/write the daily streak fields on the profile |
| [[DailyRewardConfig]] | `dayNumber()`, `applyLapse()`, `ensureData()`, `PASSIVE_BOOST_START_DAY` | Reset-day math, break detection, field normalising, day-7 threshold |
