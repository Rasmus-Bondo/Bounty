---
tags: [client, modulescript, audio, ultimate]
path: game.ReplicatedStorage.Hunters.Dust.Modules.HighNoonLocalSFX
type: ModuleScript
lines: 168
---

# HighNoonLocalSFX

OOP local sound manager for the HighNoon ultimate ability, playing non-positional sounds on the camera.

## What it does
1. Plays a layered audio sequence: start sound immediately, whistle at 0.15s, looped mid-atmosphere at 0.1s
2. Mid sound starts at time position 3s, fades in over 0.8s, and loops continuously
3. Start sound fades out after 5 seconds
4. Token system ensures only the latest Play call controls the sequence
5. Stop fades out all active sounds and cleans up

## Dependencies
- **Requires:** Nothing
- **Required by:** HighNoonClient

## Connections
### RemoteEvents
None

### BindableEvents
None

### Direct require()
None
