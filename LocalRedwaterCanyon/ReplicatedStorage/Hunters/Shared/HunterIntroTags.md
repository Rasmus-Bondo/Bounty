---
tags: [shared, modulescript, ui, hunter-intro, onboarding, mobile]
path: game.ReplicatedStorage.Hunters.Shared.HunterIntroTags
type: ModuleScript
lines: 260
---

# HunterIntroTags

Builds the small "what this button does" labels that float above a hunter's ability icons — pure construction, no state and no decisions about when they appear.

## What it does
1. Replaced a full-screen intro card (`HunterIntroCard`, renamed to this). Redwater starts shooting the moment you spawn, so a panel large enough to explain three abilities stood between a new player and their first fight. Three 2-4 word action phrases resting on the icons they describe teach the same mapping without taking the screen
2. `HunterIntroTags.attach(host, text, isTouch)` builds one label above `host` — an ability's `MainFrame` — and returns it fully transparent for the caller to fade in. `HunterIntroTags.fade(label, alpha, duration)`, `.findHosts(playerGui)` and `.clear(playerGui)` are the rest of the surface
3. Exports `LabelName`, `FadeIn`, `FadeOut` and `HoldSeconds` (30) so the two scripts can't disagree. `HoldSeconds` is the `"Default"` mode window only; `"On"` and `"Off"` ignore it
4. `findHosts` matches on **structure**, not name: the HUD's ScreenGui is named per hunter (`TemplateGameGui` / `FortunaGameGui` / `VesperGameGui` / `BramGameGui`), so it looks for a top-level enabled ScreenGui whose `Canvas` holds both an `AbilityFrame` and an `UltimateFrame`, and returns the three `MainFrame`s in HUD order (Q, E, F). StarterGui also copies the ReworkedHunterGui *design folder* into every PlayerGui, but that copy sits inside a Folder rather than being a top-level ScreenGui, so the templates can never be picked up by mistake
5. **Each tag is parented INTO the HUD frame it labels** rather than floated in its own ScreenGui. Those frames are aspect-locked and their positions are owned by a `UIGridLayout`, so anything tracking them from outside would have to re-measure every frame and would still lag a resize; a child follows for free. Nothing in the HUD iterates those frames' children, so the label is invisible to the rest of the HUD code — and is destroyed along with the HUD when a hunter switch rebuilds it
6. The label is anchored to its **own bottom edge** and pushed above the icon, so reserved wrap lines extend upward into empty screen. Top-anchoring would lay a wrapped line over the icon

## Two sizing traps, both hit for real
7. **`AutomaticSize.Y` silently defeats `TextWrapped`** and is deliberately not used. Measured on the mobile HUD, `"GRAPPLE TO SURFACES"` in a 78px-wide auto-sized label reported a single 14px line with `TextFits = false` — overflowing and clipped — while the identical label given a real height wrapped to the two lines it needs. The box is instead a fixed `WRAP_LINES` (3) of headroom, bottom-aligned, so a one-line phrase still sits on the icon and the empty reserved lines cost nothing
   - **The spare line is not recoverable screen space** — raised as an open item on 2026-08-08 and closed the same day. The reserve *looks* like ~35pt of waste sitting exactly where the touch cluster now lives, but both things that lay out around these tags — HunterMobileSprintButton's ability-row clamp and HunterMobileReloadButton's slot — measure `TextBounds` rather than this box, so the empty air is already free to them. Nor would dropping to 2 shrink what they measure: the longest copy wraps to two lines **at the ceiling size** (item 7's own `GRAPPLE TO SURFACES` measurement), so a two-line box renders identically and the band is the same height either way. All it would remove is the headroom that keeps a longer future phrase — or a handset whose metrics run wider than Studio's — from being squeezed toward `MIN_TEXT` or clipped, which is precisely the failure in item 8
8. **The text size is not assigned; `TextScaled` picks it.** Computing `TextSize` from Studio's measurements is what broke this on a real phone. At 2000x865 the box measured 117px wide and Studio put `"CHARGE AND PIN"` at 22px with `TextBounds` 102px — a comfortable one-line fit, `TextFits = true`. The device rendered it wider and clipped it mid-word to `CHARGE`, exactly as `"LIFESTEAL FRENZY"` became `LIFESTEA`. Neither Studio nor the device emulator reproduces it. `TextScaled` plus a `UITextSizeConstraint` moves the judgement onto the device, where it cannot be wrong; the measured ratio only supplies the **ceiling**, which also stops `TextScaled` inflating a short phrase to fill the whole reserved box
9. Because of 8, `TextSize` goes stale and must not be read back — `TextBounds` is the only truth once `TextScaled` is on
10. Tag width is a multiple of the icon, and the two platforms need opposite sides of 1.0. The desktop `MainFrame` is 0.64 of its grid cell, leaving a third of the cell free either side (1.35 fits). The mobile one is 0.9 of a cell with 0.03 padding — on an 800x360 phone that is a 68px icon every 70px, so the icons are barely 2px apart and **any** mobile tag wider than its own icon overlaps its neighbour (0.95)
11. The box height and the gap above the icon are measured off the icon's `AbsoluteSize`, re-synced on every change. `AbsoluteSize` reads 0 before the first layout pass and can read NaN, and `math.clamp` passes NaN straight through, so both are rejected rather than clamped; the size is seeded with a real height at construction because a zero-height `TextScaled` box renders nothing. The measure connection is disconnected on the label's `Destroying`
12. An outline (`UIStroke`) rather than a backing panel — a filled plate above every icon would rebuild the visual weight the card was removed for. `fade` moves the text and its outline together, since fading only the text leaves a floating black ghost of the phrase behind

## Why it is a separate module
Split out of the client script so the layout can be built from an edit-mode plugin against a HUD clone in CoreGui — the only way to see it without a playtest. It takes everything it draws as arguments for that reason.

## Dependencies
- **Requires:** Nothing
- **Required by:** HunterAbilityIntroClient. HunterMobileFireButton also required it (`findHosts` only, to clamp its own edge inset) until that path was deleted on 2026-08-08

## Connections
### RemoteEvents
None

### BindableEvents
None

### Direct require()
None
