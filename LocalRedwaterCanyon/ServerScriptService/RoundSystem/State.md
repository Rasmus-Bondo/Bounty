---
tags:
  - server
  - modulescript
path: game.ServerScriptService.RoundSystem.State
type: ModuleScript
lines: 17
---

# State

Shared mutable round state table used by all round system modules.

## What it does

1. Tracks whether the round is active (`roundActive`)
2. Tracks current round phase (`roundPhase`: Waiting/Countdown/Fight/Ended)
3. Stores per-player kill and death counts for the current round
4. Stores per-player kill streaks (`playerStreaks`) and active bounties with timestamps (`playerBounties`)
5. Carries the resolved gamemode as two fields: `gamemode` (the id, written once by MatchDirectoryService at boot and reassigned by a mid-server mode switch, never back to nil) and `gamemodeRules` (the rules module itself, set by RoundController once the id lands). Sharing the module here is what lets SpawnService and BotService consult `ResolveSpawn` and `DesiredBots` without a RoundController dependency, and what DamageGate reads on every damage call.
6. Provides `reset()` to clear all state between rounds
7. Carries `tutorialMode` (tri-state: nil = unresolved, false = normal, true = tutorial server), resolved once at boot by MatchDirectoryService and deliberately NOT cleared by `reset()` — a tutorial server stays one for life. Read by RoundController, ZoneService, BountyService, QuestEvents, BattlePassService, DataService and TutorialDirector

## Dependencies

- **Requires:** Nothing
- **Required by:** Domination, BotBrain (lazy, for the objective patrol hook), RoundController, ZoneService, BountyService

## Connections

### Direct require()

None - this is a shared state table.
