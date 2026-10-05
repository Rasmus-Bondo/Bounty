---
tags: [client, localscript, combat, ui, input]
path: game.StarterPlayer.StarterPlayerScripts.Combat.AbilityClient
type: LocalScript
lines: 120
---

# AbilityClient

Quickstep (Q) and Deadeye (F) ability buttons, input and local FX.

## What it does
1. Builds the `PVE_Abilities` ScreenGui in code: two ability buttons (Quickstep, Deadeye) and a full-screen blue Deadeye overlay.
2. Q / button sends `Quickstep` with the move direction (camera look if standing still); F / button sends `Deadeye`. Both are blocked while a menu is open, when mounted, dead, or not `PVEInEncounter`.
3. On the server echo, spawns sand-dust puffs along the Quickstep path for every viewer and a short blur for the owner; Deadeye shows the overlay for the owner.
4. Every Heartbeat reads `PVEQuickstepReadyAt`, `PVEDeadeyeReadyAt` and `PVEDeadeyeUntil` player attributes to render cooldown / active timers, and shows the panel only during an encounter while not mounted, downed or eliminated.

## Dependencies
- **Requires:** [[ClientMenuState]]
- **Required by:** Nobody

## Connections
### RemoteEvents
| Remote | Direction | Other script |
|--------|-----------|-------------|
| `Remotes.Ability` | → Server | [[AbilityServer]] `Quickstep` (direction) / `Deadeye` requests |
| `Remotes.Ability` | ← Server | [[AbilityServer]] Quickstep dust / Deadeye overlay echo |

### BindableEvents
None

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[ClientMenuState]] | `Menus.IsOpen()` | Suppress abilities while a menu is open |
