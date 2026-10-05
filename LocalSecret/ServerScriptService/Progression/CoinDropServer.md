---
tags: [server, script, progression, enemies]
path: game.ServerScriptService.Progression.CoinDropServer
type: Script
lines: 91
---

# CoinDropServer

Turns PVE enemy deaths into per-player, client-rendered coin drops and validates the pickups.

## What it does
1. Watches `workspace.PVE_Enemies` itself (no EnemyService hook): binds `Humanoid.Died` once on every `PVEEnemy` model, so every kill path drops coins and chunk despawns (destroyed without dying) do not.
2. Reward per kill comes from `PVEArchetype` and `PVEElite` via CoinDropConfig; every eligible player within `ShareRadius` of the corpse gets their own drop from CoinLedger.
3. Batches drops and cap evictions per player and flushes them once per Heartbeat as one `Drops` message; sweeps expired coins every 5 s.
4. Clears a player's coins (and tells the client `Clear`) on CharacterRemoving, on becoming `PVEDowned`, and on leaving the encounter; forgets them on PlayerRemoving.
5. Forwards client `Collect` id batches to `CoinLedger.collect`.

## Dependencies
- **Requires:** [[CoinDropConfig]], [[CoinLedger]]
- **Required by:** Nobody

## Connections
### RemoteEvents
| Remote | Direction | Other script |
|--------|-----------|-------------|
| `PVE.Remotes.CoinDrop` | → Client | [[CoinDropClient]] `Drops` (origin + ids, evicted ids) and `Clear` |
| `PVE.Remotes.CoinDrop` | ← Client | [[CoinDropClient]] `Collect` id batches |

### BindableEvents
None

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[CoinDropConfig]] | `RewardByArchetype`, `DefaultReward`, `EliteMultiplier`, `ShareRadius` | Reward size and who shares it |
| [[CoinLedger]] | `createDrop`, `collect`, `eligible`, `rootOf`, `clear`, `sweep` | Authoritative coin state and credit |
