---
tags: [shared, modulescript, client, ui, mobile, layout]
path: game.ReplicatedStorage.Hunters.Shared.HunterMobileSprintButton
type: ModuleScript
lines: 1063
---

# HunterMobileSprintButton

Shared OOP class for the visible on-screen **SPRINT** toggle on mobile — its own `ResetOnSpawn=false` ScreenGui, gated on `UserInputService.TouchEnabled`. Replaces the old left-screen-half double-tap-to-sprint gesture that used to live in SprintController; a dedicated toggle is clearer on touch and doesn't fight taps meant for aiming.

**It is also where the whole bottom-right touch cluster's ordered layout pass lives**, which is why it is far larger than its siblings. That responsibility is historical — SPRINT used to be the leftmost button in the row's band and therefore the thing the HUD's ability row clamped against — but the pass now drives every button and the row, so it stayed here rather than being duplicated.

**As of 2026-08-08 SPRINT is on the RIGHT**, inboard of JUMP, as part of the five-button cluster (SCOPE / FIRE / RELOAD / JUMP / SPRINT). It previously sat on the left edge above Roblox's movement thumbstick on the reasoning that sprint is a movement verb; the reference layout the touch UI was rebuilt against groups all five on the aiming thumb instead, and device testing agreed.

## What it does
1. `.new(config)` — `{Player, SprintController, GuiName?, ButtonName?, AnchorPoint?, Position?, Size?, Text?, DisplayOrder?}`. Defaults to a round "SPRINT" button in a ScreenGui named "HunterSprintGui", anchored `(1,1)` at `(0.8035, 0.6936)`, sized `0.140` of viewport **height** (squared by a 1:1 `UIAspectRatioConstraint`, clamped 47–95px). `MaxSize` is proportional to the jump button's 135 ceiling (scaled by 0.140 / 0.200) so the cluster keeps its shape on tablets; `MinSize` is a touch-target floor and is not. **These defaults are the legacy fallback only** — the button is authored in StarterGui and they exist so a runtime-built one cannot render a different cluster from the real one. `ScreenInsets = None`; see HunterMobileFireButton for the inset measurements and for why the X size scale must stay non-zero
2. **The authored button carries an icon, not text**: `Text` is `""` and a centred `ImageLabel` named `Icon` sits at `0.58` of the button, `ScaleType = Fit`, cropped to the art's tight opaque bounds (`749×713` at `(144,156)` — the source is 1024×1024 with ~27% transparent margin). Only the **runtime fallback** path assigns `button.Text`, so the cleared text is never overwritten. The icon is unaffected by the active/inactive toggle, which only swaps `BackgroundColor3`, `BackgroundTransparency` and stroke transparency
3. `:Start()` — no-op without a `SprintController`, and builds only on touch devices. It does **not** sample `TouchEnabled` once: Studio's emulator leaves it false for the first moment after client scripts start, so a one-shot check would early-return and the button would never appear there. Prefers the button authored in `StarterGui.HunterSprintGui > MobileSprintButton` (shipped `Enabled=false`), sets `ScreenGui.Enabled = true`, and tags it with a `MobileCombatButton` attribute so RoundClientController re-enables it after intermission rather than restoring the authored `Enabled=false`. It captures the resolved button's current colour as the **inactive** appearance, so a designer-chosen base colour survives the toggle
4. On tap → `SprintController:ToggleMobileSprint()`, and it subscribes to `SprintController:OnMobileSprintChanged` so it un-highlights when sprint is cancelled elsewhere (shooting drops you out of sprint, as do death and round end)
5. `:Destroy()` — disconnects the activation connection and the sprint-change subscription; the ScreenGui is left parented (PlayerGui owns its lifetime)

## The ordered layout pass (`_watchClusterLayout`)
The dependency runs one way and the order is not optional:

> cluster slots → jump clearance → the ability row's SIZE → the ability row's POSITION

Clamping the row first and moving the buttons afterwards would strand the row against a stale edge.

