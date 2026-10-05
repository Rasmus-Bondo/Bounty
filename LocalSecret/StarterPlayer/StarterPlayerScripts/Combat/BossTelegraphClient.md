---
tags: [client, localscript, combat, enemies, ui]
path: game.StarterPlayer.StarterPlayerScripts.Combat.BossTelegraphClient
type: LocalScript
lines: 93
---

# BossTelegraphClient

Readable ground outlines and a text cue for the Grave Warden's slam and sweep attacks; damage and timing stay on the server.

## What it does
1. Listens to `Remotes.EnemyFX` for `WardenSlamTelegraph` / `WardenSweepTelegraph` (within 240 studs) and draws a neon boundary on the terrain: a full circle for a slam, a cone (`Direction`, `HalfAngle`) for a sweep, tweening yellow to red until `ImpactAt`.
2. On `WardenSlam` / `WardenSweep` with a matching attack `Id`, fades the outline and enters the recovery window.
3. Clears an attack on `Died`, `WardenSlamCancelled`, boss death, removal or when `RecoveryUntil` passes.
4. Every 0.05 s shows the `PVE_BossAttackCue` label when the player is within radius + 35: `SLAM/SWEEP · MOVE OUT / DODGE SIDEWAYS / STAY CLEAR · Ns`, or `WARDEN EXPOSED · ATTACK` during recovery.

## Dependencies
- **Requires:** Nothing
- **Required by:** Nobody

## Connections
### RemoteEvents
| Remote | Direction | Other script |
|--------|-----------|-------------|
| `Remotes.EnemyFX` | ← Server | [[EnemyService]] Warden telegraph / impact / cancel / death |

### BindableEvents
None

### Direct require()
None
