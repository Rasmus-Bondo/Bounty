# 73 — `GrappleHookService` still carries its own grace implementation

[Open items index](../../OPEN-ITEMS.md) · [Conventions](../../CONVENTIONS.md)

**Closed 2026-08-11** — owner review of the standing-concern list.

---

**`GrappleHookService` still carries its own grace implementation** rather than the shared
`MovementGrace`. Deliberate at the time — it was a working live fix and refactoring it in the
same pass as a new one was not worth the risk. Migrating it is the obvious follow-up.
*(raised: [Hotfix 2](../../2026-08-01-hotfix-2.md))*
