# 51 — Dust's two world-animation ids now exist in four places

[Open items index](../OPEN-ITEMS.md) · [Conventions](../CONVENTIONS.md)

---

**Dust's two world-animation ids now exist in four places** (raised: Hotfix 10, 2026-08-07).
`RevolverWorldModelServer`, `WorldRevolverAimIdleClient`, `BotController.getWorldAnimationId` and
now `WorldAnimationPrewarmClient` each carry the hold and shoot ids as string literals, because
Dust's `WorldAnimations` folder is authored **empty** while the other three hunters' are populated
— so the prewarm script can discover theirs by scanning and has to hardcode his. Change one,
change all four. The real fix is to author the two `Animation` instances into his folder, at which
point three of the four copies can read them the way Fortuna's, Vesper's and Bram's already do.
