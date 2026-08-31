---
tags:
  - client
  - localscript
  - ui
  - hud
  - gamemode
path: game.StarterGui.DominationGui.DominationClient
type: LocalScript
lines: 410
---

# DominationClient

Drives the authored `StarterGui.DominationGui` Domination HUD (DOMINATION_SPEC 8.2): two team score
bars with "137 / 500" readouts, the three capture dials under the round timer, and the local
player's own capture bar. Built 2026-08-22; the dials replaced the per-pad bars and their
"… IS CAPTURING AN OBJECTIVE" announcers on 2026-08-23.

## What it does
1. Enables the ScreenGui (authored `Enabled = false`, `ResetOnSpawn = false`, `DisplayOrder 7`,
   `DeviceSafeInsets`) only while the workspace `Gamemode` attribute is `domination` **and**
   `ReplicatedStorage.RoundActive` is true — the same gate the RoundStatusGui score chips use, which
   this panel replaces in that mode. The gate is re-asserted every Heartbeat, not just on attribute
   changes: RoundClientController's ScreenGui sweep defaults an unknown GUI to *visible*, which put
   this whole panel over Free-for-All and Team Deathmatch on every respawn. `DominationGui` is now
   in that script's `SWEEP_EXEMPT_GUI_NAMES` as well, but that set matches by name and this loop
   cannot be raced by anything.
2. Resolves `Canvas.1Team` as the viewer's OWN side and `Canvas.2Team` as the enemy's through
   `TeamView.localTeam()` (unstamped reads as blue, matching the authored blue gradient on 1Team).
3. Score: `ProgressText = "<score> / <scoreLimit>"` from the `TeamScoreRed` / `TeamScoreBlue`
   workspace attributes and `GamemodeConfig.get("domination").scoreLimit`; `BarFill.Size.X.Scale =
   score / limit`, **negative** on 2Team because its fills are authored from the right edge.
4. Dials: the three `CapturePointClaimed` frames, keyed by their `Letter` attribute (the frames are
   named 1A / 2B / 3C so the grid sorts them left to right — that ordering is layout, not identity).
   Each fills clockwise from twelve like a cooldown, empty at neutral and a full disc at ownership,
   coloured by whichever side the signed meter is currently on — so a steal drains the dial to
   nothing, swaps colour and fills the other way.
5. Dial motion is **integrated, not interpolated**. The meter lands in 0.05 steps on an uneven beat
   (the server quantises before publishing, so a lone attacker emits at 0.25s, 0.5s, 0.25s), so both
   drawing it raw and estimating a speed from the gap between values tick visibly. The server
   publishes `DomVelocity_<L>` instead — signed, and unlike `DomRate_<L>` it covers the decay leg and
   is zero on arrival — and this script integrates it per frame, clamped to within one wire step of
   the published meter in both directions. With no velocity (a round reset, a mode swap, a mid-round
   join) it eases instead, because that is a jump rather than a motion.
6. Capture bar: visible only while `LocalPlayer.DomPad` names a pad that is not already the viewer's
   at the endpoint. Fill and text both run 0% → 100% across the current capture's LEG rather than
   across the meter — a steal off the enemy spans -1 → +1 and reads 50% at neutral, a nobody's pad
   spans 0 → +1 and so fills twice as fast for the same push speed. The leg is latched when the bar
   appears (-1 if the enemy still owns the pad or the meter is still on their side, else 0) because
   the rules module clears `DomOwner_<L>` the instant a steal crosses neutral, and re-deriving it
   per frame would rebase the bar from 50% back to 0% mid-steal. Text is `CONTESTED` or
   `CAPTURING : NN%`, floored so 100% means captured. Both read the DIAL's animated value rather
   than the wire, redrawn every frame with only the readout throttled to 10 Hz — which is also the
   only way the bar and the dial above it can agree.
