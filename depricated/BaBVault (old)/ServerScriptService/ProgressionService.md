# ProgressionService

Awards XP and Cash for kills, deaths, round completion, and survival time. Handles level-up detection and fires LevelUp events to clients.

**Path:** `game.ServerScriptService.PlayerServices.ProgressionService`
**Type:** ModuleScript (149 lines)
**Runs on:** Server

## How It Works

### Reward Methods

| Method | XP | Cash | Also Does |
|--------|-----|------|-----------|
| `awardKill(player)` | XP_PER_KILL (100) | CASH_PER_KILL (10) | Increments session+lifetime kills, checks level-up |
| `awardDeath(player)` | — | — | Increments session+lifetime deaths only |
| `awardRoundCompletion(player)` | ROUND_BONUS_XP | ROUND_BONUS_CASH | Checks level-up |

### Level-Up Detection

```
newLevel = floor(XP / XP_PER_LEVEL) + 1
```

- `XP_PER_LEVEL` = 1000 (linear progression)
- If `newLevel > data.Level`, updates level and fires `LevelUp` RemoteEvent to client with the new level number

### Time-Based Rewards

A background loop runs every 10 seconds:
1. Only active during `State.roundActive`
2. For each player who is opted in, alive, and has a humanoid with health > 0:
   - Tracks cumulative `TimeAlive` from session data
   - Every `TIME_REWARD_INTERVAL` seconds of alive time, awards `TIME_REWARD_XP` + `TIME_REWARD_CASH`
3. Uses `timeRewardTracker[userId]` to track last rewarded alive-time threshold
4. Cleaned up on PlayerRemoving

### Stats Request Handler

Also listens on `ProgressionEvents.RequestStats` (note: DataService has a similar handler). Merges persistent data with session data (SessionKills, SessionDeaths, TimeAlive, TimeDead) and fires back via `StatsResponse`.

## Dependencies

- [[Config]] — XP_PER_KILL, CASH_PER_KILL, XP_PER_LEVEL, ROUND_BONUS_XP/CASH, TIME_REWARD_INTERVAL/XP/CASH
- [[DataService]] — getPlayerData, getSessionData, incrementSessionStat, updateLeaderstats
- [[State]] — roundActive
- [[LobbyService]] — isOptedIn
- ReplicatedStorage.Events.ProgressionEvents — LevelUp, RequestStats, StatsResponse

## Used By

- [[MainServer]] — Initialize() called at boot
- [[RoundController]] — calls awardKill (via kill event), awardDeath (on Died), awardRoundCompletion (end of round)
