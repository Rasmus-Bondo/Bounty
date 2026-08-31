---
tags: [shared, modulescript, audio, combat]
path: game.ReplicatedStorage.Hunters.Dust.Modules.RevolverSoundService
type: ModuleScript
lines: 105
---

# RevolverSoundService

Static utility module for playing positional weapon sounds with proper rolloff and lifecycle management.

## What it does
1. Clones sound templates and parents them to world objects with InverseTapered rolloff (10-200 stud range)
2. Auto-destroys sounds via Debris after playback completes
3. Manages a singleton reload sound with fade-out tween before expiry
4. Provides convenience methods: PlayTrigger, PlayFire, PlayDash, PlayDashReload, PlayReloadFinish
5. Looks for named Sound children on the revolver Handle (TriggerSound, FireSound, DashSound, DashSound2, DashReload, ReloadFinish)
6. Assigns every cloned sound to the `SoundService.SFX` `SoundGroup` so SettingsController's SFX Volume slider can attenuate weapon sounds independently of the master volume and the hit-sound group

## Dependencies
- **Requires:** Nothing
- **Required by:** FPSRevolverClient

## Connections
### RemoteEvents
None

### BindableEvents
None

### Direct require()
None
