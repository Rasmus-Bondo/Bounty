---
tags: [server, modulescript, boosts, economy]
path: game.ServerScriptService.PlayerServices.BoostService
type: ModuleScript
lines: 233
---

# BoostService

Spends the live-round-time budget of active XP / Cash boost consumables and exposes a multiplier that ProgressionService applies to every gameplay earn. **Activation happens in the Bounty lobby** (BoostService there) — this place only ticks the timer during rounds and streams state for display; there is no client `ActivateBoost` handler here.

## What it does
1. `ensureBoosts(data)` — idempotent guard/migration; guarantees `Boosts = { Inventory, Active }`, resetting any pre-migration shape
2. `getMultiplier(player, kind)` — **additive** multiplier: `1 + (active potion %/100) + (daily-streak passive %/100) + (friend-group %/100)`. Adds the potion bonus while a boost of that kind has time left, adds the [[DailyRewardConfig]] `PASSIVE_BOOST_PERCENT` (+10%) whenever the player's `DailyPermaBoost` flag is set (daily streak ≥ 7), and adds [[FriendBonusService]] `getBonusPercent` (+5% per friend on the server, capped +50%). So a 25% potion + passive + 3 friends = ×1.50. The friend term is a separate additive term — it never touches or extends the potion `remaining`. Read by ProgressionService `addRewards` (`math.floor(base*mult + 0.5)`)
3. `activate(player, boostId)` — the shared activation routine (validate id + inventory, block-if-already-running, decrement, set `Active[kind] = { percent, remaining = minutes*60 }`). Exposed as a server/testing API only; **NOT wired to a client RemoteEvent here** — activation is done in the Bounty lobby
4. `grantBoost(player, boostId, count)` — adds consumables to the inventory (for the battle pass / future trading post / testing)
5. Round-gated tick loop: every ~1s **while `State.roundActive`**, decrements each online player's `Active[*].remaining` by real elapsed time, expiring at ≤ 0 (clears the slot, fires `BoostExpired`). Pauses in intermission, in the lobby, and offline
6. Writes `XPBoostRemaining` / `CashBoostRemaining` player attributes each tick for a smooth client countdown
7. Streams inventory + active state via `BoostStateEvent` (on join, activate, grant, expire) and on demand via `RequestBoostState`
8. Creates its RemoteEvents in ReplicatedStorage on `Start()` if missing

## Dependencies
- **Requires:** [[BoostConfig]], [[DailyRewardConfig]], [[DataService]], [[State]] (in Start), [[FriendBonusService]] (in Start)
- **Required by:** Main (starts it), ProgressionService (calls `getMultiplier`)

## Connections
### RemoteEvents
| Remote | Direction | Other script |
|--------|-----------|-------------|
| `RequestBoostState` | ← Client | Client asks for a fresh state push — UI (not yet built) |
| `BoostStateEvent` | → Client | Pushes `{ Inventory, Active }` on join/activate/grant/expire — UI (not yet built) |
| `BoostExpired` | → Client | Notifies a boost of a kind just ran out — UI (not yet built) |

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[BoostConfig]] | `get()` | Validate boost ids; read kind/percent/minutes |
| [[DailyRewardConfig]] | `PASSIVE_BOOST_PERCENT` | Add the daily-streak passive +10% to the multiplier when `DailyPermaBoost` is set |
| [[DataService]] | `getPlayerData()` | Read/write the player's `Boosts` on the profile |
| [[State]] | `State.roundActive` | Gate the tick loop to live rounds (match-time only) |
| [[FriendBonusService]] | `getBonusPercent()` | Add the friend-group bonus term to `getMultiplier` |
