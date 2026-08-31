# 11 — Owned items read PURCHASE instead of EQUIP in Collection after a Redwater trip

[Open items index](../../OPEN-ITEMS.md) · [Conventions](../../CONVENTIONS.md)

---

**#11 — Owned items read PURCHASE instead of EQUIP in Collection after a Redwater trip.**
*(VERIFIED by the owner 2026-08-03, shipped in [Hotfix 3](../../2026-08-03-hotfix-3.md).)*
**There was never data loss or a double-charge**, and that was established *before* the fix rather
than assumed: Redwater only ever *reads* `OwnedCharacters` / `OwnedWeaponSkins` and never writes
them, and every purchase path carries an already-owned guard, so a player clicking PURCHASE on
something they already owned was refused server-side. It returned **silently**, which was the
genuinely bad part of the UX — no Cash ever moved. Anyone re-opening this area should not
re-derive the ownership-wipe theory; it was ruled out.
