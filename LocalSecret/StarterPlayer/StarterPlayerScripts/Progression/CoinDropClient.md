---
tags: [client, localscript, progression, vfx]
path: game.StarterPlayer.StarterPlayerScripts.Progression.CoinDropClient
type: LocalScript
lines: 177
---

# CoinDropClient

Client-only visuals for the local player's PVE coin drops; reports collected coin ids to the server.

## What it does
1. Pools anchored, non-colliding clones of `PVE.CoinAssets.Coin` in a `workspace.PVE_ClientCoins` folder (particles and trails off), pre-warming 10 off the critical frame. Other players never see these coins.
2. On `Drops`, scatters each new id around the corpse onto the ground (raycast ignoring enemies, players and the coin folder) and removes any evicted ids; `Clear` and CharacterAdded drop everything.
3. One Heartbeat animates all coins with a single `BulkMoveTo`: burst hop, idle bob/spin, then a magnet phase (trail on) once within `MagnetRadius`, collected at `CollectRadius`. Coins settle if the character is lost mid-flight and hide 1 s before the server's lifetime.
4. Flushes collected ids at most every 0.1 s in `MaxCollectBatch`-sized `Collect` messages. Uses distance checks instead of Touched and plays no sound.

## Dependencies
- **Requires:** [[CoinDropConfig]]
- **Required by:** Nobody

## Connections
### RemoteEvents
| Remote | Direction | Other script |
|--------|-----------|-------------|
| `PVE.Remotes.CoinDrop` | ← Server | [[CoinDropServer]] `Drops` and `Clear` |
| `PVE.Remotes.CoinDrop` | → Server | [[CoinDropServer]] `Collect` id batches |

### BindableEvents
None

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[CoinDropConfig]] | visual timings, `MaxLiveCoinsPerPlayer`, `MaxCollectBatch`, `CoinLifetime` | Animation tuning and client-side caps |
