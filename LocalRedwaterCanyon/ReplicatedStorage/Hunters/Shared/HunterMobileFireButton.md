---
tags: [shared, modulescript, client, ui, mobile]
path: game.ReplicatedStorage.Hunters.Shared.HunterMobileFireButton
type: ModuleScript
lines: 326
---

# HunterMobileFireButton

Shared OOP class that creates the visible on-screen **FIRE** button for mobile players — its own `ResetOnSpawn=false` ScreenGui, gated on `UserInputService.TouchEnabled` so it only appears on touch devices. Extracts the formerly inline `createMobileFireButton` helpers that were duplicated (and had drifted) across Dust's HunterGuiClient, VesperHunterGuiClient, and BramHunterGuiClient, and adds the button to Fortuna's CardsHunterGuiClient. Sibling of HunterMobileAbilityButton, which covers ability frames rather than the primary fire, and of HunterMobileSprintButton, HunterMobileJumpButton and HunterMobileReloadButton.

**Layout as of 2026-08-08:** FIRE is one of five buttons in a single bottom-right cluster (SCOPE / FIRE / RELOAD / JUMP / SPRINT), all on the aiming thumb. It no longer hugs the screen edge and no longer owns its own column — it sits inboard of the outer JUMP/SCOPE column. The earlier arrangement put SPRINT on the left edge above Roblox's thumbstick on the reasoning that movement verbs belong to the movement thumb; the reference layout groups all five, and device testing agreed.

Exists because `UserInputService.TouchTap` only fires on finger *release* after Roblox's tap-vs-drag heuristic, which lags shooting and steals taps meant for aiming. A real button fires immediately on press.

## What it does
1. `.new(config)` — constructs from `{Player, OnActivated?, OnHoldStart?, OnHoldEnd?, GuiName?, ButtonName?, AnchorPoint?, Position?, Size?, Text?, DisplayOrder?}`. Defaults to a round red "FIRE" button in a ScreenGui named "HunterFireGui", anchored `(1,1)` at `(0.8999, 0.6936)` and sized `0.200` of viewport **height** (squared by a 1:1 `UIAspectRatioConstraint` with `DominantAxis = Height`, clamped 58–135px). `MaxSize` is proportional to the jump button's 135 ceiling — since 2026-08-15 FIRE and JUMP are the same size, so it matches exactly — and all five maxima have to move together or the cluster loses its shape on tablets; see HunterMobileClusterLayout.
   - **Both axes of the applied position are owned by HunterMobileClusterLayout, not by these defaults.** The authored values are the fallback and the shape reference; the live position is resolved every pass off the jump button's rendered diameter, because a `UDim2`'s X cannot reference height and the button is sized off height. That module is invoked from HunterMobileSprintButton's ordered layout pass, so nothing here calls it.
   - **The ScreenGui uses `ScreenInsets = None`.** The default `CoreUISafeInsets` shrinks the GUI rect by ~62pt per side (measured 831×418 inside a 956×440 viewport), which left a visible gap between the button and the physical screen edge on a real handset. `DeviceSafeInsets` measures identically to `CoreUISafeInsets` in Studio's simulator, so it cannot be evaluated there. The `-20` edge offset absorbs rounded corners; if a button ever lands under a camera cutout on some device, `DeviceSafeInsets` is the safer fallback.
   - This puts the button in a **different inset space from the HUD canvas** (`HunterGuiMobile`, which stays on `CoreUISafeInsets`), so clearances between the two can only be checked in absolute coordinates — never by comparing scale values.
   - **Size is a fraction of height, not fixed pixels.** At the old fixed 132px FIRE was 39% of screen height on a 338pt-tall phone and 25% on a wide one.
   - **The X size scale must stay non-zero.** `AspectType.FitWithinMaxSize` fits the square inside the element's own box, so `UDim2.new(0, 0, 0.25, 0)` collapses it to 0×0 and only the `UISizeConstraint` `MinSize` keeps it on screen.
   - **FIRE's bottom edge (0.694H) clears the ability row's tag band by only ~2pt** on the reference device. That is the tightest relationship in the whole touch layout: lowering the cluster, raising FIRE toward SPRINT, or growing the intro tags pulls FIRE into the band, at which point it — not JUMP — becomes the leftmost button the row clamps against, and the row steps ~40pt left. A degradation rather than a bug, since the clamp only ever holds the row *further* from the buttons, but it is invisible in source and only shows on a device.
   - **Raising FIRE pushes SCOPE up with it**, and SCOPE is bounded above by the pixel-pinned settings gear. On the smallest phone tested that chain leaves only ~10–12pt of slack, so don't raise this further without re-measuring the gear clearance.
   - **FIRE and JUMP no longer touch.** They used to overlap by ~2pt at the corner deliberately; the 2026-08-15 hand placement put 40pt between them.
   - **The authored button carries an icon, not text** (2026-07-30). `Text` is `""` and an `ImageLabel` named `Icon` sits centred at `0.58` of the button with `ScaleType = Fit`. This is safe because `button.Text = self.Text` is only assigned on the **runtime fallback** path — the authored StarterGui button is never written to, so the cleared text sticks across spawns. The fallback still builds a worded button; it is legacy and only reached if the ScreenGui is missing entirely.
   - The icon is **cropped to the art's tight opaque bounds** with `ImageRectOffset` / `ImageRectSize`, the same rule the kill-feed weapon icons need. All three button icons are 1024×1024 but bake in different transparent margins — FIRE's art fills 81% of its canvas, SPRINT's 73%, SCOPE's 70% — so dropped uncropped into equal boxes they render at visibly different sizes. Cropped, one `0.58` scale means the same thing on all three. FIRE's crop is `825×801` at `(118,130)`; measure with `EditableImage:ReadPixelsBuffer` rather than eyeballing if the art is ever re-exported.
   - The authored `UIPadding` (L/R `0.15`, T/B `0.28`) was **removed** when the icon landed. It existed only to fit the word inside the round button, and it left an icon just `0.44` of the button's height. SCOPE never had one, so removing it also makes the three buttons structurally identical.
