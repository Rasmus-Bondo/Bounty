---
tags: [server, modulescript, friendbonus, economy, ui]
path: game.ServerScriptService.PlayerServices.FriendBonusService
type: ModuleScript
lines: 234
---

# FriendBonusService

Computes the friend-group Cash/XP bonus in the lobby and streams each player's TOTAL active multiplier (friend bonus + active boost potions + daily-streak passive + the BOUNTY+ game pass) to the [[MultiplierDisplayClient]] display. Rules: [[FriendBonusConfig]].

## What it does
1. Counts each player's Roblox friends on the server (`Player:IsFriendsWith`, per-pair cached), capped by [[FriendBonusConfig]] `MAX_FRIENDS_COUNTED`
2. `buildState(player)` — reads the profile ([[DataService]]) for active boost potions (`Boosts.Active`) and the daily-streak passive (`DailyPermaBoost` × [[DailyRewardConfig]] `PASSIVE_BOOST_PERCENT`), combines them additively with the friend % and the BOUNTY+ term ([[BountyPlusConfig]] `bonusFraction`, +25% XP / +10% Cash, reported as `bountyPlusCashPercent` / `bountyPlusXpPercent`) into `cashMult` / `xpMult`, and fires `MultiplierStateEvent`
3. Recomputes + pushes on every roster change (PlayerAdded/PlayerRemoving) and, for a joining player, after their profile loads
4. `refresh(player)` — public; called by BoostService the instant a potion is activated so the display updates immediately. BOUNTY+ instead re-pushes off the player's `OwnsBountyPlus` attribute-changed signal, which BountyPlusService sets right after the profile stamp — ownership resolves seconds after join (a web call with retries) and again on a mid-session purchase, both long after this service's own join push
5. Handles `RequestMultiplierState` (client → fresh push). The lobby has no earning, so this figure is a live preview + motivator for the Invite Friends button; the real earn-time bonus is recomputed on the Redwater server

## Dependencies
- **Requires:** [[FriendBonusConfig]], [[DailyRewardConfig]], [[BountyPlusConfig]], [[DataService]]
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
| [[BountyPlusConfig]] | `dataOwns()`, `bonusFraction()` | BOUNTY+ ownership off the profile stamp + its Cash/XP percentages |
| [[DataService]] | `getPlayerData()` | Read active boosts + `DailyPermaBoost` from the profile |
