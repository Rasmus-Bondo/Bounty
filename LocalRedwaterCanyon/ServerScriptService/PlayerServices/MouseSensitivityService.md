---
tags: [server, modulescript, persistence, settings]
path: game.ServerScriptService.PlayerServices.MouseSensitivityService
type: ModuleScript
lines: 54
---

# MouseSensitivityService

Persists the player's mouse sensitivity slider value (`UserInputService.MouseDeltaSensitivity` on the client) across sessions.

## What it does
1. Handles `MouseSensitivityRequest` from the client: replies via `MouseSensitivityResponse` with `data.MouseSensitivity` (defaults to 0.45 if somehow missing)
2. The request handler waits/retries (0.1s steps, up to ~5s) for `DataService.getPlayerData()` to become non-nil instead of silently dropping the request — the client fires this immediately on load, which can race ahead of `ProfileStore:LoadProfileAsync` (a real DataStore round-trip) finishing in [[DataService]]. Without this wait, the client never hears back and is stuck on the default forever, looking exactly like "sensitivity doesn't persist" even though saving worked fine
3. Handles `SetMouseSensitivity` from the client: rejects non-numbers/NaN, clamps to `[0.05, 1]`, and saves to `data.MouseSensitivity`
4. Roblox does not clamp `MouseDeltaSensitivity` itself (accepts 0, negative, or values far above 1 with no error), so this service is the only validation boundary

## Dependencies
- **Requires:** [[DataService]]
- **Required by:** Main

## Connections
### RemoteEvents
| Remote | Direction | Other script |
|--------|-----------|-------------|
| `MouseSensitivityRequest` | ← Client | [[SettingsController]] requests the saved value on load |
| `MouseSensitivityResponse` | → Client | [[SettingsController]] applies the saved value to `UserInputService.MouseDeltaSensitivity` |
| `SetMouseSensitivity` | ← Client | [[SettingsController]] fires on slider release to persist the new value |

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[DataService]] | `getPlayerData()` | Read/write `MouseSensitivity` on the player's profile |
