# 48 — Aim assist camera magnetism is switched off, not removed

[Open items index](../../OPEN-ITEMS.md) · [Conventions](../../CONVENTIONS.md)

**Closed 2026-08-11** — owner review of the standing-concern list.

---

**Aim assist camera magnetism is switched off, not removed** (raised: Hotfix 10, 2026-08-07).
`RevolverConfig.AimAssist.Enabled = false` — mobile players get no camera drag, and auto-fire runs
on the lock tolerance alone. The rest of the table stays tuned for a re-enable
(`MaxYawOffsetDeg` 1.0, vertical pull 0 — tested and rejected, it steals headshots), and
`AimAssistController`'s eligibility is now split into acquisition vs rotation specifically so the
flag can never silently kill auto-fire. Open question is whether it goes back on at all; until
someone decides, a mobile aim-feel complaint should be read against this flag first.
