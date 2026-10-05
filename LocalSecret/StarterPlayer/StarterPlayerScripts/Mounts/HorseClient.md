---
tags: [client, localscript, mounts, input, camera]
path: game.StarterPlayer.StarterPlayerScripts.Mounts.HorseClient
type: LocalScript
lines: 177
---

# HorseClient

Horse riding input, the mounted third-person camera feel and gallop speedlines.

## What it does
1. X toggles mount / dismount (`Toggle`); while mounted, W/S/A/D and Shift build a throttle / steer / sprint payload sent as `Input` on every change and re-sent at least every 0.35 s; Space sends `Jump`.
2. Follows the `PVEMounted` player attribute: mounted switches to Classic camera at 12-22 stud zoom with a free cursor and shows the control hint; dismounting restores 0.5 zoom and the saved FOV and sends a zeroed input.
3. Clears held keys when a menu opens and ignores input while one is open.
4. A `PVEHorseCameraFeel` render step (Camera+2) adds a small stride bob from the horse model's `VisualStridePhase` attribute (written locally by BoneHorseIKClient) and widens FOV with `PVEHorseSpeed` / `PVEHorseGalloping`.
5. Clones `ReplicatedStorage.Speedlines` in front of the camera and scales its emitter rate with horse speed while galloping.

## Dependencies
- **Requires:** [[ClientMenuState]]
- **Required by:** Nobody

## Connections
### RemoteEvents
| Remote | Direction | Other script |
|--------|-----------|-------------|
| `Remotes.Horse` | → Server | [[HorseServer]] `Toggle` / `Input` / `Jump` |

### BindableEvents
None

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[ClientMenuState]] | `Menus.IsOpen()` | Drop held keys and hide the hint behind menus |
