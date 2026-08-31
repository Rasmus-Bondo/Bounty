# 106 — Redwater script count dropped 13 since 2026-08-11, only 2 explained

[Open items index](../OPEN-ITEMS.md) · [Conventions](../CONVENTIONS.md)

**Status:** OPEN · **Sev:** P2 · **Area:** Redwater — inventory / Frostbite bring-up
*(raised: Hotfix 16)*

---

**Symptom.** Re-measuring `FROSTBITE_CLAIM_SPEC.md` §2 during Hotfix 16 surfaced a **13-script drop**
in Redwater since the 2026-08-11 count. Two are accounted for by this release (`FootstepClient` and
`RoundSystem.DestructibleService`). The other **eleven are unexplained** — nobody has established
whether they were deliberately removed by another session, renamed, or lost.

**Repro.** Compare the current Redwater `LuaSourceContainer` count against the figure recorded in
`FROSTBITE_CLAIM_SPEC.md` §2 on 2026-08-11. The count is 290 as of 2026-08-13.

**Why it matters beyond bookkeeping.** The second map is specified as an MCP mirror of Redwater, not a
Package. A spec whose inventory is eleven scripts wrong will carry that error into Frostbite Claim,
where it is far more expensive to find.

**The test that closes it.** Reconcile the two counts name by name — diff the current Redwater script
list against the vault's `LocalRedwaterCanyon/` tree (221 files) and against the 2026-08-11 figure.
Each of the eleven must resolve to one of: deliberately deleted (and its `.md` correctly removed),
renamed (and its `.md` moved), or genuinely missing. **A missing script is the finding this item
exists to catch.**

Note the vault/Studio counts are not directly comparable — the vault tracks 221 `.md` files against 290
live scripts — so the reconciliation has to be by name, not by total.

**Flagged, not chased, in Hotfix 16** — it was surfaced by an unrelated edit and deliberately left
rather than expanding that release's scope.

**Shipped in:** raised by [Hotfix 16](../2026-08-13-hotfix-16.md) — noted under the
`DestructibleService` removal in `## Changed`. No fix shipped.
