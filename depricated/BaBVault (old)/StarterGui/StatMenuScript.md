# StatMenuScript

Tabbed stats menu with My Stats (progression + session + lifetime) and Scoreboard panels. Toggled with M key on PC; exported to `_G.ToggleStatMenu` for mobile access.

**Path:** `game.StarterGui.StatMenuGui.StatMenuScript`
**Type:** LocalScript (180 lines)
**Runs on:** Client

## Tabs

| Tab | Panel | Content |
|-----|-------|---------|
| My Stats | MyStatsPanel | Progression, session stats, lifetime stats |
| Scoreboard | ScoreboardPanel | All players with kills/deaths |
| Post Game | PostGamePanel | *(TODO: Phase 5 — wire to round-end event)* |

## My Stats Panel Sections

### Progression Section
- Cash, Level, XP (displayed as `XP % 1000 / 1000`)

### Session Section
- Kills, Deaths, K/D ratio, Time Alive, Time Dead

### Lifetime Section
- Lifetime Kills, Lifetime Deaths, Lifetime K/D, Playtime

## Scoreboard

- Dynamically creates rows for each player in the server
- Reads `SessionKills` and `SessionDeaths` from player attributes (set by [[DataService]])
- Rows alternate background transparency for readability
- Columns: Name (50%), Kills (25%), Deaths (25%)

## Input

| Input | Action |
|-------|--------|
| M key (PC) | Toggle menu open/close |
| `_G.ToggleStatMenu()` | Called by [[InputController]] for mobile button |

## Data Flow

1. On open: fires `RequestStats` RemoteEvent to server
2. Server responds via `StatsResponse` with full stats table
3. `populateStats()` fills all labels from response data

## Time Formatting

- Under 1 hour: `M:SS` (e.g., "5:30")
- Over 1 hour: `Xh Ym` (e.g., "2h 15m")

## Dependencies

- [[ProgressionEvents]] (`RequestStats`, `StatsResponse`) — in Events folder
- Player attributes `SessionKills`, `SessionDeaths` — set by [[DataService]]
- `_G.ToggleStatMenu` — consumed by [[InputController]]

## Used By

- Runs automatically in PlayerGui when the player joins
