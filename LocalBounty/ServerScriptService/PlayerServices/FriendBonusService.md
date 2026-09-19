---
tags: [server, modulescript, friendbonus, economy, ui]
path: game.ServerScriptService.PlayerServices.FriendBonusService
type: ModuleScript
lines: 280
---

# FriendBonusService

Computes the friend-group Cash/XP bonus in the lobby and streams each player's TOTAL active multiplier (friend bonus + active boost potions + daily-streak passive + the BOUNTY+ game pass + any limited-time event) to the [[MultiplierDisplayClient]] display, together with the running event's banner copy. Rules: [[FriendBonusConfig]].

## What it does
1. Counts each player's Roblox friends on the server (`Player:IsFriendsWith`, per-pair cached), capped by [[FriendBonusConfig]] `MAX_FRIENDS_COUNTED`
2. `buildState(player)` — reads the profile ([[DataService]]) for active boost potions (`Boosts.Active`) and the daily-streak passive (`DailyPermaBoost` × [[DailyRewardConfig]] `PASSIVE_BOOST_PERCENT`), combines them additively with the friend % and the BOUNTY+ term ([[BountyPlusConfig]] `bonusFraction`, +25% XP / +10% Cash, reported as `bountyPlusCashPercent` / `bountyPlusXpPercent`) into `cashMult` / `xpMult`, and fires `MultiplierStateEvent`. The limited-time event term comes from [[BoostConfig]] `eventPercent` — the SAME table both match places add to their earn multiplier, so the preview and the earn it previews cannot disagree; restating the percent or the window here would be the EmoteConfig drift again. `activeEvent(nil)` also supplies `eventLabel` and `eventEndsAt` for the banner, `endsAt` as a UTC epoch second rather than a remaining duration so the client's countdown cannot drift
3. Recomputes + pushes on every roster change (PlayerAdded/PlayerRemoving) and, for a joining player, after their profile loads
4. `refresh(player)` — public; called by BoostService the instant a potion is activated so the display updates immediately. BOUNTY+ instead re-pushes off the player's `OwnsBountyPlus` attribute-changed signal, which BountyPlusService sets right after the profile stamp — ownership resolves seconds after join (a web call with retries) and again on a mid-session purchase, both long after this service's own join push
5. **Event-boundary poll** (2026-09-19) — a 5s loop watching which event [[BoostConfig]] reports as running, re-pushing state to everyone the moment it changes. Without it a player standing in the lobby at the window's open or close keeps the stale figure, and never sees the banner, until a friend happens to join or leave. Polled rather than a timer to each `endsAt` because one loop also catches a window OPENING, a row added by a republish, and the DEV force; it calls `sendState` rather than `refreshAll`, since no friend has moved
6. Handles `RequestMultiplierState` (client → fresh push). The lobby has no earning, so this figure is a live preview + motivator for the Invite Friends button; the real earn-time bonus is recomputed on the Redwater server

## Dependencies
- **Requires:** [[FriendBonusConfig]], [[DailyRewardConfig]], [[BountyPlusConfig]], [[BoostConfig]], [[DataService]]
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
| [[BoostConfig]] | `eventPercent()`, `activeEvent()` | Limited-time event term in the multiplier, plus the banner's label + end time |
| [[DataService]] | `getPlayerData()` | Read active boosts + `DailyPermaBoost` from the profile |
