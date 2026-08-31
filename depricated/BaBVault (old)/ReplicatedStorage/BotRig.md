# BotRig

Pre-built R15 character model used as a template for spawning AI bots. Complete humanoid rig with all body parts, Motor6D joints, and the default Roblox R15 Animate script.

**Path:** `game.ReplicatedStorage.BotRig`
**Type:** Model

## Structure

- **Humanoid** — standard R15 humanoid with Animator, scale values, and HumanoidDescription
- **Animate** (LocalScript) — default Roblox R15 animation controller with all standard animation sets (walk, run, jump, climb, fall, idle, dance, etc.)
- **Body Parts** — full R15 rig: Head, UpperTorso, LowerTorso, Left/Right Upper/Lower Arm/Leg, Left/Right Hand/Foot
- **HumanoidRootPart** — root part with RootRigAttachment

## Used By

- [[BotSpawner]] — clones this model to spawn test bots at the BotSpawner part in workspace
