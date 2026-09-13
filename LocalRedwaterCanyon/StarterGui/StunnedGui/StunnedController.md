---
tags:
  - client
  - localscript
  - ui
  - hud
  - combat
path: game.StarterGui.StunnedGui.StunnedController
type: LocalScript
lines: 599
---

# StunnedController

Plays the full-screen crowd-control overlay for both halves of a Bram Breach Charge: a yellow edge
vignette plus a label reading **PINNED** while the local character is being carried and **STUNNED**
when it is slammed into a wall (or caught in a Bram-vs-Bram clash). Only the stun half gets the
screen shake, camera kick and phone haptics. Authored in the "Bounty - UI Update" design place and
imported verbatim 2026-08-27, extended to the carry 2026-08-28; the same GUI and script ship in
Frostbite Claim.

## What it does
1. Binds to the local character and watches **two** attributes — `StatusStunned` and
   `StatusPinnedUntil` — playing the sequence whenever either enters a state the last sequence did
   not already show. The bind also reads them once at level, not only on the edge: a character
   replicating to a client that joined mid-carry arrives with the attribute already set and no
   change signal ever follows.
2. Uses the attributes rather than a RemoteEvent because each has exactly one writer —
   HunterStatusEffects:ApplyStun for the stun, [[HunterActionLock]].AcquirePin for the pin — and
   between them those cover every way a charge can touch you: a player Bram's carry and slam
   through BreachChargeService, a bot Bram's through BotCombat, and the clash. A remote would have
   to be fired from all of them.
3. Requires [[HunterActionLock]] for `IsPinned` rather than reading `StatusPinnedUntil` directly.
   The pin is a `Workspace:GetServerTimeNow()` **deadline**, not a flag, and compared against
   `os.clock()` or `tick()` it would read as "never pinned" on every client. Polling that predicate
   is also what ends the carry overlay when the deadline lapses without a release.
4. Treats a carry that ends in a slam as **one** sequence: the same label swaps its word on the
   impact overshoot and the vignette never drops between the two states. That is only safe because
   the server applies the stun before releasing the pin, so the victim never sees an unlocked frame
   in between.
5. Shapes the vignette differently per half. A carry rises to `VIGNETTE_PIN_TRANSPARENCY` (0.45)
   over 0.18s and **holds**, because the ride has no fixed length — the deadline runs to
   `Time + PinGraceBuffer` (3.8s) but a victim grabbed late is slammed within half a second. A stun
   snaps to `VIGNETTE_PEAK_TRANSPARENCY` (0.3) and decays over 2.75s, tuned to run out about when
   the 2.5s slam stun does. The authored frames go fully opaque at the screen edge, which washes the
   whole viewport yellow over Redwater's orange terrain; the caps hold them back to a border so the
   label stays the brightest thing on screen. The gradients still do the falloff.
6. Clones `Canvas.TextLabel` into the authored `StunOverlay` frame and sizes the clone in pixels
   from `Canvas.AbsoluteSize`, falling back to 300x90 if the layout has not settled (the ScreenGui
   is disabled during intermission, and a disabled ScreenGui reports zero). The label is cloned
   rather than built. Since 2026-09-13 it is flat white with no UIStroke or UIGradient, per the
   NEWGUI design; its outline is the legacy text stroke that the alpha helpers drive.
7. Scales each copy's box width by its character count against `STUN_TEXT`. The label is
   `TextScaled` inside a box authored for the 7-character STUNNED, so the 6-character PINNED in an
   unscaled box would draw about 16% taller than the word it hands over to — the text would appear
   to shrink on the slam.
8. Runs a shorter streak-in for the carry — two 0.055s hops and a 0.11s rush — then parks the label
   in the centre with a slow breathe (±5% scale, ±1.6°) for the rest of the ride. The stun keeps the
   original three 0.075s hops and 0.14s rush. The carry's hops abort the moment the stun lands, so a
   victim grabbed and slammed inside a quarter-second still gets the impact rather than a stranded
   streak.
