---
tags: [client, localscript, player]
path: game.StarterPlayer.StarterPlayerScripts.Player.DisableReset
type: LocalScript
lines: 15
---

# DisableReset

Turns off the Roblox Reset Character button; expedition death goes through the downed / revive-token system instead.

## What it does
1. Calls `StarterGui:SetCore("ResetButtonCallback", false)`, retrying every 0.25 s up to 60 times until the core script is ready, and warns if it never is.
2. Repeats on every `CharacterAdded`.

## Dependencies
- **Requires:** Nothing
- **Required by:** Nobody

## Connections
None.
