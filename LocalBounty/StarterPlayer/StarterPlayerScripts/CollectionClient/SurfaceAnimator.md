---
tags: [client, modulescript, ui, tween, animation]
path: game.StarterPlayer.StarterPlayerScripts.CollectionClient.SurfaceAnimator
type: ModuleScript
lines: 206
---

# SurfaceAnimator

Animated show/hide for a SurfaceGui. Tweens both UIScale and per-descendant transparency (background, text, image, UIStroke) so the panel pops in and fades back out cleanly. First-pass values are cached so the "shown" state can be restored exactly regardless of original transparency.

## What it does
1. `SurfaceAnimator.setVisible(surfaceGui, isVisible)` is the only public entry point
2. Locates a root inside the SurfaceGui (Canvas if present, otherwise first descendant GuiObject)
3. Caches each descendant's original transparency values on first sight (BackgroundTransparency, TextTransparency/TextStrokeTransparency, ImageTransparency, UIStroke.Transparency)
4. Maintains a per-SurfaceGui `animationTokens` counter so a new call invalidates pending delayed tasks from a previous call
5. Open: enables the gui, snaps all descendants to transparency 1, tweens UIScale from `SURFACE_OPEN_START_SCALE` overshooting `SURFACE_OPEN_OVERSHOOT_SCALE` (Back/Out) then settling to `SURFACE_FINAL_SCALE`, and tweens each descendant back to its cached transparency
6. Close: tweens all descendants to transparency 1, tweens scale to `SURFACE_CLOSED_SCALE`, then disables the gui after `SURFACE_CLOSE_DURATION` (only if the token still matches)
7. Lazily creates a single `UIScale` named `CollectionSurfaceScale` on the root if one doesn't exist

## Dependencies
- **Requires:** [[Config]], [[Tween]]
- **Required by:** CollectionClient

## Connections
### RemoteEvents
None

### BindableEvents
None

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[Config]] | surface animation constants | Open/close durations + scale targets |
| [[Tween]] | `Tween.run()` | Cancel-on-replace tween of UIScale and transparency properties |
