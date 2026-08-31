# ServerStorage

Server-only storage for assets that clients cannot access directly. Contains the revolver weapon tool (cloned into player backpacks), the default R15 animation script (cloned onto characters), and animation editor save data.

**Path:** `game.ServerStorage`

## Contents

### Scripts
- [[DefaultR15Animate]] — Default Roblox R15 animation controller, cloned onto player/bot characters

### Weapon Tools
- [[BanditGun Tool]] — Current revolver weapon (Tool) with all combat scripts and animated model
- [[OldGun]] — Deprecated backup of an earlier BanditGun version

### Non-Script Assets
- **RBX_ANIMSAVES** (Model) — Roblox Animation Editor save data for rigs and revolver animations (ClearRevolverBarrel, ReloadBodyTest, RollingAnimationTest). Not used at runtime.
