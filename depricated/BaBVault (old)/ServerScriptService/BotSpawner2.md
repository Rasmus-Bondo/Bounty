# BotSpawner2

Identical to [[BotSpawner]] but uses `workspace.BotSpawner2` as the spawn location. Provides a second test bot at a different position.

**Path:** `game.ServerScriptService.Testing.BotSpawner2`
**Type:** Script (35 lines)
**Runs on:** Server

## How It Works

Same as [[BotSpawner]] — clones `ReplicatedStorage.BotRig`, spawns at `workspace.BotSpawner2` + 3 studs height, auto-respawns after 1 second on death.

## Dependencies

- ReplicatedStorage.BotRig — bot character model template
- workspace.BotSpawner2 — Part that defines spawn location
