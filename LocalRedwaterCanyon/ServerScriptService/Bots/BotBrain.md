---
tags: [server, modulescript]
path: game.ServerScriptService.Bots.BotBrain
type: ModuleScript
lines: 1368
---

# BotBrain

Low-frequency state machine that drives bot decision-making: target acquisition, fighting/repositioning, health seeking, and patrol.

## What it does
1. OOP module (`BotBrain.new`); one instance per bot, ticked on `BrainTickInterval` by the controller.
2. **Target scanning** (`_scanTarget`): collects alive players and other bots within `DetectionRange`; usually picks the nearest but randomly selects from the three closest to distribute bots across targets rather than focusing a lone player. Note this means it **does not pick the closest opponent about 45% of the time**, and `committed` then holds that choice for `TargetCommitDuration`, lapsing only past `DetectionRange`. **`BotTargetPlayersOnly`** (added 2026-08-09, stamped by BotService from `SpawnBot { TargetPlayersOnly = true }`) makes `_targetCandidates` skip the ArenaBots pool entirely — a scripted bot fights for one audience, and without it the tutorial's step 6 pair rolled each other as targets and chased off across the rocks instead of menacing the player.

2b. **Stealth is invisible to a bot unless it is told** (2026-08-06). Fortuna's ultimate hides her from *players* by turning her transparent; a bot reads positions, not pixels, so before this every gate treated an invisible Fortuna as an ordinary target — perfect `FacePosition` tracking on her live root, `CanSee` returning true because her parts stay `CanQuery`, and a shot with only `AimErrorDegrees` of scatter (2.4° on Hard). `UltimateUntargetable` existed but had exactly two readers, both of them Dust's High Noon lock-on. The whole model now runs off [[HunterCharacterUtil]]`.IsStealthed`:
    - **`_targetCandidates` excludes stealthed characters**, so she is never newly acquired and never trips Vesper's closest-threat or "Crowded" perch eviction. It deliberately does **not** un-target someone already being fought — `committed` in `_step` holds `self.Target` regardless of this list, which is what lets `_fight` fall back to memory instead of the bot simply forgetting mid-burst that anyone was there.
    - **`_fight` keeps a sight memory** (`TargetLastKnownPosition` / `TargetStealthed`, cleared by `_setTarget` on an actual target change but *not* on a `refreshReaction` re-set of the same target). While the target is stealthed the bot faces, walks toward and fires at the last position it actually saw them. Standing still is therefore still punished and moving is what breaks the lock — the counterplay the ability is meant to sell.
    - **Firing at a memory goes through `FireAt`'s `AimPoint` option**, which moves only the aim; the shot's own raycast is untouched and still resolves whoever is standing on that line. Line of sight is tested with `CanSeePosition` rather than `CanSee`, since the aim point has no character attached for the "hit the target" clause to test against.
    - **Reappearing re-arms `ReactionTime`** by stamping `TargetAcquiredAt`, so the bot has to reacquire rather than snapping onto her the frame the transparency lifts.
    - A stealthed target with nothing remembered makes the bot stand down instead of tracking; only reachable when it was already invisible the first time this bot ever looked at it.
