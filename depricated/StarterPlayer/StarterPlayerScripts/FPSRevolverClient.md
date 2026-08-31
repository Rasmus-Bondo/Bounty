---
tags: [client, localscript, combat, core]
path: game.StarterPlayer.StarterPlayerScripts.FPSRevolverClient
type: LocalScript
lines: 1496
---

# FPSRevolverClient

The main client-side weapon script. Handles first-person view model, shooting, reloading, dashing, crouching, fan-fire (Skill2), and all associated animations/sounds/VFX.

## What it does

### View Model
- Clones `ReplicatedStorage.RevolverDefaultViewmodel.ArmsViewModel` into Camera
- Updates every render frame: mouse sway, walk bob, idle sway, strafe tilt, jump/land motion, recoil, dash tumble, crouch offset
- Left arm visibility is carefully managed with tweens and token systems for reload/skill2 animations

### Shooting
- LMB or touch tap fires a bullet
- Client-side raycast for tracer VFX, then `FireBullet:FireServer()` for server validation
- 0.4s cooldown between shots, 6-round magazine
- Camera recoil spring (pitch kick + recovery), FOV kick, muzzle flash particles

### Reloading
- R key, 1.5s duration with animation and sound
- Auto-reloads when empty
- Dash instantly reloads all ammo

### Dashing (Skill1)
- Q key, 4s cooldown
- Caps air velocity before air dashes to prevent momentum stacking
- Post-dash velocity clamp and jump lock to prevent exploits
- Fires `DashRequest:FireServer()` and `DashCooldownStarted` bindable

### Fan Fire (Skill2)
- E key, 8s cooldown
- Dumps all remaining ammo rapidly (0.07s between shots)
- Reduced recoil (0.55x multiplier), shows left arm during animation

### Crouching
- LeftControl hold, reduces walk speed to 55%, lowers camera

### Air Hang
- Subtle anti-gravity force while airborne for better aerial shots

## Dependencies

- **Requires:** [[laserBeamEffect]] module from `ReplicatedStorage.Revolver`
- **Fires remotes:** `FireBullet`, `DashRequest`
- **Listens to remotes:** `ReplicateShot` (tracer VFX for other players' shots), `HighNoonVisual` (blocks shooting during ultimate)
- **Fires bindables:** `AmmoChanged`, `Reloaded`, `DashCooldownStarted`, `Skill2CooldownStarted`
- **Listens to bindables:** `DashRequested`, `Skill2Requested` (from [[HunterGuiClient]] mobile buttons)

## Communication

```
FPSRevolverClient ──FireBullet──► RevolverModule (server)
FPSRevolverClient ──DashRequest──► RevolverModule + DashDustVFXModule (server)
FPSRevolverClient ──AmmoChanged/Reloaded──► HunterGuiClient (bindable)
FPSRevolverClient ──DashCooldownStarted──► HunterGuiClient (bindable)
FPSRevolverClient ──Skill2CooldownStarted──► HunterGuiClient (bindable)
HunterGuiClient ──DashRequested──► FPSRevolverClient (bindable)
HunterGuiClient ──Skill2Requested──► FPSRevolverClient (bindable)
HighNoonClient ──HighNoonVisual──► FPSRevolverClient (blocks input)
```
