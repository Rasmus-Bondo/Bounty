---
tags: [shared, modulescript, config, progression]
path: game.ReplicatedStorage.PVE.Config.CoinDropConfig
type: ModuleScript
lines: 28
---

# CoinDropConfig

Tuning table for PVE enemy coin drops (issue #60): rewards, caps, client visuals and server validation limits.

## What it does
1. `RewardByArchetype` scrap per kill (Drifter 1, Gunslinger 2, Bomber 2, Brute 4, Warden 12), `DefaultReward` 1 and `EliteMultiplier` 2. Every eligible player near the corpse gets their own drop of this size.
2. Drop caps: `MaxCoinsPerDrop` 5, `MaxLiveCoinsPerPlayer` 40, `ShareRadius` 150 studs, `CoinLifetime` 30 s.
3. Client visuals: scatter radius, burst time and hop, magnet radius/speeds/acceleration and `CollectRadius`.
4. Server validation: `MaxCollectDistance` 48 studs from the drop origin and `MaxCollectBatch` 24 ids per Collect message.
5. Coin value never reaches the client; clients only ever see coin ids.

## Dependencies
- **Requires:** Nothing
- **Required by:** CoinLedger, CoinDropServer, CoinDropClient

## Connections
None. Pure data module.
