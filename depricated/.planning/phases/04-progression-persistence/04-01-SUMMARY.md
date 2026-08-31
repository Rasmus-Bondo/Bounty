---
plan: 04-01
phase: 04-progression-persistence
status: complete
completed: 2026-03-30
---

# Plan 04-01: DataService + Leaderstats — Summary

**Objective:** Create the DataStore persistence layer and extend leaderstats for the full player data model.

## What Was Built

### DataService ModuleScript
Created a comprehensive persistence layer at `game.ServerScriptService.RoundSystem.Modules.DataService` with:
- **DataStore integration:** Raw DataStore API (`PlayerData_v1`) with pcall error handling and retry logic (3 attempts, exponential backoff)
- **Auto-save system:** Every 5 minutes for all connected players
- **Session tracking:** Kills, Deaths, TimeAlive, TimeDead tracked per player
- **Time tracking:** Heartbeat-based accumulation with CharacterAdded/Humanoid.Died hooks
- **Player lifecycle:** Load on join, save on disconnect (PlayerRemoving), parallel saves on BindToClose
- **Client communication:** RequestStats/StatsResponse RemoteEvents for stat menu UI
- **Scoreboard support:** Session stats exported as player attributes (SessionKills, SessionDeaths) for client-readable data

### Extended Leaderstats
Modified `game.ServerScriptService.RoundSystem.Modules.LeaderstatService` to create:
- Cash NumberValue (existing)
- **Level NumberValue** (new, defaults to 1)
- **XP NumberValue** (new, defaults to 0)

### ProgressionEvents
Created folder structure at `game.ReplicatedStorage.Events.ProgressionEvents` with RemoteEvents:
- RequestStats (client → server)
- StatsResponse (server → client)
- LevelUp (server → client, for future level-up notifications)

### Server Initialization
Modified `game.ServerScriptService.RoundSystem.MainServer` to require and initialize DataService after LeaderstatService (ensures leaderstats exist before DataService populates them).

## Key Implementation Details

**Data structure (DEFAULT_DATA):**
```lua
{
    Cash = 0,
    Level = 1,
    XP = 0,
    LifetimeKills = 0,
    LifetimeDeaths = 0,
    TotalPlaytime = 0,
}
```

**Session tracking:**
- TimeAlive increments every frame while character is alive (IsAlive = true)
- TimeDead increments every frame while character is dead (IsAlive = false)
- IsAlive state managed by CharacterAdded (sets true) and Humanoid.Died (sets false)

**BindToClose behavior:**
- Skips in Studio (task.wait(1) and return)
- In live servers: parallel saves for all players not already saved, 25s timeout
- Logs completion: `[DataService] BindToClose: saved N players in Xs`

**Scoreboard integration:**
- `DataService.incrementSessionStat` calls `player:SetAttribute("Session" .. statName, value)` after updating session tracker
- Allows Plan 04-03's scoreboard to read SessionKills/SessionDeaths without RemoteEvents

## Files Modified

| File | Change |
|------|--------|
| game.ServerScriptService.RoundSystem.Modules.DataService | Created (359 lines) |
| game.ServerScriptService.RoundSystem.Modules.LeaderstatService | Extended with Level and XP NumberValues |
| game.ServerScriptService.RoundSystem.MainServer | Added DataService require and Initialize() call |
| game.ReplicatedStorage.Events.ProgressionEvents | Created folder with 3 RemoteEvent children |

## Integration Points

**For Plan 04-02 (ProgressionService):**
- `DataService.getPlayerData(player)` — returns cached data for reading Cash/Level/XP
- `DataService.incrementSessionStat(player, "Kills", 1)` — call after kill confirmation
- `DataService.updateLeaderstats(player)` — call after modifying Cash/Level/XP to sync leaderstats

**For Plan 04-03 (StatMenuGui):**
- RequestStats RemoteEvent — client fires to request stat data
- StatsResponse RemoteEvent — server fires back with statsPayload table
- Player attributes — SessionKills, SessionDeaths readable by all clients for scoreboard

## Self-Check

- [x] DataService loads player data on join with pcall error handling
- [x] Data auto-saves every 5 minutes
- [x] Data saves on player disconnect (PlayerRemoving)
- [x] BindToClose handles server shutdown with parallel saves
- [x] Leaderstats folder contains Cash, Level, XP NumberValues
- [x] TimeAlive increments while alive, TimeDead while dead
- [x] Session stats exported as player attributes (SessionKills, SessionDeaths)
- [x] ProgressionEvents folder created with 3 RemoteEvents
- [x] DataService initializes in MainServer after LeaderstatService
- [x] All acceptance criteria from plan met

**Status:** ✓ PASSED

## Testing Notes

To verify in Roblox Studio:
1. Press F5 (Play Solo) — check Output for `[DataService] Initializing...` and `[DataService] Initialized`
2. Check player's leaderstats in Explorer — should show Cash=0, Level=1, XP=0
3. Check player attributes in command bar: `game.Players:GetPlayers()[1]:GetAttribute("SessionKills")` returns 0
4. For BindToClose: Start 2-player test server, stop server, check Output for save completion log

## Known Limitations

- **POST-GAME STAT BOARD (STAT-02):** Partially implemented. PostGamePanel component will be created in Plan 04-03 but wiring to round-end event deferred to Phase 5 (round system doesn't exist yet).
- **TIME REWARDS (D-10):** Time-based XP/cash rewards will be implemented in Plan 04-02, but the "during active round" check is deferred to Phase 5 (no RoundController state to check yet).

---

*Plan: 04-01-PLAN.md*
*Phase: 04-progression-persistence*
*Completed: 2026-03-30*
