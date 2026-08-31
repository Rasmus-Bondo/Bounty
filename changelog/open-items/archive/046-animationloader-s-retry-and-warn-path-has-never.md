# 46 — `AnimationLoader`'s retry-and-warn path has never actually fired

[Open items index](../../OPEN-ITEMS.md) · [Conventions](../../CONVENTIONS.md)

**Closed 2026-08-11** — owner review of the standing-concern list.

---

**`AnimationLoader`'s retry-and-warn path has never actually fired** (raised: Hotfix 10,
2026-08-07). The whole point of the module is what happens when a clip download *fails*, and that
is a transient CDN condition nobody can induce on demand. The 2026-08-07 owner playtest confirmed
the **absence of harm** — every hunter's gun animating, no new warns, no join hitch from the
deferred prewarm sweeps — which is not the same as confirming the recovery works. What is
unexercised: the 5s and 15s retries, and the single 45s warn naming the failed ids. If a
`Failed to load animation with sanitized ID` line ever reappears on the dashboard, check whether a
`[WorldAnimationPrewarm]` warn accompanied it — that pairing is the real test, and its absence
would mean the guard is still blind.
