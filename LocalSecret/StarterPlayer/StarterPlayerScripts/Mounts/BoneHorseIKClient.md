---
tags: [client, localscript, mounts, animation, ik]
path: game.StarterPlayer.StarterPlayerScripts.Mounts.BoneHorseIKClient
type: LocalScript
lines: 333
---

# BoneHorseIKClient

Procedural bone gait, body motion and lower-leg IK for the skinned (meshed) horse; visuals stay client-local.

## What it does
1. Registers models in `workspace.PVE_Horses` with `PVEBoneHorseRig == true` once all four leg IKControls (with `UpperBone`, pole, target and `RestPosition`) replicate, collects the mesh's bones and sets `BoneGaitReady` on the model.
2. Each `PreAnimation`, resets bone transforms, then derives speed, gallop, jump, takeoff-prepare, bank and idle blends from the `HorseSpeed`, `HorseGalloping`, `HorseGrounded` and `HorseTakeoffAt` model attributes.
3. Fits body pitch / roll to a four-point ground footprint and animates body rock, bob and surge, neck / head nod, idle glances and tail sway / swats.
4. Writes `VisualJumpPitch`, `VisualSlopePitch` and `VisualStridePhase` on the model locally (HorseClient reads the stride phase for camera bob).
5. Swings each upper leg bone through walk / gallop curves and solves the lower leg with terrain-planted IK (disabled while airborne), constraining hooves to a narrow sagittal plane under the knee.
6. A `PVEBoneHorseLimits` render step (Last priority) applies the reference swing / kick / jump-tuck pose curves, clamps per-bone pitch / yaw / roll in horse space, and rate-limits rear-leg rotation.
7. Resets beyond 180 studs from the camera and on script destroy.

## Dependencies
- **Requires:** Nothing
- **Required by:** Nobody

## Connections
None. Reads horse model attributes and bone / IK instances only.
