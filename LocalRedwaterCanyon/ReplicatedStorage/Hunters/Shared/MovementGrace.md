---
tags: [shared, modulescript, anticheat, movement]
path: game.ReplicatedStorage.Hunters.Shared.MovementGrace
type: ModuleScript
lines: 168
---

# MovementGrace

Holds a MovementChecker grace attribute open until the character **lands**, instead of for a fixed number of seconds.

## What it does
1. `HoldUntilLanded(character, humanoid, attributeName, options)` writes `attributeName` to a floor timestamp, then spawns a watcher that re-extends it every `PollInterval` for as long as `Humanoid.FloorMaterial == Air`, and closes it `LandingSettle` after touchdown
2. **`InitialSeconds` is the floor, not the window.** For the first moments the character may still be standing on the surface they launched from, so a ground reading before the floor expires is not treated as a landing — a Bram charge runs along the ground for its whole duration and would otherwise close instantly
3. **`MaxGraceTime` is the abuse ceiling.** The window can never outlive it, so a validated ability buys at most that many seconds of immunity. Verified: an airborne character holds ~0.5 s of remaining grace indefinitely until the ceiling, then the window expires and stays expired
4. Airborne extension is `LandingSettle + PollInterval` ahead of now, deliberately longer than MovementChecker's 0.5 s sample interval, so a dropped poll cannot leave an uncovered check. It is also clamped to never fall below the floor — starting the loop already airborne would otherwise shorten the initial window
5. Tokens are keyed per **(character, attributeName)**, not per character. A knockback landing mid-grapple must not retire the grapple's watcher and strand the player with a window that stops extending. Calling again for the same pair retires the previous watcher, so re-arming on release is safe and does not stack tasks
6. The token table uses weak keys so a destroyed character cannot be held alive by it
7. Degrades safely: with no Humanoid there is no landing test, so it writes the floor and returns — exactly the fixed window it replaced, rather than nothing
8. `Cancel(character, attributeName)` retires a watcher without touching the attribute, letting whatever value is written expire on its own

## Why it exists
Sizing a grace to an ability's **duration** is wrong whenever the ability can leave the character airborne. The velocity MovementChecker samples is the velocity the ability gave them, and it persists until they hit the ground — a function of how far they fall, not of how long the ability ran. Two things then compound: an airborne player cannot decay violations (MovementChecker only decays on a sample that is both unflagged and grounded), and an ability can sit **above** a raw speed ceiling outright — Bram's `ChargePeakSpeed` is **42** and the horizontal ceiling was **40** until 2026-08-01 — which makes the grace load-bearing rather than a courtesy. Five weight-1 flags is a kick, and at one sample per 0.5 s that is 2.5 seconds. The ceiling is **50** now, so the charge fits under it, but the grace is still required: release and slam velocities exceed the peak, and the vertical (65) and position-delta (70) checks are unchanged.

Vesper's GrappleHookService solved this shape first and still carries its own equivalent implementation; this module is the generalisation, wired to Bram first. Migrating Vesper onto it is deliberately deferred so a working live fix is not refactored in the same pass.

All timestamps are `tick()`, because MovementChecker compares its grace attributes against `tick()` and not `os.clock()`.

## Dependencies
- **Requires:** Nothing
- **Required by:** BreachChargeService, BotCombat

## Connections
### RemoteEvents
None

### BindableEvents
None

### Direct require()
None
