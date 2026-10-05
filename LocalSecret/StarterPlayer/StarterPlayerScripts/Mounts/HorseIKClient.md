---
tags: [client, localscript, mounts, animation, ik]
path: game.StarterPlayer.StarterPlayerScripts.Mounts.HorseIKClient
type: LocalScript
lines: 122
---

# HorseIKClient

Local gait for part-built horse rigs: upper legs swing at the hip, IKControls plant the lower legs on terrain.

## What it does
1. Registers models in `workspace.PVE_Horses` tagged with the `PVEHorseRig` attribute, waiting up to 5 s for all four `<Leg>IK` controls, `<Leg>Hip` joints and target `RestPosition` attributes to replicate.
2. Each `PreAnimation`, smooths `HorseSpeed`, `HorseGalloping` and `HorseJumping` model attributes into a gait phase, using per-leg walk / gallop phase offsets from the IK target attributes.
3. Swings each `Hip.C0` from its rest pose, and spreads / reaches the legs outward during a jump.
4. Raycasts each hoof to the ground (ignoring horses and the rider), keeps stance feet planted until they go stale, refreshes planted height for downhill drops, and clamps targets to the IK chain's reach.
5. Disables IK and restores rest poses beyond 180 studs from the camera, and on script destroy.

## Dependencies
- **Requires:** Nothing
- **Required by:** Nobody

## Connections
None. Reads horse model attributes and IK instances only.
