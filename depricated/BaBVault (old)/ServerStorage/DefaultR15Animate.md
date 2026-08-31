# DefaultR15Animate

Standard Roblox R15 humanoid animation controller. Stored in ServerStorage and cloned onto player characters and bot rigs to drive all movement animations.

**Path:** `game.ServerStorage.DefaultR15Animate`
**Type:** LocalScript (~550 lines)
**Runs on:** Client (after being cloned into a character model)

## What It Does

Manages all standard character animations by listening to Humanoid state changes and playing the appropriate animation tracks:

- **Movement:** idle (3 weighted variants), walk, run, swim, swimidle, climb
- **Actions:** jump, fall, sit, toolnone, toolslash, toollunge
- **Emotes:** wave, point, dance (3 variants), laugh, cheer

## How It Works

1. On load, reads animation IDs from child StringValue objects (e.g., `walk`, `run`, `idle`)
2. Builds an `animTable` mapping state names to weighted animation lists
3. Listens to `Humanoid.Running`, `Humanoid.Jumping`, `Humanoid.FreeFalling`, etc.
4. Crossfades between animation tracks with configurable blend times
5. Supports `HumanoidDescription` overrides — replaces default anim IDs if the character has custom animations
6. Scales animation speed based on character scale via `ScaleDampeningPercent`

## Child Objects

| Child | Type | Purpose |
|-------|------|---------|
| PlayEmote | BindableFunction | Allows scripts to trigger emotes by name |
| ScaleDampeningPercent | NumberValue | Controls speed scaling relative to character size |
| idle, walk, run, jump, fall, climb, sit, swim, swimidle, toolnone, toolslash, toollunge, wave, point, dance, dance2, dance3, laugh, cheer, mood | StringValue | Animation ID containers with child Animation objects |

## Used By

- [[AnimateService]] — clones this script into player characters on spawn
- [[BotSpawner]] — clones this script onto bot rigs (via [[BotRig]] which has its own copy)
