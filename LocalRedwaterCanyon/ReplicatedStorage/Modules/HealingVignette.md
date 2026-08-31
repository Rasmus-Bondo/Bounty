---
tags:
  - shared
  - modulescript
  - client
  - ui
  - combat-feedback
path: game.ReplicatedStorage.Modules.HealingVignette
type: ModuleScript
lines: 124
---

# HealingVignette

The green pulse around the screen edges that reads as "something good just happened to you". One shared implementation behind every caller.

## What it does

1. `HealingVignette.play()` — the entire public surface. Tweens `BackgroundTransparency` on the four authored edge frames and returns immediately; callers never wait on it
2. The flash is **two beats, not one**: in over `IN_TIME` (0.16s) to `ALPHA` (0.28), dip to `BREATH_LOW`, back up to `BREATH_HIGH` over `BREATH_TIME` (0.32s), then out over `OUT_TIME` (0.45s). The second, smaller pulse is what makes it read as a heartbeat rather than a hit marker
3. **Resolves the authored GUI once and caches it.** `StarterGui.HealingVignetteGui` arrives in PlayerGui per spawn; the module finds its `Root` and collects the child Frames. The `WaitForChild` calls are **timed (10s), never infinite** — an older place copy without the authored GUI has to mean a missing flash, not a thread parked forever inside a pickup handler
4. **A shared overlap token.** Every call bumps a module-level token and each tween step checks it is still the current one, so a second flash arriving mid-sequence takes over cleanly instead of two sequences fighting over the same four frames. This only works because every caller comes through here — it is the main reason the effect is shared rather than copied
5. Warms the lookup on require (`task.spawn`), so the first real call does not pay the resolve

## Why it is a module

It lived inside HealthPackPickupFeedbackClient until 2026-08-10, when the onboarding tutorial wanted the identical flash on a completed step. Copying it would have meant two hand-tuned greens drifting apart, and would have broken the overlap token — picking up a health pack during a tutorial step is exactly the case the token exists for.

Client-only in practice despite living in ReplicatedStorage: it reads `Players.LocalPlayer`.

The frames are **authored**, not built here — `StarterGui.HealingVignetteGui` (`IgnoreGuiInset`, `ScreenInsets = None`, `ResetOnSpawn = false`, DisplayOrder 100000) holds `Root` with `TopGreen` / `BottomGreen` / `LeftGreen` / `RightGreen`, each a `Color3.fromRGB(74, 255, 84)` frame carrying a `UIGradient` rotated to fade inward from its own edge. They sit at rest fully transparent; this module only animates what is already on screen.

## Dependencies

- **Requires:** Nothing
- **Required by:** HealthPackPickupFeedbackClient (health pack pickup), TutorialClient (completed tutorial step)

## Connections

### RemoteEvents

None

### BindableEvents

None

### Direct require()

None
