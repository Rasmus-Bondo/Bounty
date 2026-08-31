---
tags:
  - shared
  - modulescript
  - config
  - mirrored
  - gamemode
path: game.ReplicatedStorage.Config.GamemodeConfig
type: ModuleScript
lines: 90
---

# GamemodeConfig

The universe-wide gamemode registry — one row per mode, mirrored verbatim into all three places.

## What it does
1. Declares `DEFAULT_ID = "deathmatch"`. Readers must treat an **absent** mode — an old directory
   entry, an old reservation record, `TeleportData` with no `gamemode` field — as this id rather
   than as unknown, because publishing does not update servers that are already running.
2. Declares `Modes`, an ordered array the lobby picker renders in order. Each row carries `id`,
   `displayName`, `blurb`, `roundTime`, `usesZone`, `teamCount` (0 = free-for-all) and
   `targetParticipants`.
3. Ships two rows: `deathmatch` (FFA, 360s, zone on, 0 teams) and `tdm` (360s, zone off, 2 teams).
4. `get(id)` returns a row or nil; `isValid(id)` is the boolean form; `list()` returns the ordered
   array. Callers decide whether nil means fall back to the default (reading old records) or fail
   loudly (boot asserts).

## Why it is universe tier
The match places resolve their rules module and round length from it, and Bounty's picker and
matchmaker read the same rows, so the three copies must agree. A new gamemode is a row here plus a
rules module under `ServerScriptService.RoundSystem.Gamemodes` in each match place — never a new
place. Which maps may run a mode is the per-place `MapConfig.Gamemodes` list, and the match place
asserts the resolved mode against both at boot.

The tutorial is deliberately **not** a row. The lobby picker calls it a mode because that is how it
reads to a player, but in code a tutorial server is one that publishes no directory entry and runs
`runTutorialSession()` instead of the round loop.

## Domination row (2026-08-22)

Third row: `id = "domination"`, displayName "Domination", `roundTime = 600`, `usesZone = false`,
`teamCount = 2`, `targetParticipants = 14`, plus a new optional field **`scoreLimit = 500`**:
objective modes end early at this score through RoundController mode hook #10; absent on the two
kill modes. It lives on the row rather than in RoundSystem.Config because the client HUD renders it.

## Dependencies
- **Requires:** Nothing
- **Required by:** TeamAffinity, RoundController, MatchDirectoryService; in Bounty, the gamemode
  picker and the matchmaker

## Connections
### RemoteEvents
None

### BindableEvents
None

### Direct require()
None
