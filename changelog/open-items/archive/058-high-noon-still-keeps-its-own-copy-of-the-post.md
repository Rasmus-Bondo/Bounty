# 58 — High Noon still keeps its own copy of the post-hit bookkeeping

[Open items index](../../OPEN-ITEMS.md) · [Conventions](../../CONVENTIONS.md)

**Closed 2026-08-11** — owner review of the standing-concern list.

---

**High Noon still keeps its own copy of the post-hit bookkeeping** instead of running through the
shared hit chain. The Hotfix 6 audio fix patched the copy rather than deleting it, deliberately —
folding it back re-routes kill feed, kill cam, ultimate charge and stats on a live ultimate, which
is far more risk than an audio fix should carry. **This remains the standing recommendation** and
is worth doing on its own; the duplicate is why #3 existed at all.
*(raised: #3, [Hotfix 6](../../2026-08-05-hotfix-6.md))*
