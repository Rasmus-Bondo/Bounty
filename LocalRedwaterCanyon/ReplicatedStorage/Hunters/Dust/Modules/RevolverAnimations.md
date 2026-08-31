---
tags: [client, modulescript, animation, combat]
path: game.ReplicatedStorage.Hunters.Dust.Modules.RevolverAnimations
type: ModuleScript
lines: 276
---

# RevolverAnimations

OOP animation manager that loads and controls the Idle, Shoot, Fanning, Reload, Walk and Run animation tracks on Dust's viewmodel.

## What it does
1. Loads six animation tracks via RevolverViewModel.LoadTrack: Idle (Idle, looped), Shoot (Action), Fanning (Action2), Reload (Action), and the two locomotion holds Walk and Run (both Movement, looped). Every clip id resolves through the Dust manifest (LoadTrack goes through HunterAnimations); the clone's own Animation instances are unread. The legacy `Skill2` fallback name is gone — no rig declared it after the Fanning rename, and the manifest cannot
2. PlayShoot: instant restart of the shoot animation
3. `GetSkill2AnimationWaitTime` returns `RevolverConfig.Skill2.ShotInterval` verbatim — the Fan-The-Hammer cadence is **authored, never measured off the clip**. Reading it off the clip meant a weapon skin that ships its own Fanning changed the ability's fire rate; see RevolverConfig for the Icefang case that exposed it
4. `GetSkill2AnimationSpeed` is the inverse: `clipLength / ShotInterval`, so one whole Fanning cycle lands on each shot whatever length the equipped skin's clip is. Returns 1 while `Length` still reads 0 (the asset has not finished downloading) rather than dividing by zero — the burst's pace is unaffected either way
5. PlaySkill2Once: plays at that computed speed, with weight and position reset
6. PlayReload: adjusts speed to match desired reload duration
7. Stop methods reset time position and weight to 0 via deferred calls
8. `SetLocomotion(state)` holds one locomotion loop, where `state` is `"Idle"`, `"Walk"` or `"Run"`. It takes **one state string rather than two booleans** because Walk and Run share Movement priority: playing both blends them to an average instead of letting one win, so the mutual exclusion is made structural rather than left to each caller. Plays at `WALK_ANIMATION_SPEED` / `RUN_ANIMATION_SPEED` (both 1, the authored rates) with a 0.15s fade in and 0.2s fade out, guarding on `IsPlaying` so a repeated "on" cannot restart a cycle mid-stride. The unwanted tracks are stopped one at a time rather than over a table literal — either can legitimately be nil, and `ipairs` over `{ nil, track }` stops on the hole and would silently leave the second one playing
8a. It deliberately does **not** suppress locomotion while an action clip runs, unlike CardsClient's equivalent. Every Dust action clip poses `LeftArm`, `RightArm` and `Root` — a superset of what Walk and Run pose, measured off the KeyframeSequences — so the priority ladder hides the cycle completely on its own. Fortuna has to suppress because her locomotion clips also pose `Card1`-`3` and drag the cards out of frame; Dust has no equivalent joint
9. Destroy stops the locomotion loop with the rest and cleans up all tracks

## Dependencies
- **Requires:** Nothing (configured externally)
- **Required by:** FPSRevolverClient

## Connections
### RemoteEvents
None

### BindableEvents
None

### Direct require()
None (all dependencies injected via constructor config)