9. Impacts on the stun only: a 0.095 / 0.07 / 0.15 overshoot-compress-rebound, then a 2s shake at
   the centre, ended early the moment `StatusStunned` clears so the 1.5s clash stun does not get a
   2.9s overlay. `SHAKE_DURATION` caps it rather than the whole sequence being scaled to the stun —
   the streak-in and pop-out are hand-tuned beats, not fractions of a duration.
10. Shakes the camera through `Humanoid.CameraOffset` on non-touch devices, saved and restored
    around the sequence. Nothing else in Redwater writes that property — LandingImpactClient
    multiplies `camera.CFrame` instead — so a plain save/restore is safe.
11. Fires mobile haptics on touch devices through **both** HapticService:SetMotor and a looped
    HapticEffect (see below). Neither fires during a carry.
12. Tweens the vignette out over 0.25s on teardown rather than snapping it: a clash stun ends well
    before the 2.75s fade-in has run out, and an instant hide reads as a dropped frame.
13. Wraps the whole sequence in a `pcall` with teardown after it — the label destroy, the camera
    restore and the haptics stop all run whether it completed or threw. `ResetOnSpawn` is false on
    this GUI, so a stranded `playing` flag would otherwise kill every later overlay for the session.
14. Re-checks the attributes once after teardown and replays only if the current state differs from
    the one just shown. The `playing` guard is genuinely open while state can still change — the
    shake caps at 2s inside a 2.5s stun and the pop-out runs another 0.19s — so a slam landing
    during a carry's pop-out, or a fresh grab straight after a stun, would otherwise be swallowed
    with no attribute change left to re-fire it. An unchanged state does not replay: that is the
    same stun still running.

## Mobile haptics — TEMPORARY, pending a DEV soak
Both haptic APIs fire on a touch device, because neither can be verified from Studio and the docs
disagree. HapticService:SetMotor is what the design place's prototype used and that service's class
description does claim mobile support — but it is marked superseded and SetMotor's own page steers
to `Gamepad1`. HapticEffect is the current API and the only one carrying an explicit "Android and
iOS phones" support list. Each is a silent no-op where unsupported, so running both costs nothing.

Two `[StunHaptics]` lines report the outcome: a support probe printed once at spawn (so a mobile
playtest can read the flags without having to get stunned first), and a per-stun line naming which
paths actually ran. After the DEV soak, delete the losing path, the probe log and the comment
around them.

## Layering and sweep behaviour
The ScreenGui is `Enabled = true`, `ResetOnSpawn = false`, `DisplayOrder 100000`, `ScreenInsets =
None` with `IgnoreGuiInset` — the same shape as HealingVignetteGui, whose authored vignette frames
this one mirrors. It needs no entry in RoundClientController's sweep sets: it ships enabled, so both
the snapshot-restore half and the unknown-GUI-defaults-to-visible half land on `true`.

`StunOverlay` is an authored full-bleed frame at `ZIndex 20`, above the `Canvas` and `Root` at 1.
The clone's ZIndex is derived from it, so the label always draws over the vignette.

## Dependencies
- **Requires:** [[HunterActionLock]]
- **Required by:** Nobody

## Connections
### RemoteEvents
None

### BindableEvents
None

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[HunterActionLock]] | `IsPinned()` / `IsStunned()` / `STUN_ATTRIBUTE` / `PIN_ATTRIBUTE` | Reads the two state attributes through their shared predicates, so the pin's server-clock deadline comparison is not duplicated here |

Reads (no edges): the local character's `StatusStunned` attribute, written by
HunterStatusEffects:ApplyStun in ReplicatedStorage.Hunters.Shared, and its `StatusPinnedUntil`
deadline, written by BreachChargeService for a player Bram and BotCombat for a bot one. The
durations it is tuned against — `SlamStunDuration` 2.5, `ClashStunDuration` 1.5, `Time` 3 and
`PinGraceBuffer` 0.8 — live in Bram's GrudgekeeperConfig and are not read here. SlowVignetteClient
watches the same stun attribute to suppress its blue vignette while this one is up.
