---
tags: [server, modulescript, persistence, settings]
path: game.ServerScriptService.PlayerServices.PlayerSettingsService
type: ModuleScript
lines: 192
---

# PlayerSettingsService

Persists all client-side player settings (crosshair color/size, HUD toggles, audio volumes, shadows) on the profile via a single get-all / set-one remote pair.

## What it does
1. Defines validators for each setting: `CrosshairColorIndex` (1-8), `CrosshairSize` (0.5-2.5), `ShowPingFPS` (bool), `ShadowsEnabled` (bool | nil), `AbilityDescriptions` (`"On"` / `"Default"` / `"Off"`), `MasterVolume`, `SFXVolume`, `HitSoundVolume`, `MusicVolume` (all 0-1)
1a. `AbilityDescriptions` governs **Redwater's** hunter ability tags — `"On"` always visible, `"Default"` a 30s window per match join and hunter switch, `"Off"` never. The lobby has no ability HUD of its own and nothing here reads the value, but it is writable from this place's settings panel so a player can configure it before queueing. Stored as a string rather than an index so the profile stays readable and an unrecognised value fails the validator instead of silently meaning a different mode
1b. `AutoFireEnabled` (bool, default **true**, added 2026-08-07) governs **Redwater's** mobile auto-fire the same way — nothing in the lobby reads it, but the lobby settings panel can flip it and the shared profile must never drop the write. Same default and validator as Redwater's copy, deliberately: a key accepted in one place and rejected in the other silently loses the player's choice
2. **Proactively pushes** saved settings to each client on `Players.PlayerAdded` (after profile loads via `waitForProfileData`) so the panel hydrates without client-side polling
3. Handles `PlayerSettingsRequest` as an explicit on-demand fallback — same payload, same code path
4. Handles `SetPlayerSetting(key, value)` from the client; rejects unknown keys and invalid values before writing to `data.Settings`
5. `ShadowsEnabled` has a nil default — means "let the client decide by platform" (PC on, mobile off)

## Dependencies
- **Requires:** [[DataService]]
- **Required by:** Main

## Connections
### RemoteEvents
| Remote | Direction | Other script |
|--------|-----------|-------------|
| `PlayerSettingsRequest` | ← Client | [[SettingsController]] optional on-demand refresh |
| `PlayerSettingsResponse` | → Client | Fired proactively on `PlayerAdded` and on each request; [[SettingsController]] applies payload, [[LoadingScreen]] awaits it as a load-readiness gate |
| `SetPlayerSetting` | ← Client | [[SettingsController]] fires on toggle click / slider release / swatch click |

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[DataService]] | `getPlayerData()` | Read/write the `Settings` sub-table on the player's profile |
