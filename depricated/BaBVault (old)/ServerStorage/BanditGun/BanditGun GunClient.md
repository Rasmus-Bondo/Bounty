# BanditGun GunClient

Client-side aiming, camera control, IK targeting, animations, and input handling for the revolver. Sets up a third-person shoulder camera with right-arm IK aiming on equip, and tears everything down cleanly on unequip/death/round-end.

**Path:** `game.ServerStorage.BanditGun.GunClient`
**Type:** LocalScript (599 lines)
**Runs on:** Client

## On Equip

1. Caches all character parts (Head, UpperTorso, RightUpperArm, RightHand, Waist, Neck)
2. Locks mouse to center, hides cursor
3. Sets camera FOV to 62, locks zoom to 6 studs
4. Sets shoulder camera offset: `Vector3.new(3.25, 0.75, 0)`
5. Creates invisible AimTarget and ElbowPole parts in workspace
6. Creates IKControl on Humanoid (RightUpperArm → RightHand chain targeting AimTarget)
7. Plays looping hold animation (`rbxassetid://126968150228468`)
8. Connects to `RenderStepped` for per-frame updates

## Per-Frame Updates (RenderStepped)

| Function | What It Does |
|----------|-------------|
| `updateCharacterYaw()` | Rotates HumanoidRootPart to face camera's flat look direction |
| `updateTorsoTilt()` | Applies pitch to Waist (85% strength, ±35°) and Neck (40% strength, ±20°) |
| `updateElbowPole()` | Positions elbow pole relative to shoulder for natural arm bend |
| `updateAimTarget()` | Lerps aim target 14 studs ahead of shoulder along camera look vector |

## Shooting

1. On Tool.Activated: checks equipped, not reloading, cooldown elapsed (0.4s client-side)
2. Gets shot origin from MuzzleAttachment world position
3. Gets direction by raycasting from screen center through camera viewport
4. Plays shoot animation (`rbxassetid://118579986801446`, Priority Action4)
5. Client-predicted fire sound for instant feedback
6. Sends `"Fire"` to server via [[GunRemote]]

## Camera Settings

| Setting | Value |
|---------|-------|
| FOV | 62 |
| Min/Max Zoom | 6 / 6 (locked) |
| Shoulder Offset | (3.25, 0.75, 0) |
| AutoRotate | false (manual yaw) |

## IK Settings

| Setting | Value |
|---------|-------|
| IK Type | Transform |
| Chain | RightUpperArm → RightHand |
| Weight | 1.0 |
| Smooth Time | 0.05s |
| Aim Distance | 14 studs |
| Aim Smoothness | 0.2 (lerp factor) |

## Remote Events Handled

| Action | Response |
|--------|----------|
| `"Ammo"` | Updates local ammo/maxAmmo, updates tool name |
| `"ReloadStarted"` | Sets reloading flag |
| `"ReloadFinished"` | Clears reloading, updates ammo |
| `"DryFire"` | (placeholder for click sound) |
| `"ForceStopReload"` | Clears reloading flag |

## Cleanup

On unequip, death, round end, or tool destruction:
- Disconnects RenderStepped
- Stops all animations
- Destroys IK, AimTarget, ElbowPole
- Resets Waist/Neck transforms, AutoRotate, CameraOffset
- Restores original FOV, zoom, mouse behavior

## Dependencies

- [[GunRemote]] — client-server communication
- `RoundActive` (BoolValue in ReplicatedStorage) — force-resets on round end

## Used By

- Runs automatically when the [[BanditGun Tool]] is equipped by a player
