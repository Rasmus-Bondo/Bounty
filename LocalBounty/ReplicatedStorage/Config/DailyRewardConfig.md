---
tags: [shared, modulescript, dailyreward, config]
path: game.ReplicatedStorage.Config.DailyRewardConfig
type: ModuleScript
lines: 143
---

# DailyRewardConfig

Shared catalog + rules for the daily play-streak rewards. Identical copy must exist in Redwater Canyon — edit both together (same rule as BoostConfig / BattlePassConfig).

## What it does
1. `DAYS` — the 7-day reward track (day 1 → 50 Cash, day 2 → 200 XP, day 3 → 1 Cash + 1 XP boost item, day 4 → 100 Cash, day 5 → 400 XP, day 6 → 1 Cash + 1 XP boost item, day 7 → 50 Tokens + unlock the passive boost) plus `REPEAT_REWARD` (day ≥ 8 → 10 Tokens). Each day is a list of grant entries (`cash`/`xp`/`tokens`/`boost`/`passive`)
2. `PASSIVE_BOOST_PERCENT = 10`, `PASSIVE_BOOST_START_DAY = 7` — the passive +10% Cash & XP unlocked at day 7, active while the streak stays ≥ 7 (read by BoostService `getMultiplier`, additive with a boost potion)
3. `CASH_BOOST_ID` / `XP_BOOST_ID` — the BoostConfig ids handed out on boost days (`cash_25_15`, `xp_25_15`)
4. `FREE_FIRST_DAY = true` — Day 1 is granted FREE and is instantly claimable in the Bounty lobby WITHOUT playing a round; Day 2+ still require finishing a round. Applies to a brand-new player AND whenever the streak has just lapsed to 0 (welcome-back). Consumed by the Bounty DailyRewardService
5. `RESET_OFFSET_HOURS = 0` — the global daily reset happens at 00:00 in UTC+this offset (0 = midnight UTC, one shared reset instant for everyone, not spoofable via a device clock). Shift it to move the reset to a timezone's midnight (e.g. -5 → 00:00 US-Eastern)
6. `getReward(dayNum)` — reward def for a streak day (day ≥ 8 → REPEAT_REWARD)
7. `dayNumber(nowSec?)` — the whole reset-day number, `floor((now + RESET_OFFSET_HOURS*3600)/86400)`
8. `nextResetTime(nowSec?)` / `secondsUntilReset(nowSec?)` — unix time of / seconds remaining until the next reset boundary (0..86400); `secondsUntilReset` is sent to the client so the panel can tick a live countdown on the next-to-unlock tile
9. `isLapsed(lastPlayDay, today)` — true if a full reset-day was skipped (streak broken)
10. `ensureData(data)` — defensive normaliser for the four profile fields (`DailyStreak`, `DailyLastPlayDay`, `DailyPending`, `DailyPermaBoost`)
11. `applyLapse(data, today)` — on a broken streak, resets the counter to 0, turns off the passive boost, and CLEARS the unclaimed queue (unclaimed rewards are lost on a break, by design). Called on reads in both places

## Dependencies
- **Requires:** Nothing
- **Required by:** DailyRewardService (claims the queued rewards; grants the free Day 1), DailyLoginController (reward labels + countdown for the track UI). References BoostConfig ids by string only (no require).

## Connections
None
