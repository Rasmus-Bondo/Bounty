# 41 — The ultimate-ready glow has never been measured on a phone

[Open items index](../../OPEN-ITEMS.md) · [Conventions](../../CONVENTIONS.md)

**Closed 2026-08-11** — owner review of the standing-concern list.

---

**The ultimate-ready glow has never been measured on a phone** (raised: Hotfix 9, 2026-08-06).
`UltimateReadyFX` is **24 stacked `UIShadow`s**, and lighting a tile tweens all 24. Every verified
playtest of it ran on desktop; mobile is most of the player base and is exactly where 24 extra
draws per lit HUD would show. Nothing suggests it is a problem — it simply has not been looked at.

**Cheap to close, and cheap to fix if it fails.** Brightness is solved *against* the layer count
(`total ^ share`, shares summing to 1), so the count can be lowered purely for performance without
re-tuning the glow — that was designed in deliberately. Check frame time on a real handset with an
ultimate charged, and drop the layer count if it costs anything.
