---
tags: [server, modulescript, persistence, settings]
path: game.ServerScriptService.PlayerServices.PlayerSettingsService
type: ModuleScript
lines: 196
---

# PlayerSettingsService

Persists all client-side player settings (crosshair color/size, HUD toggles, audio volumes, shadows) on the profile via a single get-all / set-one remote pair. Mouse sensitivity keeps its own dedicated MouseSensitivityService because it's a `UserInputService` property rather than a per-instance value and predates this service.

## What it does
1. Extends the profile template with a `Settings` sub-table containing: `CrosshairColorIndex` (1-8), `CrosshairSize` (0.5-2.5 multiplier), `ShowPingFPS` (bool), `ShadowsEnabled` (bool | nil, where nil means "let client decide by platform"), `AbilityDescriptions` (`"On"` / `"Default"` / `"Off"`), `MasterVolume`, `SFXVolume`, `HitSoundVolume`, `MusicVolume` (all 0-1). Backfilled onto existing profiles via `:Reconcile()` in [[DataService]]
1a. `AbilityDescriptions` governs Redwater's hunter ability tags — `"On"` always visible, `"Default"` a 30s window per match join and hunter switch, `"Off"` never. Stored as a **string** rather than an index so the profile stays readable and an unrecognised value fails the validator instead of silently meaning a different mode. The same key exists in Bounty's copy of this service so the setting can be changed from either place
1b. `AutoFireEnabled` (bool, default **true**, added 2026-08-07) governs mobile auto-fire — the weapon firing on its own while the crosshair holds an enemy. Touch-only in the UI (the settings row is hidden elsewhere) but accepted from any device so the lobby toggle works too; the same key with the same default and validator exists in Bounty's copy, because a key accepted in one place and rejected in the other silently drops the player's choice. The default must stay `true` to agree with the clients, which treat an absent `AutoFireEnabled` attribute as ON
2. **Proactively pushes** the saved payload to each client on `Players.PlayerAdded` (after `:LoadProfileAsync()` completes via `waitForProfileData` — 0.1s x 50 retries) so the settings-panel UI hydrates without any client-side polling. Also handles explicit `PlayerSettingsRequest` from the client (same payload, same code path) as a fallback / on-demand refresh. This proactive push is what fixes the "rejoined the game but ShowPingFPS/Shadows/etc. reverted to defaults" bug — the old flow relied entirely on client polling and could silently drop the response if `waitForProfileData` timed out on all 5 client retries. Response payload contains every setting; invalid or missing values fall back to the per-setting default
3. Handles `SetPlayerSetting` from the client with a `(key, value)` pair. Rejects unknown keys and drops any value that fails the per-setting validator (type check + clamp for numbers, type check for booleans, `math.floor` + clamp for the crosshair color index). This is the only validation boundary — Roblox does not clamp `SoundGroup.Volume` or `Lighting.GlobalShadows` on its own
4. `MusicVolume` drives the `SoundService.Music` `SoundGroup`. The map's music track (`Workspace.Wagon Trail Blues`) is routed through that group directly (pre-placed Sound with `SoundGroup` set in Studio). Additional music tracks should also be assigned to `SoundService.Music` to inherit the slider

## Dependencies
- **Requires:** [[DataService]]
- **Required by:** Main

## Connections
### RemoteEvents
| Remote | Direction | Other script |
|--------|-----------|-------------|
| `PlayerSettingsRequest` | ← Client | [[SettingsController]] optional on-demand refresh (proactive server push on `PlayerAdded` is the primary path) |
| `PlayerSettingsResponse` | → Client | Server fires proactively on `PlayerAdded` (once profile loads) and again on each `PlayerSettingsRequest`; [[SettingsController]] applies the saved payload to every control |
| `SetPlayerSetting` | ← Client | [[SettingsController]] fires on toggle click / slider release / swatch click to persist |

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[DataService]] | `getPlayerData()` | Read/write the `Settings` sub-table on the player's profile |
