# BotSpawner

Spawns a test bot from BotRig template at the BotSpawner part in workspace. Auto-respawns on death after a short delay.

**Path:** `game.ServerScriptService.Testing.BotSpawner`
**Type:** Script (35 lines)
**Runs on:** Server

## How It Works

### Constants

| Constant | Value | Description |
|----------|-------|-------------|
| RESPAWN_DELAY | 1 | Seconds before respawning after death |
| HEIGHT_OFFSET | 3 | Studs above spawner part to place bot |

### Spawn Flow

1. Clones `ReplicatedStorage.BotRig` template
2. Parents to workspace
3. Pivots to `workspace.BotSpawner.CFrame + Vector3(0, 3, 0)`
4. Hooks `Humanoid.Died`:
   - Waits 1 second
   - Destroys old bot
   - Recursively calls `spawnBot()` (infinite respawn loop)

Runs `spawnBot()` immediately on script start.

## Dependencies

- ReplicatedStorage.BotRig — bot character model template
- workspace.BotSpawner — Part that defines spawn location

## Related

- [[BotSpawner2]] — identical script using `workspace.BotSpawner2` as spawn point
