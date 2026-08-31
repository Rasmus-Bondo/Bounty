# StarterPlayer

Contains all client-side scripts that run on each player. Split into three containers:

## StarterPlayerScripts

Scripts cloned into each player's PlayerScripts on join. Run once per player, persist across respawns.

| Script | Type | Lines | Description |
|--------|------|-------|-------------|
| [[FirstPersonCamera]] | LocalScript | 385 | First-person camera with right arm aiming, body visibility, tool grip pitch |
| [[InputController]] | LocalScript | 117 | Keyboard + mobile touch bindings for sprint, crouch, shoot, reload |
| [[HitMarkScript]] | LocalScript | 681 | Crosshair dot, triangle hitmarker, kill skull, hit stacking, screen shake |
| [[ClientVisualScript]] | LocalScript | 32 | Receives [[ReplicateShot]] events, renders tracer + muzzle flash on other players |
| [[ZoneAtmosphere]] | LocalScript | 77 | Post-processing effects when outside the zone (color correction + blur) |
| [[StaminaBarClient]] | LocalScript | 20 | Smoothly interpolates stamina bar fill from player Stamina attribute |
| [[PerformanceMonitor]] | LocalScript | 79 | FPS-based quality tiers — scales particle rates for low-end devices |
| [[CardClientScript]] | LocalScript | 25 | Bootstraps tarot card system via [[CardController]] module |
| [[recoil]] | LocalScript | 59 | **Disabled** — standalone camera recoil prototype (not used) |

## StarterCharacterScripts

Scripts cloned into each character model on spawn. Destroyed and re-created each respawn.

| Script | Type | Lines | Description |
|--------|------|-------|-------------|
| [[DefaultFootStepRemover]] | LocalScript | 17 | Mutes Roblox's default "Running" sound so [[FootstepService]] can play custom ones |
| [[StartProceduralLocomotion]] | LocalScript | 22 | Creates a [[ProceduralLocomotion]] controller for the character |
| [[ProceduralLocomotion]] | ModuleScript | 291 | Foot IK system — plants feet on ground when idle using raycasts + IKControl |

## StarterCharacter

Pre-configured R15 character model with custom Animate script (Roblox default animation controller). Sets the base animation set for all players.
