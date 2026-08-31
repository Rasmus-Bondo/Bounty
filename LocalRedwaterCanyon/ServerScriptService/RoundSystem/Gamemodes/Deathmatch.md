---
tags:
  - server
  - modulescript
  - gamemode
  - rules
path: game.ServerScriptService.RoundSystem.Gamemodes.Deathmatch
type: ModuleScript
lines: 98
---

# Deathmatch

Free-for-all rules — the gamemode-varying decisions extracted from RoundController, unchanged from
the FFA behaviour it had inline before the gamemode axis existed.

## What it does
Declares `Id = "deathmatch"`, `TeamCount = 0`, `UsesZone = true`, then implements the nine hooks
RoundController calls at the points where modes differ:

1. `Init(ctx)` — nothing. Runs once at boot after the mode resolves.
2. `PrepareRound(ctx)` — nothing.
3. `ResolveSpawn(player)` — returns nil, which falls through to SpawnService's normal shuffled safe
   pool. That is the whole FFA answer.
4. `OnDeath(victimCharacter, killerPlayer, killerBotId)` — nothing. FFA has no mode-level scoring.
5. `GetOutcome()` — highest kill count wins. Players are scanned first and the best bot takes over
   only on **strictly** more kills, so a bot tied with a player never claims the win line. Returns
   `{ kind = "player", player, kills }` or `{ kind = "draw" }`.
6. `DecorateVictoryPayload(payload)` — returns it unchanged; FFA adds no fields.
7. `CanDamage(attacker, victim)` — always true. One function call per damage site, no behaviour
   change.
8. `DesiredBots(humanCount)` — nil, so BotService keeps its own `MinBots` / `DesiredRoundParticipants`
   logic exactly as before the axis existed.
9. `EndRound()` — nothing.

RoundController owns the round loop, payouts, analytics, retirement, late-join handling and the
teleport paths; only these nine points vary by mode. A new gamemode is a sibling module with the
same interface plus a row in the gamemode registry, and its id in `MapConfig.Gamemodes` for every
map that may run it. RoundController matches the resolved mode id against each sibling's `.Id`, so
the script name and the wire id stay independently renameable.

## Dependencies
- **Requires:** [[State]], [[BotService]] (lazy, behind a local function — BotService pulls in a
  large tree at load and this module must be require-safe from RoundController's boot path)
- **Required by:** RoundController, which requires every ModuleScript in this folder while looking
  for the one whose `.Id` matches the resolved mode

## Connections
### RemoteEvents
None

### BindableEvents
None

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[State]] | `State.playerKills` | Scan kill counts for the winner |
| [[BotService]] | `GetBestBot()` | The best bot's kill count, to compare against the best player |
