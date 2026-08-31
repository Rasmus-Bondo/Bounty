---
tags: [shared, modulescript, quests, config]
path: game.ReplicatedStorage.Config.QuestConfig
type: ModuleScript
lines: 229
---

# QuestConfig

Single source of truth for daily quest definitions, selection and reset cadence. Mirrored verbatim across both places.

## What it does
1. Exports `DAILY_COUNT` (3) and `WEEKLY_COUNT`. **`WEEKLY_COUNT = 0`**: the old weekly pool is gone entirely; the Quests menu WEEKLY tab shows battle-pass quests from `BattlePassConfig.WEEKS`, rendered by [[QuestClient]]
2. Exports `DAILY_RESET_SECONDS` (86400) and `WEEKLY_RESET_SECONDS` (604800)
3. Exports `BONUS` — the complete-all reward per cadence. Only the daily bonus is reachable while `WEEKLY_COUNT = 0`, since an empty bucket never reads as complete
4. Defines `QUESTS` — **24 daily quests across 10 groups** (`kills`, `precision`, `streak`, `damage`, `support`, `rounds`, `placement`, `bounty`, `ability`, `hunter`). Each entry carries `id`, `type`, `group`, `goal`, `cadence`, `reward`, `label`
5. `cycleIndex(resetSeconds, now)` — the only definition of "which day is it"
6. `selectForCycle(cadence, count, userId, cycle)` — deterministic seeded shuffle that never returns two quests from the same `group`
7. Quest `type` strings must match the `eventType` passed to `QuestEvents.track()` in Redwater
8. Daily `reward.xp` sits on the 0.50x scale set 2026-07-25. Quest XP is **account** XP (lands in `data.XP`, no boost multiplier) — battle-pass quest XP is a separate track that never touches `data.XP`
9. Rewards follow `cash = 26 × matches` (rounded to 5) and `xp = 2 × cash` on every row, retuned 2026-07-31 alongside the goals. `d_rounds_2` was previously the one row breaking the 2× rule (35/75)

## Why selection lives here
The two places used to assign buckets with **different algorithms against one shared profile**: this place shuffled randomly and expired on UTC-day boundaries; Redwater rotated deterministically and expired on a rolling 24h from `assignedAt`. Whichever place a player loaded first won the assignment, and the rolling-vs-aligned mismatch meant one place could consider a bucket live that the other had already rolled over — silently swapping the player's quests and wiping progress. Selection is now one function seeded by `(userId, cycle)`, so both places compute the same set without talking to each other.

## Why every quest carries a `group`
A draw never takes two quests from the same group, because same-group quests are tiers of one objective and the smaller tier completes itself. The old pool was 3 groups × 2 tiers drawn 3-at-a-time: **12 of every 20 draws (60%)** handed out a pair like "Get 5 Kills" + "Get 10 Kills" where the 5 was free, which also made the complete-all bonus randomly a 2- or 3-objective day. Verified after the rewrite: 8,400 draws across 400 users × 21 days produced 0 duplicate-group draws and 975 distinct combinations.

## Goals are sized in matches, not raw counts

Retuned **2026-07-31**. A day is gated by the *hardest* of its three cards, and by that measure the pool was already long — mean **4.36 matches** to clear all three. The defect was the **floor**: ten of the 24 quests finished inside 1.5 matches and four inside a single one, so **44% of days handed the player a card that was already complete when their first match ended**. Two cards done in game one, then a grind for the straggler — which is what "players finish the dailies in a couple of games" actually described. The day was never short; the cards were.

Goals are now sized against measured per-match rates for an average 6-minute round: 14 kills, ~10 headshot **hits** (`headshot` fires per hit, not per kill), ~2,000 damage, 2.5 assists, ~1 `becomeBounty`, 1.8 ultimate kills. Fifteen goals moved; nothing now clears in under ~1.75 matches.

Verified over 90,000 draws through `selectForCycle`:

| | Before | After |
|---|---|---|
| Day has a card done in <1 match | 44.0% | **0.0%** |
| Day cleared in ≤2 matches | 14.3% | **0.5%** |
| Mean matches to clear all 3 | 4.36 | 4.72 |

The nine low-**rate** quests were deliberately left alone (both streaks, both podiums, win, both bounty kills, bounty time, hunter variety) — they already sat at 1.67–6.67 matches. `d_win_1` and `d_hunters_1` in particular are a lottery and a feature-discovery check rather than dials a player can turn inside a session, so raising them would add waiting, not difficulty. They are also why 36% of days still need more than 5 matches, which is the open question hanging over the complete-all bonus for a 3-games-a-day player.

**Quest ids are deliberately not renamed** to match their new goals — `d_kills_5` now asks for 25. Ids are persisted in profile buckets and QuestService drops slots whose id no longer exists, so renaming would churn every live bucket for cosmetic tidiness.

## "Bounty" alone is never a label
The three bounty types are three different jobs and the word by itself picks none of them. `bountyClaim` is *killing the marked player*, `becomeBounty` is *being marked*, `bountyTime` is *seconds spent marked* — so "Claim 2 Bounties" / "Become a Bounty" / "Hold a Bounty for 2 Minutes" all read as roughly the same sentence and two of them can be drawn on the same day. They now say `Kill 2 Bounty Targets` / `Become the Bounty` / `Be the Bounty for 2 Minutes`, matching the weekly set's wording. Any new bounty quest names the target explicitly.

## Label length is a hard constraint
The objective text renders into a `TextScaled` box roughly **86×13 px** on a phone. A label needing more than ~1.3× that width wraps to two ~6px lines and becomes unreadable. Measured, not estimated — every label in this file is verified under that ceiling. Anything longer belongs in the card's title slot, which is twice the height; that is why the hunter quest's "swap on death" lives in [[QuestClient]]'s `QUEST_TITLE` map rather than in the label.

## Kills, headshots, damage and streaks all count against bots
Bots are round participants and always have been, so this is not a new farming vector — it is the same rate kills already pay. Placement quests include bots in the standings for the same reason.

## Dependencies
- **Requires:** Nothing
- **Required by:** QuestService (Bounty), QuestService (Redwater), QuestClient

## Connections
None

## Adding a new quest type
1. Add entries to `QUESTS` with a new `type` string and an appropriate `group`
2. Add `QuestEvents.track(player, "<type>", n)` at the relevant hook point in Redwater
3. Add a `QUEST_TITLE` entry in [[QuestClient]] so the card gets a category label
4. Mirror the file to the other place and verify byte length + checksum
