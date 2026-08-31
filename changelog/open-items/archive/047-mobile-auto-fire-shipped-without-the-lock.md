# 47 — Mobile auto-fire shipped without the lock indicator it was built with

[Open items index](../../OPEN-ITEMS.md) · [Conventions](../../CONVENTIONS.md)

**Closed 2026-08-11** — owner review of the standing-concern list.

---

**Mobile auto-fire shipped without the lock indicator it was built with** (raised: Hotfix 10,
2026-08-07). The crosshair lock ring was built and removed the same day at the owner's request, so
a touch player now gets no feedback about *why* the gun is or is not firing — the acquire dwell
(0.08s) and loss grace (0.12s) are both invisible. The hunter clients still publish the
`AutoFireLocked` player attribute and nothing consumes it; that attribute is the hook if feedback
comes back. Recorded because "auto-fire feels unreliable" reports would most likely be *this*,
not a lock bug — check the attribute before touching `AimAssistController.GetLock`.
