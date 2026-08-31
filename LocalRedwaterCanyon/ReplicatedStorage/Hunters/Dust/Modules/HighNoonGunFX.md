---
tags: [client, modulescript, vfx, audio, ultimate]
path: game.ReplicatedStorage.Hunters.Dust.Modules.HighNoonGunFX
type: ModuleScript
lines: 486
---

# HighNoonGunFX

OOP gun effects manager for HighNoon shots including animations, sound pooling, muzzle flash, and laser beams.

## What it does
1. Finds the client viewmodel's gun parts (Handle, MuzzlePart, MuzzleAttachment) from the camera, resolving the gun model through `RevolverViewModel.FindRevolverModel`. It used to carry its own copy of that name list, which had no structural fallback: Icefang named its gun model `Ice` (since renamed), so the lookup returned nil and `PlayLocalShot` bailed on a nil muzzle position before reaching the fan animation — the ultimate's per-shot animation, muzzle flash, fire sound, beam and aim nudge were all dead on that skin
2. Caches three animation tracks via a shared `loadViewModelTrack` helper — `Shoot` (Action), `Fanning` (Action3) and `Ultimate` (Action2) — resolving each id from the **Dust manifest** through `HunterAnimations.id` with `RevolverViewModel.EquippedSkinName()` (the clone's Animation instances are unread; the old `Skill2` fallback is gone). The priority ladder is load-bearing: the held ultimate pose has to cover the looped Idle while still losing to the per-shot fan replays. Each is force-set `Looped = false`, because the authored Fanning clip has Loop baked on
3. `PlayUltimateIntro` plays the ultimate draw once and then **freezes it on its last frame**, holding that pose for the whole lock-on phase. The freeze is `AdjustSpeed(0)` plus a `TimePosition` write parked `ULTIMATE_HOLD_EPSILON` (0.03s) short of the end — a non-looped track stops itself the instant it reaches its length, so holding exactly on the last frame is a race the track wins. The hold is **polled**, not scheduled off a `task.delay`, because `AnimationTrack.Length` reads 0 until the asset finishes downloading; the poll is deadlined at `length + 1s` so a viewmodel detached mid-intro can't spin the coroutine forever
4. `StopUltimate` bumps a token (cancelling any in-flight hold poll) and restores speed before stopping — speed is 0 while held, so skipping that would leave the next `Play` unable to advance
5. `PlayFanShot` replays Fan-The-Hammer once per ultimate shot, sped up to `Length / UltimateFanShotInterval` (0.12s, matching `HighNoonServerConfig.Timing.ShotDelay`) so a whole fan lands between shots instead of being cut in half by the next one. Falls back to the shoot pop on a viewmodel with no Fanning clip
6. Manages a pool of 8 pre-cloned fire sounds for rapid-fire playback without allocation
7. Plays muzzle flash and smoke particle effects per shot
8. `PlayLocalShot` orchestrates: aim nudge event, **fan replay** (was the shoot animation before the 2026-08-09 animation pass), muzzle FX, fire sound, laser beam
9. `PlayCanShootCue` plays a DashReload sound as audio feedback when HighNoon can fire
10. `Reset` releases the held ultimate pose *before* dropping the track cache — otherwise the track is orphaned frozen on Dust's arms and the next ultimate loads a second one on top of it

Note that Fanning ends up loaded twice on one Animator (RevolverAnimations owns the Skill2 copy). That is pre-existing for Shoot and safe here: FPSRevolverClient blocks normal shooting and cancels Skill2 for the whole ultimate, so the two copies never play at once.

## Dependencies
- **Requires:** [[RevolverViewModel]] (gun-model resolver + equipped-skin name); [[HunterAnimations]] (clip ids — from `ReplicatedStorage.Hunters.Shared`); [[AnimationLoader]] (`loadCached`, for the Shoot/Fanning/Ultimate viewmodel tracks — from `ReplicatedStorage.Modules`); everything else is configured externally via injected dependencies
- **Required by:** HighNoonClient

## Connections
### RemoteEvents
None

### BindableEvents
| Bindable | Direction | Other script |
|----------|-----------|-------------|
| `HighNoonAimNudge` | → | [[HighNoonViewModelOrbit]] receives gun flick position |

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[RevolverViewModel]] | `RevolverViewModel.FindRevolverModel()` | Resolve the equipped skin's gun model out of `camera.ClientViewModel` |
| [[HunterAnimations]] | `HunterAnimations.id()` | Resolve the Shoot/Fanning/Ultimate clip ids from the Dust manifest |