3. **Close-threat override** (`_updateClosestThreat` / `_overrideCloseThreat`, Vesper only): the pool roll plus a 850-stud `DetectionRange` meant a Vesper would keep servicing a target across the canyon while an opponent stood on her perch. Anyone inside `SniperPanicRadius` becomes the target outright and re-asserts `TargetLockedUntil` every tick, so the commit window cannot drag her back mid-brawl. Runs every tick rather than only on scan ticks — someone closing to knife range should not have to wait out `TargetScanInterval`. `_setTarget` is called **only on an actual target change**; calling it every tick would keep resetting `TargetAcquiredAt` and she would never satisfy `ReactionTime` to fire.
4. **Damage response** (`OnDamaged`): resolves the last attacker from `LastDamager` / `LastDamagerBotId` attributes and locks onto them for `DamageTargetLockDuration`; records the threat position for repositioning. **An attacker who is stealthed still gets the damage and the threat position recorded — so retreating and repositioning react normally — but buys no target lock** (2026-08-06). Fortuna's ultimate *opens* with a ring of cards, so without this her own escape tool pointed every bot the ring clipped straight back at her for `DamageTargetLockDuration`: 7 seconds against a 2.1s invisibility window, which is the single biggest reason she felt tracked through the whole ult.
5. **Health seeking** (`_updateHealthState` / `_seekHealth`): when health drops below `SeekHealthBelowPercent`, finds the nearest active health pack via `BotPathing.FindNearestActiveHealthPack` and navigates to it; cancels once health exceeds `StopSeekingHealthAbovePercent` or the pack is gone. Gives Fortuna an explicit defensive dash opportunity toward the pack (the only case that claims the whole tick — `_seekHealth` returns `true`).
6. **Fighting while wounded**: the pack run owns navigation only, mirroring the firewall-escape handling. The bot still scans for targets, faces them, and fires on the way to the pack via `_fight(now, movementOwned)`, so a low-health bot is not a free kill; `movementOwned` suppresses `_combatMovement` and ability thinking so neither can steer it off the pack route.
7. **Combat movement** (`_combatMovement`): takes the target's **position** rather than its root part (changed 2026-08-06), so `_fight` can hand it the remembered position and the bot pushes toward where it *thinks* the target is instead of tracking a body it cannot see. Strafe cadence varies by hunter — Dust uses fast direct `Humanoid:Move` strafing with an obstacle probe ray that reverses direction on obstruction; all others use tactical pathfinding samples around their `DesiredRange`. Retreats when health is below `RetreatHealthThreshold` and recently hit.
8. **Vesper perch hold**: holds position while the bot is within `SniperPerchRadius` of its reserved perch and `BotSniperPerchUntil` is in the future. The hold is a **lease, not a camp** — it was a flat 30s timer with no exit condition, which made her whole behaviour "hook up, freeze, kill or die there" with nothing an opponent could do about it.
9. **Perch eviction** (`_updateVesperPerch` / `_evictVesperPerch`): runs early in `_step` so an eviction lands on the same tick, since clearing the perch attributes is what `_combatMovement` and `_patrol` read to decide she is still holding. `SniperPerchMinHold` grants a grace window so she cannot be evicted on the tick she arrives. Three triggers: **Crowded** (any living body inside `SniperPanicRadius`), **Bleeding** (lost `SniperEvictionDamageRatio` of max health since arriving, and hit recently), **Blind** (no shootable target for `SniperBlindTimeout`). Bleeding publishes `BotEscapeHookFrom`/`BotEscapeHookUntil` for BotCombat to spend, gated by `SniperEscapeCooldown` on top of the ability cooldown so a busy area cannot make her chain escapes. Blind never buys a hook — there is nothing to flee.
10. **Fight or flight when jumped**: Crowded is a *choice*, not automatic flight. Fleeing requires the escape cooldown to be up **and** `BotCombat:HasEscapePerch` to confirm somewhere real to go, so being cornered reliably resolves to standing and fighting; below half health she always flees when she can, otherwise it is a `SniperFleeChance` coin flip. Choosing to fight evicts the perch anyway (so she strafes and shoots back rather than freezing on it), sets no escape intent, and publishes `BotFightBackUntil` — without which `ThinkAbility`'s ordinary `distance < 48` rule would hook her to another perch, which is fleeing by another name.
11. **Perch peek** (`_vesperPeek`): a small shuffle inside the flat ring `resolvePerchPad` validated, so a perched Vesper reads as alive rather than as a statue. **She plants her feet whenever she has a shot** — a player stands still to take aim and charge the scope meter, and a sniper who shuffles constantly is both wrong and nearly unhittable. The shuffle only fills the gaps: reloading (`Combat.ReloadEndsAt`) or no visible target. With a 4-round magazine and a 3s reload that works out to roughly one ≤2-stud reposition per magazine. Candidate offsets are ground-checked against pad height before use, and a failed sample returns to centre. Movement is `Humanoid:MoveTo(goal)` with an **absolute** goal — never `Pathing:DirectMove`, which aims at `position + direction * 100` and, because `MoveTo` persists between brain ticks, turned a two-stud shuffle into "walk 100 studs that way" and marched her off the ledge. `Pathing:Stop()` first nils `Pathing.Destination`, which also makes both branches of BotPathing's `MoveToFinished` handler no-op instead of treating the peek as a failed path.
12. **Patrol** (`_patrol`): when no target is visible, paths to a random spawn point at `PatrolRetargetInterval`; requires `PatrolMinTravelDistance` separation to avoid short hops. An evicted Vesper first commits to a `RotationDestination` for `SniperRotationDuration`, so the walk between perches reads as crossing the map rather than aimless wandering. Arrival is measured against the stored destination directly, **not** `Pathing:HasArrived` — that returns true whenever `Pathing.Destination` is nil, which is exactly the state the peek's `Stop()` leaves behind, and it cancelled the rotation on its first tick.
13. **Ability thinking**: on `AbilityThinkInterval`, delegates hunter-specific ability decisions to `BotCombat` (e.g. Fortuna dash, Vesper hook, Dust High Noon).
14. **Fortuna jump owns navigation but not aim**: `IsJumping` is deliberately **not** in `_step`'s grapple/dash early-return guard, because that returns before `_fight` — she should keep facing and shooting across the whole arc, which is the entire point of her float, and BotController's `MoveTo` is already steering her to the pad. Instead every destination-issuing branch (firewall retreat, health-pack run, `_combatMovement`, patrol) is suppressed by folding `jumping` into `movementOwned`, the same way the firewall retreat and the pack run already suppress each other.
15. **Two of her four jump triggers live here** (the other two are the blocked-route callback in BotPathing and the high-ground branch in BotCombat), both in `_combatMovement`. **Vertical chase**: a target `VerticalChaseMinRise` above her with a short flat gap is what the jump is actually for — following someone onto a structure rather than pathing the long way round. The downward case needs nothing new, since `AllowSafeDropPaths` already walks her off ledges and lets her fall naturally. **Evasive hop**: fires when recently hit, rolled against `AbilityUsageChance`, and it does *not* return — the hop rides whatever strafe the code below picks, which is what gives it air control. `EvasiveCooldown` is deliberately long so it punctuates a fight instead of turning her into a bunny-hopper.
16. **`StandDown` — the inert-bot state** (`_enterStandDown` / `_exitStandDown`, added 2026-08-08). When the model carries `BotStandDown`, `_step` returns immediately: the bot stands exactly where it spawned, never paths, never turns to face anyone, never acquires a target and — because the brain never reaches its combat calls — never attacks. A live, damageable training dummy, which is what the onboarding tutorial's first steps need. It is the stronger of the two peaceful states: BotCombat's `BotHoldFire` disarms a bot but deliberately leaves it walking, for the tutorial's later steps where the player has to learn to lead a moving target. It is also **not** `SetActive(false)`, which stops the step loop outright — this bot is still stepping, so clearing the flag releases it straight back into a normal fight on the next tick.

	The early return sits **above `Pathing:Update`**, and that placement is half the mechanism: a `MoveTo` already issued goes on walking the bot out of position, the same trap Bram's pin hit. So `Pathing:Stop()` is not sufficient on its own and the state also takes a zero-speed [[HunterMovement]] override (`LockJump` set, no `Duration` — held until cleared rather than expiring). Writing `Humanoid.WalkSpeed` directly would not survive the service's next resolve. Entry and exit are transition-guarded on `self.StandingDown` so the override is applied and cleared once rather than every tick; the only per-tick cost is `Humanoid:Move(Vector3.zero)`, making a stood-down bot marginally cheaper than a live one. Clearing `self.Target` on entry is what stops it tracking, since everything that turns a bot toward an enemy reads that field.
