---
tags:
  - server
  - modulescript
  - gamemode
  - rules
  - teams
  - objective
path: game.ServerScriptService.RoundSystem.Gamemodes.Domination
type: ModuleScript
lines: 800
---

# Domination

Two teams, three capture pads, first to 500 points. The third gamemode and the first objective
mode (DOMINATION_SPEC, built 2026-08-22). Same hook interface as its two siblings plus the two
optional hooks it introduced — `ShouldEndRound` (#10) and `PatrolTarget` (#11) — which are nil on
Deathmatch and TeamDeathmatch, so neither of those moves.

## What it does
Declares `Id = "domination"`, `TeamCount = 2`, `UsesZone = false`, `UsesCapturePoints = true` (read by
RoundController, which parks the pads and beams through CapturePointService in every other mode and
restores them before `Init` — nil on the two siblings), and:

1. `Init(ctx)` — hands the context to TeamDeathmatch (party-aware arrivals), then resolves the three
   pads once: workspace-root Models named `<MapConfig.Instances.CapturePoints>*` carrying a `Letter`
   attribute (A/B/C — the attribute is the contract, never the name or Explorer order). The capture
   volume is derived: flat radius = half the model's larger footprint side, height band from the
   largest-footprint part's top surface up by `Config.DOMINATION_CAPTURE_HEIGHT`. Pairs each pad with
   its nearest unclaimed `<prefix>Beam` part, stamps `Letter` on it (runtime only) and warns past 30
   studs.
2. `PrepareRound(ctx)` — TeamDeathmatch's PrepareRound (fresh teams, spawn slots, zeroed scores),
   every pad back to neutral (nobody starts owning a home pad), zeroed fractional carry, then starts
   the accrual loop, which waits for `State.roundActive` and ticks every
   `Config.DOMINATION_TICK_INTERVAL` until the round ends.
3. Each tick: counts live fighters (players **and** `workspace.ArenaBots` rigs, `IsAlive` — never a bare
   `Health > 0`) per pad per team, steps each pad's **signed meter** (-1 red … 0 neutral … +1 blue):
   one team present pushes it at `1 / DOMINATION_HALF_TIME_BY_ALLIES[clamp(n)]` per second, both
   present **freezes** it, an empty pad drifts back toward its owner's endpoint at
   `DOMINATION_DECAY_MULTIPLIER` × the solo rate. Ownership is the endpoint: a pad pays only while
   its meter sits at ±1. Crossing 0 from the owner's side is a **neutralise**, landing on an
   endpoint is a **capture**; both pay every ally player on the pad via
   `ProgressionService.awardObjective` **and report `neutralise` / `capture` to [[QuestEvents]] off the
   same occupant list** (2026-08-27), so the quest means exactly what the XP means — you were
   standing on the pad when the meter landed — rather than becoming a second, subtly different
   definition. Bots are excluded by construction, since the occupant lists hold players only. Then accrues
   `held × DOMINATION_POINTS_PER_SECOND_PER_POINT + DOMINATION_PASSIVE_POINTS_PER_SECOND` per second
   per team into a fractional carry and hands `TeamService.AddScore` whole points only.
4. Publishes per pad, on change only, as workspace attributes keyed by letter: `DomOwner_A`
   (`red`/`blue`/`""`), `DomMeter_A` (signed, 0.05 steps), `DomCapturing_A`, `DomContested_A`,
   `DomRate_A` (meter units/s), `DomVelocity_A` (signed, what the meter is ACTUALLY doing this
   instant — added 2026-08-23, and unlike `DomRate_A` it covers the decay leg and is zero on
   arrival, so the HUD can integrate it rather than draw the quantised meter); and `DomPad` on
   each Player (the letter they stand on, `""` off-pad). No colour is written — the client paints
   pads relative to the viewer.
5. `ResolveSpawn` / `resolveSpawnForTeam` / `GetOutcome` / `DecorateVictoryPayload` / `CanDamage` /
   `DesiredBots` — TeamDeathmatch's own functions, assigned directly.
6. `OnDeath(victim, killerPlayer, killerBotId)` — kills do not move the team score. A human killer
   whose enemy died inside a pad the killer's team owns earns the pad-defence bonus on top of the
   normal kill pay.
7. `EndRound()` — stops the accrual loop (token bump), zeroes scores via TeamDeathmatch, removes the
   `Dom*` attributes and the `DomPad` stamps so the next mode inherits nothing.
8. `ShouldEndRound()` — true once either score reaches the GamemodeConfig row's `scoreLimit`.
   RoundController polls it in the fight loop (mode hook #10).
9. `PatrolTarget(botModel)` — where a bot should go, asked every brain tick (BotBrain lets the
   objective own a bot's feet unless its target is an immediate threat — a team-mode bot is never
   idle, so an idle-only hook never fired). Tiers: a contested pad (or an own pad being drained),
   then a neutral one, then an enemy-held one, then the own-held pad nearest the enemy base.
   Within a tier the **emptiest** pad wins and distance is only the tie-break, under a cap that is
   the **even split** of this side's bots over the pads (`DOMINATION_BOTS_PER_PAD` is now just its
   ceiling). A bot keeps its pad unless a strictly better tier appears **or** the cap no longer has
   room for it, so a clump left by a tier change unwinds. Returns the pad's floor-level centre, its
   radius, and a **hold slot** — the lowest index free on that pad, which BotBrain turns into a
   side of the pad to stand on (mode hook #11).

## Dependencies
- **Requires:** [[Config]], [[State]], [[TeamService]], [[TeamBaseService]], [[TeamDeathmatch]],
  [[MapConfig]], [[TeamAffinity]], [[HunterCharacterUtil]], [[ProgressionService]], [[QuestEvents]] (the
  last two lazy, at reward time — both live under PlayerServices, which the bootstrap starts after
  the round system)
- **Required by:** RoundController, which requires every ModuleScript in this folder while looking
  for the one whose `.Id` matches the resolved mode; BotService and BotBrain reach it through
  `State.gamemodeRules` rather than a require

## Connections
### RemoteEvents
None

### BindableEvents
None

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[TeamDeathmatch]] | `Init`, `PrepareRound`, `ResolveSpawn`, `resolveSpawnForTeam`, `GetOutcome`, `DecorateVictoryPayload`, `CanDamage`, `DesiredBots`, `EndRound` | Everything TeamCount = 2 buys — teams, houses, friendly fire, bot fill, banner, draw rule |
| [[TeamService]] | `AddScore()`, `GetScores()` | Integer score publish; the score-limit test |
| [[TeamBaseService]] | `baseFor(team)` | The enemy spawn house's position, for the bot tier-4 ranking |
| [[TeamAffinity]] | `teamOf()` | Which side each fighter on a pad is on |
| [[HunterCharacterUtil]] | `IsAlive(humanoid)` | Dead bodies never hold a pad |
| [[MapConfig]] | `Instances.CapturePoints` | The pad / beam name prefix for this map |
| [[Config]] | `DOMINATION_*` | All tuning |
| [[State]] | `roundActive` | The accrual loop's gate and the bot hook's gate |
| [[ProgressionService]] | `awardObjective(player, kind, xp, cash)` | Capture / neutralise / defend rewards |
| [[QuestEvents]] | `track()` | `capture` / `neutralise` quest progress, fired from `payOccupants` beside the reward |
