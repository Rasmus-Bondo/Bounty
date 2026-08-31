# 34 — Auto-fire now shoots through wooden cover, and that is a feel change nobody has played

[Open items index](../../OPEN-ITEMS.md) · [Conventions](../../CONVENTIONS.md)

**Closed 2026-08-11** — owner review of the standing-concern list.

---

**Auto-fire now shoots through wooden cover, and that is a feel change nobody has played**
(raised: Hotfix 12, 2026-08-08). Status: **OPEN**. P2. Aim assist used to decide line of sight
with a plain raycast while the guns resolve their real shot through the shared penetration rules,
so wood, planks and fabric read as solid to the lock and auto-fire was strictly *stricter* than
the weapon. Sight is now decided by the rules the bullet obeys, for all four hunters at once —
which is correct, and also means the gun will now open up through a fence or a wooden building
wall at reduced damage where it used to stay silent. That is a real change in how aggressive
auto-fire feels, not just a bug fix, and the arithmetic cannot answer whether it reads as
helpful or as shooting at things the player did not intend. **The lever if it proves too strong
is `DamageMultiplierPerLayer`, per hunter** — Vesper's is already tuned down to 0.35. Cover the
round genuinely cannot cross (three or more walls, an over-thick part, a non-penetrable material)
still blocks the lock, and solid geometry behind the wood still blocks, so the failure mode is
over-eagerness through soft cover and nothing wider.
