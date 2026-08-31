# 76 — Kill-feed rows do not hug their content, so short rows show a wide empty bar

[Open items index](../../OPEN-ITEMS.md) · [Conventions](../../CONVENTIONS.md)

**Closed 2026-08-11** — owner review of the standing-concern list.

---

**Kill-feed rows do not hug their content, so short rows show a wide empty bar.** `Bob [icon] Al`
is ~90px of content inside a fixed 352px mobile row (392 desktop), and the drop-shadow spans the
whole width — the same "spilling into a wide bar" complaint that picking `ROW_WIDTH` 352 for mobile
was meant to address, just at a different name length. Now more visible than it was, because #14's
fix means names no longer pad the row out to a fixed width. The fix is a variable row width, which
is why it was not smuggled into #14: rows are positioned at `x = 0` inside a right-anchored feed
frame, so hugging means re-anchoring every row and reworking both `updateRowPositions` and the
slide-in tween, which interpolates `Size` and `Position` in offsets.

**Downgraded to cosmetic on 2026-08-04 and no longer urgent.** Right-aligning the row content
(see #14's follow-up) means the *text* now ends at a constant 16.2px from the screen edge on every
row, so the feed reads as properly pinned even though the bar behind it is still a fixed width. The
empty space moved to the left of the content, where there is nothing to be flush with. What remains
is only that the translucent bar is wider than it needs to be on short rows — worth doing for
polish, no longer worth the positioning rework on its own.
*(raised: #14, deliberately not fixed)*
