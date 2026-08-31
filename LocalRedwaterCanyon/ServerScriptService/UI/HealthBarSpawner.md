---
tags:
  - server
  - modulescript
  - ui
path: game.ServerScriptService.UI.HealthBarSpawner
type: ModuleScript
lines: 48
---

# HealthBarSpawner

Server-side setup that hides Roblox's native overhead name/health display on every character, globally, for all players.

## What it does

1. On `Start()`, zeroes `StarterPlayer.HealthDisplayDistance`/`NameDisplayDistance` at runtime so any new humanoid seeds with 0 distance even before the per-character setup fires
2. Sets up each player (existing and newly joined) by connecting to `CharacterAdded`
3. On character spawn, immediately applies the full hide-stack on the humanoid (no `task.defer` — runs synchronously to close the damage-flash race window):
   - `DisplayDistanceType = None`
   - `HealthDisplayType = AlwaysOff`
   - `HealthDisplayDistance = 0`
   - `NameDisplayDistance = 0`
4. If the humanoid isn't a child yet, hooks `ChildAdded` and applies the same when it arrives
5. Does **not** create or manage the custom overhead health bar GUI itself — that is HealthBarSpawnerClient's job, spawned per-attacker only. This script only ensures the native Roblox health/name display never shows for anyone

## Dependencies

- **Requires:** Nothing
- **Required by:** Main

## Connections

### RemoteEvents

None

### BindableEvents

None

### Direct require()

None
