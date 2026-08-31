# 104 — Bounty music retry-and-warn path is unexercisable

[Open items index](../OPEN-ITEMS.md) · [Conventions](../CONVENTIONS.md)

**Closed 2026-08-15 — owner decision. Never exercised; the path only runs on a failed asset fetch,
which cannot be induced.** Live since 2026-08-13 (Hotfix 16). Closed on elapsed time, not on
evidence. If it resurfaces, raise a **new id**.

**Status:** CLOSED 2026-08-15 (never verified) · **Sev:** P3 · **Area:** Redwater — BountyMusicClient
*(raised: Hotfix 16)*

---

**Symptom.** A failed asset fetch produced a clone with no audio data and **no log line at all** — the
round-ending track's own `TimeLength <= 0` guard just returned. `BountyMusicClient` now preloads its
five cues at boot, retries the failures once after 10s, then warns naming whatever never arrived.

**Repro.** **Unexercisable by construction.** A CDN failure cannot be induced on demand. All eight ids
from the original live report resolve through `GetProductInfo`, are public-domain Roblox library audio,
and preload clean from Studio — so the failure was the client's network, not permissions or moderation,
and nothing local reproduces it.

The 2026-08-13 playtest proves absence of harm (music still plays), not that the guard works.

**The test that closes it.** There is no positive test. Treat it as closed when a live client warning
naming a cue **does** appear and correctly identifies the missing track — i.e. the next time the CDN
fails, the instrument reports it instead of the old silence. Until then it stays unverified, and that
is the accurate state rather than an omission.

**Shipped in:** [Hotfix 16](../2026-08-13-hotfix-16.md) — under `## Fixed`.
