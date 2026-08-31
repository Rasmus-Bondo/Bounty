# Events Folder

Central hub for all RemoteEvents and BindableEvents used in client-server communication.

**Path:** `game.ReplicatedStorage.Events`
**Type:** Folder

## Contents

### Direct Children

| Name | Class | Direction | Description |
|------|-------|-----------|-------------|
| [[CombatEvents]] | ModuleScript | — | Convenience module that caches GunRemote and EliminatePlayer references |
| GunRemote | RemoteEvent | Client → Server | Fires when player shoots; carries origin, direction, hit data |
| EliminatePlayer | BindableEvent | Server → Server | Internal server event fired when a player is killed |
| RoundEvent | RemoteEvent | Bidirectional | Client sends "JoinRound"/"LeaveRound"; used by [[LobbyService]] |
| PostGameStats | RemoteEvent | Server → Client | Sends sorted kill/death stats after round ends; used by [[RoundController]] |
| RespawnCountdown | RemoteEvent | Server → Client | Sends respawn delay timer to dead player's client |

### MovementEvents (Subfolder)

| Name | Class | Direction | Description |
|------|-------|-----------|-------------|
| SprintEvent | RemoteEvent | Client → Server | Toggle sprint on/off; handled by [[MovementService]] |
| CrouchEvent | RemoteEvent | Client → Server | Toggle crouch on/off; handled by [[MovementService]] |

### ProgressionEvents (Subfolder)

| Name | Class | Direction | Description |
|------|-------|-----------|-------------|
| RequestStats | RemoteEvent | Client → Server | Client requests their stats; handled by [[DataService]] |
| StatsResponse | RemoteEvent | Server → Client | Server responds with player stat data |
| LevelUp | RemoteEvent | Server → Client | Notifies client of a level-up; fired by [[ProgressionService]] |

## Referenced By

- [[CombatEvents]] — caches GunRemote and EliminatePlayer
- [[GunServer]] — fires GunRemote responses and listens for EliminatePlayer
- [[GunClient]] — fires GunRemote to server on shoot
- [[InputController]] — fires SprintEvent and CrouchEvent
- [[MovementService]] — listens for SprintEvent and CrouchEvent
- [[RoundController]] — fires PostGameStats and RespawnCountdown
- [[LobbyService]] — listens for RoundEvent
- [[DataService]] — listens for RequestStats, fires StatsResponse
- [[ProgressionService]] — fires LevelUp
