# 44 — Fortuna's lag compensation has never run against real latency

[Open items index](../../OPEN-ITEMS.md) · [Conventions](../../CONVENTIONS.md)

**Closed 2026-08-11** — owner review of the standing-concern list.

---

**Fortuna's lag compensation has never run against real latency** (raised: Hotfix 9, 2026-08-06).
Hotfix 9 widened `CardsConfig.LagCompensation.PartRadii` from 5 tracked parts to 13 and pointed
`findLagCompensatedHit` at bots as well as players. Studio ping is ~0, so **only the forgiveness
spheres were confirmed** — the rewind itself, which is the half that only does anything under
latency, was not exercised. The radii are the player-facing buff and they are verified; what is
unverified is whether the rewind picks the right historical position for a moving target on a real
connection. Worth a look on live before widening anything further.
