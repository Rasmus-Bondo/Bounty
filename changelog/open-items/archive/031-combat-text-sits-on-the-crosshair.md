# 31 — Combat text sits on the crosshair, and its background is twice the width of the text

[Open items index](../../OPEN-ITEMS.md) · [Conventions](../../CONVENTIONS.md)

---

**Status:** **VERIFIED by the owner 2026-08-07**, tested on a Galaxy S25 Ultra and on PC · **Sev:** P2
· **Area:** Redwater — combat feed (`CombatFeedClient`) · In Studio, **not yet published**

**Reported (2026-08-07, owner's own play):** on mobile the floating combat text sits squarely on top
of the crosshair, making it hard to aim. The black banner behind it stops short of nothing — it
extends well past the text on both sides, on PC as well as mobile. Follow-ups during the fix: the
banner's left edge cut off sharply instead of fading; on PC the feed covered the equipped weapon; and
the mobile text was too large, truncating names.

**Four separate defects, all in one file.**

**1 — The feed was centred on the aim point.** Rows were anchored at `0.5` of width. Measured live on
the reporter's device (685x338 safe area): the newest row spanned y 108–136 with the crosshair centre
at y 121.5. Dead on.

*Fixed by* moving the rows into a lane **right** of the crosshair — left-aligned, growing rightward
from `LANE_OFFSET_SCALE` 0.045 of width. A fraction of **width**, not a constant, because the
crosshair scales with width too: GunGui's Canvas is `0.065` of width on `RelativeXX`, so its
half-width is `0.0325` of width and the lane stays ~1.4x clear of it at any viewport.

**Moving it sideways rather than up was the load-bearing choice.** The band *above* the crosshair is
only ~110px on a phone once the 58px round timer is paid for, and `KillCamClient` already claims it —
it bottom-anchors the "KILLED BY" card off the `FeedBaseYScale` attribute. Raising the feed would
have put both in that band with room for neither, i.e. a new bug in exchange for the old one. Going
sideways left the kill cam untouched.

**2 — The "black banner" was `UIShadow` blurring the BOX, not the glyphs.** `BlurRadius` was
`UDim.new(0.5, 0)` — a **scale** radius, taken against the element's own size — on a label whose box
was a flat `0.78` of the 680px row. That is 530px of box holding 258px of text, so the blur painted a
slab twice the width of the words. **`KillFeedClient` has the identical bug and worked around it by
narrowing its rows** (see its `ROW_WIDTH` comment); this one measures instead.

*Fixed by* `BlurRadius = UDim.new(0, 14)` plus sizing each box from `GetTextBoundsAsync`. **Set
`RichText` on the params or the `<font>` tags are measured as literal characters** — the same string
reports 258px parsed and 785px unparsed.

**3 — The shadow was clipped on three sides.** Reported once the banner hugged the text: the left
edge stopped sharply while the right faded. A `CanvasGroup` renders its children into a texture of
its own `AbsoluteSize` and clips the rest, and the label sat flush at x=0 in a canvas exactly
`ROW_HEIGHT` tall — so the blur was cut dead on the **left, top and bottom**. Only the right faded,
because there the label had the remaining 680px of canvas to bleed into. It read as a left-edge
problem because the text is a horizontal strip.

*Fixed by* `SHADOW_MARGIN` 18px of dead canvas on every side (must exceed `BlurRadius` 14 plus the
shadow's 2px `Offset`), subtracted back out of the row's position so the **text** still lands on the
lane start. That subtraction is **scaled** (`SHADOW_MARGIN * targetScale`): the margin lives inside
the row's `UIScale`, and a constant would have staggered the rows' left edges by ~5px down the stack
as the older ones shrink.

**4 — Fixed per-device buckets, replaced with a curve.** The five discrete profiles jumped 0.64→1.12
across a one-pixel viewport change, and left phones at 20.5px of effective text — **6.1% of a 338px
screen against desktop's 3.0%**. On PC the stack grew *down* from a fixed 0.565 base to ~0.79, which
is where the first-person viewmodel renders, on the same side as the lane.

*Fixed by* deriving everything from viewport height. `FEED_SCALE = (height/1080)^0.7`, clamped
0.40–1.15. **The exponent is the point:** a straight `height/1080` ratio puts a phone at 0.31 — 10px
text — because small screens need proportionally *larger* UI, not the same fraction. Row step, row
count and base-Y all follow from it, and `BASE_Y_SCALE` is solved **backwards from the stack's bottom
edge** (`STACK_BOTTOM_Y` 0.58) so a taller stack starts higher instead of reaching further down over
the weapon.

| Viewport | Scale | Text | % height | Rows |
|---|---|---|---|---|
| S25 Ultra 685x338 | 0.44 | 14.2px | 4.2% | 3 |
| iPhone 16 Pro Max | 0.53 | 17.1px | 3.9% | 3 |
| iPad 10th | 0.83 | 26.4px | 3.2% | 4 |
| 1366x768 laptop | 0.79 | 25.2px | 3.3% | 4 |
| 1920x1080 | 1.00 | 32.0px | 3.0% | 6 |

**Two truncation traps, both invisible at desktop scale — do not re-derive these.**
- **A fit allowance has to be proportional.** Bounds are measured at `TEXT_SIZE`, but the row renders
  through a `UIScale`, and scaled glyph layout rounds up per glyph: a 258px line renders **133** wide
  at 0.5x where the ratio predicts 129, ~3%. The error grows with line length, so a flat 3px slack
  that was ample at scale 1.0 still ellipsised `+$120` once phones dropped to 0.44.
- **A box sized to fit its own text must never be *allowed* to truncate.** `TextTruncate` is now
  enabled only for lines that genuinely overran the lane. With `AtEnd` always on, a few pixels of
  underestimate cost the whole `+$120`; with `None` they cost the last glyph's final column, clipped
  invisibly inside a 680px canvas. This was still cutting a short ASSIST line at the oldest row's ~8px
  effective size, *after* the proportional allowance went in.

**`TextBounds` is reported in RENDERED pixels while `Size` is unscaled.** Mixing them collapsed a
clamped bounty row to `BOUNTY…` — 262px of text read back as 131, the box was set to half what the
text needed, and the renderer truncated again to match. The refit divides the row's live `UIScale`
back out; both values are read in the same instant, so a mid-tween scale stays self-consistent.

**The lane's right bound is measured, not tabulated.** It reads the live `MobileFireButton` position
out of `HunterFireGui`, because **HunterMobileFireButton resolves its own edge inset at runtime** by
clamping against the ability HUD — on a 1.44-aspect iPad the resolved and authored values differ by
25pt, so any static per-device fraction copied here would be wrong on exactly the phones it matters
on. Falls back to a width fraction on desktop and in the window before the button exists.

**A hard floor keeps the ordinary reward row from ever truncating**, whatever the lane says. On a
1.78-aspect phone (iPhone 7) FIRE is large enough that the measured lane is ~20px short of it, so
that row sits nearer the button — a deliberate trade, since a translucent button behind the tail of
the text beats shipping `ELIMINATION +250 XP …` as the commonest line in the game.

**Verified by measurement + screenshot, then by the owner on real hardware.** Geometry was read from
a live client (`eval_client_runtime`) rather than assumed — that is where the crosshair's y 121.5
against the row's 108–136 came from, and it also turned up that `GunGui` is `ScreenInsets.None`
(779x359) while `CombatFeedGui` is `DeviceSafeInsets` (685x338), so the two do **not** share a
coordinate space even though both report `AbsolutePosition` against the same origin. Layout was then
mocked in `StarterGui` with the crosshair, FIRE button and kill feed drawn to their real measured
positions, **with every constant parsed out of the shipped source** so the preview could not drift
from the code. Owner tested on a Galaxy S25 Ultra and on PC 2026-08-07 and signed it off.

**Residual, accepted — the second name in a bounty announcement still truncates on a phone.** The
lane is 188px on an S25 Ultra, bounded by FIRE at x=572, and a two-name announcement needs ~624px at
full size. Nothing that fits beside the crosshair can show it whole; it improved from
`BOUNTY CLAIMED …` to `BOUNTY CLAIMED RUSTYJAKE TOOK DOWN…` (text budget 267 → 397 unscaled px).
Showing it in full needs its own full-width line, which is a separate change and was not made.

**Regression checklist if this area is touched again:** confirm the crosshair is clear on a phone;
confirm the shadow fades on **all four** sides, not just the right; confirm `ELIMINATION +250 XP •
+$120` and `ASSIST` render in full at every row age (the oldest row is the one that truncates first);
confirm the feed clears the viewmodel on PC; confirm the "KILLED BY" card still lands above the feed,
since it reads `FeedBaseYScale` and that value now moves with the viewport rather than coming from a
table — **nothing on the kill cam side may assume the old 0.565 desktop constant.**
