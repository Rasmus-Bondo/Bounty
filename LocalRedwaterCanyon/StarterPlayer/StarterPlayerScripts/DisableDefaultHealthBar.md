---
tags:
  - client
  - localscript
path: game.StarterPlayer.StarterPlayerScripts.DisableDefaultHealthBar
type: LocalScript
lines: 3
---

# DisableDefaultHealthBar

Disables the default Roblox health bar CoreGui so only the custom HUD health bar is visible.

## What it does

1. Calls StarterGui:SetCoreGuiEnabled to disable Enum.CoreGuiType.Health

Renamed from `DisableDefaultHealth` on 2026-08-13. It only ever hid the CoreGui element, but the old name read as if it disabled health *regeneration* — which is what `StarterCharacterScripts.Health` actually replaced that day. Matches its sibling `DisableDefaultLeaderboard`. The name is not referenced from any script in either place.

## Dependencies

- **Requires:** Nothing
- **Required by:** Nobody

## Connections

### RemoteEvents

_None_

### BindableEvents

_None_

### Direct require()

_None_
