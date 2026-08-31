# AnimateService

Forces the default R15 Animate script and animation IDs onto every character. Protects against Roblox or avatar bundles overwriting the Animate LocalScript with non-default animations.

**Path:** `game.ServerScriptService.WorldServices.AnimateService`
**Type:** ModuleScript (112 lines)
**Runs on:** Server

## How It Works

### Default R15 Animation IDs

| Animation | Asset ID(s) |
|-----------|-------------|
| idle | `507766666`, `507766951` (two variants) |
| walk | `507777826` |
| run | `507767714` |
| jump | `507765000` |
| fall | `507767968` |
| climb | `507765644` |
| swim | `507784897` |
| swimidle | `507785072` |

### Protection Flow (`protectCharacter`)

1. Calls `fixAnimate()` immediately on spawn
2. Calls again after 0.5s and 1s delays (catches late overwrites)
3. Watches `ChildAdded` — if anything named "Animate" is added, re-runs fix after 0.1s

### Animation Fixing (`fixAnimate`)

1. Only runs on R15 rigs
2. If the character's Animate script is missing or not a LocalScript, replaces it with the `DefaultR15Animate` clone from ServerStorage
3. Ensures an `idle` folder exists inside Animate
4. For each animation slot, calls `ensureAnim()` which:
   - Creates the Animation instance if missing or wrong type
   - Only overwrites the AnimationId if the current one is empty (preserves custom animations via `hasCustom` check)

### Key Behavior

- Respects custom animations — if a player/avatar has a non-empty AnimationId, it won't be overwritten
- The fallback `DefaultR15Animate` LocalScript is stored in ServerStorage and cloned as needed

## Dependencies

- ServerStorage.DefaultR15Animate — fallback Animate LocalScript template
- Players service

## Used By

- [[MainServer]] — Initialize() called at boot
- Replaces deprecated `ForceDefaultR15Animate` script
