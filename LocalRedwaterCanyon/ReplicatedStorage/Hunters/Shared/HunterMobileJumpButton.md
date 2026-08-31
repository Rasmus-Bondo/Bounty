---
tags: [shared, modulescript, client, ui, mobile]
path: game.ReplicatedStorage.Hunters.Shared.HunterMobileJumpButton
type: ModuleScript
lines: 331
---

# HunterMobileJumpButton

Shared OOP class for the visible on-screen **JUMP** button on mobile, and the suppressor for Roblox's built-in touch jump button. Sibling of HunterMobileFireButton, HunterMobileSprintButton and HunterMobileReloadButton; it occupies the outer column of the bottom-right cluster, directly under FIRE and sharing that column with Vesper's SCOPE.

Exists because Roblox's own jump button is a fixed size in a fixed corner and cannot be restyled or moved, so it could never sit where the rest of the touch cluster wanted it.

## What it does
1. `.new(config)` — `{Player, OnActivated, GuiName?, ButtonName?, AnchorPoint?, Position?, Size?, Text?, DisplayOrder?}`. Defaults to a round button in a ScreenGui named "HunterJumpGui", anchored `(1,1)` at `(0.950, 0.8886)`, sized `0.200` of viewport **height** (squared by a 1:1 `UIAspectRatioConstraint`, clamped 56–135px). **These defaults are the legacy fallback only** — the button is authored in StarterGui and they are kept equal to it so a runtime-built one cannot render a different cluster from the real one. `ScreenInsets = None`; see HunterMobileFireButton for the inset measurements and for why the X size scale must stay non-zero
2. **Jump INPUT is not owned here.** ManuelJumpClient owns it, including the `canJump()` gate every movement lock in the game is honoured through, so this button only reports a press. Wiring it straight to `Humanoid.Jump` would punch through every ability lock — which is the exact bug that gate exists to prevent
3. **Hides Roblox's built-in touch jump button.** It lives at `PlayerGui.TouchGui.TouchControlFrame.JumpButton`, but every step of that path is created lazily by the PlayerModule and re-created when the control scheme changes, so the match is on **name** across PlayerGui descendants — present and future — rather than a path walk. `Visible` is re-applied rather than set once, because PlayerModule's TouchJump sets it back to true whenever it re-enables (respawn, control-scheme change, jump being re-allowed)
4. `:Start()` — builds only on touch devices, using the same deferred `TouchEnabled` poll as the other cluster buttons (Studio's emulator leaves `TouchEnabled` false for the first moment after client scripts start, so a one-shot check would early-return and the button would never appear). Prefers the button authored in `StarterGui.HunterJumpGui > MobileJumpButton` (shipped `Enabled=false`) and sets `ScreenGui.Enabled = true`; only builds one at runtime if none exists. Tags the ScreenGui with a `MobileCombatButton` attribute so RoundClientController re-enables it after intermission rather than restoring the authored `Enabled=false`
5. `:Destroy()` — disconnects; the ScreenGui is left parented (PlayerGui owns its lifetime across respawns)
6. **`.onPressed(fn)` — a module-level subscription to the raw press** (2026-08-08), fanned out after `OnActivated` with a `pcall` per listener so one subscriber throwing cannot swallow the press for the ones after it. Returns a disconnect function. It is module-level rather than per-instance because a subscriber has no handle on the single button ManuelJumpClient builds, and every client script shares one require cache. This exists because behavior 2 plus behavior 3 together silently removed jump input from any hunter that layers its own jump on top — see the gotcha below

## Gotchas
- **A hunter with its own jump gets NOTHING from this button unless it subscribes.** CardsClient reaches Fortuna's double jump through a context action and through `UserInputService.JumpRequest`; a press here raises neither, because this is a plain `TextButton` and behavior 3 hides the built-in touch button that used to raise `JumpRequest` on a phone. Fortuna's air jump therefore stopped working on mobile the day this shipped, while her ground jump kept working through ManuelJumpClient's own handler — a half-broken symptom that pointed at the double jump rather than at the input. Fixed 2026-08-08 by having CardsClient subscribe via `onPressed`. A subscriber **must** drop the subscription in its hunter-switch teardown: this button outlives every hunter, so a stale listener runs the outgoing hunter's jump for the incoming one
- The default position is a **static constant and deliberately does not mirror the fire button.** It briefly did, back when FIRE hugged the screen edge and resolved its own inset against the live HUD at runtime. The 2026-08-08 cluster rebuild moved FIRE inboard to its own slot, so there is nothing left to track, and mirroring it now would drag JUMP out of its column
- JUMP is the reference button for the whole cluster's scale — HunterMobileClusterLayout expresses every other button's offset as a multiple of JUMP's rendered diameter, and its 135pt ceiling is the number the other four maxima are derived from. Changing its size or its ceiling rescales the entire cluster, and since 2026-08-15 it also rescales the HUD's ability row, which is sized against the same diameter
- **JUMP is the lowest button and the only one that reaches into the ability row's vertical band**, so it alone decides how far right the row can slide. It is the rightmost button of the five, which is why the row can now run all the way over to it
- **The authored button's `Icon` sits at `0.84`, not the `0.58` its four siblings use — do not "correct" it.** The icon swapped on 2026-08-08 to `rbxassetid://120949938372211`, whose artwork occupies only 53% of its 1024² canvas where the previous asset filled 77%. `ScaleType = Fit` fits the *canvas*, so at a matched 0.58 the visible glyph rendered 0.30 of the button side against 0.40–0.47 for FIRE / SPRINT / RELOAD / SCOPE — visibly the runt of the cluster. 0.84 puts the rendered glyph at 0.437 × 0.445, level with its neighbours. **The number to match across these five buttons is the rendered glyph, not the `Icon.Size` property**, and the two only agree while the assets are padded alike. Measure a replacement's opaque pixel bounds before setting a size; the button's own `Size`, `UISizeConstraint` and `UIAspectRatioConstraint` are not involved and must not be touched to fix an icon
- **The runtime fallback button has no icon at all.** `_buildButton` only styles a button when none is authored, and that path sets `Text = "JUMP"` with no `Icon` child — while the shipped authored button is icon-only (`Text = ""`). The fallback is legacy and normally unreachable, but anything reasoning about this button's appearance from the module source alone will describe a button players never see

## Dependencies
- **Requires:** [[HunterMobileClusterLayout]]
- **Required by:** ManuelJumpClient (builds it), CardsClient (subscribes via `onPressed` only — it never constructs a second button)

## Connections
### RemoteEvents
None

### BindableEvents
None

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[HunterMobileClusterLayout]] | `.apply(playerGui)` | Resolve this button's slot in the bottom-right cluster on both axes; it cannot be authored because the button is sized off height and a UDim2's X cannot reference height |
