---
tags:
  - client
  - localscript
  - hud
  - progression
path: game.StarterPlayer.StarterPlayerScripts.HunterXPBarClient
type: LocalScript
lines: 271
---

# HunterXPBarClient

Drives the HUD's XP bar under the health bar and the `LV. N` label beside the player name, on every hunter HUD.

## What it does

1. Binds to any ScreenGui in PlayerGui whose `Canvas.PlayerFrame` carries `PersistentXPBar` (with `Fill`, `ProgressTrail`, `ImpactScale`), on join and on every `ChildAdded`, so the four hunter HUD clients and a mid-match hunter switch need no wiring. `PlayerFrame.PlayerLevel` is picked up when present
2. Reads two Player attributes and nothing else: `Level` (DataService `updateLeaderstats`) and `LevelProgress` (0..1 through the current level, published by ProgressionService, which owns the curve). Both change signals feed one deferred refresh
3. A HUD that appears snaps to the current state; only changes after it exists animate
4. A gain in the same level: the translucent trail tweens ahead, the yellow fill follows 0.13 s later, the bar pops through its `ImpactScale`, and the trail fades out
5. A level-up: the bar fills to full, shakes and flashes, then restarts from empty at the level the attributes show at that moment, so a multi-level jump is one flash and a progress update that lands mid-sequence is kept. Updates are held off until the restart, then re-read. Timed with fixed delays, not a `Tween.Completed` chain, so a HUD rebuilt mid-sequence cannot strand it
6. XP going down (a data correction) snaps without animation
7. Silent: the level-up sound belongs to LevelRewardClient's card, which fires off the same level-up

The two instances are the design place's, added to both `ReworkedHunterGui` templates by the `xpbar` part of `NEWGUI_PORT_RESTYLE.luau`. They are authored empty (no fill, `LV. 1`).

## Dependencies

- **Requires:** Nothing
- **Required by:** Nobody

## Connections

### RemoteEvents

_None_

### BindableEvents

_None_

### Direct require()

_None_
