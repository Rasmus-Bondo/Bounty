---
tags: [server, modulescript]
path: game.ServerScriptService.Bots.BotConfig
type: ModuleScript
lines: 445
---

# BotConfig

Central configuration table for all arena bot behaviour: toggles, counts, timing, per-hunter stats, difficulty tiers, and pathfinding agent parameters.

## What it does
1. Exposes a single `BotConfig` table consumed by every other Bot module; setting `Enabled = false` disables bots game-wide.
1a. **Population counts**: `DesiredRoundParticipants` (10 — target total fighters, players + bots), `MaxBots` (8 — ceiling) and `MinBots` (4 — floor). `MinBots` is a floor at *every* player count, not a fallback: the bots are deliberately weak, so it guarantees every player, especially a new one on a phone, always has something they can reliably kill. It is a skill-floor guarantee rather than an empty-server one, which is why it does not taper as population grows. It replaced `MinRealPlayersBeforeNoBots = 8`, which zeroed bots at 8 players and so made an 8-player match (8 fighters) emptier than a 7-player one (10). With Redwater capped at 10 humans, the arena ceiling is 14 fighters.
2. Defines five difficulty presets (`Training`, `Easy`, `Casual`, `Normal`, `Hard`; `BotDifficulty` defaults to `Casual` since 2026-10-04, and the tutorial pins Easy/Training per bot) with reaction time, aim error, attack range, ability usage chance, movement aggression, fire-rate multiplier, and — since 2026-08-08 — `DamageMultiplier`.

2b. **`DamageMultiplier`, and why `Training` exists.** The three original tiers differ only in how *often* a bot lands a shot; none of them changed what a landed shot cost, and that is the gap `Training` closes. A player rig carries `Humanoid.MaxHealth` **100** — nothing overrides the authored value for players, unlike bots, whose `BotController` raises to their `HunterBehavior` figure (Dust/Fortuna 150, Vesper 125, Bram 225) — while Vesper's headshot is 125 and Bram's near headshot is 100. **At `Easy`, either of them one-shots a full-health player**, and no amount of aim error changes the shot that does land. `Training` therefore carries `DamageMultiplier = 0.35`, chosen against that 100: Vesper's headshot becomes 43.75 and Bram's 35, so nothing in the roster kills in fewer than three hits. Above ~0.53 a Vesper headshot plus a body shot kills again. `Easy`/`Normal`/`Hard` are all `1`, so the multiplier is a no-op outside the tutorial. BotCombat applies it on **every** damage path including ability and ultimate damage — a bot that cannot kill you with its gun but still slams you for full has not been made gentler — and Dust's High Noon needs it especially, since that ultimate passes a percentage of the victim's MaxHealth as a true execute that would otherwise ignore every other lever.
3. Stores per-hunter `HunterBehavior` entries (health, speed, desired combat range, default character path, default weapon skin) for Dust, Fortuna, Vesper, and Bram.
4. Configures weighted hunter selection (`HunterWeights`), per-hunter round ceilings (`HunterCaps`), and a pool of western-themed bot display names.
5. Sets pathfinding agent parameters (`PathAgent`), stuck-recovery thresholds, Fortuna dash lane sampling values, and Vesper sniper-perch reservation radii.
5a. **`PathAgent` fallback rules.** `AgentCanJump` is `false` for every hunter, so two exceptions cover the routes that need a jump link and are not jumps: `AllowSafeDropPaths` with `SafeDropMinimumHeight` / `SafeDropMaximumHeight` / `SafeDropMaximumHorizontalGap` (walking off a ledge), and — added 2026-08-15 — `AllowSteppedRoutes` with `SteppedRouteMaxStepUp` (3) / `SteppedRouteMaxStepDown` (6) / `SteppedRouteMaxHorizontalGap` (8), which accepts a route whose links are all small steps. The step bounds are sized off the map: across the 86 measured routes down a rock the worst step-up was 2.3 studs and the worst step-down 4.2.

5b. **One capsule for the whole roster** (2026-08-19). `AgentRadius`/`AgentHeight` are `2.55`/`6.4` — Bram's dimensions — and **no hunter overrides them any more**. Roblox builds a separate navigation mesh per distinct radius/height pair, lazily, on the first route request, and each build measured ~10s on Redwater; Bram's old per-hunter override therefore meant two meshes and ~20s of building, landing on the first round because that is when the fleet first asks for routes. Unified **up** rather than down: shrinking Bram to 2.2/5.5 brings back the wedging his override existed to stop, whereas the lighter hunters only route a little more conservatively around gaps they could technically squeeze through. Adding a per-hunter `PathAgent` with different dimensions re-introduces the second build — BotPathing's warm-up reads `HunterBehavior` and will warm it rather than regress silently, but it costs another ~10s of boot.

5c. **Objective-mode engagement** (2026-08-22): `ObjectiveEngageRange` (65), `ObjectiveCloseThreatRange`
(20), `ObjectiveThreatLock` (2 s — how long a bot keeps the enemy it decided to shoot before the
three-nearest roll may take it back) and `ObjectiveFightStrafeInterval` (2 s — the pad mill cadence
while trading shots, against `PatrolRetargetInterval` idle), all read by BotBrain's
`_objectiveDecision` / `_patrolObjective`. In Domination a bot on its pad holds it and fights from it;
a bot on the way breaks off only for an enemy inside the close-threat range (seen or not) or visible
inside the engage range. No effect in FFA or TDM.

