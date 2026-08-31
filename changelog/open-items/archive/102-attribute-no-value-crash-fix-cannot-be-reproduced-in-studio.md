# 102 — Attribute *no-value* crash fix cannot be reproduced in Studio

[Open items index](../OPEN-ITEMS.md) · [Conventions](../CONVENTIONS.md)

**Closed 2026-08-15 — owner decision. Never playtested; the test below was never run.** Live since
2026-08-13 (Hotfix 16) with no recurrence reported — and this one has a dashboard signal, so silence
is weak evidence rather than none. Closed on elapsed time. If it resurfaces, raise a **new id**.

**Status:** CLOSED 2026-08-15 (never verified) · **Sev:** P1 · **Area:** both places — 18 call sites, 9 scripts
*(raised: Hotfix 16)*

---

**Symptom.** `BountyListClient.applySnapshot` threw `missing argument #1` before dressing a single
bounty card, so the panel never appeared for affected players, repeating once per snapshot for as long
as a bounty was up (19 client errors on r2518). The same unsafe read was fixed as a class across 18
call sites in 9 scripts in both places.

**Repro.** **Not reproducible in Studio.** The engine returns `nil` there rather than *no value*, so
the failing branch cannot be entered from an edit session or a Studio playtest. This is why the fix
went in as a class rather than at the crash site — the individual sites cannot be tested either.

**The test that closes it.** After the next publish, watch the Creator Hub client error list for
`missing argument #1`. **Expect it to go to zero.** Separately, on live, confirm the Redwater bounty
card panel actually appears when a bounty goes up — that is the player-visible half.

**`AntiCheat.MovementChecker` matches the same grep and was deliberately left alone** — it is already
safe. Do not "fix" it in a later sweep and assume it was an oversight.

**Shipped in:** [Hotfix 16](../2026-08-13-hotfix-16.md) — under `## Fixed`.
