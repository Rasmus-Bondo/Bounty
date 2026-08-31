---
tags: [client, modulescript, ui, notifications]
path: game.ReplicatedStorage.Modules.NotificationModule
type: ModuleScript
lines: 95
---

# NotificationModule

Shared client-side notification system. Drives the existing `NotificationFrame/NotificationText` label in MainMenuGui — text-only, no backgrounds. Colors sourced from the `TextColors` folder on NotificationText.

## What it does
1. Waits for `PlayerGui/ReworkedMainMenuFolder/MainMenuGui/NotificationFrame/NotificationText` at load time
2. Reads colors once from `TextColors`: PositiveText (success), NegativeText (error), StorePurchaseText (info); white for status
3. Adds a UIScale to NotificationText for the pop-in animation; starts label fully hidden (TextTransparency=1, UIStroke.Transparency=1)
4. `Notify`: reveals label with color + Back pop-in, auto-dismisses after 3.5s via Quad fade-out; replaces any active notification
5. `ShowStatus`: persistent display (no auto-dismiss) — used for teleport flow ("Finding match", "Teleporting…")
6. `DismissStatus`: fades out the status; no-op if status is not active
7. All reveal/conceal calls cancel in-flight tweens first to prevent transparency fights

## Dependencies
- **Requires:** Nothing
- **Required by:** ReworkedUIPlay, ReworkedPartyClient

## Connections
### RemoteEvents
None

### BindableEvents
None

### Direct require()
None

## Public API
| Function | Arguments | Behavior |
|----------|-----------|---------|
| `Notify(message, type)` | string, "info"\|"success"\|"error" | Shows auto-dismiss toast |
| `ShowStatus(message)` | string | Shows persistent status slot |
| `DismissStatus()` | — | Hides status slot |
| `ShowError(message)` | string | Dismisses status, shows error toast |
