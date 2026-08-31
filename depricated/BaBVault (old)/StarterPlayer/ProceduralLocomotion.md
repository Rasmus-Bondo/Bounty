# ProceduralLocomotion

ModuleScript implementing a foot IK system that plants character feet accurately on the ground when idle. Uses raycasts to find ground position and IKControls to position each foot, with knee pole targets for natural leg bending.

**Path:** `game.StarterPlayer.StarterCharacterScripts.ProceduralLocomotion`
**Type:** ModuleScript (291 lines)
**Runs on:** Client (per character)

## How It Works

### Setup
- Requires R15 rig (asserts on RigType)
- Creates invisible anchored Parts as IK targets and pole targets for each leg
- Creates IKControl instances (Type=Transform, Weight=1, Priority=10) parented to Humanoid
- Excludes own character from raycasts

### Idle Mode (standing still)
- Computes desired foot position: root + side spacing (0.78) + forward offset (0.05)
- Raycasts down from 4.5 studs above to 8 studs below to find ground
- Smoothly lerps foot targets toward ground hit (exponential alpha, IdleFollow=12)
- Foot CFrame oriented to match root forward direction projected onto surface normal

### Moving / Airborne
- Disables IK entirely (IK.Enabled = false)
- On transition back to idle: snaps feet to correct positions before re-enabling

### Pole Targets
- Positioned in front of and to the side of each knee
- Keeps legs bending forward naturally
- Updated every frame regardless of IK state

### Cleanup
- `Destroy()` disconnects all connections and removes IK parts

## Default Config

| Parameter | Default | Description |
|-----------|---------|-------------|
| FootSpacing | 0.78 | Lateral offset from root center |
| ForwardBase | 0.05 | Forward offset from root |
| RaycastHeight | 4.5 | Ray origin above foot position |
| RaycastDepth | 8 | Ray length below origin |
| PlantVerticalOffset | 0.08 | Offset above hit point |
| IKSmoothTime | 0.04 | IKControl SmoothTime |
| IKPriority | 10 | IKControl Priority |
| PoleForward | 3.0 | Pole distance in front |
| PoleSide | 1.25 | Pole lateral offset |
| PoleUp | 0.5 | Pole height offset |
| IdleFollow | 12 | Lerp speed for idle tracking |
| MoveDirectionThreshold | 0.05 | Min MoveDirection to count as moving |
| VelocityThreshold | 1.0 | Min velocity to count as moving |

## Dependencies

- R15 character rig (LeftUpperLeg, RightUpperLeg, LeftFoot, RightFoot)
- workspace:Raycast for ground detection

## Used By

- Created by [[StartProceduralLocomotion]] on each character spawn
