# 36 — The mobile auto-fire retune has not been played on a phone

[Open items index](../../OPEN-ITEMS.md) · [Conventions](../../CONVENTIONS.md)

**Closed 2026-08-11** — owner review of the standing-concern list.

---

**The mobile auto-fire retune has not been played on a phone** (raised: Hotfix 11, 2026-08-07).
Status: **OPEN**. P2. Every lock radius in the release was resized against a *server* constant —
`HitForgiveness.Radius` for Dust and Vesper, Fortuna's lag-comp torso spheres, Bram's damage cone —
so the arithmetic is checkable and was checked, but "does the gun now fire when you expect it to"
is a feel question a compile cannot answer. The retune only ever *widens* the tolerance, so the
failure it can newly produce is auto-fire firing at someone it should have let go, not staying
silent. **Bram is the one to test first**: he moved furthest (1.5° → 7.6° at 60 studs) and is the
only hunter whose floor is angular rather than a sphere, so he is where an over-wide lock would
show up soonest. Also worth confirming the raised 350-stud acquisition ceiling does not make a
mobile Dust feel like he is being aimed for him at ranges where he only deals his 20/40 floor.
