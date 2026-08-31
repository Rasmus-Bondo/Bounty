# 85 — Profile schema is not version-tracked in code

[Open items index](../OPEN-ITEMS.md) · [Conventions](../CONVENTIONS.md)

---

**Profile schema is not version-tracked in code.** Add a `ProfileSchemaVersion` field and an
explicit migration step per bump, so "can I safely revert past this?" is answerable without
reading code. *(raised: Launch)*
