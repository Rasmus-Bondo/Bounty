# 42 — Bram's Last Call tile pop is confirmed on mobile but not desktop

[Open items index](../../OPEN-ITEMS.md) · [Conventions](../../CONVENTIONS.md)

**Closed 2026-08-11** — owner review of the standing-concern list.

---

**Bram's Last Call tile pop is confirmed on mobile but not desktop** (raised: Hotfix 9,
2026-08-06). The desktop playtest pass ran *before* the pop was requested, so it verified Last Call
resetting both cooldowns but not the animation that now plays when it does. The edit-mode harness
and the owner's mobile pass both cover it; this is a one-look confirmation, not a suspected defect.
Nothing else in the cooldown work carries the caveat.
