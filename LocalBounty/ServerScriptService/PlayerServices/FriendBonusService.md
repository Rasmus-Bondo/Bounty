---
tags: [server, modulescript, friendbonus, economy, ui]
path: game.ServerScriptService.PlayerServices.FriendBonusService
type: ModuleScript
lines: 190
---

# FriendBonusService

Computes the friend-group Cash/XP bonus in the lobby and streams each player's TOTAL active multiplier (friend bonus + active boost potions + daily-streak passive) to the center-top [[MultiplierDisplayClient]] display. Rules: [[FriendBonusConfig]].

## What it does
1. Counts each player's Roblox friends on the server (`Player:IsFriendsWith`, per-pair cached), capped by [[FriendBonusConfig]] `MAX_FRIENDS_COUNTED`
2. `buildState(player)` — reads the profile ([[DataService]]) for active boost potions (`Boosts.Active`) and the daily-streak passive (`DailyPermaBoost` × [[DailyRewardConfig]] `PASSIVE_BOOST_PERCENT`), combines them additively with the friend % into `cashMult` / `xpMult`, and fires `MultiplierStateEvent`
3. Recomputes + pushes on every roster change (PlayerAdded/PlayerRemoving) and, for a joining player, after their profile loads
4. `refresh(player)` — public; called by BoostService the instant a potion is activated so the display updates immediately
5. Handles `RequestMultiplierState` (client → fresh push). The lobby has no earning, so this figure is a live preview + motivator for the Invite Friends button; the real earn-time bonus is recomputed on the Redwater server

## Dependencies
- **Requires:** [[FriendBonusConfig]], [[DailyRewardConfig]], [[DataService]]
- **Required by:** Main (starts it), BoostService (`refresh` on activate)

## Connections
### RemoteEvents
| Remote | Direction | Other script |
|--------|-----------|-------------|
| `MultiplierStateEvent` | → Client | [[MultiplierDisplayClient]] renders cash/xp multipliers |
| `RequestMultiplierState` | ← Client | [[MultiplierDisplayClient]] asks for a fresh push on startup |

### BindableEvents
None

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[FriendBonusConfig]] | `percentForFriends()`, `clampFriends()` | Friend bonus math |
| [[DailyRewardConfig]] | `PASSIVE_BOOST_PERCENT` | Daily-streak passive term in the total multiplier |
| [[DataService]] | `getPlayerData()` | Read active boosts + `DailyPermaBoost` from the profile |
