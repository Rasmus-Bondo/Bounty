# FootstepService

Spawns visible footprint decals on sand surfaces as players walk. Each footprint fades in, stays visible briefly, then fades out and self-destructs. Also plays randomized sand step sounds.

**Path:** `game.ServerScriptService.WorldServices.FootstepService`
**Type:** ModuleScript (126 lines)
**Runs on:** Server

## How It Works

### Per-Character Setup
On CharacterAdded, starts a Heartbeat loop that:
1. Checks if player is moving (`MoveDirection.Magnitude > 0.1`)
2. Checks if standing on Sand material (`FloorMaterial == Sand`)
3. Alternates left/right foot each step
4. Respects cooldown interval between steps

### Footprint Creation
For each step:
1. Raycasts down from foot position (origin +1, direction -4 studs)
2. Only creates on Sand material hits
3. Clones `ReplicatedStorage.Footstep` template (Part with Decal)
4. Positions at hit point + 0.02 Y offset, oriented to foot's forward direction
5. Plays SandStep sound with randomized pitch (0.5-0.65) and volume (0.35-0.45)

### Lifecycle
- **Fade in**: decal transparency 1→0 over 0.08s (Quad easing)
- **Visible**: holds for 3.2s
- **Fade out**: decal transparency 0→1 over 0.8s (Quad easing)
- **Cleanup**: Part destroyed after fade completes

### Constants

| Constant | Value |
|----------|-------|
| FOOTSTEP_SIZE | 1.5 x 0.08 x 1.5 studs |
| FOOT_Y_OFFSET | 0.02 studs above ground |

All timing/audio values come from [[Config]].

## Dependencies

- [[Config]] — interval, timing, pitch/volume ranges
- ReplicatedStorage.Footstep — template Part with Decal and SandStep Sound
- TweenService — decal fade animations

## Used By

- [[MainServer]] — Initialize() called at boot
- Works with [[DefaultFootStepRemover]] (client) which mutes Roblox's built-in running sounds
- Replaces deprecated `Footstep` script