17. **Scripted route** (`SetRoute` / `_updateRoute`, added 2026-08-08): an authored walk the bot performs instead of choosing its own destinations — spawn behind cover, walk out in front of the player. Waypoints are consumed in order and `_updateRoute` returns true while the route owns the tick, which is what stops target selection, combat repositioning and patrol fighting it for the humanoid. It is placed **below `Pathing:Update`**, which walks the computed path, and **above every destination-issuing branch**, which is what it has to displace — the opposite placement to `StandDown`, whose whole job is to stop `Pathing:Update` running at all.

	Arrival is measured flat, so a waypoint part dropped slightly off the floor still counts. A waypoint change re-requests with `force`, abandoning the previous path at once; otherwise it refreshes on a 1s cadence so a bot knocked off course re-paths itself. `HoldAtEnd` (the default) sets `BotStandDown` when the last waypoint lands, reusing the inert state rather than inventing a second kind of stillness — that is the "walk out from behind the wall and wait to be shot" case; `HoldAtEnd = false` hands the bot back to its ordinary behaviour, which combined with a leash is a bot that walks somewhere specific and then mills about there. `Loop` restarts the circuit instead. `SetRoute` also calls `FacePosition(nil, false)` so the humanoid steers where it is walking — a route issued mid-fight would otherwise keep the AlignOrientation locked on the old target and moonwalk the whole way. Both `SetRoute` and `SetApproach` stamp **`BotAuthoredWalk`** on the model (cleared when a route ends or either is cancelled), which BotPathing reads to holster Fortuna's proactive and blocked-route jumps for the duration — a mid-choreography hop onto the scenery is how the tutorial's walk-in bot missed its mark (2026-08-09).
