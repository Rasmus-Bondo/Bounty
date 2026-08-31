# MainServer

Entry-point Script that boots the entire server. Requires and initializes all service modules in order, then starts the round loop.

**Path:** `game.ServerScriptService.RoundSystem.MainServer`
**Type:** Script (34 lines)
**Runs on:** Server

## How It Works

### Initialization Order

1. [[RagdollService]].Initialize()
2. [[CollisionService]].Initialize()
3. [[LeaderstatService]].Initialize()
4. [[FootstepService]].Initialize()
5. [[AnimateService]].Initialize()
6. [[MovementService]].Initialize()
7. [[DataService]].Initialize()
8. [[ProgressionService]].Initialize()
9. [[LobbyService]].Initialize()
10. [[InvulnService]].Initialize()
11. [[DestructibleService]].Initialize()
12. [[ZoneService]].Initialize()

### Round System Startup

After all services are initialized:
1. `RoundController.connectEvents()` — hooks EliminatePlayer BindableEvent
2. `RoundController.connectPlayers()` — hooks PlayerAdded + CharacterAdded
3. `RoundController.run()` — enters the infinite round loop (never returns)

## Dependencies

- Requires modules from RoundSystem (siblings), PlayerServices, WorldServices, and Shared folders

## Used By

- Roblox engine runs this automatically as a top-level Script in ServerScriptService
