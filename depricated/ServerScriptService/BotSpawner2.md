---
tags: [server, script, bots]
path: game.ServerScriptService.BotSpawner2
type: Script
lines: 39
---

# BotSpawner2

Standalone script that spawns and respawns bot characters from a template rig.

## What it does

1. Grabs `ReplicatedStorage.BotRig` as a template
2. Finds 6 `BotSpawner` parts in Workspace (`BotSpawner1` through `BotSpawner6`)
3. Clones the template onto each spawner, offset slightly above
4. When a bot's Humanoid dies, waits 1 second, destroys the old bot, and spawns a fresh one at the same spawner

## Dependencies

- **Requires:** Nothing — no module imports
- **Required by:** Nobody
- **Reads from:** `ReplicatedStorage.BotRig`, `Workspace.BotSpawner1..6`

## Notes

- Completely independent from Main and all other server scripts
- Bots are regular `Model` instances with Humanoids, so they are targetable by combat systems like any character
- The respawn loop is recursive: `humanoid.Died` → `spawnBot()` → new `humanoid.Died` → repeat