6. **Step 0 — `HunterMobileClusterLayout.apply`** places every cluster button. Must come first: both later steps measure those buttons' edges
7. **Step 0.5 — `_seedAbilityRow`** puts a freshly rebuilt row straight onto the placement the last round settled on. The HUD is rebuilt from **authored** positions on every spawn, so without this the row is re-derived from scratch in front of the player each round. Only reused at the same canvas width — the stored value is a scale but the clamp that produced it is a pixel gap, so after a rotation or resize it falls through to measuring
8. **`_applyJumpClearance`** is a safety net against overlap, not a spacing rule, so `JUMP_CLEARANCE` (4) must stay **below** the gap the cluster layout actually lays out. At 12 it fought the layout and pushed the cluster back apart. Under the 2026-08-15 layout it is **inert at every aspect** — SPRINT sits 1.797 jump diameters inboard of the outer column against JUMP's 0.167, so the two are never within 4pt
9. **`_applyAbilityRowInset`** slides the HUD's ability row left until it clears the cluster, and packs the ultimate tile against the first ability tile so all three read as one row. `ROW_CLEARANCE` (11) is the one knob that moves the row horizontally — the row is clamped to `(leftmost cluster button in its band).left - ROW_CLEARANCE`, so +1 here is −1pt of row. It went 12 → 6 → 11 over 2026-08-08: 12 left a visible channel, 6 read as too tight on device
10. The ultimate's packing **cannot** be authored as a fixed canvas-X offset, which is what it was and why the ultimate overlapped the first ability on a real handset: the tiles are sized `RelativeYY` (off canvas HEIGHT) while their positions are canvas-X scales, so how much canvas WIDTH a tile occupies changes with aspect. Measured and re-packed every pass, it cannot drift
11. The row measures the **rightmost tile, not the rightmost frame** — `AbilityFrame` is a grid container wider than the icons in it, so its own edge over-reports by half a cell
12. It asks the **live cluster** which button is leftmost in the band rather than assuming. Before the 2026-08-08 rebuild SPRINT was leftmost and hard-coding it was correct; under the 2026-08-15 layout the cluster is lifted clear of the row and JUMP — the rightmost button of the five — is the only one still reaching into the band, which is what lets the row run all the way over to it

## Sizing the row to the cluster (`scaleAbilityRow`, 2026-08-15)
13. **The row and the cluster scale off different things, and on a tablet they come apart.** Every cluster button is a fraction of screen HEIGHT; the HUD `Canvas` is aspect-locked at 7.4 and takes the *smaller* of 0.95 × screen width and 0.23 × screen height. On a phone the height term binds (or ties, at 16:9) and the two track each other — the canvas measures 1.150 jump diameters tall on the A06 reference and 1.150–1.158 on an iPhone 7, 6 Plus, XR, 13, 16 and 16 Pro Max. On a 4:3 tablet the **width** term binds instead and the canvas reaches ~1.40, so the tiles run ~21% oversized against the cluster, and so do the intro tags, whose text ceiling is a fraction of the tile they label
14. That is why the row could not reach JUMP on a tablet: the tag band grew with the tiles until it reached above SPRINT's bottom edge, SPRINT became the leftmost button in the band, and behavior 9 correctly but uselessly held the row ~137pt further left than the phone layout puts it (measured on a 1024×768 iPad 6th)
15. `CANVAS_PER_JUMP` (1.1504) is the A06 reference ratio, so **every phone resolves to a scale of exactly 1.00 and cannot be moved by this** — the same "keyed to the overshoot, so it is zero when there is none" construction `LIFT_PER_CLAMP` uses. 4:3 and 16:10 tablets resolve to ~0.82; a 1.6-aspect tablet (Redmi Pad SE, Tab A8) is already in proportion and also resolves to 1.00
16. The scale is written to **`AbilityFrame` and `UltimateFrame`'s `Size`**, not to a `UIScale`. The grid inside `AbilityFrame` is authored entirely in scale (`CellSize` 0.485 × 0.97, `CellPadding` 0.03), so shrinking the container takes the tiles *and* the gaps between them with it; the tiles are `RelativeYY`, so their diameter follows the container's height
17. It is keyed to the **canvas**, not to a measured tile, because the canvas is the one rect in this negotiation the function does not itself resize — so there is no pass where it reads back a size the engine has not laid out yet and squares its own scale. The scale applied is recorded as a `RowScale` attribute on each frame and divided back out next pass, which makes it idempotent with no memory of the authored size; a rebuilt HUD arrives with no attribute, reading as 1, which is correct because it also arrives at its authored size

