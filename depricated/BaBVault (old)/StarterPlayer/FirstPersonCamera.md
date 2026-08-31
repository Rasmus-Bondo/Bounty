# FirstPersonCamera

First-person camera system that activates during active rounds. Handles mouse look, body visibility, right arm pitch tracking, and tool grip adjustment.

**Path:** `game.StarterPlayer.StarterPlayerScripts.FirstPersonCamera`
**Type:** LocalScript (385 lines)
**Runs on:** Client

## How It Works

### Activation
- Only enables when `RoundActive == true` AND player Role is "Bandit" or "Townsfolk"
- Disables on death, round end, or role change
- On disable: restores default camera (Classic mode), shows cursor, resets body visibility

### Camera Control
- Sets CameraType to Scriptable, locks mouse to center
- Accumulates mouse delta into TargetAngleX (pitch, clamped -80 to 80) and TargetAngleY (yaw)
- Smoothly interpolates actual angles toward targets (0.35 lerp factor per frame)
- Camera placed at Head.Position with PlayerHeadOffset (0, 0.7, 0)
- Rotates HumanoidRootPart CFrame to match camera yaw (character faces where you look)
- C key toggles free mouse cursor

### Body Visibility
- Head + face decal hidden (LocalTransparencyModifier = 1)
- All accessories hidden
- Body parts visible when CanViewBody = true
- On disable: restores all parts to visible

### Right Arm Aiming
- Manipulates RightShoulder Motor6D Transform on UpperTorso
- Base pose: arm lifted -95deg, forward -10deg, yaw 8deg
- Aim pose: additional roll based on camera pitch
- Lerped at ArmLerpSpeed = 0.25 for smooth transitions

### Tool Grip Pitch
- Caches original Tool.Grip on equip
- Each frame: applies pitch rotation to grip (ToolPitchStrength = 1.0)
- Resets grip on unequip or camera disable

### Tool Animation Suppression
- Caches animation IDs from Animate script's toolnone/toolslash/toollunge folders
- Stops any playing tool hold animations each frame to prevent conflicts

## Constants

| Constant | Value |
|----------|-------|
| FieldOfView | 80 |
| Sensitivity | 0.1 |
| Smoothness | 0.05 |
| Pitch clamp | -80 to 80 deg |
| PlayerHeadOffset | (0, 0.7, 0) |
| ArmPitchStrength | 1.0 |
| ArmLerpSpeed | 0.25 |
| BaseLift | -95 deg |
| BaseForward | -10 deg |
| BaseYaw | 8 deg |
| FreeMouse toggle | C key |

## Dependencies

- ReplicatedStorage.RoundActive BoolValue
- Player "Role" attribute (set by [[RoleService]])
- UpperTorso.RightShoulder Motor6D (R15 rig)
- Character Animate script (for tool animation ID caching)

## Used By

- Runs automatically for all players in StarterPlayerScripts
- Works alongside [[BanditGun GunClient]] (which uses shoulder cam instead — different camera system)
