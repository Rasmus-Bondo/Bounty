# BanditGun GunClient

Client-side revolver controller — manages third-person shoulder camera, right arm IK aiming, torso pitch tracking, hold/shoot animations, client-predicted fire sound, reload requests, and round-end cleanup.

**Path:** `game.StarterPack.CamGun.BanditGun.GunClient`
**Type:** LocalScript (599 lines)
**Runs on:** Client

## How It Works

### On Equip
1. Saves original camera/mouse state
2. Locks mouse to center, hides cursor
3. Sets FOV to 62, zoom to 6 (fixed distance)
4. Applies shoulder camera offset (3.25, 0.75, 0)
5. Creates IK aim target + elbow pole parts in workspace
6. Creates IKControl on Humanoid for right arm aiming
7. Plays looping hold animation
8. Starts RenderStepped loop

### Per-Frame (RenderStepped)
1. Rotates character yaw to match camera horizontal direction
2. Tilts waist + neck joints to match camera pitch
3. Positions elbow pole relative to upper torso
4. Lerps aim target toward camera look direction

### On Fire (Tool.Activated)
1. Checks cooldown (0.4s), equipped state, not reloading
2. Gets shot origin from Handle.MuzzleAttachment
3. Raycasts from screen center to find aim target point
4. Plays shoot animation (Action4 priority)
5. Clones + plays positional fire sound on muzzle (client-predicted)
6. Fires [[GunRemote]] with origin + direction to server

### Round End Reset
- Listens to [[RoundActive]] BoolValue — on false, force-resets everything

## Camera Settings

| Constant | Value | Purpose |
|----------|-------|---------|
| CAMERA_FOV | 62 | Field of view while aiming |
| CAMERA_MIN_ZOOM | 6 | Fixed zoom distance |
| CAMERA_MAX_ZOOM | 6 | Fixed zoom distance |
| SHOULDER_CAMERA_OFFSET | (3.25, 0.75, 0) | Right shoulder offset |

## Torso Pitch

| Constant | Value | Purpose |
|----------|-------|---------|
| MAX_WAIST_PITCH | 35 deg | Waist rotation limit |
| MAX_NECK_PITCH | 20 deg | Neck rotation limit |
| WAIST_STRENGTH | 0.85 | Waist pitch multiplier |
| NECK_STRENGTH | 0.4 | Neck pitch multiplier |

## IK Settings

| Constant | Value | Purpose |
|----------|-------|---------|
| RIGHT_ARM_IK_WEIGHT | 1 | Full IK influence |
| AIM_TARGET_DISTANCE | 14 | Studs ahead for aim target |
| AIM_TARGET_SMOOTHNESS | 0.2 | Lerp factor per frame |
| IK_SMOOTH_TIME | 0.05 | IKControl smooth time |
| ELBOW_POLE_RIGHT/UP/BACK | 1.5 / 0.75 / 0.75 | Elbow pole offsets |

## Remote Messages Handled

| Action | Response |
|--------|----------|
| Ammo | Updates local ammo count, refreshes tool name |
| ReloadStarted | Sets reloading = true |
| ReloadFinished | Clears reload, updates ammo |
| DryFire | (placeholder for click sound) |
| ForceStopReload | Cancels reload state |

## Dependencies

- [[GunRemote]] — fire/reload requests to server, ammo updates from server
- [[RoundActive]] — BoolValue in ReplicatedStorage for round-end cleanup
- Handle.MuzzleAttachment — shot origin position
- FireSound — Sound template on the tool

## Used By

- Runs inside BanditGun Tool on the client when equipped
