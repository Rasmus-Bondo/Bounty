---
tags:
  - client
  - localscript
  - audio
  - combat
  - dust
path: game.StarterPlayer.StarterPlayerScripts.Dust.WorldRevolverShotSoundClient
type: LocalScript
lines: 201
---

# WorldRevolverShotSoundClient

Plays a positional 3D gunshot sound at another player's world-model revolver when they fire, skipping the shooter so they don't hear it twice.

## What it does
1. Listens to the `WorldRevolverShotSound` RemoteEvent (fired by [[RevolverWorldModelServer]]) with the shooter as payload
2. Returns immediately if the shooter is the local player (the FPS client already plays the shooter's own local fire sound)
3. Locates the shooter's `WorldRevolverCosmetic`, finds its `FireSound` template (searches by name, then via the `RevolverHandle` path), and clones it onto the muzzle attachment/part with InverseTapered rolloff (12-185 studs)
4. Streaming-safe: with StreamingEnabled a distant shooter's cosmetic can replicate as an empty Model, so the script falls back to the `FireSound` inside the always-replicated `ReplicatedStorage.Hunters.Dust.Objects.WorldRevolver` template, parents to the character's `HumanoidRootPart` when the muzzle parts are streamed out, and silently skips (no warn) when the shooter is fully streamed out
5. Cleans up the cloned sound via `Debris` after it finishes playing
6. Assigns the cloned sound to the `SoundService.SFX` `SoundGroup` so SettingsController's SFX Volume slider attenuates other players' gunshots alongside every other weapon sound cloned by RevolverSoundService

## Dependencies
- **Requires:** [[HunterClientState]]
- **Required by:** Nobody

## Connections
### RemoteEvents
| Remote | Direction | Other script |
|--------|-----------|-------------|
| `WorldRevolverShotSound` | ← Server | Fired by [[RevolverWorldModelServer]] on every valid shot |

### BindableEvents
None

### Direct require()
None
