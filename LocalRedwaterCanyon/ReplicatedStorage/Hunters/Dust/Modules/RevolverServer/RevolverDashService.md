---
tags: [server, modulescript, combat, movement, dash]
path: game.ReplicatedStorage.Hunters.Dust.Modules.RevolverServer.RevolverDashService
type: ModuleScript
lines: 192
---

# RevolverDashService

OOP server-side dash execution handler that validates, applies velocity, and manages cooldowns.

## What it does
1. Validates dash: player alive, not in HighNoon, cooldown elapsed (4s), valid move direction
2. Plays a server-side dash animation on the humanoid — the shared roll by default, or nothing at all when the caller passes `AnimationId = ""` (Bram opts out: his Breach Charge body animation is owned by GrudgekeeperWorldVisualServer, and the roll's legs would fight the charge run). The track is loaded **once per character** via [[AnimationLoader]] `loadCached`, held in `self.DashTracks[humanoid]` and replayed on each dash; each humanoid's own `Destroying` hook drops its entry
3. Sets horizontal velocity to dash direction * speed (240, or * 0.45 for air dash)
4. Disables AutoRotate and faces character in dash direction during dash
5. After 0.5s, reduces velocity to ground end multiplier (0.35) or air end multiplier (0.15)
6. Re-enables AutoRotate 0.12s after dash ends
7. Cleans up per-player cooldown tracking on disconnect

**`ResetAll()` clears every dash cooldown at round start** (2026-08-06). The cooldowns are absolute `os.clock()` stamps and the server plays rounds back to back now, so one started in the dying seconds of a round was still running when the next began. Wired to `ReplicatedStorage.RoundActive` by each hunter server module that owns an instance of this service (Dust's RevolverModule, Fortuna's CardsServer, and Bram's BreachChargeService, which wraps one) — the same signal UltimateChargeService already resets charges on. Named alongside `CleanupPlayer`, which is the leave-the-game path and is not a substitute.

## Dependencies
- **Requires:** [[AnimationLoader]] (from `ReplicatedStorage.Modules`, for the dash roll clip) — otherwise configured externally
- **Required by:** RevolverModule, GrudgekeeperModule (Bram instance handed to BreachChargeService — Breach Charge validation/cooldown)

## Connections
### RemoteEvents
None

### BindableEvents
None

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[AnimationLoader]] | `.loadCached()` | The dash roll clip, loaded once per character and replayed |
