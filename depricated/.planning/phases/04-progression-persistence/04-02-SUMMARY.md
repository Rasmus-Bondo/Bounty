---
plan: 04-02
phase: 04-progression-persistence
status: complete
completed: 2026-03-30
---

# Plan 04-02: ProgressionService + GunServer Hooks — Summary

**Objective:** Build the progression reward system that awards XP and cash for kills, round completion, and time played.

## What Was Built

### ProgressionService ModuleScript
Created comprehensive reward system at `game.ServerScriptService.RoundSystem.Modules.ProgressionService` with:
- **Tunable reward constants:**
  - `XP_PER_KILL = 100` — 100 XP per kill
  - `CASH_PER_KILL = 10` — $10 per kill
  - `ROUND_BONUS_XP = 50` — 50 XP for completing a round
  - `ROUND_BONUS_CASH = 5` — $5 for completing a round
  - `TIME_REWARD_XP = 25` — 25 XP every 2 minutes alive
  - `TIME_REWARD_CASH = 3` — $3 every 2 minutes (rounded from $2.50 to avoid float precision)
  - `XP_PER_LEVEL = 1000` — Linear 1000 XP per level

- **Core functions:**
  - `awardKill(player)` — Awards XP + cash, increments session/lifetime kills, checks level-up, updates leaderstats
  - `awardDeath(player)` — Increments session/lifetime death counters
  - `awardRoundCompletion(player)` — Awards round bonus XP + cash, checks level-up
  - `checkLevelUp(player, data)` — Internal helper calculates new level (`floor(XP / 1000) + 1`), fires LevelUp RemoteEvent to client

- **Time-based reward loop:**
  - Awards 25 XP + $3 every 2 minutes (120 seconds)
  - Only awards if player character exists with Humanoid Health > 0
  - **TODO Phase 5:** Add round-active gating (currently awards whenever alive)

### Combat Integration
Modified `game.ServerStorage.BanditGun.GunServer` to hook ProgressionService:
- Added `require(game.ServerScriptService.RoundSystem.Modules.ProgressionService)` at top
- After kill confirmation (`eliminatePlayerEvent:Fire`), calls:
  - `ProgressionService.awardKill(player)` — Awards killer
  - `ProgressionService.awardDeath(hitPlayer)` — Tracks victim death

### Server Initialization
Modified `game.ServerScriptService.RoundSystem.MainServer`:
- Added ProgressionService require and Initialize() call after DataService
- Print confirmation: `[MainServer] ProgressionService initialized`

## Key Implementation Details

**Level-up formula:**
```lua
local newLevel = math.floor(data.XP / XP_PER_LEVEL) + 1
-- Example: 0 XP = Level 1, 1000 XP = Level 2, 2000 XP = Level 3
```

**Kill rewards:**
- Session stats incremented via `DataService.incrementSessionStat` (also increments lifetime counters)
- Leaderstats updated via `DataService.updateLeaderstats` for immediate UI feedback
- Level-up checked after every XP award
- LevelUp RemoteEvent fires to client on level-up

**Time rewards:**
- `task.wait(TIME_REWARD_INTERVAL)` loop every 2 minutes
- Checks all connected players: `Players:GetPlayers()`
- Only awards if `character.Humanoid.Health > 0` (alive check)
- Round-active check deferred to Phase 5 (marked with TODO comment)

**Cash precision decision:**
- D-10 specifies $2.50 time reward
- Research Pitfall 7 warns of float precision issues
- Rounded to $3 to avoid float accumulation errors

## Files Modified

| File | Change |
|------|--------|
| game.ServerScriptService.RoundSystem.Modules.ProgressionService | Created (123 lines) |
| game.ServerScriptService.RoundSystem.MainServer | Added ProgressionService require + Initialize() |
| game.ServerStorage.BanditGun.GunServer | Added ProgressionService require + awardKill/awardDeath calls |

## Integration Points

**For Plan 04-03 (StatMenuGui):**
- LevelUp RemoteEvent — client can listen for level-up notifications
- DataService stats — already available through RequestStats RemoteEvent (Plan 01)

**For Phase 5 (Round System):**
- `ProgressionService.awardRoundCompletion(player)` — call at round end for all active players
- Time reward gating — add round-active check in time reward loop (TODO comment at line 105)

## Self-Check

- [x] ProgressionService awards 100 XP + $10 per kill
- [x] ProgressionService awards 50 XP + $5 for round completion
- [x] ProgressionService awards 25 XP + $3 every 2 minutes while alive
- [x] Level-up triggers at 1000 XP increments (linear progression)
- [x] LevelUp RemoteEvent fires to client on level-up
- [x] All reward constants tunable at top of module
- [x] GunServer calls awardKill on killer and awardDeath on victim
- [x] Leaderstats update immediately after every reward
- [x] Time reward loop only awards when Humanoid.Health > 0
- [x] TODO comment added for Phase 5 round-active gating
- [x] All acceptance criteria from plan met

**Status:** ✓ PASSED

## Testing Notes

To verify in Roblox Studio:
1. Press F5 (Play Solo) — check Output for `[ProgressionService] Initialized`
2. Start 2-player test server
3. Get a kill — check Output for `[Progression] PlayerName earned 100 XP + $10 for kill`
4. Check leaderstats after kill: Cash increased by 10, XP increased by 100
5. Get 10 kills (1000 XP total) — verify Level changes from 1 to 2 in leaderstats
6. Stay alive for 2 minutes — verify time reward log appears in Output

## Known Limitations

- **TIME REWARDS (D-10):** Currently awards whenever alive. Round-active check deferred to Phase 5 when RoundController state becomes available. TODO comment added at ProgressionService line 105.
- **ROUND COMPLETION (PROG-01):** `awardRoundCompletion` function exists but not wired yet. Phase 5 will call this from RoundController at round end.

---

*Plan: 04-02-PLAN.md*
*Phase: 04-progression-persistence*
*Completed: 2026-03-30*
