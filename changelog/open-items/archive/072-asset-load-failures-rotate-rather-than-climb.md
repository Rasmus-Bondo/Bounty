# 72 — Asset load failures rotate rather than climb

[Open items index](../../OPEN-ITEMS.md) · [Conventions](../../CONVENTIONS.md)

**Closed 2026-08-11** — owner review of the standing-concern list.

---

**Asset load failures rotate rather than climb** — 43 animation and 25 sound failures, plus three
meshes, all traced to real healthy assets and Roblox-side fetch noise. A retry
(`PreloadAsync` + status callback + one re-issue) is the only thing that would change the
outcome, held until an export shows the counts climbing.
*(raised: [Hotfix 2](../../2026-08-01-hotfix-2.md) — full analysis there)*
