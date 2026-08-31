---
tags: [shared, modulescript, client, ui, mobile, layout]
path: game.ReplicatedStorage.Hunters.Shared.HunterMobileClusterLayout
type: ModuleScript
lines: 509
---

# HunterMobileClusterLayout

Resolves the position — both axes — of every button in the bottom-right touch cluster (SCOPE, FIRE, RELOAD, JUMP, SPRINT), so the five hold their shape on any aspect ratio. Stateless and idempotent: `apply(playerGui)` reads the live screen size and writes an absolute result, so any number of callers at any time converge on the same answer.

## Why it exists (this cannot be authored)
Every button is sized as a fraction of screen **HEIGHT** — a 1:1 `UIAspectRatioConstraint` on a height-driven `Size`. But a `UDim2`'s X can only be a fraction of **WIDTH** or a pixel offset; it cannot reference height. So an authored X scale and a height-derived diameter drift apart as the aspect changes, and the cluster shears. Authored in width scales off the reference aspect 2.23, FIRE and JUMP overlapped by 2pt there (correct) but by 15pt on an iPhone 7, as did SCOPE and FIRE.

## What it does
1. `apply(playerGui)` — the whole surface. Positions each cluster button as
   `right edge = OUTER_RIGHT * screenWidth - offset * jumpDiameter` and
   `bottom edge = OUTER_BOTTOM * screenHeight - offset * jumpDiameter`,
   so internal spacing is rigid in one unit and only the cluster's distance from the screen edge tracks width — the one relationship that genuinely is about width
2. **`OUTER_RIGHT` (0.965) and `OUTER_BOTTOM` (0.975) are the only two values that move the whole cluster.** Every button is an offset from that corner, so the shape survives retuning either. 0.965 was tuned on device: the reference's 0.922 read as the cluster floating (74pt of air on an 800pt phone), 0.985 was too tight
3. **Offsets are keyed to the JUMP button's RENDERED diameter ("JD"), not to screen height.** Every button carries a `UISizeConstraint` and on a tablet all five hit `MaxSize` — an iPad 10th is 820pt tall, so JUMP's ideal 0.200H is 164pt against a 135pt ceiling. The buttons stop growing but a height-derived offset does not, and the cluster spreads (measured under the older sizes on that iPad: FIRE-to-JUMP opened to +38pt, SPRINT-to-JUMP to 102pt). JUMP is the reference because every hunter has one, unlike SCOPE, and it is both the lowest button and one notch inboard of the outer column
4. The vertical axis had the identical bug one step removed, and was left unresolved on the assumption that height-fraction gaps are rigid. They are, right up until a `MaxSize` binds: on a 13in iPad every vertical gap inflated by exactly the clamp ratio 192/110 = 1.74x (SCOPE→FIRE 33pt → 95pt, RELOAD→JUMP 43pt → 124pt) and the column came apart. Bottoms are now resolved by the exact mirror of the horizontal rule
5. The cluster is anchored from its **bottom**, not its top, so it keeps hugging the corner the thumb rests in. Top-anchoring also produces a tight cluster but strands 106pt of dead screen below the lowest button on a 13in iPad
6. **A width ceiling (`MAX_DIAMETER_W`, 0.092) on top of the authored pixel ceiling.** Two independent limits: the pixel `MaxSize` is about physical button size, this one is about how much horizontal room the HUD can spare. Bigger buttons push the ability row left, and past a point the row's ultimate tile collides with the ammo pips. The pass caches the designer's authored `MaxSize.X` in an `AuthoredMaxPx` attribute the first time it runs, so re-running never compounds and the authored value stays the source of truth
7. **The width ceiling is skipped entirely wherever the pixel ceiling does not already bind**, which is every phone — so it is structurally incapable of moving a handset, rather than tuned not to. The same is true of `LIFT_PER_CLAMP`, which is exactly zero when nothing clamps. `BOTTOM_LIFT_JD` (0.4321) is the one universal term, and it was read off a live playtest in which the buttons were dragged into place by hand
8. `OFFSET_H` / `OFFSET_V` are likewise no longer derived — they are measured off that hand-placed playtest and converted into height fractions. The derivation tables in the module header are how it got there, not what it is now

## The layout it currently holds (re-placed by hand 2026-08-15)
Measured on a Galaxy A06 (800×360, aspect 2.22) in the `ScreenInsets = None` screen the buttons live in, which the engine reported as 799×359:

| button | right | bottom | diameter | size |
|---|---|---|---|---|
| SCOPE | 771 | 195 | 66.1 | 0.184H |
| JUMP | 759 | 319 | 71.8 | 0.200H |
| FIRE | 719 | 249 | 71.8 | 0.200H |
| RELOAD | 659 | 189 | 44.0 | 0.1226H |
| SPRINT | 642 | 249 | 50.3 | 0.140H |

