# 60 — A flagged bot briefly pushes the arena above its headcount target

[Open items index](../../OPEN-ITEMS.md) · [Conventions](../../CONVENTIONS.md)

**Closed 2026-08-11** — owner review of the standing-concern list.

---

**A flagged bot briefly pushes the arena above its headcount target.** A bot displaced by a join
now leaves on its next death rather than instantly, so a run of joins can reach a worst case of 8
bots alongside 10 players where the old behaviour capped at 4. Transient by construction — every
flagged bot leaves on its next death and a round boundary rebuilds the roster regardless — and the
bot count never exceeds the existing maximum of 8. **Deliberately not given a timeout**: that
reintroduces the disappearing-bot symptom on a delay.
*(raised: #19, [Hotfix 6](../../2026-08-05-hotfix-6.md))*
