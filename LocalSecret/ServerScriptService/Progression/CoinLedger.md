---
tags: [server, modulescript, progression]
path: game.ServerScriptService.Progression.CoinLedger
type: ModuleScript
lines: 103
---

# CoinLedger

Server-authoritative ledger for client-rendered PVE coin drops: value, ownership, expiry and exactly-once credit.

## What it does
1. Keeps per-player coin bags (`id -> value, origin, expires`), an oldest-first order queue and a live count; ids are a global incrementing counter.
2. `createDrop(player, origin, total)` splits the scrap into up to `MaxCoinsPerDrop` coins, evicts the oldest past `MaxLiveCoinsPerPlayer`, and returns the new ids plus the evicted ids.
3. `collect(player, ids)` rejects oversize batches and ineligible players, then credits each unexpired id within `MaxCollectDistance` of its drop origin exactly once.
4. `awardScrap` is the single credit point: it adds to the run's carried `PVEUnsecured` (the same path as salvage pickups), secured on extraction and wiped on down/death.
5. `eligible(player)` requires `PVEInEncounter`, not `PVEDowned`/`PVEEliminated`, and a living root; `rootOf`, `clear`, `sweep` (expired coins) and `liveCount` round out the API.

## Dependencies
- **Requires:** [[CoinDropConfig]]
- **Required by:** CoinDropServer

## Connections
### RemoteEvents
None

### BindableEvents
None

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[CoinDropConfig]] | `MaxCoinsPerDrop`, `MaxLiveCoinsPerPlayer`, `CoinLifetime`, `MaxCollectDistance`, `MaxCollectBatch` | Caps, expiry and pickup validation |
