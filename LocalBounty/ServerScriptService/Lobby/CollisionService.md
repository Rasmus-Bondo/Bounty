---
tags: [server, modulescript, lobby, physics]
path: game.ServerScriptService.Lobby.CollisionService
type: ModuleScript
lines: 35
---

# CollisionService

Disables character-to-character collision so players can walk through each other.

## What it does
1. Registers a "Characters" collision group via PhysicsService
2. Sets Characters group to not collide with itself
3. On CharacterAdded, assigns all BasePart descendants to the "Characters" collision group
4. Listens for new descendants added to characters and assigns them too

## Dependencies
- **Requires:** Nothing
- **Required by:** Main

## Connections
### RemoteEvents
None

### BindableEvents
None

### Direct require()
None
