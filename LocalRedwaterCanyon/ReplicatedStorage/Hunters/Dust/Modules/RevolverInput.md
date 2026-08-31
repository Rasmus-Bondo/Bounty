---
tags: [client, modulescript, input, combat]
path: game.ReplicatedStorage.Hunters.Dust.Modules.RevolverInput
type: ModuleScript
lines: 82
---

# RevolverInput

OOP input handler that maps keyboard/mouse inputs to revolver action callbacks.

## What it does
1. Listens for MouseButton1 click for shooting (PC only — mobile fire goes through HunterGuiClient's dedicated Fire button → FireRequested BindableEvent, since the old `UserInputService.TouchTap` handler had inherent input lag from Roblox's tap-vs-drag heuristic firing on finger release)
2. Maps configurable keys to reload (R), dash (Q), skill2 (E)
3. Manages connection lifecycle with Start/Stop/Destroy methods
4. Ignores inputs that are game-processed (typing in chat, etc.)

## Dependencies
- **Requires:** Nothing (configured externally via callbacks)
- **Required by:** FPSRevolverClient

## Connections
### RemoteEvents
None

### BindableEvents
None

### Direct require()
None
