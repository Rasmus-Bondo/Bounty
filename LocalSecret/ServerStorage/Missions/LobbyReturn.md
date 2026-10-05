---
tags: [server, modulescript, missions, teleport]
path: game.ServerStorage.Missions.LobbyReturn
type: ModuleScript
lines: 75
---

# LobbyReturn

Individual Secret-to-lobby teleport with retry and failure handling (issue #62).

## What it does
1. `Send(player, reason)` teleports ONE player (never teammates) to `LobbyPlaceId` with TeleportData `{source="Secret", reason}`; returns false if a teleport is already pending. Sets `PVEReturningToLobby` and posts "Heading back to town..." through the `PVEExplorationMessage` attributes.
2. Only moves the player: callers validate eligibility and grant rewards first, so a retried or failed teleport can never re-grant anything.
3. Retries a failed `TeleportAsync` call, and transient `TeleportInitFailed` results (Flooded/Failure), up to `MaxAttempts` with `RetryDelay`; a token guards against stale retries. On final failure it clears the pending state and tells the player "Couldn't reach town - try leaving again", leaving them where they stand.
4. An accepted teleport clears itself after `PendingTimeout` if neither departure nor a failure arrives; PlayerRemoving drops the entry.
5. `IsPending(player)` lets callers skip players already on their way.

## Dependencies
- **Requires:** [[LobbyReturnConfig]]
- **Required by:** MissionServer

## Connections
### RemoteEvents
None

### BindableEvents
None

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[LobbyReturnConfig]] | `LobbyPlaceId`, `MaxAttempts`, `RetryDelay`, `PendingTimeout` | Destination and retry policy |
