---
tags: [client, localscript, combat, ui]
path: game.StarterPlayer.StarterPlayerScripts.Combat.DamageNumbersClient
type: LocalScript
lines: 98
---

# DamageNumbersClient

Floating damage numbers over hit enemies, styled after Redwater's.

## What it does
1. Listens to `Remotes.Hit` and rounds `data.damage`; ignores zero damage.
2. Resolves the hit target to its client visual: if the target has a `PVEId`, finds the rig in `workspace.PVE_ClientEnemies` whose `PVEProxyId` matches (rigs created by EnemyRenderer), else uses the target itself.
3. Creates (and weakly caches) one always-on-top `PVEDamageNumbers` BillboardGui on the visual's `Head`.
4. Body hits: cream number that pops, drifts up with jitter and fades.
5. Headshots: gold `N!` that pops, then splits into two halves that fly apart and fade.

## Dependencies
- **Requires:** Nothing
- **Required by:** Nobody

## Connections
### RemoteEvents
| Remote | Direction | Other script |
|--------|-----------|-------------|
| `Remotes.Hit` | ← Server | [[CombatServer]] hit confirm (`damage`, `headshot`, `target`) |

### BindableEvents
None

### Direct require()
None
