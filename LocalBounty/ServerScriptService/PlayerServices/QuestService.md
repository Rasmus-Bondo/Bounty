---
tags: [server, modulescript, quests]
path: game.ServerScriptService.PlayerServices.QuestService
type: ModuleScript
lines: 211
---

# QuestService

Assigns daily quests to players on join, resets expired buckets, and handles reward claiming.

## What it does
1. Reads quest definitions from [[QuestConfig]] `questById` directly — it no longer builds local `questById`/`dailyPool`/`weeklyPool` tables, because a second copy of the index is just somewhere for the two places to disagree
2. On player join, polls until the DataService profile is loaded then calls `refreshAndSend`
3. `refreshAndSend` calls `ensureQuestData` (guards against missing fields on old profiles, incl. `bonusClaimedAt` per bucket) then fires the full quest state
4. `assignBucket` delegates selection to [[QuestConfig]] `selectForCycle(cadence, count, userId, cycle)`, so both places derive the same bucket for a player from `(userId, cycle)` alone
5. `isExpired` compares the stored `bucket.cycle` against `QuestConfig.cycleIndex`. Profiles predating `bucket.cycle` carry only `assignedAt`, so their cycle is derived from it rather than treating them as expired on sight
6. `count == 0` (the disabled weekly cadence) is handled explicitly: an empty bucket is *correct* there and must not read as "needs assignment", or every call would rewrite the profile
7. Drops slots whose quest id no longer exists in the config. Without this a stale id sits in the bucket unclaimable until the next reset, because the claim path resolves `questById[slot.questId]` and silently returns on a miss
8. Handles `ClaimQuestRewardEvent`. **Single quest** (numeric `slotIndex`): validates cadence, slot index and completed+unclaimed state, awards `reward.xp` to profile data and `reward.cash` via [[Wallet]] `award` (reason `quest`). **Complete-all bonus** (`slotIndex == "bonus"`): validates every slot is completed and the bonus is unclaimed this cycle, stamps `bucket.bonusClaimedAt`, then awards `QuestConfig.BONUS[cadence]`
9. Quest XP is written straight into `data.XP` (it does **not** go through Redwater's ProgressionService, so no boost multiplier applies and no LevelUp fires). Both claim paths therefore re-derive `data.Level` via [[DataService]] `getLevelFromXP` immediately after — without it the stored level and the Level leaderstat stayed stale until the player next earned XP in Redwater
10. Bonus "claimed this cycle" is **derived** from `bonusClaimedAt` vs the current cycle, so it self-expires on reset with no explicit clear

## Assignment used to diverge between places
This place shuffled the pool randomly and expired buckets on **UTC-day boundaries**; Redwater rotated deterministically and expired on a **rolling 24h** from `assignedAt` — both writing one shared profile. They could disagree about which quests were live *and* about when the day ended, so a player crossing between places could watch their quests swap out mid-day with progress reset. Selection and cycle maths now live in the mirrored config.
11. **BOUNTY+ boost** (2026-09-06) — both claim paths (single quest and the complete-all bonus) run `reward.cash` and `reward.xp` through `BountyPlusConfig.apply` before the Wallet award and the `data.XP` write. Quests carry no other multiplier, so the pass term IS the multiplier here — a bare x1.25 / x1.10. The same helper the quest card draws with, so the two cannot disagree

## Dependencies
- **Requires:** [[DataService]], [[Wallet]], [[QuestConfig]], [[BountyPlusConfig]]
- **Required by:** Main

## Connections
### RemoteEvents
| Remote | Direction | Other script |
|--------|-----------|-------------|
| `QuestDataEvent` | → Client | [[QuestClient]] receives full quest state on join and after claim |
| `ClaimQuestRewardEvent` | ← Client | [[QuestClient]] fires when player clicks Claim |
| `RequestQuestDataEvent` | ← Client | [[QuestClient]] pulls current state on demand |

### BindableEvents
None

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[DataService]] | `getPlayerData()`, `getLevelFromXP()`, `updateLeaderstats()` | Read/write profile, re-derive `data.Level` after a quest XP write, sync leaderstats |
| [[Wallet]] | `award()` | Award `reward.cash` as a Cash economy Source (reason `quest`) on claim |
| [[QuestConfig]] | `questById`, `selectForCycle()`, `cycleIndex()`, `BONUS`, counts, intervals | Quest definitions, deterministic assignment, cycle maths, bonus rewards |
