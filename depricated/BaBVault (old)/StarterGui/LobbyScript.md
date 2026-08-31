# LobbyScript

Lobby join/leave button with 4 context-sensitive states, round timer, and player count display. Handles mid-round joining with a 5-second countdown confirmation.

**Path:** `game.StarterGui.LobbyGui.LobbyScript`
**Type:** LocalScript (135 lines)
**Runs on:** Client

## Button States

| State | Condition | Text | Color |
|-------|-----------|------|-------|
| 1 | Not opted in, no round | "Join Queue" | Green (60, 140, 60) |
| 2 | Not opted in, round active | "Join Match" | Green (60, 140, 60) |
| 3 | Opted in, no round | "Leave Queue" | Red (180, 60, 60) |
| 4 | Opted in, round active | "Leave Game" | Orange (200, 80, 40) |

## Mid-Round Join/Leave

When clicking during an active round:
1. Button becomes non-interactive
2. 5-second countdown displayed: `"Join Match (5)"`, `"(4)"`, etc.
3. After countdown completes, fires `JoinRound` or `LeaveRound` to server

When clicking outside a round: fires immediately (no countdown).

## Info Display

| Element | Content |
|---------|---------|
| PlayerCountLabel | "Players: X" — count of opted-in players |
| TimerLabel | Status + time, e.g., "Intermission 0:30" or "Time left 2:15" |

### Timer Logic

- Shows only game-phase statuses: "Waiting for players...", "Intermission", "Fight!"
- "Fight!" displays as "Time left" instead
- Winner announcements are filtered out (handled by [[PostGameScript]])
- Updates every 1 second via polling loop

## State Reactivity

Listens to:
- `player.OptedIn` attribute changes
- `workspace.RoundTimeLeft` attribute changes
- `RoundStatus` StringValue changes
- `RoundTime` IntValue changes

## Dependencies

- Player `OptedIn` attribute — set by [[LobbyService]]
- `workspace.RoundTimeLeft` attribute — set by [[RoundController]]
- [[RoundEvent]] RemoteEvent — sends `"JoinRound"` / `"LeaveRound"` to [[LobbyService]]
- `RoundStatus` (StringValue), `RoundTime` (IntValue) — in ReplicatedStorage

## Used By

- Runs automatically in PlayerGui when the player joins
