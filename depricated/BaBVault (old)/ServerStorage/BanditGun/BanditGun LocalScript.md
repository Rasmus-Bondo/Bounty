# BanditGun LocalScript

Plays synchronized reload animations on both the revolver gun model and the player's character body when R is pressed. Uses the animated RevolverTest model's built-in Humanoid/Animator.

**Path:** `game.ServerStorage.BanditGun.LocalScript`
**Type:** LocalScript (69 lines)
**Runs on:** Client

## How It Works

1. On equip: loads a character body reload animation (`rbxassetid://73370986814391`) on the player's Animator at Action priority
2. On R key press (with debounce):
   - Plays gun animation (`rbxassetid://87858669330219`) on the RevolverTest model's Animator
   - Plays character body animation simultaneously
   - Waits for character animation to finish before allowing another reload

## Gun Model Setup

The script references `Handle.RevolverTest` — an animated Model inside the tool's Handle containing:
- Its own Humanoid + Animator (for gun-specific animations)
- Motor6D joints connecting: Root → RevolverHandle → RevolverBody → (RevolverTop, RevolverIgniter, RevolverTrigger, RevolverReload → RevolverBarrel → PistolBullet1–6)

## Notes

- This handles the *visual* reload animation only — actual ammo state is managed by [[BanditGun GunServer]] and communicated via [[GunRemote]]
- The R key input is also handled by [[BanditGun GunClient]] which sends the reload request to the server

## Dependencies

- RevolverTest model in Handle — must have Humanoid and Animator
- Player character must have Humanoid with Animator

## Used By

- Runs automatically when the [[BanditGun Tool]] is equipped
