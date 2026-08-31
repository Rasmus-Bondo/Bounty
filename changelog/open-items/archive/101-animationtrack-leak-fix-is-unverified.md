# 101 — AnimationTrack leak fix is unverified

[Open items index](../OPEN-ITEMS.md) · [Conventions](../CONVENTIONS.md)

**Closed 2026-08-15 — owner decision. Never playtested; the test below was never run.** Live since
2026-08-13 (Hotfix 16) with no recurrence reported. Closed on elapsed time, not on evidence. If it
resurfaces, raise a **new id**.

**Status:** CLOSED 2026-08-15 (never verified) · **Sev:** P2 · **Area:** Redwater — Fortuna, shared dash
*(raised: Hotfix 16)*

---

**Symptom.** Fortuna's double jump and the shared dash roll each loaded a fresh `AnimationTrack` per
press and never released it, walking the Animator to its 64-track ceiling over a long life. Past the
ceiling it refuses *every* later load, including the stock `Animate` script's jump clip — which is the
shape the original report arrived in (a client warning naming the default R15 jump asset, 44
occurrences, nothing pointing at either script).

**Repro.** Never reproduced deliberately. It needs a single life long enough to press double jump or
dash ~64 times, which no ordinary playtest reaches.

**The test that closes it.** Not a playtest — a counter. After the next publish, watch the Creator Hub
client warning list for the stock R15 jump asset id. **Expect it to stop appearing.** A single
long-lived player is enough to produce it if the leak is still there, so a clean week is the signal.

Faster alternative if someone wants it sooner: on live, take one life and press double jump ~70 times
without dying, then dash. If the dash still animates, the cache is working.

**Affects** Fortuna (both paths) and Dust (dash only). Bram opts out of the roll and was never exposed.

**Shipped in:** [Hotfix 16](../2026-08-13-hotfix-16.md) — under `## Fixed`.
