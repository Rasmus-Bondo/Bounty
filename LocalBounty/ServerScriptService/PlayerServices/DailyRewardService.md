---
tags: [server, modulescript, dailyreward, economy]
path: game.ServerScriptService.PlayerServices.DailyRewardService
type: ModuleScript
lines: 199
---

# DailyRewardService

CLAIMS the daily play-streak rewards, and grants the **free instant Day 1**. Days 2+ are EARNED in Redwater (round finish); here in the lobby the player drains the pending queue (`DailyPending`) **one day at a time**. Rules live in [[DailyRewardConfig]].

## What it does
1. `ensureFreeFirstDay(data)` — the **free Day 1**: when a player has no active streak (brand-new OR just lapsed to 0), it starts the streak at day 1 and queues Day 1 as pending so it is **instantly claimable in the lobby WITHOUT playing a round**. Mirrors Redwater `registerPlay`'s day-1 bookkeeping (`DailyStreak = 1`, `DailyLastPlayDay = today`) so the normal claim path needs no special-casing and Redwater's `registerPlay` is a no-op for the rest of that day. Idempotent (no-op once streak ≥ 1); keyed on `DailyStreak == 0` so the free Day 1 returns after every lapse (welcome-back). Gated by `DailyRewardConfig.FREE_FIRST_DAY`
2. `sendState(player)` — applies any lapse (`applyLapse`, which wipes the unclaimed queue on a broken streak), then `ensureFreeFirstDay`, then fires `DailyRewardState` with `{ streak, pending, permaBoost, passivePercent, advancedToday, secondsUntilReset }`. `advancedToday` = has the player already advanced the streak today (free Day 1 or a round played today); the panel shows a live reset countdown on the next tile while true, and a "PLAY" prompt once the reset has passed. `secondsUntilReset` (from [[DailyRewardConfig]]) drives that countdown
3. `claim(player, dayNum)` — **per-day claim**. Applies a lapse + `ensureFreeFirstDay`, then removes the FIRST pending entry equal to `dayNum` and grants just that one day; ignores a `dayNum` that is not currently pending. Per grant kind: Cash/Tokens via [[Wallet]] `award` (reason `daily_reward`); account XP added to `data.XP` with `data.Level` recomputed from a mirrored XP curve (matches Redwater's `Config.XP_BASE/LINEAR/QUADRATIC` + ProgressionService); boost items via [[BoostService]] `grantBoost`; `passive` is a no-op here (the +10% is driven by the play-streak in Redwater). Syncs leaderstats via [[DataService]] `updateLeaderstats`, then re-sends a fresh `DailyRewardState` so the panel re-renders
4. Local XP curve mirror: `xpNeededForLevel` / `levelFromTotalXP` (kept in sync with Redwater so lobby-granted XP lands on the same level as gameplay XP)
5. On `Start()` + PlayerAdded, pushes state so the [[DailyLoginController]] can show its pending dot + the free Day 1 as soon as the player loads; handles `RequestDailyReward` and `ClaimDailyReward` (validates the day number is a number); creates its RemoteEvents in ReplicatedStorage if missing

## Dependencies
- **Requires:** [[DataService]], [[Wallet]], [[BoostService]], [[DailyRewardConfig]]
- **Required by:** Main (starts it)

## Connections
### RemoteEvents
| Remote | Direction | Other script |
|--------|-----------|-------------|
| `RequestDailyReward` | ← Client | [[DailyLoginController]] asks for the current state |
| `DailyRewardState` | → Client | Full state `{ streak, pending, permaBoost, passivePercent, advancedToday, secondsUntilReset }` for the track UI |
| `ClaimDailyReward` | ← Client | [[DailyLoginController]] claims ONE pending day (sends the day number) |

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[DataService]] | `getPlayerData()`, `updateLeaderstats()` | Read/write daily fields; sync Cash/Tokens/Level/XP after a claim |
| [[Wallet]] | `award()` | Credit + log Cash/Tokens (reason `daily_reward`) |
| [[BoostService]] | `grantBoost()` | Grant the day 3 / 6 boost items into the inventory |
| [[DailyRewardConfig]] | `getReward()`, `dayNumber()`, `secondsUntilReset()`, `applyLapse()`, `ensureData()`, `FREE_FIRST_DAY` | Reward mapping, reset-day math, countdown, break detection, free Day 1 gate |
