---
tags: [client, localscript, missions, camera, fx]
path: game.StarterPlayer.StarterPlayerScripts.Missions.NuclearEffects
type: LocalScript
lines: 48
---

# NuclearEffects

Cosmetic camera shake for the nuclear launch mission; gameplay never depends on it.

## What it does
1. Listens to `Remotes.NuclearCue` for `Launch` (240-stud range) or `Explosion` (500-stud range) and queues a shake scaled by distance, lasting the sent duration (clamped 0.1-12 s).
2. A render step at Camera+20 sums noise-based translation and rotation from all active shakes (explosions decay fast and hit harder; launches ramp in) and applies it to the camera.
3. A second render step at Camera-1 removes last frame's offset first, so shakes never accumulate into the camera.
4. Unbinds both render steps when the script is destroyed.

## Dependencies
- **Requires:** Nothing
- **Required by:** Nobody

## Connections
### RemoteEvents
| Remote | Direction | Other script |
|--------|-----------|-------------|
| `Remotes.NuclearCue` | ← Server | [[NuclearLaunchController]] launch / explosion cue |

### BindableEvents
None

### Direct require()
None