## Three traps in the band measurement, all hit for real
18. **The band must INCLUDE the intro tags.** Measuring the tiles alone was tried and is wrong even though a tag never reaches further right than its own tile (+0.0pt on every slot) — that only means a tag cannot *widen* the row, and says nothing about the space *above* the icons, which is exactly where the lifted cluster sits. Dropping the tags let the row slide 53.7pt right and put RELOAD straight through the third tag by 25.4pt
19. **…but only the tag's VISIBLE TEXT, not its box.** A tag reserves three wrap lines and bottom-aligns its text, so most of its box is deliberately empty air. Counting the box made the band ~35pt taller than anything visible and dragged RELOAD into the row: measured live on an iPhone 7, a 49pt tag box carrying 14pt of text, with RELOAD's bottom 8.2pt clear of the nearest visible text while overlapping the empty box by 18.4pt. `TextBounds` is the right measure even though it over-reports on real handsets, because over-reporting only makes the band *taller* — it errs toward holding the row left, never toward an overlap
20. **Resolving once is not enough, and the canvas edge is not a fallback.** Two things grow the row's obstacles a beat *after* the HUD appears: the intro tags (attached on a 0.25s retry once the round is live) and the cluster buttons (re-enabled by RoundClientController on the same boundary). Breaking on first success locked in the pre-tag answer, which then sat there wrong until something unrelated re-triggered the pass — picking up a health pack parents a ScreenGui into PlayerGui and the row snapped left mid-fight. It now requires `SETTLE_PASSES` (6 × 0.25s = 1.5s) of stillness, and a pass where **no** cluster button shares the band returns "not resolved" rather than clamping to the canvas edge, which would slide the row right and then drag it back the instant the buttons appear

## Gotchas
- **Do not reach for a `UIScale` to size the ability row.** HunterIntroTags recomputes each tag's box and text-size ceiling from its host tile's `AbsoluteSize` on every change, and `AbsoluteSize` includes a `UIScale` — so a scaled tile would be re-measured already-scaled and the tag would come out scaled twice. Writing the frames' `Size` instead means the tags recompute once, linearly, and the band `_applyAbilityRowInset` measures is the band that was actually shrunk
- The button must be created by the hunter's **combat** client (the one that calls `sprintController:Update` each frame) so it is wired to the ACTIVE controller — a GUI client's `runtime.SprintController` is a separate, unused instance
- The settled row placement is cached at **module level**, not per-instance, so it survives a hunter switch rebuilding the object. A stale seed from another hunter is still far closer than the authored position, and the measure loop corrects it either way
- `AbsolutePosition` is directly comparable between the cluster buttons and the HUD even though they are in different inset spaces (`None` vs `CoreUISafeInsets`) — the `None` gui simply reports a negative origin. Scale values are **not** comparable
- Every measurement rejects NaN and zero rather than clamping: `AbsoluteSize` reads 0 before the first layout pass and can read NaN, and arithmetic passes NaN straight through
- **Both writers measure the button's RESTING rect, not its live one** (`restingRect`, 2026-08-10). `AbsoluteSize` and `AbsolutePosition` include any `UIScale` on the object, so a button in the middle of an animation reports the animated rect — and the tutorial's cue pulses SPRINT, FIRE and RELOAD to 1.22 on their authored `BreatheScale`. `restingRect` divides the scale back out and re-derives the origin through the anchor point (the anchor is the one point a `UIScale` leaves fixed, so the resting rect is exactly recoverable). Without it `_applyAbilityRowInset` clamps the ability row against a growing edge and the three tiles slide left and right in time with the pulse, and `_applyJumpClearance` — which is one-way — walks the button further left on every pass and never gives the ground back. It returns the live values untouched when there is no scale or the scale is 1, so ordinary combat measures exactly what it always did

## Dependencies
- **Requires:** [[HunterMobileClusterLayout]]
- **Required by:** FPSRevolverClient (Dust), CardsClient (Fortuna), SunspikeClient (Vesper), GrudgekeeperClient (Bram)

## Connections
### RemoteEvents
None

### BindableEvents
None

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[HunterMobileClusterLayout]] | `.apply(playerGui)` | Step 0 of the ordered layout pass — place every cluster button before measuring their edges for jump clearance and the ability row inset |