9. **SCOPE alone holds the outer column; JUMP is one notch inboard of it and is the lowest button**, so JUMP is the base every vertical offset is measured up from. The previous shape — SCOPE and JUMP sharing the column, SPRINT on the bottom row, FIRE and JUMP deliberately touching at the corner — is gone
10. **The cluster no longer hugs the bottom corner.** JUMP's bottom edge is 0.888H, 40pt clear of the screen edge. That lift is what lets the HUD's ability row slide right underneath the cluster, and it is why only JUMP still reaches into the row's vertical band
11. **RELOAD's `SIZE_H` is 0.1226, not the 0.100 it was authored at.** 0.100 was never the size anyone saw: the button's own `MinSize` of 44pt overrode it on the reference device (0.100 × 359 = 35.9), so 0.1226H is the fraction that renders those same 44pt without the clamp, and it keeps RELOAD's proportion on taller screens instead of letting it fall back toward half a jump

## Gotchas
- **The five authored `MaxSize` values must stay proportional to each other**, at 135 × the button's size ratio — 135 / 135 / 124 / 95 / 83 for JUMP / FIRE / SCOPE / SPRINT / RELOAD. `apply` gates the width ceiling **per button**, engaging only once that button's own natural size passes its own `MaxSize`, so maxima that are not in the same ratio as `SIZE_H` cross at different screen heights and for a whole band of devices some buttons are clamped while others are still growing. Found 2026-08-15 the moment `SIZE_H` changed underneath the old maxima (139/135/134/113/73): on a 1024×768 iPad 6th, JUMP was clamped to 94pt while SPRINT was still free at 107.5pt — the small button rendering *larger* than the big one, with nothing erroring. At 135 × ratio all five reach their ceiling together at H = 675
- **`SIZE_H` never sets a size** — the `Size` authored on each button in StarterGui does, and this table only feeds the tablet width ceiling. They have to be kept equal by hand
- **Which cluster buttons reach the ability row's band is what `BOTTOM_LIFT_JD` is really tuning.** The row is clamped against every button that overlaps it and the leftmost wins — no partial credit. Under this layout that is JUMP alone, the rightmost button there is, so the row gets as much width as the cluster can give it. FIRE clears the band by only ~2pt on the reference device: lowering the cluster, raising FIRE toward SPRINT, or growing the intro tags pulls FIRE in and steps the row ~40pt left. A degradation rather than a bug — the clamp only ever holds the row *further* from the buttons — but invisible in source and only visible on a device
- `JUMP_CLEARANCE` in HunterMobileSprintButton is a safety clamp that must stay **below** the SPRINT→JUMP figure here or it fights this table. It is **inert at every aspect** under this layout: SPRINT sits 1.797 JD inboard of the outer column against JUMP's 0.167, so SPRINT's right edge is always ~0.126H clear of JUMP's left. Re-check it only if SPRINT moves back out toward the column
- **FIRE and JUMP no longer touch.** They used to overlap by ~0.005H at the corner deliberately; the 2026-08-15 hand placement put 40pt between them (FIRE's right edge 0.900W against JUMP's 0.950W). Anything written on the assumption that the corner pair is a single visual unit is out of date
- `AbsoluteSize` reads 0 before the first layout pass and can read NaN; both are rejected rather than clamped, since arithmetic passes NaN straight through
- **A button's size is read at REST** (`restingSize`, 2026-08-10). `AbsoluteSize` includes any `UIScale`, and the onboarding tutorial pulses SPRINT / FIRE / RELOAD to 1.22 on their authored `BreatheScale` to point the player at them — as of 2026-08-26 HunterHudShake also pulses all five on landing, and JUMP and SCOPE were given a `BreatheScale` of their own to make that uniform. Since this pass is idempotent by design — it reads the live screen and writes an absolute result — a pass that lands mid-pulse would place the cluster from the animated diameter and place it somewhere different a frame later, which is the one thing the layout is built not to do. The helper divides the scale back out; with no scale, or a scale of 1, it returns `AbsoluteSize` unchanged, so nothing outside a cue measures differently than before
- **`jumpDiameter` was the one raw read left**, and it was the worst place for one: it is the unit every other button's position is expressed in, so a UIScale on JUMP moved the whole cluster and put it back. It survived because nothing scaled JUMP — the tutorial never cues it, so it had no `UIScale` at all — until the landing shake gave it one. Routed through `restingSize` on 2026-08-26

## `GuiNames` is the cluster's membership list
Exported as an array and derived from `OFFSET_H`, so callers outside this module do not keep their own copy. A button added to the layout is in the cluster by definition; the failure mode of a hand-kept list is that it silently covers four buttons out of five. Order is not meaningful — `apply` itself walks the table in `pairs` order. HunterMobileSprintButton's own `CLUSTER_GUI_NAMES` predates this and is still a separate literal.

## Dependencies
- **Requires:** Nothing
- **Required by:** HunterMobileSprintButton, HunterMobileJumpButton, HunterHudShake

## Connections
### RemoteEvents
None

### BindableEvents
None

### Direct require()
None
