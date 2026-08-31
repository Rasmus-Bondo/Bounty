---
tags: [shared, modulescript, client, ui, mobile]
path: game.ReplicatedStorage.Hunters.Shared.HunterMobileReloadButton
type: ModuleScript
lines: 234
---

# HunterMobileReloadButton

Shared OOP class for the visible on-screen **RELOAD** button on mobile — the smallest button in the bottom-right touch cluster, sitting inboard of FIRE. Sibling of HunterMobileFireButton, HunterMobileSprintButton and HunterMobileJumpButton.

Exists because mobile had no manual reload at all: HunterAutoReload covers the transition to empty and R covers PC, which left touch players unable to top up a part-full cylinder before a fight.

## What it does
1. `.new(config)` — `{Player, OnActivated, GuiName?, ButtonName?, AnchorPoint?, Position?, Size?, Text?, DisplayOrder?}`. Defaults to a round "RLD" button in a ScreenGui named "HunterReloadGui", anchored `(1,1)` at `(0.8248, 0.5265)`, sized `0.1226` of viewport **height** (squared by a 1:1 `UIAspectRatioConstraint`, clamped 44–83px). **These defaults are the legacy fallback only** — the button is authored in StarterGui and they are kept equal to it. `ScreenInsets = None`; see HunterMobileFireButton for the inset measurements and for why the X size scale must stay non-zero
2. **It does NOT contain a reload pipeline.** Each hunter's combat client already owns a `startReload()` with its own gating — mid-ability, mid-dash, already reloading, already full — so the caller passes `OnActivated` and keeps that logic where it lives. The same split HunterMobileFireButton uses for firing
3. `:Start()` — builds only on touch devices, using the same deferred `TouchEnabled` poll as the other cluster buttons. Prefers the button authored in `StarterGui.HunterReloadGui > MobileReloadButton` (shipped `Enabled=false`) and sets `ScreenGui.Enabled = true`; only builds one at runtime if none exists. Tags the ScreenGui with a `MobileCombatButton` attribute so RoundClientController re-enables it after intermission rather than restoring the authored `Enabled=false`
4. `:Destroy()` — disconnects; the ScreenGui is left parented (PlayerGui owns its lifetime across respawns)

## Gotchas
- **The reference layout's reload slot is unusable.** It puts reload small and inboard of fire, which lands on the ability intro tags' reserved wrap lines. The whole cluster is now lifted clear of the tag band instead (see `BOTTOM_LIFT_JD` in HunterMobileClusterLayout), which puts RELOAD's bottom edge at 0.527H — well above the row rather than beside it
- **`MinSize` is the one clamp allowed to distort the cluster.** `MaxSize` is proportional to the jump button's 135 ceiling (0.1226 / 0.200) so the cluster keeps its shape on tablets, but `MinSize` is a flat 44 — the legal touch-target floor
- **`MinSize` silently overrode this button's authored size for months.** It was authored at 0.100H, which is 35.9pt on the 359pt reference screen, so the 44pt floor won and 0.100 was never the size anyone actually saw or signed off. Corrected to 0.1226H on 2026-08-15 — identical on the reference device, and it holds RELOAD's proportion on taller screens instead of letting it drift back toward half a jump diameter. If you change this size, check it against `MinSize` before believing the number

## Dependencies
- **Requires:** Nothing
- **Required by:** FPSRevolverClient (Dust), CardsClient (Fortuna), SunspikeClient (Vesper), GrudgekeeperClient (Bram)

## Connections
### RemoteEvents
None

### BindableEvents
None

### Direct require()
None
