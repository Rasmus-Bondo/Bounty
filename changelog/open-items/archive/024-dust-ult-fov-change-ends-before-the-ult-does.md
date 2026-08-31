# 24 — Dust ult FOV change ends before the ult does

[Open items index](../../OPEN-ITEMS.md) · [Conventions](../../CONVENTIONS.md)

---

**Status:** **VERIFIED by the owner 2026-08-04**, on the owner's sign-off rather than a reported
playtest run · **Sev:** P2 · **Area:** Redwater — Dust · In Studio, **not yet published**

**Reported:** When High Noon activates, the FOV narrows (scoped-in feel), but the FOV snaps back to normal before the ult actually expires. The player feels like the ult has ended while they still have targeting active, which is confusing.

**All three original notes were wrong, and it is worth knowing why before touching this area again.**
Nothing restores the FOV early. **No timer, tween duration or ult-end signal is involved at all** — and
`fovController:Reset()` is already correctly tied to the ult-end event (`HighNoonClient:388` on the
server's `End`, plus `:223` on the local death/respawn reset and `:455` on hunter-switch teardown), so
the third note's early-end concern was already satisfied. The FOV is **abandoned**, not restored.

**Cause (2026-08-04): Dust has two unconditional writers of `camera.FieldOfView`, and the ultimate's
one gives up first.** This is precisely the failure `HunterImplementationGuide` warns about, which is
why it went unnoticed — the guide's rule was being followed in spirit and the second writer did not
look like one.

- `HighNoonFOV:BezierTo` drives a `RunService.RenderStepped` connection, and **disconnects itself the
  frame its tween lands** (`StopTween` at `alpha >= 1`). It never *holds* the tight FOV; it relies on
  nobody else writing.
- `RevolverCameraEffects:Update` wrote `camera.FieldOfView` **every frame unconditionally**, driven
  from `FPSRevolverClient`'s `BindToRenderStep("UpdateViewModel", Camera + 1)`.

**Render order decides it, and it was measured rather than assumed** — a probe binding both in this
place reports `BindToRenderStep(Camera+1) -> RenderStepped` every frame. So while HighNoonFOV is
connected it writes *second* and wins, which is why the zoom is visible and the bug looks like a
restore. The instant it disconnects, `RevolverCameraEffects` is the only writer left.

**The snap is instantaneous, not an ease**, because `FPSRevolverClient:1187` calls
`cameraEffects:ResetFOV()` on High Noon `Start` — so `CurrentFOV` is already parked on `DefaultFOV`
and the very next frame writes it outright. Timings: the intro is `ZoomOutTime 0.6 + ZoomInTime 2.1`
= **2.7s**, against `HighNoonServerConfig.Timing.MaxHoldTime` = **5s**. The tight FOV was therefore
held for roughly **one frame** out of a five-second ultimate.

**Fix (2026-08-04, `RevolverCameraEffects` only — no call-site changes).** Gave Dust's compositor the
release behaviour that Vesper's and Bram's already have, **and which were derived from this module
without it**: it now only writes `FieldOfView` while the composed target (`TargetFOV +
SprintFOVOffset`) or the current value is more than `FOV_IDLE_EPSILON` (0.05) from `DefaultFOV`, and
otherwise clears a new `FOVActive` flag and stops writing. On the next active frame it re-captures
its smoothing origin from `camera.FieldOfView`, so resuming eases from where the camera actually is
instead of snapping from a stale value. `ResetFOV` clears the flag as well, since it writes a known
value directly. The magic `14` and the epsilon are now named constants (`FOV_SMOOTH_SPEED`,
`FOV_IDLE_EPSILON`).

**Why that alone is sufficient, and why no flag had to be plumbed between the two modules.** During
High Noon, Dust is idle *by construction*: `Start` cancels sprint and `SetCanSprintCheck`
(`FPSRevolverClient:780`) blocks it for the duration, so `SprintFOVOffset` is exactly 0 —
`SprintController:Cancel` assigns `_sprintAlpha = 0` outright and its decay uses `math.max(0, ...)`,
so it genuinely reaches zero rather than approaching it; `canShoot` is false and `OnCanDashCheck`
refuses, so no shoot or dash kick can move `TargetFOV`; and `ResetFOV()` has already parked
`CurrentFOV`. The release branch therefore holds for the whole ultimate and High Noon is the sole
owner, with **no cross-module coupling and nothing that can strand** if the ult ends by death, stun
or teardown.

**Deliberately NOT done — two tempting fixes that are worse:**
- *Making `HighNoonFOV` hold the tight FOV with a live `RenderStepped`.* Smaller, and it would work
  today — but only because `RenderStepped` happens to run after `BindToRenderStep`. It keeps two
  systems writing the camera every frame, which is the thing the guide forbids and the thing that
  caused this.
- *A `Suspended` flag on `RevolverCameraEffects` set by High Noon's `Start`/`End`.* Correct, but it
  adds a lifecycle that can strand the camera suspended if the ult ends on a path that skips `End`,
  in exchange for nothing the idle release does not already give.

**Also updated: `HunterImplementationGuide`.** Its FOV rule said "only ONE script should own
`camera.FieldOfView` writes" — true, and followed, and still not enough. It now states that the owner
must *release* the camera when idle and re-capture on resume, records the measured
`BindToRenderStep(Camera+1)` → `RenderStepped` order that makes an always-on writer silently win, and
cites this bug. Both the prose rule and the swap checklist item carry it.

**Verified by simulation, since MCP playtesting is unavailable.** The module was recompiled from
source with `loadstring` and run against a stub camera: with the camera left at the tight FOV 44 and
the compositor idle, it stays at **44.000 across 3 seconds of frames** (it read 70 before the fix);
sprint still eases to **78.000**; a shoot kick drives to 70.67 and then settles and releases; and a
re-engage after release eases from a camera sitting at 50 rather than snapping from a stale 70.
`RevolverCameraEffects` (178 lines), `HunterImplementationGuide` (781), `FPSRevolverClient`,
`HighNoonClient` and `HighNoonFOV` all compile.

**Regression checklist if this area is touched again:**
1. Fire High Noon and confirm the narrowed FOV **holds** from the end of the zoom until the ultimate
   actually ends, then eases back over ~0.85s rather than snapping.
2. End the ultimate early — die during it, and get stunned by a Bram during it — and confirm the FOV
   returns cleanly both times and that a later sprint still widens normally.
3. Sprint immediately as the ultimate ends, inside the 0.85s return tween. This is the one remaining
   handoff window: the compositor re-captures mid-tween, which should read as continuous. If it
   reads as a hitch, that is the known edge, not a regression.
4. Confirm ordinary Dust play is unchanged — sprint widen, shoot kick, dash kick, and the FOV on
   death into the kill cam.

**Item 3 is the one that was never exercised by the simulation** and is the only place a regression
would plausibly hide — the stub-camera run covers holding, sprint, the kick and the re-capture, but
not a live handoff landing inside HighNoonFOV's own return tween.