18. **Approach** (`SetApproach` / `_updateApproach`, added 2026-08-08): walk to a specific character and stay with them, overriding this bot's own idea of where it wants to stand. **That override is the point, not a side effect** — `_combatMovement` holds a bot at its hunter's `DesiredRange`, which for Vesper is 150 studs, so a Vesper told to "come to the player" would otherwise walk *away* to open the range she prefers. Approach owns the tick outright, so no `DesiredRange`, strafe, perch or patrol can argue with it. It re-paths to wherever the subject is *now*, so it tracks a player who moves rather than walking to where they used to be; on arrival it stops and turns to face them, and resumes if they wander off — "come here and stay with me", not "go to this spot", which is what `SetRoute` is for. The two are mutually exclusive and setting either clears the other.

	**An authored walk (either kind) clears the scope pose and the strafe flag on the tick it takes ownership** (added 2026-08-09). `SetWorldScoped(false)` and `IsStrafing = false` are otherwise only reached by branches *below* the route/approach return, so a bot that fought even once before being handed a walk kept Vesper's scoped world animation for the entire journey — aiming down a rifle at nothing while jogging. `SetWorldScoped` no-ops when unchanged and for every hunter but Vesper, so this costs the other three nothing.

	The subject is resolved **afresh every tick** rather than held: a Player's `Character` is replaced on every respawn, so a cached model would follow a corpse. If the subject is gone or dead the bot holds position rather than reverting to ordinary behaviour, since for the tutorial's bounty bot that would mean wandering off mid-step; clearing the approach is the caller's job. Facing is handed back to the humanoid while walking (so it steers where it is going instead of side-stepping with its torso locked) and re-asserted every tick once arrived, so it keeps turning if the player circles it.

## Team modes

Target selection skips allies, so a bot never picks a teammate as its target in the first place.

## Domination objective (2026-08-22)

**Mode hook #11, and why it cannot live in `_patrol` alone.** `_scanTarget` has no line-of-sight
test and `DefaultDetectionRange` spans the map, so in a team mode a bot ALWAYS has a target —
`_patrol` is reached only without one, and the first build (hook consulted from `_patrol`) never sent
a single bot to a pad in the owner's playtest. As built, same day:

