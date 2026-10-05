---
tags: [server, modulescript, missions, nuclear]
path: game.ServerStorage.Nuclear.NuclearLaunchController
type: ModuleScript
lines: 101
---

# NuclearLaunchController

Server-owned cosmetic motion for the nuclear rocket: hatch, ignition, launch and airburst. Fueling validation stays in MissionVariety.

## What it does
1. `Controller.new(model)` finds the rocket's `Tip` (hinge) and its `LightBulb` and optional `Engine` Fire, asserting the required parts exist.
2. Stage machine driven by `Step(dt)`: Closed, Opening, Open, Closing, Arming, Ignition, Launching, Complete. `Open` / `Close` swing the tip 100 degrees over 1.8 s; closing leads to Arming.
3. `Ignite()` (only from Arming) lights the engine and fires the `Launch` cue; ignition shakes the rocket for 2.8 s, then it climbs 260 studs over 8 s.
4. `Explode()` fires the `Explosion` cue, spawns a short-lived neon fireball, smoke and sparks airburst in `workspace.NuclearAirburst`, and destroys the rocket.
5. The bulb blinks while the rocket is active; `Cleanup()` turns fire and light off.

## Dependencies
- **Requires:** Nothing
- **Required by:** MissionVariety

## Connections
### RemoteEvents
| Remote | Direction | Other script |
|--------|-----------|-------------|
| `Remotes.NuclearCue` | → All clients | [[NuclearEffects]] `Launch` and `Explosion` camera/audio cues |
