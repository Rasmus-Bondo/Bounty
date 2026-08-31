# 30 — Bounty portrait cards are too heavy on a phone

[Open items index](../../OPEN-ITEMS.md) · [Conventions](../../CONVENTIONS.md)

**Closed 2026-08-11** — owner decision to retire the launch-issue list.

**This was never fixed, and "no recurrence" does not apply to it.** It was the one launch issue
still marked plain `OPEN`: the problem was measured but **no treatment was ever chosen** between
smaller / transparent / relocated on mobile. Closing it drops undone design work rather than
retiring a defect that stopped happening. The measurements below are still good — start from them
rather than re-measuring if the cards are revisited.

---

**Status:** OPEN · **Sev:** P2 · **Area:** Redwater — bounty list HUD, mobile

**Reported 2026-08-05** (owner's own play): the new ViewportFrame bounty cards should be **smaller,
transparent, or placed somewhere else on mobile**. Three candidate treatments, none chosen — this
item is the measurement and the constraints, not a decision.

**Measured, and there is a real asymmetry — but it is not the row.** The row scales honestly: `Canvas`
is `Size {0.34, 0}, {0.175, 0}` with a `UIAspectRatioConstraint` (2.8, `DominantAxis = Height`) and
**no** `UISizeConstraint`, so it is 17.5% of viewport height on every device by construction. That
part was verified when it was built and is not the problem.

**The problem is the 60px pin above it, which does not scale.** `Canvas` sits at
`Position {0.5, 0}, {0, 60}` — a pixel pin measured against `RoundStatusGui`'s timer stack. So the
occupied band from the top edge is `60 + 0.175 x H`, and the fixed 60 is worth far more on a short
screen:

| Viewport height | Pin | Row | Band from top edge | % of screen |
|---|---|---|---|---|
| 375 (phone landscape) | 60 | 65.6 | 125.6 | **33.5%** |
| 768 (tablet) | 60 | 134.4 | 194.4 | 25.3% |
| 1080 (desktop) | 60 | 189.0 | 249.0 | 22.7% |

A third of a phone screen against under a quarter of a monitor. On a 375-tall screen that also leaves
only **~62px between the bottom of the row and the crosshair**, so a target on a platform above you is
read through the cards — which is the specific moment a bounty holder is most likely to be up there.

**There is no mobile branch to extend.** `BountyListClient` contains **zero** references to
`TouchEnabled` or an `IS_MOBILE` constant (grepped) — one geometry serves every device. Whatever is
chosen is the first device split this panel has, so it needs a deliberate home: a `UIScale` on
`Canvas` driven from `TouchEnabled` is the cheapest form and keeps the structure authored, per the UI
rules.

**Notes on each of the three options, so the choice is not made blind:**

- **Smaller** is the straightforward one — but it does **not** buy back the 60px pin, which is the
  larger half of the phone's 125.6px band. Shrinking the row alone takes 33.5% to about 27% at a 0.7
  scale. The pin has to come down with it, and it cannot go below `RoundStatusGui`'s timer stack
  (y 0–58, also pinned in offsets) without the two colliding. Note also that the name box is already
  ~12px on a 360-tall phone at full size, which is why `fitName` clamps to 12 characters; shrinking
  further makes the name decorative rather than readable, and that should be accepted openly rather
  than discovered.
- **Transparent is nearly free mechanically and expensive visually.** The fade path already composes
  `resting + (1 - resting) x rowAlpha` per element via `getStrokeVisibleTransparency` /
  `getTextVisibleTransparency`, and covers `ViewportFrame.ImageTransparency` too, so a mobile resting
  alpha rides machinery that exists. The cost is that it spends contrast that was **already measured
  as marginal**: the gold ring is 2.1:1 on a sunlit canyon wall and 1.5:1 on bright sand, below the
  3:1 floor, and only clears it because `RingShadow` puts a black edge outside it. Fading the card
  fades that rescue as well. If this route is taken, the ring and its shadow should hold their alpha
  while the portrait and panel fade, not fade uniformly.
- **Moving it — check the history first.** The row was at the **upper left** before the 2026-08-05
  rework, and that position is what squeezed the mobile SPRINT button to a 6.3px gap on a Galaxy A06.
  Moving it back is re-introducing a known mobile bug. The other edges are taken too: kill feed and
  the gear + Stats cluster top-right, FIRE/SCOPE right, SPRINT above the left thumbstick. There is no
  free corner on a phone, which is an argument for treating this as a size/opacity problem rather
  than a placement one.

**Adjacent, and it bears on "smaller" being enough: up to three live `ViewportFrame`s each render a
~270-part rig every frame.** `hideSlot` destroys a portrait with its row precisely because hidden
viewports still render, so the cost is real and it is a phone cost. Shrinking a `ViewportFrame` cuts
fill rate but not rig complexity, so if the panel reads as *heavy* rather than merely *large* on a
handset, the lever is fewer cards or a cheaper portrait on mobile — not a smaller one. Worth a
`capture_micro_profiler` sample on a phone preset with three bounties up before committing.

**Whatever is chosen, verify with `set_device_simulator` across a small phone, a tablet and a
windowed desktop** — the row's whole design premise is proportional scaling, so a mobile-only branch
is exactly the change that can break the other two without anyone looking.
