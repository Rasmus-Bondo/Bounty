---
tags: [client, localscript, ui, hud]
path: game.StarterPlayer.StarterPlayerScripts.HunterGuiClient
type: LocalScript
lines: 426
---

# HunterGuiClient

Client-side HUD manager. Creates the game UI from a template and manages ammo display, skill cooldowns, and mobile ability buttons.

## What it does

### UI Setup
- Clones `TemplateGameGui` from `ReplicatedStorage.GuiTemplates.HunterGui.Template` into PlayerGui
- Sets `ResetOnSpawn = false` so it persists across respawns
- Displays player name

### Ammo Display
- Shows 6 bullet icons that animate in/out (Back easing) when ammo changes
- Rich text ammo counter with pulse animation on change
- Format: `{current} / 6`

### Skill Cooldowns
- Skill1 (Dash) and Skill2 (Fan Fire) each have a fill-based cooldown indicator
- `FrameBorderCooldown` shrinks over the cooldown duration via linear tween
- Countdown text updates every 0.1s

### Mobile Buttons
- Creates invisible `TextButton` overlays on Skill1 and Skill2 frames
- Only visible when `TouchEnabled` is true
- Fires `DashRequested` / `Skill2Requested` bindables back to [[FPSRevolverClient]]

## Dependencies

- **Requires:** Nothing
- **Listens to bindables:** `AmmoChanged`, `Reloaded`, `DashCooldownStarted`, `Skill2CooldownStarted` (from [[FPSRevolverClient]])
- **Fires bindables:** `DashRequested`, `Skill2Requested` (consumed by [[FPSRevolverClient]])
- **Creates UI:** `TemplateGameGui` in PlayerGui (read by HighNoonClient for charge UI)
