# 35 — The bot scripting layer has no consumer yet

[Open items index](../OPEN-ITEMS.md) · [Conventions](../CONVENTIONS.md)

---

**The bot scripting layer has no consumer yet** (raised: Hotfix 12, 2026-08-08). Status:
**OPEN**. P3. Hotfix 12 shipped the peaceful-bot states (hold fire / stand down), authored
spawning, leashing, routes, approach, per-bot difficulty, despawn and population locking, plus a
`Training` difficulty tier at 0.35 damage — all of it built for an onboarding tutorial that does
not exist. Every lever defaults off and was verified inert at preflight, so it costs nothing in
a live round, but it is also **entirely unexercised in a real match**: no scripted sequence has
driven it end to end, and the failure modes it was written against (a flag coming back armed
after a respawn, `Reconcile` retiring an authored bot, a Vesper walking away from a player she
was told to approach) are all reasoned rather than observed. Treat the first tutorial build as
the integration test for this API, and expect to find things there rather than in a normal round.
