---
tags: [client, localscript, combat, ui, audio]
path: game.StarterPlayer.StarterPlayerScripts.Combat.HitFeedbackClient
type: LocalScript
lines: 69
---

# HitFeedbackClient

Crosshair hitmarker, flash and kill-skull animation on confirmed hits.

## What it does
1. Drives the authored `PVE_CombatHUD.HitFeedback` frame (three `Triangle` arms, `FlashFrame`, `CrosshairDot`, `SkullMark`, `Sounds`).
2. On each `Remotes.Hit`, cancels running tweens, resets, and plays a new sequence (a token guards stale delayed tweens).
3. Plays the Body/BodyLayer or Headshot/HeadshotLayer sound pair with a small random pitch.
4. Pulses the dot and flash, and pushes the triangle arms out then back; headshots are red-tinted, larger and hold longer.
5. When `data.killed` is set, pops and fades the skull mark.

## Dependencies
- **Requires:** Nothing
- **Required by:** Nobody

## Connections
### RemoteEvents
| Remote | Direction | Other script |
|--------|-----------|-------------|
| `Remotes.Hit` | ← Server | [[CombatServer]] hit confirm (`headshot`, `killed`) |

### BindableEvents
None

### Direct require()
None
