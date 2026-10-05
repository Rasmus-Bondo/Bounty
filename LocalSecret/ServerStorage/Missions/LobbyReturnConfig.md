---
tags: [server, modulescript, config, missions, teleport]
path: game.ServerStorage.Missions.LobbyReturnConfig
type: ModuleScript
lines: 13
---

# LobbyReturnConfig

Destination and retry policy for leaving Secret for the lobby.

## What it does
1. `LobbyPlaceId` (90720424663491) is the only place in Secret that names the lobby place id; a TODO (#66) moves it into the mirrored GameEnvironment so it resolves per environment.
2. `MaxAttempts` 3 total tries for transient teleport failures, `RetryDelay` 3 s.
3. `PendingTimeout` 30 s, after which a pending teleport with no departure or failure clears so the player can ask again.

## Dependencies
- **Requires:** Nothing
- **Required by:** LobbyReturn

## Connections
None. Pure data module.
