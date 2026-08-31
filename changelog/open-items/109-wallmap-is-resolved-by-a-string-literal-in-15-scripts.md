# 109 — `WallMap` is resolved by a string literal in 15 scripts, so `MapConfig` cannot own it

[Open items index](../OPEN-ITEMS.md) · [Conventions](../CONVENTIONS.md)

**Status:** DEFERRED · **Sev:** — · **Area:** Redwater — combat raycast filters, 15 scripts
*(raised: Hotfix 17)*

---

**Symptom.** `FROSTBITE_CLAIM_SPEC.md` §5 lists `WallMap` in `MapConfig.Instances`, but it is
resolved by the bare string `"WallMap"` in 15 scripts — 13 of them repeating a
`{ "VesperHookSpotsBot", "WallMap" }` raycast-filter idiom. Wiring only the 2 sites the spec names
would leave 13 ignoring the table, which is worse than not having the entry: a config that is
authoritative for some callers and not others invites exactly the assumption it breaks. So
`MapConfig.Instances` deliberately omits it, and a second map's wall model must still be named
`WallMap`.

**Repro.** Not a defect — a deferral. `grep_scripts` for `WallMap` in Redwater returns the 15 sites.
Note `grep_scripts` matches literals, so search the bare name, not an alternation.

**The test that closes it.** Extract the shared filter idiom into one helper that reads
`MapConfig.Instances`, add `WallMap` to the table, and confirm all 15 sites route through it — then
a map whose wall model has a different name loads without touching combat code. Until then, the
closing test is simply that Frostbite's wall model is named `WallMap`.

**`CorpseFolder` was dropped from the spec's map contract in the same pass** and is not deferred —
it has zero references in all 290 Redwater scripts, so Frostbite would have been authored a folder
nothing reads. Do not re-add it from the spec.

**Shipped in:** [Hotfix 17](../2026-08-13-hotfix-17.md) — under `## Changed`.
