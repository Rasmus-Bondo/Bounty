---
tags: [client, localscript, ui, lobby]
path: game.StarterPlayer.StarterPlayerScripts.DisableResetCharacter
type: LocalScript
lines: 17
---

# DisableResetCharacter

Disables the Roblox reset character button in the lobby.

## What it does
1. Calls `StarterGui:SetCore("ResetButtonCallback", false)` in a retry loop until successful

## Dependencies
- **Requires:** Nothing
- **Required by:** Nobody

## Connections
### RemoteEvents
None

### BindableEvents
None

### Direct require()
None