2. **It does not resolve its own position.** Until 2026-08-08 it did: FIRE hugged the right screen edge and re-derived its horizontal inset against the live HUD (`_applyEdgeInset` / `_watchEdgeInset`, clamping against the ability row found by structure through HunterIntroTags' `findHosts`). The cluster rebuild inverted the relationship — FIRE moved inboard to a static slot and the HUD's ability row is now what gives way — which left that path **unreachable**: `_watchEdgeInset` was no longer called from `:Start()`, so it hooked nothing and wrote nothing. It was **deleted on 2026-08-08** along with the module's only `require`, taking the module from 436 to 322 lines. `HunterMobileClusterLayout.apply` owns every cluster button's position on both axes; the row's side of the negotiation lives in HunterMobileSprintButton's `_applyAbilityRowInset`.

   Its measurements are kept as a comment in the source rather than in the deleted code, because they are what a future "just author a static offset" attempt would otherwise rediscover the hard way: **with FIRE on the screen edge, its clearance from the ability row is *horizontal*, and how much of it exists tracks aspect ratio rather than width — and not monotonically.** Resolved insets at a 0.09 reach, measured against a live HUD clone with real tags attached:

   | Aspect | Device | Width | Resolved inset |
   |---|---|---|---|
   | 1.44 | iPad 10th | 1177 | 71 — **clamped** (asked 105) |
   | 1.78 | iPhone 7 / SE | 665 | 39 — **clamped** (asked 59) |
   | 2.18 | iPhone 16 Pro Max | 955 | 85 |
   | 2.23 | Galaxy A06 | 798 | 71 |
   | 2.80 | wide / foldable | 1657 | 149 |

   The two clamped rows were hard against the ability row, so no larger reach could have moved them.
   - **An earlier version of this table was wrong** (it claimed a 20pt ceiling at 1.78 and 43pt at 1.44, and drove an original 0.045 reach). Re-measured, the gap at the authored floor is 32pt on 1.78. The tags land **1pt inside** their `MainFrame` on every slot, confirming the frame was the correct conservative bound — a tag is 0.95 of its icon and centred, so it can never be the wider of the two.
3. `:Start()` — builds only on touch devices. It does **not** sample `UserInputService.TouchEnabled` once: Studio's device emulator leaves `TouchEnabled` `false` for the first moment after client scripts start (it flips true a beat later), so a one-shot check would early-return and the button would never appear in the emulator. Instead it builds immediately if touch is already on, else polls for up to ~12s and builds the instant `TouchEnabled` flips true; a real non-touch PC never flips it, so nothing is built. Once triggered it resolves the button and wires input. It **prefers a button authored in `StarterGui`** (`StarterGui.HunterFireGui > MobileFireButton`, shipped `Enabled=false`) — `WaitForChild(GuiName, 3)` picks up the PlayerGui clone so designers can tweak Position/Size/style in the editor without the runtime overwriting them — and sets `ScreenGui.Enabled = true` (reached only on touch). It also tags the ScreenGui with a `MobileCombatButton` attribute (read by `RoundClientController`) so the round HUD manager re-enables it when gameplay is restored after intermission, instead of snapshotting the authored `Enabled=false` and re-hiding it for the whole round. Only if no authored ScreenGui exists does it build + style a fresh one at runtime (legacy fallback). All four hunters now share the single `HunterFireGui` name (the old per-hunter `FortunaFireGui`/`VesperFireGui`/`BramFireGui` overrides were removed), so there is one editor object to tweak.
4. Two activation styles (pick one per hunter):
   - **Tap** — pass `OnActivated`; fired on `Activated`, one call per tap (Dust / Vesper / Bram single-shot weapons).
   - **Hold** — pass `OnHoldStart` / `OnHoldEnd`; press fires the start, release fires the end, so the caller can drive press-and-hold auto-repeat (Fortuna's card throw, matching PC click-and-hold). Hold tracks the exact InputObject and releases via the global `UserInputService.InputEnded`, so dragging the finger off the button still ends the hold and unrelated touches (movement thumbstick) don't cancel it.
5. `:Destroy()` — disconnects connections, releases any active hold, and leaves the ScreenGui parented (PlayerGui owns its lifetime across respawns).

## Dependencies
- **Requires:** Nothing — the `HunterIntroTags` require went with `_applyEdgeInset` on 2026-08-08 (item 2)
- **Required by:** HunterGuiClient (Dust), VesperHunterGuiClient, BramHunterGuiClient, CardsHunterGuiClient (Fortuna)

## Connections
### RemoteEvents
None

### BindableEvents
None

### Direct require()
None
