---
tags: [server, script, mounts]
path: game.ServerScriptService.Mounts.HorseServer
type: Script
lines: 309
---

# HorseServer

Server-authoritative summoned horse with curved steering, sprint, jump and terrain following.

## What it does
1. `Horse` remote `Toggle` summons a clone of `PVE.HorseAssets.MeshedHorseRig` in front of the player (refused while boarding the train, downed, eliminated or in a boss arena), welds the rider on, hides their `PVEWorldWeapon`, and registers the horse as a Chrono `PVEHorse` entity (`NATIVE_WITH_LOCK`).
2. `Input` sets throttle/steer/sprint (zeroed after 1.25 s without input); `Jump` queues a takeoff with a 0.18 s anticipation (`HorseTakeoffAt`).
3. Heartbeat moves the anchored horse: walk 34 / sprint 54 / reverse 14 studs/s, speed scaled by slope grade sampled from `PVEWorldQuery`, stopped at unloaded chunks (`IsLoaded`) and at terrain/collidable walls swept at hoof and chest height.
4. Snaps to ground below, refuses rises over 5 studs or steep normals, and falls back to the last safe grounded CFrame when no ground is found.
5. Publishes motion attributes on the horse (`HorseSpeed`, `HorseGrounded`, `HorseJumping`, `HorseGalloping`) and the rider (`PVEMounted`, `PVEHorseSpeed`, `PVEHorseGalloping`) at 10 Hz.
6. Dismount restores the rider beside the horse (or the last safe point), resets WalkSpeed/JumpPower and destroys the horse; triggered by toggle, death, respawn, leaving, `PVEForceDismount` or `PVEForceDismountNow` (which returns whether the player is now unmounted).

## Dependencies
- **Requires:** [[chrono]] (passes the ChronoConfig ModuleScript instance to `Chrono.Start`)
- **Required by:** Nobody

## Connections
### RemoteEvents
| Remote | Direction | Other script |
|--------|-----------|-------------|
| `Remotes.Horse` | ← Client | [[HorseClient]] Toggle / Input / Jump |

### BindableEvents
| Bindable | Direction | Other script |
|----------|-----------|-------------|
| `ServerStorage.PVEForceDismount` (BindableEvent) | ← (creates) | [[BossArena]] dismount on arena entry |
| `ServerStorage.PVEForceDismountNow` (BindableFunction) | ← OnInvoke (creates) | [[MissionServer]] synchronous dismount before train boarding |
| `ServerStorage.PVEWorldQuery` (BindableFunction) | → Invoke | [[WorldRuntime]] `Sample` heights and `IsLoaded` |

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[chrono]] | `Chrono.Start`, `Chrono.Entity.new/Destroy` | Replicate horse motion to clients |
