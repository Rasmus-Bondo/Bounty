# RagdollService

Server-authoritative ragdoll system. On death, clones the character as a physics-enabled corpse, hides the original, and applies shot impulse for directional knockback.

**Path:** `game.ServerScriptService.WorldServices.RagdollService`
**Type:** ModuleScript (188 lines)
**Runs on:** Server

## How It Works

### Architecture
All ragdoll creation runs server-side — corpses are server-owned Models in `workspace.Corpses`. Physics replicates to all clients automatically with no client-side ragdoll code needed.

### Death Flow

1. On character spawn: sets `BreakJointsOnDeath = false`, hooks Died event
2. On death (if `ShouldRagdoll` attribute is true):
   a. Clones character as a corpse model → parents to `workspace.Corpses`
   b. Hides original character (transparency=1, collision=false, root teleported to y=-500)
   c. Creates a [[Ragdoll]] instance on the corpse and enables it
   d. Applies stored shot impulse from player attributes

### Corpse Preparation (`prepareCorpseModel()`)
- Destroys all Scripts, LocalScripts, and Tools from the clone
- Disables Humanoid display (name, health bar)
- Sets `BreakJointsOnDeath = false`, `RequiresNeck = false`

### Shot Impulse
The gun system stores the kill shot direction as player attributes (`RagdollForceX/Y/Z`). On death:
- Reads direction from attributes
- Applies impulse: `(direction * 35 + Vector3(0,8,0)) * mass` to UpperTorso/LowerTorso/Head
- Clears stored force attributes after application

### Player Attributes Used

| Attribute | Type | Description |
|-----------|------|-------------|
| ShouldRagdoll | boolean | Set by gun system to enable ragdoll on next death |
| RagdollForceX/Y/Z | number | Shot direction components for impulse |

## Dependencies

- [[Ragdoll]] — OOP module that handles Motor6D → BallSocketConstraint conversion
- ReplicatedStorage.RoundActive — waited for at init

## Used By

- [[MainServer]] — Initialize() called at boot
- [[GunServer]] — sets ShouldRagdoll and RagdollForce attributes before killing
- [[SpawnService]] — clears corpses folder on round reset
