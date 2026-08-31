# 95 — Bram's stun server-side backstop

[Open items index](../../OPEN-ITEMS.md) · [Conventions](../../CONVENTIONS.md)

---

**Bram's stun server-side backstop.** *(raised: Launch — resolved 2026-08-01, shipped in
[Hotfix 3](../../2026-08-03-hotfix-3.md).)* Stun and pin are now enforced on the server rather than
trusted from the client: the check is folded into each hunter module's `isRoundCombatAllowed()`,
so all 14 call sites inherit it, and `CardsServer` / `HighNoonModule` carry explicit guards.
A dropped client message can no longer under-apply the stun.
