# 37 — Vesper's `FireQuality = 0.55` is a first guess and the single lever if she reads wrong

[Open items index](../../OPEN-ITEMS.md) · [Conventions](../../CONVENTIONS.md)

**Closed 2026-08-11** — owner review of the standing-concern list.

---

**Vesper's `FireQuality = 0.55` is a first guess and the single lever if she reads wrong**
(raised: Hotfix 11, 2026-08-07). Status: **OPEN**. P3. She is the only hunter that waits for the
crosshair to sit well inside the lock tolerance before shooting, on the reasoning that her shot
economy (4 rounds, 3s reload, 1.8s between) makes a marginal miss cost more than a few frames'
delay. The number was derived from the argument, not from play. **Raise it toward 1.0 if she reads
as hesitant; that is the whole fix, and it is one constant.** The other three are at 1.0
deliberately and should not be moved with her — firing at every chance is correct for them.
