---
tags: [server, script, mounts]
path: game.ServerScriptService.Mounts.WadingServer
type: Script
lines: 15
---

# WadingServer

Keeps terrain water wadeable by disabling swimming on every character.

## What it does
1. On every character spawn, disables `HumanoidStateType.Swimming` on its Humanoid so players walk through water instead of swimming.
2. Binds existing players at start as well as new ones.

## Dependencies
- **Requires:** Nothing
- **Required by:** Nobody

## Connections
None.