- `_objectiveTarget(now)` asks `State.gamemodeRules.PatrolTarget(model)` (through a lazy `require`
  of `RoundSystem.State`) once per tick, memoised on `ObjectiveTick`, for a position and hold
  radius; nil when no objective mode runs or it has nothing for this bot.
- `_objectiveDecision(now)` — run in `_step` when the bot has a target and nothing else owns
  movement — decides whether the **objective owns the feet** and whether there is something to
  shoot meanwhile. Capture and fight are **not a choice** (owner, same day: a bot that could only
  do one of them "felt not right"): **on its pad** the bot holds the pad and fights from it whatever
  is happening — shot at, rushed, a target across the map — the feet stay inside the radius and the
  gun answers the nearest enemy it can see; **on the way** it breaks off only for an immediate
  threat (an enemy inside `ObjectiveCloseThreatRange` seen or not, or visible inside
  `ObjectiveEngageRange`), and that is a real fight after which the walk resumes; sniped from afar
  it keeps walking and shoots back if it can see the shooter. The threat judged is the **nearest
  enemy** (`ClosestThreat`, now computed for objective-mode bots as well as Vesper), not
  necessarily the committed `self.Target`, and line of sight is tested **without the fire cone**
  (`CanSee(threat, nil, true)`) because a bot milling on a pad faces its walk, not the enemy.
  Whatever it decides to shoot becomes the target and `TargetLockedUntil` is pushed out by
  `ObjectiveThreatLock` every tick it stays, so the three-nearest roll cannot flip the pick and keep
  resetting the reaction timer. Shooting while the objective owns the feet is `_fight(now, true)`,
  the firewall-escape shape: face and fire, never reposition; `_patrolObjective` mills on
  `ObjectiveFightStrafeInterval` instead of `PatrolRetargetInterval` meanwhile, so a pad-holder
  trading shots is a moving target. Never for a perched Vesper. FFA and TDM get `false, false` and
  are untouched.
- `_patrolObjective(now)` is the walk itself, reached from `_step` (objective owns) and from
  `_patrol` (no target at all). Outside the radius it paths there (`RequestMove` with `force`,
  re-issued on arrival or every `PatrolRetargetInterval`); inside it, it re-targets a fresh point
  every `PatrolRetargetInterval`, so the bot holds the pad rather than treating arrival as
  patrol-complete. Distance is measured against the hook's position, never `Pathing:HasArrived`.
  A nil answer falls through to the random-spawn patrol unchanged.

  **Holders take a side of the pad each** (2026-08-24). The hook's optional **third return** is a
  hold slot index, carried through `_objectiveTarget`; the mill point sits at `slot × 2.39996` rad
  — the golden angle, so any number of holders land apart — in a `0.35–0.7 × radius` band, with a
  small jitter each retarget. A uniform roll inside `0.6 × radius` put every bot sent to a pad in
  the same few studs of its centre, which reads as a heap rather than a held point. The band stops
  short of the rim because the radius is derived from the pad's larger footprint side and so runs
  off the floor on the short axis, and a bot that steps off stops counting toward the capture. A
  mode that returns no slot (any future objective hook) falls back to a stable per-bot angle.

## Dependencies
- **Requires:** [[HunterCharacterUtil]], [[HunterMovement]] (otherwise receives a controller reference containing pathing, combat, config, and humanoid), [[TeamAffinity]], [[State]] (lazy, `gamemodeRules()` — the objective patrol hook)
- **Required by:** BotController

## Connections
### RemoteEvents
None

### BindableEvents
None

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[HunterMovement]] | `.SetOverride()`, `.ClearOverride()` | The zero-speed root behind `StandDown`. The service owns every character's WalkSpeed, so a direct `Humanoid.WalkSpeed` write here would be overwritten on its next resolve |
| [[HunterCharacterUtil]] | `.IsStealthed()` | The one predicate behind every stealth gate here: excluding a hidden character from `_targetCandidates`, suppressing the `OnDamaged` target lock, and switching `_fight` onto its sight memory |
