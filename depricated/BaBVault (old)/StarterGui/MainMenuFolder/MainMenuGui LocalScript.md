# MainMenuGui LocalScript

Drives all main menu hover animations — gradient color sweeps, scale tweens, arsenal gun flick physics, play button scaling, and main menu music management.

**Path:** `game.StarterGui.MainMenuFolder.MainMenuGui.CanvasBottom.LocalScript`
**Type:** LocalScript (533 lines)
**Runs on:** Client

## Features

### 1. Gradient Hover Effect
- Each store frame (ArsenalFrame, HuntersFrame, etc.) has a TextButton with a Header
- On hover: a UIGradient sweeps from left to right (offset -1 → +1), painting a gold highlight
- On leave: gradient sweeps back to hidden position
- Applied to both text labels and image labels within each frame

### 2. Scale Animation
- Store frame buttons scale up to 1.06x on hover, back to 1.0 on leave
- Special icon images scale to 1.08x independently

### 3. Arsenal Gun Flick
- ArsenalFrame has two gun icons (IconImage + IconImage2)
- On hover: 4-phase physics animation:
  1. Pull back (0.16s, Back easing) — guns rotate outward 20°
  2. Bounce (0.08s, Sine) — settle to 15°
  3. Snap forward (0.07s, Quart) — rotate inward 12°
  4. Settle (0.14s, Sine) — return near rest with 4° residual
- On leave: smooth reset to original position/rotation

### 4. Play Button & Change Mode
- PlayButton scales to 1.05x on hover
- ChangeModeButton + ChangeModeButtonText scale to 1.04x together

### 5. Menu Music
- Plays looping `MainMenuMusic` sound when MainMenuGui ScreenGui is enabled
- Stops when ScreenGui is disabled (e.g., entering game)

## Animation Constants

| Constant | Value | Purpose |
|----------|-------|---------|
| hoverScale | 1.06 | Store frame button scale |
| iconHoverScale | 1.08 | Special icon scale |
| playButtonHoverScale | 1.05 | Play button scale |
| changeModeHoverScale | 1.04 | Mode button scale |
| hoverColor | (246, 157, 22) | Gold gradient highlight color |
| hoverTweenInfo | 0.12s Quad Out | Hover-in timing |
| leaveTweenInfo | 0.2s Quint Out | Hover-out timing |
| gradientTweenInfo | 0.28s Quart Out | Gradient sweep in |
| gradientLeaveTweenInfo | 0.3s Quart Out | Gradient sweep out |

## Sound Assets

| Sound | Location | Description |
|-------|----------|-------------|
| ClickSFX | CanvasBottom | Cloned and played on each hover |
| MainMenuMusic | CanvasBottom | Looping background music |

## Dependencies

- MainMenuGui ScreenGui structure — store frames, play frame, icons
- ClickSFX and MainMenuMusic sounds in CanvasBottom

## Used By

- Runs automatically in PlayerGui when the player joins
