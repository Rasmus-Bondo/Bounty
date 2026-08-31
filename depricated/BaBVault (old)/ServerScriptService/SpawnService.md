# SpawnService

Handles all player teleportation — lobby spawns, round spawns, zone-safe spawn filtering, and corpse cleanup.

**Path:** `game.ServerScriptService.RoundSystem.SpawnService`
**Type:** ModuleScript (145 lines)
**Runs on:** Server

## How It Works

### Utility Functions

- `getCharacterRoot(character)` — returns HumanoidRootPart
- `getHumanoid(character)` — returns Humanoid
- `getSpawnParts(container)` — collects all BasePart children from a folder
- `shuffleArray(array)` — Fisher-Yates shuffle for randomized spawn assignment

### Teleportation

All teleports position the player 4 studs above the spawn part's CFrame to prevent ground clipping.

- `teleportPlayerToSpawn(player, spawnPart)` — core teleport (guards for alive character)
- `sendPlayerToLobby(player)` — random lobby spawn
- `teleportPlayersToUniqueLobbySpawns(playersList)` — shuffled unique spawns, wraps if more players than spawns
- `teleportAllToLobby()` — all players to lobby
- `sendPlayerToRoundSpawn(player)` — picks a random round spawn, **filters to safe zone** spawns first (falls back to all spawns if none are safe)
- `teleportPlayersToRound(banditPlayer)` — round start: bandit goes to BanditSpawn (supports both single BasePart and Folder of spawns), townsfolk get shuffled unique round spawns

### Other

- `clearCorpses()` — clears `workspace.Corpses` folder
- `ensureAllPlayersAlive()` — calls `LoadCharacter()` on any dead/missing characters

## Dependencies

- [[References]] — spawn folders, bandit spawn object
- [[ZoneService]] — `isPositionInSafeZone()` for zone-safe spawn filtering

## Used By

- [[RoundController]] — calls all spawn functions during round lifecycle
