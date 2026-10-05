---
tags: [client, localscript, camera, movement, viewmodel]
path: game.StarterPlayer.StarterPlayerScripts.ViewmodelController
type: LocalScript
lines: 929
---

# ViewmodelController

Local first-person viewmodel, momentum movement (sprint, slide, slope ride, bunny-hop, air glide) and camera feel for the lobby.

## What it does
1. Forces `CameraMode = LockFirstPerson`. Clones ReplicatedStorage.TestingArms into the CurrentCamera (client-only), anchoring only its PrimaryPart and caching the `HeadViewport` marker offset; walk/run tracks from ReplicatedStorage.Animations (`Walk`, `Run`) play on the clone's own Animator.
2. Clones ReplicatedStorage.Speedlines into the camera; its ParticleEmitter turns on above 30 studs/s with a rate scaled to speed, placed in front of the camera with an aspect- and FOV-adjusted offset.
3. Momentum: base WalkSpeed 20, ramping to 24 walking or 32 sprinting (LeftShift), plus a bunny-hop boost (+1.5 per moving jump, cap +4, absolute cap 36, 0.18s cooldown, decays). Jumping above base speed carries horizontal momentum (cap 44) with limited air steering.
4. Slide (LeftControl): grounded, moving and at least 23 studs/s gives speed x1.28 (cap 42), decelerating to 18, max 1.35s. Sliding off a ledge adds one +3.5 burst (cap 46). On slopes of 7-58 degrees the slide steers downhill and accelerates (cap 54) with no duration limit. Jumping out carries 88% of slide speed. Airborne at 18+ studs/s, LeftControl starts an air glide (x1.08, cap 42, 1.1s cooldown). WalkSpeed is held at 0 during a slide and velocity is written directly; the walk/run pose is frozen.
5. Camera, bound to RenderStep at `Camera + 1`: FOV 70 rising to 86 with speed (96 while sliding), a 1.25-stud viewpoint drop while sliding, walk/sprint bob (no jump/landing bob), A/D strafe offset and roll on a damped spring, and a short roll/yaw snap on quick strafe reversals. Yaw sway goes to the viewmodel only so strafes do not curve.
6. Builds a `SpeedGui` speedometer in code (studs/s plus SPRINTING / MOMENTUM / SLIDING / SLOPE SLIDE / GLIDING) and three looped local Sounds (run, slide, wind) under the camera, created with `Instance.new` and **no SoundGroup**; it mutes the character's default `Running` sound.
7. Ignores movement keys while a TextBox is focused; tears everything down on `script.Destroying`.

## Dependencies
- **Requires:** Nothing
- **Required by:** Nobody

## Connections
None. Reads ReplicatedStorage.TestingArms, Animations and Speedlines by name only.
