---
tags: [server, modulescript]
path: game.ServerScriptService.PlayerServices.MouseSensitivityService
type: ModuleScript
lines: 52
---

# MouseSensitivityService

Server module that persists and serves mouse sensitivity settings per player.

## What it does
1. Listens for `MouseSensitivityRequest` from client; reads saved sensitivity from profile data and fires it back via `MouseSensitivityResponse`
2. Retries up to 50 times (0.1 s each) if profile data isn't loaded yet when the request arrives
3. Listens for `SetMouseSensitivity` from client; validates the value is a sane number then clamps it to [0.05, 1] and writes it to `data.MouseSensitivity`
4. Default sensitivity: `0.45`

## Dependencies
- **Requires:** [[DataService]]
- **Required by:** Main (via `Start()` call chain)

## Connections
### RemoteEvents
| Remote | Direction | Other script |
|--------|-----------|-------------|
| `MouseSensitivityRequest` | ← Client | [[SettingsController]] |
| `MouseSensitivityResponse` | → Client | [[SettingsController]] |
| `SetMouseSensitivity` | ← Client | [[SettingsController]] |

All three remotes live under `ReplicatedStorage.Events.SettingsEvents`.

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[DataService]] | `DataService.getPlayerData(player)` | Read/write `MouseSensitivity` field |
