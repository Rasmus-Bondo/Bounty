# LobbyService

Manages player opt-in/opt-out for rounds. Players toggle participation via the RoundEvent RemoteEvent. Handles mid-round joining (immediate spawn + gun + invuln) and mid-round leaving (cleanup + return to lobby).

**Path:** `game.ServerScriptService.RoundSystem.LobbyService`
**Type:** ModuleScript (98 lines)
**Runs on:** Server

## How It Works

### Opt-In Flow (`optIn`)

1. Sets `OptedIn` attribute on player to `true`
2. Adds player to `State.optedInPlayers` table
3. **If round is already active** (mid-match join):
   - Sets Role to "Bandit" (enables first-person camera on client)
   - Teleports to a safe round spawn via [[SpawnService]]
   - Gives bandit gun via [[BanditService]]
   - Applies invulnerability via [[InvulnService]]

### Opt-Out Flow (`optOut`)

1. Sets `OptedIn` attribute to `false`
2. Removes from `State.optedInPlayers`
3. **If leaving during active round**:
   - Clears Role attribute (disables first-person camera)
   - Removes bandit gun
   - Waits 0.2s for client camera to disable
   - Calls `LoadCharacter()` (hookCharacter will send to lobby)

### Event Listener

Listens on `ReplicatedStorage.Events.RoundEvent`:
- `"JoinRound"` → `optIn(player)`
- `"LeaveRound"` → `optOut(player)`

### Cleanup

PlayerRemoving calls `optOut()` to clean up state for disconnecting players.

### Query Methods

| Method | Returns |
|--------|---------|
| `isOptedIn(player)` | `true` if player has OptedIn attribute == true |
| `getOptedInPlayers()` | Array of opted-in players still connected |
| `getOptedInCount()` | Count of opted-in connected players |

### Opt-In Persistence

Opt-ins persist across rounds by design — players stay opted in through intermission and into the next round. `resetAllOptIns()` exists but is not called in the normal round loop.

## Dependencies

- [[State]] — optedInPlayers table
- [[Config]] — (imported but not heavily used)
- [[SpawnService]] — sendPlayerToRoundSpawn
- [[BanditService]] — giveBanditGun, removeBanditGunFromPlayer
- [[InvulnService]] — applyInvulnerability
- ReplicatedStorage.Events.RoundEvent — RemoteEvent

## Used By

- [[MainServer]] — Initialize() called at boot
- [[RoundController]] — checks opt-in count for round start, gets opted-in players list
- [[DataService]] — isOptedIn for time tracking gates
- [[ProgressionService]] — isOptedIn for time-based rewards
- [[ZoneService]] — isOptedIn for zone damage targeting
- [[LobbyGui]] (client) — fires JoinRound/LeaveRound via RoundEvent
