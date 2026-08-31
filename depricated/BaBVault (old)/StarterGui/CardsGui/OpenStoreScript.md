# OpenStoreScript

Switches the camera to a fixed shop viewpoint with mouse-driven parallax. Pauses parallax when previewing a card.

**Path:** `game.StarterGui.CardsGui.OpenStoreScript`
**Type:** LocalScript (69 lines)
**Runs on:** Client

## How It Works

### On Open (OpenButton click)
1. Sets camera to `Scriptable` mode
2. Locks camera CFrame to `workspace.ShopCameraPoint`
3. Enables parallax loop

### Per-Frame Parallax (RenderStepped)
1. If `PreviewingCard.Value` is true: smoothly lerps offset back to zero (camera centers)
2. Otherwise: calculates mouse position relative to screen center
3. Applies offset using `PARALLAX_STRENGTH_X/Y` multiplied by normalized mouse position
4. Lerps current offset toward target for smooth movement

### On Close (CloseButton click)
1. Disables parallax
2. Restores camera to `Custom` mode with Humanoid as subject

## Parallax Constants

| Constant | Value | Purpose |
|----------|-------|---------|
| PARALLAX_STRENGTH_X | -2.5 | Horizontal camera shift range |
| PARALLAX_STRENGTH_Y | -1.5 | Vertical camera shift range |
| PARALLAX_SMOOTHNESS | 0.05 | Lerp factor per frame |

## Dependencies

- `workspace.ShopCameraPoint` — Part defining shop camera position/angle
- `CardsGui.PreviewingCard` — BoolValue, pauses parallax during card flip
- Player character Humanoid — restored as camera subject on close

## Used By

- [[CardsGui]] — open/close buttons trigger this script
