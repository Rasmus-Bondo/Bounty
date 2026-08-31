# References

Cached reference table for commonly-accessed workspace objects and replicated values. Avoids repeated `WaitForChild` calls across modules.

**Path:** `game.ServerScriptService.Shared.References`
**Type:** ModuleScript (37 lines)
**Runs on:** Server

## Cached References

### Workspace Objects

| Key | Source | Description |
|-----|--------|-------------|
| lobbySpawnsFolder | Workspace.LobbySpawns | Folder containing lobby spawn BaseParts |
| townsfolkSpawnsFolder | Workspace.SpawnPoints | Folder containing round spawn BaseParts |
| banditSpawnObject | Workspace.BanditSpawn | Bandit-specific spawn (BasePart or Folder) |

### ServerStorage

| Key | Source | Description |
|-----|--------|-------------|
| banditGunTemplate | ServerStorage.BanditGun | Gun tool template to clone for players |

### Events

| Key | Source | Description |
|-----|--------|-------------|
| eliminatePlayerEvent | ReplicatedStorage.Events.EliminatePlayer | BindableEvent fired when a player is eliminated |

### Replicated Values (created if missing)

| Key | Type | Description |
|-----|------|-------------|
| roundStatus | StringValue | Current round status text (read by client UI) |
| roundActiveValue | BoolValue | Whether a round is active (read by [[FirstPersonCamera]], [[InputController]]) |
| roundTime | IntValue | Countdown timer value (read by client HUD) |

## Dependencies

- ReplicatedStorage, Workspace, ServerStorage — standard Roblox services

## Used By

- [[RoundController]], [[SpawnService]], [[BanditService]] — all read from this shared table
