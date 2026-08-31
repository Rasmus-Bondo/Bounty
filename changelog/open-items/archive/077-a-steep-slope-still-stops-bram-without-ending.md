# 77 — A steep slope still stops Bram without ending his charge

[Open items index](../../OPEN-ITEMS.md) · [Conventions](../../CONVENTIONS.md)

---

~~**A steep slope still stops Bram without ending his charge** — he grinds to the 3s timeout.~~
**FULLY FIXED 2026-08-05 — VERIFIED by the owner by playtest the same day. In Studio, not yet
published.** Fixed in two passes on that day.

*The GRIND half first*: stall detection is back on both the player and bot paths, ending a blocked
charge as a **plain release** rather than a slam, which is what makes it safe — it was deleted
originally for causing false slams, and `StallSpeed` / `StallGrace` had sat unread in the config
ever since. A charge blocked at t=1.00s now releases at t=1.17s.

*That was the wrong half*, as a follow-up playtest reported: it made the failure fast instead of
making the charge work, and the victim still dropped for `ReleaseDamage` short of the wall. **The
CLIMB half is now fixed too.** Nothing in the charge could lift Bram at all — it moves on a
Plane-mode `LinearVelocity` driving X/Z with **Y left free** — so a 40–55° face sat in a dead band:
too steep to ride up, too shallow to slam. `breachClimbRate` in `GrudgekeeperClient` probes the
ground 4 studs ahead and holds the upward speed that clears the rise, capped by
`ChargeMaxUpwardSpeed` (was **0**, read only by a dead `getBreachVelocity`; now 52, under
`MovementChecker`'s ceiling of 65). The stall check was corrected to full 3D displacement in the
same pass — it measured flat XZ, which reads a charge climbing cleanly as *more* stalled the better
it climbs.

**The `cos 55` threshold itself is still unchanged and still deliberately so:** that is the
steepness rule (`|normal.Y| <= 0.5736`), not the cast shape, and widening it re-opens the
false-slam problem that got stall detection deleted on purpose. The climb assist closes the dead
band from the other side instead, and the handover was measured against ramps at known angles as
landing exactly on that threshold — 54° climbs, 56° slams, no gap. The old measurements at
`workspace.CHARGEPOINT` (terrain −X face `|normal.Y|` **0.6502** → ramp; `RockLarge` +Z face 0.0480
→ wall; terrain ground 0.7703 → ramp) still describe the geometry, but that 0.6502 face is now
climbed rather than stalled against — and note the marker itself no longer exists.
*(raised: #9)*
