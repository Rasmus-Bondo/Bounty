# RoundController

The main round loop — orchestrates the entire game flow from waiting for players through intermission, fight phase, post-game stats, and reset. The largest and most central module in the game.

**Path:** `game.ServerScriptService.RoundSystem.RoundController`
**Type:** ModuleScript (316 lines)
**Runs on:** Server

## How It Works

### Round Loop (`run()`)

Infinite `while true` loop with these phases:

1. **Waiting** — polls `LobbyService.getOptedInCount()` every second until >= `MIN_PLAYERS`
2. **Intermission** — counts down `INTERMISSION_TIME` (10s), clears roles, sets RoundActive=false. Re-checks player count after countdown
3. **Setup** — `ensureAllPlayersAlive()`, sets all opted-in players to Bandit role, teleports to round spawns, gives guns, applies invulnerability
4. **Fight** — sets `roundActive=true`, plays RoundStart SFX, starts [[ZoneService]], counts down `ROUND_TIME` (600s). Can be interrupted by `roundCancelled`
5. **Ended** — stops zone, awards round completion XP/Cash via [[ProgressionService]], collects kill/death stats, determines winner, fires [[PostGameStats]] to clients, waits 5s
6. **Reset** — `resetRound()`: clears state, removes guns, clears corpses, resets destructibles and zone, reloads opted-in characters, teleports to lobby

### Character Hooking (`hookCharacter()`)

Called on every CharacterAdded:
- Sets MaxHealth to `PLAYER_MAX_HEALTH` (150)
- If round is active and player is opted in: immediately sets Role="Bandit" and Invulnerable=true
- **Died handler**: tracks death count, awards death stats, fires [[RespawnCountdown]] to client, schedules LoadCharacter after `RESPAWN_DELAY` (3s)
- **Deferred spawn logic**: waits for character to fully load, then either:
  - **In round + opted in**: teleports to round spawn, gives gun, applies invulnerability
  - **Not in round**: clears role, sends to lobby

### Event Handling (`connectEvents()`)

Listens to `EliminatePlayer` BindableEvent:
- Calls [[RoleService]].eliminatePlayer()
- Tracks kill in State.playerKills

### Winner Determination (`getWinner()`)

Simple highest-kills-wins. Returns player and kill count.

### Post-Game Stats

Collects `{name, kills, deaths}` for each opted-in player, sorted by kills descending (deaths as tiebreaker). Fired to clients via PostGameStats RemoteEvent.

### Round Cancellation

`cancelRound()` sets flags to abort the fight loop. After a 3s delay, calls resetRound().

## Dependencies

- [[Config]] — all timing/health constants
- [[State]] — round state management
- [[References]] — replicated values (RoundStatus, RoundActive, RoundTime)
- [[SpawnService]] — all teleportation
- [[RoleService]] — role assignment and clearing
- [[BanditService]] — gun distribution
- [[LobbyService]] — opt-in checking
- [[InvulnService]] — spawn protection
- [[ProgressionService]] — XP/Cash awards
- [[DestructibleService]] — map reset
- [[ZoneService]] — zone start/reset
- ReplicatedStorage.Events.PostGameStats — sends stats to client
- ReplicatedStorage.Events.RespawnCountdown — sends respawn timer to client
- ReplicatedStorage.SFX.RoundStart — round start sound

## Used By

- [[MainServer]] — calls `connectEvents()`, `connectPlayers()`, `run()`
