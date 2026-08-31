---
tags: [server, modulescript, teleport]
path: game.ServerScriptService.PlayerServices.LeaveToLobbyService
type: ModuleScript
lines: 144
---

# LeaveToLobbyService

Teleports a player back to the Bounty lobby place on request, retrying until it sticks.

## What it does
1. Handles `LeaveToLobbyRequest` from the client
2. Builds `TeleportOptions` and attaches the player's original arrival TeleportData via `RoundController.getReturnTeleportData(player)` before calling `SetTeleportData()`, so a player leaving early (e.g. the "RETURN TO BOUNTY" button) carries the exact same group payload as a normal end-of-round teleport — the payload is no longer filtered by which members are still present, so even the last member of a group to leave keeps their party data
3. Calls `TeleportService:TeleportAsync(Config.LOBBY_PLACE_ID, { player }, teleportOptions)` in a `pcall`, building a fresh `TeleportOptions` on every attempt
4. Retries up to `MAX_ATTEMPTS` (3) total attempts when the call throws synchronously, backing off `RETRY_DELAY` (1.5s) × attempt number
5. Listens to `TeleportService.TeleportInitFailed` to catch the async failure path — `TeleportAsync` returning cleanly does not mean the player left, and a teleport that dies during initiation (Flooded, GameEnded, GameFull, …) otherwise strands the player on a closing server with a dead button. `Flooded` / `IsTeleporting` / `GameFull` back off `BACKOFF_DELAY` (6s) instead of the normal delay
6. Tracks attempts per player in an `attempts` table shared by both retry paths so they run off one budget; a player only enters the table after requesting a leave, which stops the `TeleportInitFailed` listener from stealing [[RoundController]]'s end-of-round teleports (those still have no retry of their own)
7. Ignores repeat button presses while a retry chain is already running for that player
8. Clears the player's attempt count on `Players.PlayerRemoving`, which makes any pending retry a no-op once the teleport succeeds
9. No-ops if `Config.LOBBY_PLACE_ID` is 0 (matches the guard [[RoundController]] uses for its own end-of-round lobby teleports), and warns and bails out of `Start()` if the `LeaveToLobbyRequest` remote is missing

## Dependencies
- **Requires:** [[Config]], [[RoundController]]
- **Required by:** Main

## Connections
### RemoteEvents
| Remote | Direction | Other script |
|--------|-----------|-------------|
| `LeaveToLobbyRequest` | ← Client | [[SettingsController]] fires after the player confirms leaving; also fired by [[VictoryShowcaseClient]]'s "RETURN TO BOUNTY" button on the post-round stats screen |

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[Config]] | `Config.LOBBY_PLACE_ID` | Destination place for the teleport |
| [[RoundController]] | `RoundController.getReturnTeleportData(player)` | Returns the player's original arrival `TeleportData` so group state survives an early leave |
