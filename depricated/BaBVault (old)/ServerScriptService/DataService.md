# DataService

Handles all player data persistence via DataStoreService. Manages a server-side cache, session tracking (kills, deaths, time alive/dead), auto-saving, and graceful shutdown saves.

**Path:** `game.ServerScriptService.PlayerServices.DataService`
**Type:** ModuleScript (378 lines)
**Runs on:** Server

## How It Works

### DataStore

- Store name: `"PlayerData_v1"`
- Data encoded as JSON via HttpService before saving
- Keys: player UserId as string

### Default Data Schema

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| Cash | number | 0 | In-game currency |
| Level | number | 1 | Player level |
| XP | number | 0 | Experience points |
| LifetimeKills | number | 0 | Total kills across all sessions |
| LifetimeDeaths | number | 0 | Total deaths across all sessions |
| TotalPlaytime | number | 0 | Cumulative play time (seconds) |

New fields are automatically merged with defaults on load (schema migration).

### Session Tracker (per player, in-memory only)

| Field | Type | Description |
|-------|------|-------------|
| Kills | number | Kills this session |
| Deaths | number | Deaths this session |
| TimeAlive | number | Seconds alive during active rounds (opted-in only) |
| TimeDead | number | Seconds dead this session |
| JoinTime | number | `os.clock()` at session start (reset on each save) |
| LastAliveTime | number | Last time marked alive |
| IsAlive | boolean | Currently alive |

### Loading (`loadPlayerData`)

1. Calls `safeGet` with retry (up to 3 attempts, exponential backoff: 2s, 4s)
2. Decodes JSON if stored as string
3. Merges with `DEFAULT_DATA` to handle schema additions
4. Initializes session tracker
5. Sets `SessionKills`/`SessionDeaths` attributes on player (client-readable)

### Saving (`safeSave`)

1. Updates `TotalPlaytime` by adding elapsed time since `JoinTime`
2. Resets `JoinTime` to current time for next save interval
3. JSON-encodes data, calls `SetAsync`

### Time Tracking

Per-player Heartbeat connection:
- **Alive + round active + opted in**: increments `TimeAlive`
- **Dead**: increments `TimeDead`
- Tracks alive/dead state via CharacterAdded and Humanoid.Died events

### Save Triggers

| Trigger | Behavior |
|---------|----------|
| PlayerRemoving | Save + cleanup caches + cleanup time tracking |
| Auto-save loop | Every `AUTO_SAVE_INTERVAL` (300s / 5 min), saves all players |
| BindToClose | Saves all unsaved players on server shutdown (25s timeout, skips in Studio) |

Uses `savedPlayers` table to prevent double-save between PlayerRemoving and BindToClose.

### Stats Request Handler

Listens on `ProgressionEvents.RequestStats` RemoteEvent. Responds with a payload containing:
- Progression: Cash, Level, XP, XPToNextLevel
- Session: SessionKills, SessionDeaths, TimeAlive, TimeDead
- Lifetime: LifetimeKills, LifetimeDeaths, TotalPlaytime

### Public API

| Method | Description |
|--------|-------------|
| `loadPlayerData(player)` | Load from DataStore, init cache + session |
| `getPlayerData(player)` | Get cached persistent data |
| `getSessionData(player)` | Get session tracker |
| `incrementSessionStat(player, statName, amount)` | Increment session + lifetime stat, update attribute |
| `updateLeaderstats(player)` | Sync cache → leaderstats/PlayerStats values |

## Dependencies

- [[Config]] — AUTO_SAVE_INTERVAL, XP_PER_LEVEL
- [[State]] — roundActive (for time tracking gates)
- [[LobbyService]] — isOptedIn (for time tracking gates)
- [[LeaderstatService]] — creates leaderstats/PlayerStats folders (waited for)
- DataStoreService, HttpService, RunService
- ReplicatedStorage.Events.ProgressionEvents — RequestStats, StatsResponse, LevelUp

## Used By

- [[MainServer]] — Initialize() called at boot
- [[ProgressionService]] — reads/writes player data, increments stats
- [[RoundController]] — (indirectly via ProgressionService)
