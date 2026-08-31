# Ragdoll

OOP module that converts an R15 character's Motor6D joints into BallSocketConstraints for physics-based ragdoll behavior. Used by [[RagdollService]] on death.

**Path:** `game.ServerScriptService.WorldServices.Ragdoll`
**Type:** ModuleScript (164 lines)
**Runs on:** Server

## How It Works

### Construction (`Ragdoll.new(character)`)
Takes a character model, stores references to character and Humanoid, initializes empty constraint list.

### Enabling (`Ragdoll:enable()`)

1. Configures Humanoid: `BreakJointsOnDeath=false`, `RequiresNeck=false`, `AutoRotate=false`, `PlatformStand=true`
2. Makes HumanoidRootPart non-collidable and massless, zeroes velocity
3. Iterates all Motor6D joints and for each:
   - Creates two Attachments (using Motor6D's C0/C1 CFrames)
   - Creates a BallSocketConstraint between them
   - Disables the original Motor6D
4. Enables collision on all R15 body parts (except HumanoidRootPart)
5. Sets HumanoidState to Physics
6. Applies random initial impulse and angular impulse for natural tumble

### BallSocketConstraint Settings

| Property | Value |
|----------|-------|
| LimitsEnabled | true |
| TwistLimitsEnabled | true |
| UpperAngle | 35 |
| TwistLowerAngle | -20 |
| TwistUpperAngle | 20 |
| MaxFrictionTorque | 10 |
| Restitution | 0 |

### Collidable Parts
All 15 R15 body parts are set to CanCollide=true: Head, UpperTorso, LowerTorso, all arm segments (Upper/Lower/Hand), all leg segments (Upper/Lower/Foot). HumanoidRootPart is always non-collidable.

### Cleanup (`Ragdoll:destroy()`)
Removes all created constraints and attachments, nils out references.

## Dependencies

- R15 character rig with Motor6D joints

## Used By

- [[RagdollService]] — creates Ragdoll instances on corpse clones
