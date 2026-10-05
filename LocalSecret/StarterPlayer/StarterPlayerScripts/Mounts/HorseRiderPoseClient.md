---
tags: [client, localscript, mounts, animation]
path: game.StarterPlayer.StarterPlayerScripts.Mounts.HorseRiderPoseClient
type: LocalScript
lines: 59
---

# HorseRiderPoseClient

Local seated riding pose for every mounted player; the server keeps mount authority.

## What it does
1. Each `PreSimulation`, finds every player with `PVEMounted == true` and records their Motor6D / AnimationConstraint joints that appear in a fixed `POSE` table (hips, knees, shoulders, elbows, waist, root).
2. Blends `Transform` on those joints toward the riding pose over ~0.125 s.
3. Adds gallop lean and bounce from `PVEHorseGalloping`, and a bank from the character's yaw rate; waist / root rotations are computed in horse space so mirrored rig axes don't reverse the lean.
4. Clears transforms on dismount, character change, player leave and script destroy.

## Dependencies
- **Requires:** Nothing
- **Required by:** Nobody

## Connections
None. Reads player attributes and character joints only.
