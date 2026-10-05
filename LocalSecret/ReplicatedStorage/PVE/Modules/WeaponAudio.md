---
tags:
  - client
  - modulescript
  - combat
  - audio
path: game.ReplicatedStorage.PVE.Modules.WeaponAudio
type: ModuleScript
lines: 90
---

# WeaponAudio

Client-only weapon fire and reload sound playback. The local player's own weapon plays in 2D from a pool; other players' weapons play positionally from world parts.

## What it does

1. On require, builds a `PVE_LocalWeaponAudio` folder under SoundService and clones each sound in `PVE.Assets.<Weapon>.Sounds` into a round-robin pool (12 voices for `Fire`, 2 for `ReloadMovement`, 1 otherwise), all on the `SFX` SoundGroup
2. Preloads the pooled sounds and every weapon animation in the background, and warns if the preload is incomplete
3. `Audio.Fire(id, parent)` plays the fire sound: from the pool when `parent` is nil, or as a clone parented to `parent` with InverseTapered 10-200 stud rolloff, cleaned up by Debris after 10 s
4. `Audio.Reload(id, parent, duration, elapsed)` schedules time-stretched reload cues and returns a handle with `Stop()` / `Finish()`. The revolver retimes its 1.5 s authored reload; the shotgun plays two movement cues plus a final reload cue
5. `elapsed` lets a reload that is already under way join late: cues that have passed are skipped or started part-way through, and each cue fades out over 0.06 s before its cutoff

## Dependencies

- **Requires:** Nothing
- **Required by:** CombatClient

## Connections

None. Reads sound and animation templates from `ReplicatedStorage.PVE.Assets`.
