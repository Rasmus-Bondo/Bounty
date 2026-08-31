---
tags: [server, modulescript, quests]
path: game.ServerScriptService.PlayerServices.QuestService
type: ModuleScript
lines: 250
---

# QuestService

Assigns daily quest slots, tracks progress during gameplay, pushes daily state to the in-round HUD, and fires a completion toast. Claiming lives in Bounty; progress is written straight to the player's ProfileService profile and persists via the shared `PlayerData_v2` DataStore.

## What it does
1. Reads quest definitions from [[QuestConfig]] `questById` directly — it no longer builds a local index, because a second copy of the lookup is just somewhere for the two places to disagree
2. `ensureRemote()` ensures the `Events/QuestEvents/QuestStateUpdated` RemoteEvent and `QuestStateRequest` RemoteFunction exist in ReplicatedStorage
3. `assignBucket` delegates selection to [[QuestConfig]] `selectForCycle(cadence, count, userId, cycle)`, so both places derive the same bucket for a player from `(userId, cycle)` alone
4. `ensureBucket` decides staleness by comparing the stored `bucket.cycle` against `QuestConfig.cycleIndex`. Profiles predating `bucket.cycle` carry only `assignedAt`, so their cycle is derived from it — without that every such profile would read as "wrong cycle" on first load and be reassigned on sight, wiping a day of progress the moment this shipped
5. `count == 0` (the disabled weekly cadence) is handled explicitly: an empty bucket is *correct* there and must not read as "needs assignment", or every call would rewrite the profile
6. Drops slots whose quest id no longer exists in the config (a pool edit between sessions) and reassigns if that empties the bucket
7. `trackEvent(player, eventType, amount)` increments matching slots and marks `completed` when `progress >= goal`
8. Fires `QuestCompleteEvent` the moment a slot completes, with `{ title, objective, goal }`
9. `waitForProfile(player)` polls `DataService.getPlayerData` every 0.1s (15s timeout) — needed on teleport-in because ProfileService's async load can outrun any fixed delay
10. `sendDailyState(player)` and the `QuestStateRequest` bind both wait for the profile, so the client's eager-fetch on join yields until data is ready instead of getting an empty table

## Assignment used to diverge between places
This place rotated the pool deterministically and expired buckets on a **rolling 24h** from `assignedAt`; Bounty shuffled randomly and expired on **UTC-day boundaries** — both writing one shared profile. They could disagree about which quests were live *and* about when the day ended, so a player crossing between places could watch their quests swap out mid-day with progress reset. Selection and cycle maths now live in the mirrored config.

## Prefer QuestEvents at hook sites
Call [[QuestEvents]] `track()` rather than this module's `trackEvent` directly. The battle-pass weeklies are a second quest engine reading the same events, and a site that calls only one of the two silently half-tracks.

## Dependencies
- **Requires:** [[DataService]], [[QuestConfig]]
- **Required by:** Main, QuestEvents

## Connections
### RemoteEvents
| Remote | Direction | Other script |
|--------|-----------|-------------|
| `QuestCompleteEvent` | → Client | [[QuestToastClient]] shows the QuestCompleteNotification panel; payload `{ title, objective, goal }` |
| `QuestStateUpdated` | → Client | **No consumer.** DailyQuestClient was its only listener and was deleted with the in-match DAILY OBJECTIVES panel on 2026-07-30; QuestService still fires it |

### RemoteFunctions
| Remote | Direction | Other script |
|--------|-----------|-------------|
| `QuestStateRequest` | ← Client | **No caller.** Same removal; the RemoteFunction is still created and still has an `OnServerInvoke` handler |

### BindableEvents
None

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[DataService]] | `getPlayerData()` | Read and write quest progress in the player's profile |
| [[QuestConfig]] | `questById`, `selectForCycle()`, `cycleIndex()`, counts, reset intervals | Quest definitions, deterministic assignment, and cycle maths |

## Hook points
All gameplay events now arrive through [[QuestEvents]] `track()`, which fans out to this module and to [[BattlePassService]]:

| Caller | Events tracked |
|--------|----------------|
| [[ProgressionService]] | `kill`, `assist`, `roundComplete`, `becomeBounty` |
| [[BountyService]] | `bountyClaim`, `bountyTime` |
| [[RoundStatsService]] | `damage`, `headshot`, `killStreak5`, `ultimateKill` |
| [[RoundController]] | `win`, `podium`, `hunterVariety` |
| [[HighNoonModule]], [[StarfallSightModule]], [[LastCallModule]], [[CardsServer]] | `ultimateUse` |
