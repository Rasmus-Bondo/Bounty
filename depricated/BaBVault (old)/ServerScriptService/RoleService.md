# RoleService

Manages player roles via the `Role` player attribute. Roles determine FPS camera activation, gun access, and round participation.

**Path:** `game.ServerScriptService.RoundSystem.RoleService`
**Type:** ModuleScript (26 lines)
**Runs on:** Server

## Roles

| Role | Meaning |
|------|---------|
| "Bandit" | Active round participant — gets FPS camera, gun, can deal/take damage |
| "Eliminated" | Died during the round — awaiting respawn |
| nil | Not in a round (lobby player or between rounds) |

## Methods

### clearRoles()
Sets `Role = nil` on all players. Called during intermission and round reset.

### setAllBandits()
Sets `Role = "Bandit"` on all players. (Available but not used by current round flow — [[RoundController]] sets roles individually.)

### eliminatePlayer(player)
Changes a Bandit's role to "Eliminated". Guards: only works if current role is "Bandit". Does NOT call LoadCharacter — respawn is handled by [[RoundController]]'s Died handler to avoid double-respawn.

## Dependencies

- Players service

## Used By

- [[RoundController]] — calls clearRoles() during reset/intermission, eliminatePlayer() on death
- Client reads `Role` attribute: [[FirstPersonCamera]] activates for Bandit/Townsfolk, [[InputController]] gates controls
