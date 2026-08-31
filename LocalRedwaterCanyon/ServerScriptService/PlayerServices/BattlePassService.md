---
tags: [server, modulescript, battlepass]
path: game.ServerScriptService.PlayerServices.BattlePassService
type: ModuleScript
lines: 217
---

# BattlePassService

Redwater-side battle-pass server. **Earns** BP XP and tracks weekly quests during gameplay, writing to the shared profile (ProfileService auto-saves; the Bounty lobby reads it and owns the reward-track claim UI). Weekly quests **complete** here but never pay out here — their XP is claimed by hand in the lobby. Also runs the Dead Man's Hand per-life tracker. The `ensureData` guard + season-rollover logic is mirrored from Bounty's BattlePassService — keep the two in sync. All BP amounts and quest logic live here so the hook points in other scripts stay to a single semantic call each.

## What it does
1. `ensureData(data)` — idempotent guard: initializes `Tokens`/`Boosts`/`Cosmetics` and the `BattlePass` sub-table, and on a `SEASON_ID` change forfeits unclaimed rewards and resets xp/claimed/quests/ownsFullPass while KEEPING the token wallet + cosmetics. Runs on join (once the profile loads) and on every earn entry point. Also carries the one-time **manual-claim migration** (`bp.questClaimMigrated`): quests completed under the old auto-grant rule already paid their XP, so they are stamped `claimed = true` once — without it every historic completion would show up as claimable and pay twice. Mirrored verbatim in Bounty's copy
1b. `ensureData` also carries the **quest-progress reset lever**: if `bp.questProgressToken ~= Config.QUEST_PROGRESS_TOKEN` it clears `bp.quests` and stamps the new token, once per token value per profile. This wipes weekly quest progress and nothing else — `bp.xp`, `level`, `ownsFullPass` and the reward-track claims all survive, which is what makes it safe to pull mid-season when a quest's goal or label changes. The alternative, a `SEASON_ID` bump, would take the entire pass down with it. Mirrored verbatim in Bounty's copy
2. `awardSource(player, name)` (internal) adds `Config.XP_SOURCES[name]` BP XP and recomputes level
3. `trackQuest(player, eventType, amount)` — iterates every currently-unlocked week's quests whose `type` matches; increments progress, and on completion marks `completed = true` / `claimed = false` and fires `QuestCompleteEvent` with a `{ title, objective, goal }` payload titled `WEEK <n> QUEST` (reusing the daily/weekly quest notification pipeline). It **does not grant the quest's XP** — that waits until the player claims it in the lobby Quests menu (Bounty's `ClaimBattlePassQuestEvent`)
4. Semantic gameplay hooks, each called from one place: `onKill` (kill XP + DMH kill count if a bounty), `onAssist`, `onRoundComplete`, `onBountyClaim`, `onBecomeBounty` (+ starts a fresh DMH life). These award BP XP **only** — they no longer call `trackQuest` for their own event, because the same call sites now report through QuestEvents, which fans out to this module's `trackQuest` *and* to the daily engine. Putting a `trackQuest` back into one of these would double-count every weekly quest
5. `onBountyTakenDown` calls `trackQuest` directly rather than going through QuestEvents — `deadMansHand` is raised from inside this module and exists only in [[BattlePassConfig]], so the daily engine has nothing to match
6. **Dead Man's Hand**: counts kills scored while `State.playerBounties[player]` is set; `onBountyTakenDown(player)` (called from [[BountyService]] `registerDeath` when a bounty holder dies) credits the `deadMansHand` quest if that life scored ≥ 2 kills, then clears the counter
7. No claim handling or state streaming here — both the reward track *and* the weekly quests are claimed in the Bounty lobby; this place only writes progress to the shared profile
8. **Tutorial guards (design 4.1):** `awardSource` and `trackQuest` both early-return while `State.tutorialMode`, so no battle-pass XP or weekly-quest progress is written from tutorial kills or the bounty claim. Guarding these two chokepoints covers every `on*` entry point at once, including `onBountyTakenDown`'s direct `trackQuest` call that bypasses QuestEvents

## Dependencies
- **Requires:** [[DataService]], [[BattlePassConfig]], [[State]]
- **Required by:** Main, ProgressionService (calls the on* hooks), BountyService (calls `onBountyTakenDown`), QuestEvents (calls `trackQuest`)

## Connections
### RemoteEvents
| Remote | Direction | Other script |
|--------|-----------|-------------|
| `QuestCompleteEvent` | → Client | [[QuestToastClient]] shows the QuestCompleteNotification panel when a BP weekly quest completes |

### BindableEvents
None

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[DataService]] | `getPlayerData()` | Read/write BP progress on the player's profile |
| [[BattlePassConfig]] | `WEEKS`, `REWARDS`, `XP_SOURCES`, `levelFromXP()`, `currentWeek()` | XP amounts, quest definitions, level and week math |
| [[State]] | `State.playerBounties` | Detect whether a killer is currently a bounty (Dead Man's Hand) |

## Hook points
| Caller | Call |
|--------|------|
| [[ProgressionService]] `awardKill` | `onKill` |
| [[ProgressionService]] `awardAssist` | `onAssist` |
| [[ProgressionService]] `awardRoundCompletion` | `onRoundComplete` |
| [[ProgressionService]] `awardBountyKill` | `onBountyClaim` |
| [[ProgressionService]] `notifyBountyPlaced` | `onBecomeBounty` |
| [[BountyService]] `registerDeath` (had bounty) | `onBountyTakenDown` |
