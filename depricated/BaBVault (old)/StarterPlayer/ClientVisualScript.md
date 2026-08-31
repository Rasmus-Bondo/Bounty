# ClientVisualScript

Receives replicated shot events from the server and renders bullet tracers + muzzle flash particles on the shooting player's gun for all other clients.

**Path:** `game.StarterPlayer.StarterPlayerScripts.ClientVisualScript`
**Type:** LocalScript (32 lines)
**Runs on:** Client

## How It Works

1. Listens to `ReplicateShot.OnClientEvent(tool, origin, hitPosition)`
2. Validates tool still exists in game
3. If tool has MuzzlePart.MuzzleAttachment: uses attachment WorldPosition as tracer start, emits FlashEmitter particle
4. Falls back to `origin` parameter if no muzzle attachment
5. Calls [[laserBeamEffect]] module to render the tracer beam

## Dependencies

- ReplicatedStorage.Revolver.Remotes.[[ReplicateShot]] — fired by [[BanditGun GunServer]]
- ReplicatedStorage.Revolver.[[laserBeamEffect]] — tracer rendering module
- Tool.MuzzlePart.MuzzleAttachment — tracer origin point
- Tool.MuzzlePart.FlashEmitter — ParticleEmitter for muzzle flash

## Used By

- Runs automatically for all players in StarterPlayerScripts
- Renders other players' shots (your own tracer is handled by your GunClient)
