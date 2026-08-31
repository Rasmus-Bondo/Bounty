---
tags:
  - server
  - modulescript
  - gamemode
  - rules
  - teams
path: game.ServerScriptService.RoundSystem.Gamemodes.TeamDeathmatch
type: ModuleScript
lines: 539
---

# TeamDeathmatch

7v7, six minutes, most enemy kills wins. Same nine-hook interface as its Deathmatch sibling, so
RoundController stays mode-agnostic.

## What it does
Declares `Id = "tdm"`, `TeamCount = 2`, `UsesZone = false`, and:

1. `Init(ctx)` / `PrepareRound(ctx)` — stores RoundController's `{ row, groupIdOf, friendTargetOf }`
   context. Prepare
   clears the per-round spawn slots and calls team assignment for everyone present. Both also kick
   the once-per-server spawn-marker reachability probe (see Spawning).
2. `ResolveSpawn(player)` — the team's spawn house, every spawn and respawn, for the whole match. It is also
   the lazy assignment point for a mid-round arrival: the first spawn is the first moment a team is
   needed. `preferredTeamFor` answers it in priority order — a seated party-mate's team, absolute
   and whatever the balance (parties are never split), then **the friend this player pressed Join on
   in the lobby** if that side still has room. Room is `MAX_TEAM_HUMANS`, `TEAM_SIZE` plus
   `Config.FRIEND_SLOTS` (9), which is the same worst case the twelve spawn markers were sized for.
   Until the friend rule existed a friend join was indistinguishable from any other arrival and took
   the smaller side — i.e. the enemy of the friend it was aimed at, about half the time.
3. `OnDeath(...)` — the only mode scoring point. A kill scores when the killer's team differs from
   the victim's, so suicides, environment deaths and friendly incidents score nothing. The killer's
   team comes from the attribute for a player and from the bot record for a bot, because a dying
   victim's rig carries only the killer's bot id.
4. `GetOutcome()` — most enemy kills at the buzzer, with a `statusLine` of the form
   `"Red team wins 24-19!"`. Equal is a **draw**: no sudden death, no tiebreaker, podium and payouts
   run exactly as for a win.
5. `DecorateVictoryPayload(payload)` — adds `teamOutcome = { kind, team, red, blue }`. The podium
   itself is untouched and still ranks every fighter by kills across both teams.
6. `CanDamage(attacker, victim)` — nothing crosses teams. Self-damage is never gated, because that
   is a hunter design question rather than a team one.
7. `DesiredBots()` — `max(2, TEAM_SIZE - humans)` per side, overriding `BotConfig.MinBots` entirely
   in this mode. `TEAM_SIZE` is 7.
8. `EndRound()` — zeroes the scores for the intermission HUD; the summary banner already captured
   its copy in `DecorateVictoryPayload`. Team stamps persist through the summary and reset at the
   top of the next round.

## Spawning
`resolveForTeam(team, key)` asks `TeamBaseService.baseFor(team)` for the side's spawn house, then:

- **Authored markers only.** `<base>.Points` holding BaseParts, ordered by a numeric name compare so
  `Point10` follows `Point9` — Explorer child order is not stable. The marker's authored rotation
  **is** the spawn facing. Twelve markers per house cover the worst case a side can hold at the
  14-fighter cap, because slot assignment wraps modulo the folder and two fighters sharing a marker
  at round start is a physics pop.
- **No markers returns nil,** which drops that side to SpawnService's FFA pool and warns once per
  team. The `RedTeamSpawn` / `BlueTeamSpawn` placeholder slabs were deleted with the houses' arrival,
  so there is no longer a slab to scatter across — and guessing a position inside a house would spawn
  people inside walls. Scattered across the map is wrong, but it is safe ground.
- Slots are stable per fighter and unique per team, so round-start placement and any retry land the
  same spot and simultaneous spawns cannot stack. Both paths add the same +4 stud lift the FFA spawn
  path uses; never pivot a rig exactly onto the floor, because the foot offset differs per hunter.
- **Markers are ordered by bot reachability (2026-08-23).** Once per server, a background probe runs
  one `PathfindingService:ComputeAsync` from each marker — with `BotConfig.PathAgent`'s capsule and
  the same +4 lift — to a ground point twenty studs outside the house, and reorders the folder so
  the markers a bot can actually leave come first. It waits for the house to be unparked and for
  `BotPathing.IsNavigationReady()`, warns which markers failed, and keeps the authored order when
  nothing at all is reachable. **Bots draw from the reachable end and players from the far end**,
  wrapping bots modulo the reachable count rather than the whole folder. Until the probe lands,
  spawning uses the authored order.

## Spawn slot allocation

`slotFor(team, key, markerCount, forBot)` splits the folder between the two kinds of fighter: bots
count up from index 1, players count down from the last index. Both sides of the split are stable
per fighter for the round. A bot key is the string `"bot:<id>"` that BotService passes; a player key
is the Player instance.

`resolveSpawnForTeam` is exposed on the module so the bot spawn path can call it with a bot id.
BotService reaches it through `State.gamemodeRules` rather than requiring this module.

## Reused by Domination (2026-08-22)

Gamemodes.Domination requires this module and assigns `ResolveSpawn`, `resolveSpawnForTeam`,
`GetOutcome`, `DecorateVictoryPayload`, `CanDamage` and `DesiredBots` directly, and calls `Init`,
`PrepareRound` and `EndRound` from its own hooks — so a change to any of those here changes
Domination too. `OnDeath` is the one hook Domination does not reuse (kills do not score there).

## Dependencies
- **Requires:** [[Config]], [[TeamBaseService]], [[TeamAffinity]], [[TeamService]], [[BotService]],
  [[BotConfig]], [[BotPathing]] (the last three lazy, for the same load-order reason as the
  Deathmatch sibling)
- **Required by:** Domination (delegation, see above); RoundController, which requires every ModuleScript in this folder while looking
  for the one whose `.Id` matches the resolved mode

## Connections
### RemoteEvents
None

### BindableEvents
None

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[Config]] | `FRIEND_SLOTS` | The two friend seats, which set how far a friend join may push one side |
| [[TeamBaseService]] | `baseFor(team)` | The side's spawn house, whose `Points` folder holds the spawn markers |
| [[TeamAffinity]] | `teamOf()`, `areAllies()` | Scoring side and the friendly-fire answer |
| [[TeamService]] | `AssignAll()`, `AssignArrival()`, `teamOf()`, `AddScore()`, `GetScores()`, `ZeroScores()`, `CountHumans()` | All team membership and score state |
| [[BotService]] | `GetBotTeam()` | The killer bot's side, for the scoring hook |
| [[BotConfig]] | `PathAgent` | The bot path capsule the spawn-marker reachability probe measures with |
| [[BotPathing]] | `IsNavigationReady()` | Holds the probe until the navigation mesh has finished building |
