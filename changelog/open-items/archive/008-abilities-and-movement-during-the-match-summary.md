# 8 — Abilities and movement during the match summary

[Open items index](../../OPEN-ITEMS.md) · [Conventions](../../CONVENTIONS.md)

---

**#8 — Abilities and movement during the match summary.** *(VERIFIED in playtest by the owner
2026-08-03, shipped in [Hotfix 4](../../2026-08-03-hotfix-4.md).)* Movement was never the bug — it was
Fortuna's `CardsServer`/`CardsClient` and Dust's `HighNoonModule`, the modules that never grew
the `RoundActive` check. Fixed by folding the round phase into `HunterActionLock` so all twelve
gates inherit it rather than writing the helper a sixth and seventh time.
**Technique worth reusing:** the verification put a `print` *past* each gate, so silence is the
pass condition and a client line with no matching server line isolates which layer refused.
**Not separately exercised, low risk:** Fortuna's four remotes and her client cast inherit the
identical predicate that Dust's path was observed refusing. Recall is the one worth a glance if
anyone is in there anyway — it is a server teleport, so before the fix it moved an anchored
player during the showcase.
