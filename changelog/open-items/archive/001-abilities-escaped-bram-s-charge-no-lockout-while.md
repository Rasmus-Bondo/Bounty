# 1 — Abilities escaped Bram's charge; no lockout while pinned

[Open items index](../../OPEN-ITEMS.md) · [Conventions](../../CONVENTIONS.md)

---

**#1 — Abilities escaped Bram's charge; no lockout while pinned.** *(VERIFIED by the owner
2026-08-01, shipped in [Hotfix 3](../../2026-08-03-hotfix-3.md).)* A gate existed but tested only
`StatusStunned`, which Breach Charge writes solely on the wall slam — so the entire pin/carry
phase was ungated. New shared `HunterActionLock` is the single "may this character act"
predicate. The three abilities named in the report were simply the roster's three *displacement*
abilities, which is why patching those three would have been the wrong fix.
**Regression checklist if this area is touched again:** get rammed as Fortuna/Dust/Vesper and
mash the escape ability mid-carry (nothing should happen); confirm fire and reload are dead
during the carry and return the instant the pin releases; let a charge time out with no wall
(victim must recover fully); Bram charges a wall while stunned by a *second* Bram (his charge
must still end cleanly — the `WallHit`/`End` exception); watch a bot get rammed (stops casting,
still recovers).