7. One deferred render per frame on any `Dom*` / `TeamScore*` / `Gamemode` attribute change,
   `RoundActive.Changed`, the viewer's `DomPad` change, and `TeamView.onChanged`.

## How a dial is drawn
Worth reading before touching the `Circle.Sweep` instances, because three obvious constructions all
fail and the failures only show on a phone, where these render at about 25 px:

- **Not a UIGradient with a hard stop.** Exact in Studio and wrong on a handset — the phone
  interpolates the transparency sequence instead of honouring the stop, and the fill arrives as a
  soft crescent hugging the rim with white through the middle. Swapping the stop for a linear ramp
  in Studio reproduces the phone's picture exactly.
- **Not a rotated half-disc inside a clipping Frame.** `ClipsDescendants` does not clip a rotated
  descendant, nor one under a rotated ancestor, so the disc leaks across the whole screen.
- **Not a rounded disc composited inside a CanvasGroup.** That clips correctly, but a CanvasGroup
  renders to an integer-sized texture that the rotation then resamples, so the disc's curved edge
  lands a fraction of a pixel off the track's edge behind it and the rim fringes all the way round.

What it is: `Sweep` (CanvasGroup, dial-sized, `UICorner` 1,0) → `Gate` (CanvasGroup, clipped to half
the dial) → `Pivot` (twice the dial, centred on it, `Rotation` = the sweep angle) → `Fill` (the left
half of Pivot, a plain rectangle with no rounding). Fill is a half-**plane** rather than a half-disc,
so gate ∩ half-plane is a sector with square outer corners, and Sweep rounds it off — `UICorner`
rounds a CanvasGroup's *composited content*, so the pie's outer edge is cut by the same
screen-resolution rounding that draws the white track behind it and cannot disagree with it. The only
soft edge left is the straight radial cut, which is the edge that is moving. Pivot is twice the dial
and centred on it because `Rotation` turns an element about its own **centre**, not its AnchorPoint.
`RightGate` carries 0–50% and `LeftGate` 50–100%, both at 360 × fraction, and `LeftGate` carries the
single pixel of gate overlap because it is only ever visible once the right half is already full. A
full dial short-circuits all of it — the `Circle`'s own background with both gates hidden — which is
the state an owned pad rests in for most of a round.

## Layout
The dial row sits between the two score panels, and the gap is held open by `Canvas.Spacer` rather
than by layout padding. The row is sized off screen **height** (`0.0284H + 19`, which is what keeps
the dials the same size on every aspect) while a `UIGridLayout`'s padding can only be a fraction of
the parent's **width** — the two only agree near 16:9, and on a 4:3 tablet the dials grew into the
bars. The Canvas therefore uses a `UIListLayout` with a `Spacer` whose `SizeConstraint` is
`RelativeYY`, taking *both* axes from the parent's height: `1.0729 × canvas height + 77` is the dial
span plus clearance at any resolution. Verified 667×375 through 2560×1440.

## Dependencies
- **Requires:** [[GamemodeConfig]], [[TeamView]]
- **Required by:** Nobody

## Connections
### RemoteEvents
None

### BindableEvents
None

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[GamemodeConfig]] | `get("domination").scoreLimit` | The "/ 500" half of the readout |
| [[TeamView]] | `localTeam()`, `color()`, `onChanged()`, `PLATE` | Which panel is "yours", the dial fill colour, and the repaint when the stamp lands |

Reads (no edges): workspace attributes `Gamemode`, `TeamScoreRed`, `TeamScoreBlue`, `DomOwner_*`,
`DomMeter_*`, `DomVelocity_*`, `DomContested_*` (published by Gamemodes.Domination and TeamService),
`Player.DomPad`, and the `ReplicatedStorage.RoundActive` BoolValue. `DomCapturing_*` and `DomRate_*`
are no longer read by anything: the announcers went with the `Captures` frames on 2026-08-23 and the
seconds-left countdown became a percentage on 2026-08-24. Both are still published.
