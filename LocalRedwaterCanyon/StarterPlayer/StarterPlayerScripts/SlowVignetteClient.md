---
tags:
  - client
  - localscript
  - ui
  - hud
  - combat
path: game.StarterPlayer.StarterPlayerScripts.SlowVignetteClient
type: LocalScript
lines: 158
---

# SlowVignetteClient

The blue edge vignette that reads as "you are slowed". Builds its own `SlowVignetteGui` in code and
drives it from the local character's `StatusSlowed` attribute, suppressed for the duration of a
stun.

## What it does
1. Builds `SlowVignetteGui` at `DisplayOrder 99998`, `ScreenInsets = None`, `ResetOnSpawn = false`,
   with four gradient-faded edge frames in `BLUE` (35, 145, 255) at rest fully transparent.
2. Fades them to `ACTIVE_ALPHA` 0.38 over 0.12s when the local character reads `StatusSlowed`, and
   back out over 0.18s when it clears. `StatusSlowed` is published by HunterMovement, which is the
   only thing that can see every live slow at once.
3. **Suppresses the blue entirely while `StatusStunned` is set** (2026-08-27). A stun IS a 100%
   slow — HunterStatusEffects:ApplyStun applies one so the StatusSlowed hand-off keeps working — so
   without this the blue edges sat under StunnedGui's yellow ones for the whole 2.5s slam.
4. The suppression **latches** rather than reading the stun flag each time. The two attributes are
   retired by different loops off the same expiry — StatusSlowed by HunterMovement's 10Hz
   enforcement pass, StatusStunned by HunterStatusEffects's own expire loop at 0.15s — so whenever
   the stun flag wins that race a plain read blinks blue on for up to a tick, right as the player
   recovers. The latch is set while stunned and released only once **both** read false, which is
   self-terminating and needs no grace constant.
5. Rebinds on `CharacterAdded`, clearing the latch and both attribute connections; `CharacterRemoving`
   disconnects, clears the latch and hides the frames instantly.

## The trade in the latch
An independent slow that lands *during* a stun — Vesper's pinning round at 0.3s, Bram's shrapnel —
stays hidden until it expires rather than reappearing on recovery, because `StatusSlowed` is a
single boolean covering all live slows and never goes false in that window. Every such slow is well
under a second, which is cheaper than a blue blink at the end of roughly 40% of stuns.

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

Reads (no edges): the local character's `StatusSlowed` attribute, published by HunterMovement, and
its `StatusStunned` attribute, written by HunterStatusEffects:ApplyStun — both in
ReplicatedStorage.Hunters.Shared. SprintController watches StatusSlowed as well. The yellow vignette
this one defers to belongs to StunnedController.
