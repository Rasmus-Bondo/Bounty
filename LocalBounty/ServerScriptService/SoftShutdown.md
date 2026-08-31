---
tags: [server, script, teleport, release, lifecycle]
path: game.ServerScriptService.SoftShutdown
type: Script
lines: 79
---

# SoftShutdown

Evacuates players to a fresh server instead of dumping them to the website when this server closes. Identical copy must exist in both places — edit both together.

## What it does
1. Binds `evacuate` to `game:BindToClose`, so it runs whenever the server is shutting down — including a *Shut Down All Servers* from the Creator Hub
2. Returns immediately in Studio, since stopping a playtest fires BindToClose too and teleporting out of one only produces a confusing error
3. Teleports every remaining player to `GameEnvironment.bountyPlaceId` with `TeleportData = { softShutdown = true }`, so an arriving server can tell a restart from an ordinary join
4. Retries up to 3 times inside a 25-second budget, waiting up to 6 seconds after each attempt for players to actually leave before judging whether it worked
5. Holds the shutdown open while players are still present — returning from BindToClose early would let the server die and strand anyone mid-teleport

## Why the destination is always the lobby
This is what lets the file stay byte-identical across both places. Redwater closing sends players to the lobby because a match in progress cannot be resumed anyway; Bounty closing sends them to a fresh copy of the lobby, and a closing server stops accepting joins so matchmaking cannot put anyone back into this one.

## Why it matters
Publishing does not update servers that are already running — they keep the old code until they empty out. During that window a player can sit in a Bounty on new code and teleport into a Redwater on old code, which is a mirrored-config drift scenario arising purely from timing, with both copies correct on disk. Being able to retire old servers on demand closes that window.

Degradation is graceful: if the teleport fails outright the player is disconnected, which is exactly what would have happened with no soft shutdown at all.

## Dependencies
- **Requires:** [[GameEnvironment]]
- **Required by:** Nobody

## Connections
### RemoteEvents
None

### BindableEvents
None

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[GameEnvironment]] | `GameEnvironment.bountyPlaceId` | Evacuation destination, resolved per-universe |
