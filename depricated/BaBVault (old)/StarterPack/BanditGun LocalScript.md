# BanditGun LocalScript

Plays the revolver model's reload animation — triggers both a gun-rig animation and a character body animation when R is pressed.

**Path:** `game.StarterPack.CamGun.BanditGun.LocalScript`
**Type:** LocalScript (69 lines)
**Runs on:** Client

## How It Works

1. Gets the gun's internal Humanoid/Animator from `Handle.RevolverTest`
2. Loads a gun animation (barrel open/close) on the gun rig's Animator
3. On equip: loads a character animation (body reaches to reload) on player's Animator
4. R key press: plays both animations simultaneously, debounces until character track finishes

## Animation Assets

| Animation | ID | Target |
|-----------|----|--------|
| Gun rig | rbxassetid://87858669330219 | RevolverTest Humanoid Animator |
| Character body | rbxassetid://73370986814391 | Player Humanoid Animator (Action priority) |

## Dependencies

- Handle.RevolverTest.Humanoid — the gun model's internal rig
- Player character Humanoid + Animator

## Used By

- Runs inside BanditGun Tool alongside [[BanditGun GunClient]] and [[BanditGun RevolverGuiClient]]
