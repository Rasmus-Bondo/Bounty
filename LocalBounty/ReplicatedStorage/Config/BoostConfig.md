---
tags: [shared, modulescript, boosts, config]
path: game.ReplicatedStorage.Config.BoostConfig
type: ModuleScript
lines: 55
---

# BoostConfig

Shared catalog of the XP / Cash boost consumables. Identical copy must exist in Redwater Canyon — edit both together (same rule as BattlePassConfig).

## What it does
1. Exports `BOOSTS` — a map of 6 boost ids to `{ kind, percent, minutes, label, icon }`. Two kinds (`xp`, `cash`) × three durations (15/30/60 min), all `percent = 25`. `xp` multiplies account/level XP earning; `cash` multiplies Cash earning. `minutes` is a budget of **live-round** time spent only during active Redwater rounds (see Redwater's BoostService)
2. `icon` is the potion art for that boost — one asset per duration so 15/30/60 are tellable apart. It lives here rather than in either UI because **two** readers paint it: BoostsTab and BattlePassClient's reward cards. Adding a boost gives both its art automatically
3. `get(id)` — returns the catalog entry for an id, or nil
4. `list()` — stable id list for UI, sorted by kind then ascending duration

## Dependencies
- **Requires:** Nothing
- **Required by:** BoostService (validates ids on activate), BoostsTab (grid order, labels + icons), BattlePassClient (reward-card icon for `kind == "boost"`), BattlePassService (`get()` validates a `boost` reward's `boostId` before granting — an unknown id now refuses the claim rather than writing an unspendable inventory entry). A future trading-post UI will require it client-side.

## Connections
None
