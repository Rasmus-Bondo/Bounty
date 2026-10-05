---
tags: [server, modulescript, missions, exploration]
path: game.ServerStorage.Missions.ExplorationEncounterService
type: ModuleScript
lines: 164
---

# ExplorationEncounterService

Session-persistent optional trail encounters (guarded caches and first-aid stops); the server owns claims, healing and loose rewards.

## What it does
1. `Load(key, position, guarded, cleared, kind, guardsRemaining)` keeps one state per chunk key for the whole session and builds a crate + health-potion model with a prompt and label in `workspace.PVE_ExplorationEncounters` (max 10 active).
2. `SetGuards` / `Clear` update the remaining-guard count and unlock the cache; `Unload` destroys the model but keeps the state; `Positions` lists loaded encounter positions.
3. `Claim(key, player)` validates range (12 studs), line of sight and that the player is not downed, eliminated, boarding or mounted, then heals up to 40 once per player and, for cleared guarded caches during an expedition, adds 12 `PVEUnsecured` loose supplies once per player.
4. Feedback goes to the player through the `PVEExplorationMessage` / `PVEExplorationMessageId` attributes.
5. `Rescue` (stranded traveller, +20 supplies to nearby expedition members) exists, but `Load` rewrites `kind == "Rescue"` to `"Cache"`, so the rescue path is currently unreachable.
6. Creates the `PVEExplorationMapSnapshot` BindableFunction returning each loaded encounter's position, kind, cleared state and per-player potion/loot availability for the trail map.

## Dependencies
- **Requires:** Nothing
- **Required by:** ChunkEnemyServer

## Connections
### BindableEvents
| Bindable | Direction | Other script |
|----------|-----------|-------------|
| `ServerStorage.PVEExplorationMapSnapshot` (BindableFunction) | ← OnInvoke (creates) | [[WorldRuntime]] merges markers into the map snapshot |
