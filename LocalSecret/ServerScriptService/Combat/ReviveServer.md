---
tags: [server, script, combat]
path: game.ServerScriptService.Combat.ReviveServer
type: Script
lines: 113
---

# ReviveServer

Downed-state, revive tokens and revive shrines for PVE expeditions.

## What it does
1. On `PVEPlayerDowned` (expedition players only): holds the player at 1 HP, sets `PVEDowned`, zeroes `PVEUnsecured`, freezes movement (stores WalkSpeed/JumpPower) and drops any token they were carrying.
2. Spawns a glowing revive token (built in code under `workspace.PVE_ReviveTokens`) with a 30 s countdown billboard and sets `PVEReviveDeadline`.
3. A teammate picks the token up via ProximityPrompt (`PVECarryingToken`), then triggers a shrine in `workspace.PVE_ReviveShrines` or the station's `StationReviveShrine` to revive the victim at 50% HP beside the shrine.
4. If the deadline lapses the victim is eliminated (`PVEEliminated`, out of the encounter, killed).
5. `PVEReleaseCarriedToken` lets other systems drop a carried token back into the world; tokens are also released on character removal / leave and cleared when the encounter phase becomes `Idle`, `Failed` or `TravelFailed`.

## Dependencies
- **Requires:** Nothing
- **Required by:** Nobody

## Connections
### BindableEvents
| Bindable | Direction | Other script |
|----------|-----------|-------------|
| `ServerStorage.PVEPlayerDowned` | ← | [[EnemyService]] lethal enemy damage |
| `ServerStorage.PVEReleaseCarriedToken` | ← (creates) | [[MissionServer]] drop a carried token |
