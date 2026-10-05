---
tags: [server, modulescript, missions, nuclear]
path: game.ServerStorage.Nuclear.NuclearLeverSequence
type: ModuleScript
lines: 97
---

# NuclearLeverSequence

Four-lever launch puzzle on a shared server timer; each platform's lever can be pulled once per attempt.

## What it does
1. `Sequence.new(root, state, folder)` indexes four launch platforms (each `ControlPanel` with `Lever` and `Button`), asserting exactly four; lever poses replicate through `LeverPose<N>` CFrameValues in `folder`.
2. Publishes `NuclearLeverCount`, `NuclearLeverDeadline` and `NuclearLeverGoal` (4) on the mission state for the HUD.
3. `Activate(index)`: the first pull starts a 12 s deadline; each pull tweens the lever (`FlickDegrees`, default -110) and turns the button green. Four pulls finish the sequence.
4. `Step()` resets every lever when the deadline lapses (returning `"Reset"`) and re-enables prompts after the reset animation; returns `"Success"` when finished.
5. `PauseTime(seconds)` extends the deadline; `Cleanup()` restores unfinished levers and destroys the prompts.
6. The per-lever `Prompt` is not created here; the caller (MissionVariety) assigns it to each record.

## Dependencies
- **Requires:** Nothing
- **Required by:** MissionVariety

## Connections
None.
