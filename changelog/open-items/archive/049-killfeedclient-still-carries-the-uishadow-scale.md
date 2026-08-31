# 49 — `KillFeedClient` still carries the `UIShadow` scale-radius bug that Hotfix 10 fixed in `CombatFeedClient`

[Open items index](../../OPEN-ITEMS.md) · [Conventions](../../CONVENTIONS.md)

**Closed 2026-08-11** — owner review of the standing-concern list.

---

**`KillFeedClient` still carries the `UIShadow` scale-radius bug that Hotfix 10 fixed in
`CombatFeedClient`** (raised: Hotfix 10, 2026-08-07). `BlurRadius = UDim.new(0.5, 0)` is a
**scale** radius taken against the element's own box, so a label whose box is much wider than its
text blurs the whole box. `CombatFeedClient` now uses a fixed 14px radius against per-row measured
bounds; `KillFeedClient` instead works around the symptom by narrowing its rows, which is the
precedent this fix departed from. Not urgent — the workaround holds — but the two feeds now
disagree about how the same widget works, and the next person to touch either will find only one
of them correct.
