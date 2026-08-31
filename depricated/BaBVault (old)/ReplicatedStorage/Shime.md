# Shime

UI shimmer/shine effect library. Creates an animated gradient overlay on any GuiObject to produce a loading-skeleton-style shimmer.

**Path:** `game.ReplicatedStorage.Shime`
**Type:** ModuleScript
**Runs on:** Client (required by other client modules)

## How It Works

1. Creates a `Frame` overlay inside the target GuiObject with `ClipsDescendants = true`
2. Adds a `UIGradient` with a transparent-to-white-to-transparent pattern
3. Tweens the gradient `Offset` from -1 to 1 to animate the shimmer across the element
4. Automatically matches parent `UICorner` radius and `UIPadding` offsets

## API

| Method | Description |
|--------|-------------|
| `Shime.new(parent, time?, style?, direction?, repeatCount?, reverses?, delayTime?)` | Create a new shimmer on a GuiObject |
| `:Play()` | Start the shimmer animation |
| `:Pause()` | Pause at current position |
| `:Cancel()` | Stop and hide the shimmer |
| `:GetFrame()` | Get the overlay Frame |
| `:GetGradient()` | Get the UIGradient |
| `:GetCorner()` | Get the UICorner (if created) |

## Used By

- [[CardFactory]] — creates shimmer on Legendary card SurfaceGui frames
- [[CardEffects]] — starts/stops legendary preview shimmer via cardData.shimmer
