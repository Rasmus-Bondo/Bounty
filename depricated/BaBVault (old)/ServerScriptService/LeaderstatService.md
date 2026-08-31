# LeaderstatService

Creates the standard Roblox leaderstats folder and a PlayerStats folder on each player. These hold the values displayed on the leaderboard and used by the progression system.

**Path:** `game.ServerScriptService.PlayerServices.LeaderstatService`
**Type:** ModuleScript (42 lines)
**Runs on:** Server

## How It Works

On PlayerAdded (and for existing players at init):

### leaderstats Folder (visible on leaderboard)

| Value | Type | Default | Description |
|-------|------|---------|-------------|
| Cash | NumberValue | 0 | In-game currency |
| Level | NumberValue | 1 | Player level |

### PlayerStats Folder (internal tracking)

| Value | Type | Default | Description |
|-------|------|---------|-------------|
| XP | NumberValue | 0 | Experience points toward next level |

Guards against duplicates — checks `FindFirstChild` before creating.

## Dependencies

- Players service

## Used By

- [[MainServer]] — Initialize() called at boot
- [[ProgressionService]] — reads/writes Cash, Level, XP values
- [[DataService]] — saves/loads these values to DataStore
- Replaces deprecated `leaderstat` script
