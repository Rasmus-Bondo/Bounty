# CollisionService

Disables player-to-player collision using PhysicsService collision groups. Players can walk through each other but still collide with the world.

**Path:** `game.ServerScriptService.PlayerServices.CollisionService`
**Type:** ModuleScript (36 lines)
**Runs on:** Server

## How It Works

1. Registers a "Characters" collision group via PhysicsService
2. Sets Characters-to-Characters collision to **false**
3. On CharacterAdded: sets all BasePart descendants to the "Characters" collision group
4. Watches DescendantAdded to catch parts added later (accessories, tools)

## Dependencies

- PhysicsService — collision group API
- Players service

## Used By

- [[MainServer]] — Initialize() called at boot
- Replaces deprecated `PlayerCollisionGroup` script
