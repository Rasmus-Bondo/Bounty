# 52 — `CodeRedemptionService` is a 17th mirrored module that no automated gate checks

[Open items index](../../OPEN-ITEMS.md) · [Conventions](../../CONVENTIONS.md)

**Closed 2026-08-11** — owner review of the standing-concern list.

---

**`CodeRedemptionService` is a 17th mirrored module that no automated gate checks** (raised:
Hotfix 8). It exists in both places and its `CODES` table plus `resolveCode` gate must stay in
step, but it is **not** on the 16-file mirrored list in `CLAUDE.md`, `CONVENTIONS.md`,
`.claude/skills/preflight/SKILL.md` or `.claude/skills/changelog/SKILL.md` — so preflight's Step 1
does not look at it. Hotfix 8 found it had drifted on its user-facing strings and reconciled them,
but **the next drift will be just as invisible**, and the failure mode is the one that matters:
a code added to one place only reads back as invalid in the other while still burning its one-shot
per-profile grant.

It cannot simply be added to the 16, because a whole-file byte compare **would fail by design** —
the award plumbing deliberately differs (Bounty pays through `Wallet`; Redwater routes Cash/XP via
`ProgressionService.awardCodeRedemption`, which owns the XP curve and the `LevelUp` fire) and
unifying it is explicitly not wanted. Whole-file lengths legitimately sat at 4989 vs 5341 while the
mirrored halves matched exactly.

**The fix is a partial-mirror check, not a listing:** checksum the `local CODES = {...}` block and
the `resolveCode` function separately, the way Hotfix 8's preflight did by hand, and add that as its
own gate step. Until then, **anyone adding or editing a redemption code must diff both copies
manually.** Deferred rather than done because it changes the preflight skill rather than the game,
and doing it mid-release would have shipped an unreviewed gate.
