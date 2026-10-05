---
tags: [server, script, combat]
path: game.ServerScriptService.Combat.AbilityServer
type: Script
lines: 75
---

# AbilityServer

Validates and applies the two PVE player abilities, Quickstep and Deadeye.

## What it does
1. Creates `Remotes.Ability` if missing and handles `Quickstep` / `Deadeye` requests.
2. Only accepts a request from a living player who is in an encounter (`PVEInEncounter`) and not mounted, downed or eliminated.
3. Quickstep: 6.5 s cooldown (scaled by `PVERunQuickstepScale`, clamped 0.64-1), refuses when a wall is within 3 studs, then sets a 58 stud/s horizontal velocity on the root and broadcasts the dash.
4. Deadeye: 22 s cooldown, writes `PVEDeadeyeUntil` (6 s window) which [[CombatServer]] reads as a x1.25 damage multiplier, and broadcasts the activation.
5. Cooldowns live in replicated player attributes (`PVEQuickstepReadyAt`, `PVEDeadeyeReadyAt`) so the client HUD can read them.

## Dependencies
- **Requires:** Nothing
- **Required by:** Nobody

## Connections
### RemoteEvents
| Remote | Direction | Other script |
|--------|-----------|-------------|
| `Remotes.Ability` | ← Client / → All clients | [[AbilityClient]] requests and replicated Quickstep/Deadeye FX |