6. **Vesper perch tuning**: `SniperPerchHoldDuration` is the base lease (11s, down from a flat 30s camp), with `SniperPerchMinHold` as an arrival grace and `SniperPanicRadius` / `SniperEvictionDamageRatio` / `SniperBlindTimeout` as the early-exit triggers BotBrain evaluates. `SniperEscapeCooldown` gates escape hooks separately from the ability cooldown. `SniperPeekRadius` (2) must stay well inside the flat ring `resolvePerchPad` validates (3 studs) or the perch shuffle walks her off the ledge; it governs idle fidget between shots only, since she stands still whenever she has a shot, so raising it to make her harder to hit just reads as jitter. `SniperRotationDuration` is how long an evicted Vesper commits to crossing the map on foot. `SniperFleeChance` / `SniperFightBackDuration` govern the fight-or-flight choice when she is jumped at close range, and `SniperCloseTargetLock` is how long a close opponent overrides target commitment.
7. **Fortuna jump tuning** (`FortunaJump`): the only bot jump in the game. `PathAgent.AgentCanJump` stays `false` for everyone including her — ordinary jump waypoints made target-facing bots moonwalk diagonally into the air — so this is an authored ability with its own `IsJumping` flag rather than a loosening of the shared guards. `FirstJumpPower` (50), `DoubleJumpPower` (48) and `AirtimeGravityMultiplier` (0.72) are copied from the authored player values so a bot's arc matches a real Fortuna's: ~8.9 studs on the first jump, ~8.2 more from the second. `SingleJumpRise` is what makes the second jump conditional — anything under it is cleared on one impulse, and only ~17% of the map's usable pads need both. `MinRise` is **4, not 2**: sweeping the canyon, 91% of unobstructed "step-ups" are under 3 studs of ordinary terrain undulation, so a lower bar spends her jump on bumps she would walk over anyway. It governs the jump-*onto* case only; a hop *over* a fence onto level ground qualifies through the obstruction test instead and can have a rise of zero. The three cooldowns are deliberately long because she cannot dodge while committed, and they share one `Jump` key so every trigger draws on the same budget. `ProactiveJumpInterval` is how often she *looks* for something to hop — it exists because the first build hung the traversal jump off blocked-route recovery and measured at **zero** firings: across 35 cross-canyon routes the pathfinder never failed once, it just quietly walked the long way around. Probing forward on a timer instead lands at roughly one traversal jump per 5s of walking, and self-regulates, since open canyon has no obstruction to find.
7b. **`HoldFire`** (added 2026-08-08, default `false`): the blanket peaceful-bot switch, sitting next to `BotDifficulty` because that is where someone tuning bots for a test looks. With it true every bot walks, paths, chases, takes damage and accrues ultimate charge as normal but never fires and never uses an ability — BotCombat vetoes `FireAt` and `ThinkAbility` on the `BotHoldFire` model attribute, which BotService stamps at spawn from this key **or** the per-bot `record.HoldFire` the onboarding tutorial sets. It is read at spawn rather than per shot, so flipping it mid-round takes effect as bots respawn; `BotService.SetHoldFire` is the immediate per-bot path. Named `HoldFire` and not `Passive` because `"Passive"` is already the HunterMovement base-speed layer key BotController uses for every bot's WalkSpeed, and this flag deliberately leaves movement alone.

7c. **`StandDown`** (added 2026-08-08, default `false`): the stronger peaceful state, sitting next to `HoldFire`. Bots stand exactly where they spawned, never path, never turn to face anyone and never acquire a target — live, damageable training dummies. Implies `HoldFire`, so it is sufficient on its own. BotBrain implements it (`_enterStandDown`, an early return above `Pathing:Update` plus a zero-speed HunterMovement root); BotService stamps the `BotStandDown` attribute at spawn from this key or the per-bot `record.StandDown`. The two states exist separately because the onboarding tutorial needs both: its first steps want a motionless target so nothing competes with the instruction on screen, while its later steps need a bot that walks, or the player never learns to lead a target.
8. Provides `BotConfig.GetDifficulty()` helper that resolves the active difficulty table.
9. **`HunterCaps`**: a hard per-round ceiling per hunter, applied by BotService on top of `HunterWeights` — a hunter at its cap is dropped from the draw entirely, including the zero-weight fallback path. `Vesper = 2`, because a lobby stacked with snipers is not fun to play against. Hunters absent from the table are uncapped. The cap counts live records, which survive death and respawn, so it holds for the whole round rather than per spawn.

## Team modes and the 2026-08-18 density pass

`DesiredRoundParticipants` is 14 (`MaxBots` 13, `MinBots` 4) -- the owner's "more fighters per
game" pass. The number is only meaningful if the Creator Hub **Maximum Visitor Count** is raised to
match on both match places; the seats above the old cap are otherwise fiction.

`HunterCaps` caps a hunter's copies in one match (`Vesper = 2`, the sniper-wall guard). In a team
mode the cap is judged per side rather than per arena, so one team rolling its Vespers early cannot
lock the other team out of the hunter.

Team modes override `MinBots` entirely: the per-team floor in the rules module replaces the global
one, so each side is filled to its own target rather than the arena to a single number.

Vesper's perch behaviour was retuned in the same pass -- hold shortened, rotation lengthened and the
eviction damage ratio dropped -- so a sniper bot spends most of its time moving rather than camping
one ledge. The three constants are commented in place.

## Dependencies
- **Requires:** Nothing
- **Required by:** BotService, BotController, BotPathing, BotCombat, BotBrain (passed as `config` through the controller), BountyService (reads `HunterBehavior[<hunter>].DefaultCharacter` for a bot's bounty-card portrait)

## Connections
### RemoteEvents
None

### BindableEvents
None

### Direct require()
None
