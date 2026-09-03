---
tags: [server, modulescript, boosts, economy]
path: game.ServerScriptService.PlayerServices.BoostService
type: ModuleScript
lines: 179
---

# BoostService

Bounty-lobby boost server — where players **activate** XP / Cash boost consumables. Activation writes the running boost onto the shared profile; because the lobby has no round loop it stays **paused** at full duration here, and only ticks down (and multiplies earnings) once the player is in a live Redwater round — handled by Redwater's BoostService. Catalog: [[BoostConfig]] (mirrored verbatim both places).

## What it does
1. `ensureBoosts(data)` — idempotent guard; guarantees `Boosts = { Inventory, Active }`
2. `activate(player, boostId)` — validates the catalog id + inventory count, **blocks if a boost of that kind is already running** (block-until-expired), else decrements inventory and sets `Active[kind] = { percent, remaining = minutes*60 }`. No ticking in the lobby, so remaining stays paused. After activating, nudges [[FriendBonusService]] `refresh` (lazy/guarded) so the center-top total-multiplier display updates immediately
3. `grantBoost(player, boostId, count)` — adds consumables to the inventory (future trading post / testing; the battle-pass reward claim writes inventory directly in BattlePassService; also called by DailyRewardService to hand out the day 3 / 6 boost items). Refreshes state via `sendState`
4. `sendState(player)` — writes `XPBoostRemaining` / `CashBoostRemaining` attributes and fires `BoostStateEvent` with `{ Inventory, Active }` (on join / activate / grant)
5. Handles `ActivateBoost` (client → activate) and `RequestBoostState` (client → sendState); creates both RemoteEvents plus `BoostStateEvent` in ReplicatedStorage on `Start()`
6. On join, polls `DataService.getPlayerData` until the profile loads, then guards + sends initial state

## Dependencies
- **Requires:** [[BoostConfig]], [[DataService]], [[FriendBonusService]] (lazy, in `activate`)
- **Required by:** Main (starts it), DailyRewardService (calls `grantBoost` for daily boost-day rewards)

## Connections
### RemoteEvents
| Remote | Direction | Other script |
|--------|-----------|-------------|
| `ActivateBoost` | ← Client | [[BoostsTab]] requests activating an owned boost by id (BOOSTS tab USE button) |
| `RequestBoostState` | ← Client | [[BoostsTab]] / [[Panels]] ask for a fresh state push on open / entering BOOSTS |
| `BoostStateEvent` | → Client | Pushes `{ Inventory, Active }` on join / activate / grant to [[BoostsTab]] |
| `BoostStateEvent` | → Client | [[NewItemClient]] listens only as an ownership-moved signal for the COLLECTION dot chain |

### BindableEvents
None

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[BoostConfig]] | `get()` | Validate boost ids; read kind/percent/minutes |
| [[DataService]] | `getPlayerData()` | Read/write the player's `Boosts` on the profile |
| [[FriendBonusService]] | `refresh()` | Push a fresh total-multiplier display state right after a boost is activated |
