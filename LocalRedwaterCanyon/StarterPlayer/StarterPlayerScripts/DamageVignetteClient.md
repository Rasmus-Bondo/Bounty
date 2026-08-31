---
tags:
  - client
  - localscript
  - ui
  - combat-feedback
path: game.StarterPlayer.StarterPlayerScripts.DamageVignetteClient
type: LocalScript
lines: 292
---

# DamageVignetteClient

Red screen-edge vignette that flashes on taking damage and pulses continuously at low health.

## What it does
1. Builds a full-screen GUI with four gradient-edge red frames (top/bottom/left/right) that fade from transparent at center to opaque at the screen edge
2. Watches `Humanoid.HealthChanged`; on any health decrease, flashes the vignette to an alpha proportional to damage taken (scaled against `MAX_DAMAGE_REFERENCE` = 75), fading in over 0.04s and out over 0.55s
3. Below 30% health, starts a continuous pulse tween (0.85s in/out) between low alpha and near-zero, looping until health recovers above the threshold or the player dies
4. Resets vignette alpha to 0 and stops the pulse on death or character removal

## Dependencies
- **Requires:** Nothing
- **Required by:** Nobody

## Connections
### RemoteEvents
None

### BindableEvents
None

### Direct require()
None
