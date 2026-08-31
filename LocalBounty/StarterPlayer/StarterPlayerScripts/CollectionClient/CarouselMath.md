---
tags: [client, modulescript, ui, math]
path: game.StarterPlayer.StarterPlayerScripts.CollectionClient.CarouselMath
type: ModuleScript
lines: 77
---

# CarouselMath

Pure math helpers for the circular carousel. No Roblox instances touched — just numbers and Vector3s.

## What it does
1. `clamp(value, min, max)` and `wrapIndex(index, total)` (1-based ring index) and `roundToNearest(value)`
2. `signedCircularOffset(index, position, total)` — shortest signed offset from `position` to `index` on a ring of `total` slots
3. `circularDistance(index, position, total)` — magnitude of the signed offset
4. `targetTransparency(distance, visibleRange)` — banded transparency curve (0 / 0.35 / 0.7 / 1) used to fade carousel buttons by distance
5. `targetScale(distance, normalScale, selectedScale)` — Vector3 lerp from normal to selected scale as distance approaches 0
6. `applyBounce(scale, bounceProgress, shrinkAmount)` — sine-curve shrink applied to a scale during the bounce animation
7. `stableAnimationOffset(seedText, maxOffset)` — deterministic 0..maxOffset hash so each viewport icon's idle animation starts at a different time

## Dependencies
- **Requires:** Nothing
- **Required by:** CollectionClient, ViewportIcon, Reel

## Connections
### RemoteEvents
None

### BindableEvents
None

### Direct require()
None
