---
tags: [server, modulescript, missions]
path: game.ServerStorage.Missions.MissionVariety
type: ModuleScript
lines: 421
---

# MissionVariety

Objective mechanics for the non-combat mission types; the server owns progress, carry state and timing.

## What it does
1. `Catalog` / `Order` define four mission kinds: Mine (recover three crates), Escort (supply wagon), TNT (refuel and launch the nuclear missile) and Valves (steam engine pressure pump). Mine crates themselves are run by MineSupplyMission.
2. `Prepare(kind, position, context)` builds the objective props at a walkable floor near the site, applies authored artwork through MissionArtService when available, and for TNT wires a NuclearLaunchController and a NuclearLeverSequence. `Enable()` turns on the first prompts and hint.
3. `TryInteract(player, id)` validates `context.Allow`, 12-stud range, line of sight and a 0.2 s cooldown, then advances the objective: open the missile tip, carry one TNT bundle at a time (`PVECarryingTNT`), load 3, close the tip, pull the four launch levers; or lock valves 1-3 only while their gauge is green (a miss vents for 2 s).
4. `Step(dt)` drives the nuclear stage machine through arming, ignition and launch; moves the escort wagon along its route only while an allowed player is within 28 studs, and damages it from nearby mission enemies (failing at 0 health); animates valve gauges.
5. Publishes HUD state on the mission state object (`ObjectiveStage`, `ObjectiveProgress`, `ObjectiveFinishAt`, `EscortHealth`, `EscortMoving`, `ValveGreen`, `CurrentValve`, `NuclearLever*` via the lever sequence) and a hint text.
6. `PauseTime`, `Status()` (ready, failed), `Anchor()` and `Cleanup()` (releases carried TNT, destroys props) support the caller's mission loop.

## Dependencies
- **Requires:** [[MissionArtService]], [[NuclearLaunchController]], [[NuclearLeverSequence]]
- **Required by:** MissionServer

## Connections
### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[MissionArtService]] | `Apply`, `SetVisible` | Authored prop artwork (wagon, rocket, TNT, pump, valve) |
| [[NuclearLaunchController]] | `.new(rocket)`, `Open/Close/Ignite/Step` | Missile tip and launch motion |
| [[NuclearLeverSequence]] | `.new(platforms, state, folder)`, `Enable/Activate/Step` | Four-lever arming puzzle |
