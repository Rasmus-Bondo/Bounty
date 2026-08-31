---
tags: [server, modulescript, quests]
path: game.ServerScriptService.PlayerServices.QuestEvents
type: ModuleScript
lines: 139
---

# QuestEvents

Single fan-out point for every trackable quest event — reports once to both the daily engine and the battle-pass weeklies.

## What it does
1. `track(player, eventType, amount)` forwards one event to **both** [[QuestService]] `trackEvent` (daily bucket) and [[BattlePassService]] `trackQuest` (season weeklies). Before this module each hook site had to remember both engines and several did not: `awardKill` called both, `awardAssist` called only BattlePassService, `claimBounty` called only QuestService — and the failure mode is silent, since a quest whose type only one engine tracks simply never progresses
2. Resolves both engines **lazily** and caches them, so requiring this module at load time closes no require cycle. An engine that fails to load caches `false` instead of retrying on every kill
3. Wraps both calls in `pcall` — neither quest engine is allowed to throw into a gameplay path
4. Rejects non-`Player` subjects. Several stat entry points accept a bot participant id as well as a Player, and bots own no profile
4a. **Tutorial guard:** `track` early-returns while `State.tutorialMode` — one line that covers every quest emission from the tutorial's kills and bounty claim (design 4.1). BattlePassService additionally guards its own `trackQuest`/`awardSource` doors for the one direct call (`onBountyTakenDown`) that bypasses this module
5. `noteUltimateUsed(player)` records the `ultimateUse` event **and** stamps the ultimate-kill window, so the four hunter activation sites only need to know one function
6. `isUltimateKill(player)` answers whether a kill right now counts as an ultimate kill: true while the `UltimateActive` attribute is set, or within `ULTIMATE_KILL_WINDOW` (10s) of activation
7. `reset()` clears all windows; called from RoundController at round start so a window opened in the dying seconds of one round cannot credit the first kill of the next
8. Timestamps live in a server-side table, deliberately **not** a Player attribute — as an attribute they would replicate to every client and hand out "enemy X ulted 2s ago"

## Why the ultimate-kill window is a time window
A strict "damage whose SourceType was Ultimate" rule is uncompletable on half the roster:
- **Dust** (High Noon) and **Vesper** (Starfall Sight) do deal Ultimate-sourced damage
- **Bram** (Last Call) is a self-buff dealing no damage of its own — you shoot normally through it, so the buff window *is* the ultimate
- **Fortuna**'s ult is a vanish. It deals no damage at all and CardsServer blocks her basic and Ability1 throws for its whole duration, so she cannot land a hit while it is active — every kill it earns lands *after* it

The cost is looseness (an unrelated kill 8s after a whiffed High Noon still counts). That is the right trade for a quest: being generous costs nothing, being uncompletable on the hunter you main is what players notice.

## Dependencies
- **Requires:** [[State]], [[QuestService]], [[BattlePassService]] (the engines lazily, inside functions)
- **Required by:** ProgressionService, BountyService, RoundStatsService, RoundController, HighNoonModule, StarfallSightModule, LastCallModule, CardsServer

## Connections
### RemoteEvents
None

### BindableEvents
None

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[QuestService]] | `trackEvent()` | Forward the event to the daily quest bucket |
| [[BattlePassService]] | `trackQuest()` | Forward the same event to the season's weekly quests |

## Adding a new trackable event
1. `QuestEvents.track(player, "<type>", n)` at the gameplay hook point
2. An entry with that `type` in `QuestConfig.QUESTS` and/or `BattlePassConfig.WEEKS`
3. A `QUEST_TITLE` entry in Bounty's QuestClient so the card gets a category label

An unknown type is a harmless no-op in both engines, so step 1 can land before step 2.
