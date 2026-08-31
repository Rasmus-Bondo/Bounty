# 70 — `Workspace.TumbleweedSpawns` has duplicate child names

[Open items index](../OPEN-ITEMS.md) · [Conventions](../CONVENTIONS.md)

---

**`Workspace.TumbleweedSpawns` has duplicate child names** — `StartPoint` ×3, `EndPoint` ×2 —
so `FindFirstChild("StartPoint")` returns an arbitrary one. Looks like a lane is missing its
`EndPoint`. *(raised: [Hotfix 2](../2026-08-01-hotfix-2.md))*
