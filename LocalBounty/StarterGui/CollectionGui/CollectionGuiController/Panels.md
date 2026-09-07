---
tags: [client, modulescript, ui, collection, navigation, animation]
path: game.StarterGui.CollectionGui.CollectionGuiController.Panels
type: ModuleScript
lines: 695
---

# Panels

WHICH view is showing, and whether the menu is open at all. Everything here is coordination **between** the tabs rather than the content of any one of them.

## What it does
1. `setLeftMode(mode)` — HUNTERS / BOOSTS / EMOTES. Toggles the three left frames, **retitles the big panel header** in `CanvasLeft.Background.TitleFrame` (a sibling of all three, so without this it read "HUNTERS" over the boost and emote grids), hides the right-hand tab row + PREVIEW button for the two non-hunter modes, and drives the entering tab's warm-up. Entering EMOTES re-cuts the rig render window and plays the entry ripple; leaving it gives the rigs back
2. `setRightTab(tabName)` — SKINS / WEAPON / TITLES. Moves the highlight **first** so it always follows the clicked tab, then swaps `SkinFrame` / `TitlesFrame`, re-derives the selection for the entering tab, and requests fresh title ownership on TITLES-tab open (a battle-pass claim in another panel can have unlocked an account title since this menu was last built)
3. `rebuildRight()` / `updateRightSelection()` — the right-panel **dispatchers**. The two right-hand views own their own tiles; these just pick which one is showing. Injected into [[HuntersTab]] as `rebuildRight`, because selecting a hunter has to rebuild whichever view is showing but choosing between them is not hunter-grid business
4. `revealCollectionPanels` — the entrance slide: all three root frames slide in with a 0.52s Back-out tween plus a 0.94→1 `CollectionRevealScale`. `CanvasLeft` and `AbilityPanelNew` come from the left on the same frame so they travel in formation holding their gap; `CanvasRight` from the right 0.08s later
5. `setOpen(open)` — reveals after `REVEAL_DELAY` (1.8s, matching MenuHandlerScript's camera flight) or reverses over 0.24s Quad-in. Resets to HUNTERS + SKINS, resets selection to equipped, and force-hides the emote shop button (which shares PREVIEW's slot and would otherwise strand a PURCHASE button under the hunters view)
6. Owns the six menu-tab button connections and `Shop.closeMenu`
7. `init()` — the bottom-bar wiring
8. `fitPanels()` — the **narrow-screen fit**, run once at require time (before the home snapshot) and again on `ViewportSize` / `AbsoluteSize`. Squeezes `CanvasLeft`, `CanvasRight` and `AbilityPanelNew` in Y until the left tab row — which hangs below the panel and is the only part of this menu the bottom bar can swallow — lands at `0.775` of the gui (the HOME diamond's topmost visible pixel, not `CanvasBottom`'s empty top edge at `0.75`), and multiplies the panels' sub-pixel `UIStroke` so the top border draws. Interpolated on aspect: at 16:9 and wider it writes the authored Position/Size back from a snapshot, untouched

⚠ **Open/close follows the `SelectedMenuFrame` attribute** on `MainMenuGui`, which MenuHandlerScript publishes from `selectMenuFrame` — the one function **every** navigation route passes through (tab press, black-bar transition, trading-post cinematic, the `MenuNavigateRequested` bindable other panels fire). It used to hook the other four tabs' buttons instead, which only fire for navigation that *starts* on the bottom bar, so any hand-off left these panels on screen over the page underneath. The `3CollectionFrame` button hook is kept for the re-press case: pressing Collection while already on Collection changes no attribute. `setOpen` early-returns when the state already matches, so the two cannot fight.

⚠ **`init()` is called LAST by the controller, not at require time.** `task.spawn` runs its function synchronously until it yields, and `WaitForChild` returns **without yielding** when the child already exists — so if the whole main-menu tree is present this would run `applySelection()` during require, calling `setOpen(true)` before any grid had been built. The single-file version had this block at the very end of the file for the same reason.

⚠ **The fit runs BEFORE the home snapshot, and a refit retakes it.** `reveal.leftHome` / `rightHome` / `abilitiesHome` are what every open and close tweens back to, so a fit that landed after them would be undone by the next slide. The aspect is read off `Camera.ViewportSize`, never off the ScreenGui: this menu is disabled whenever it is closed, and a disabled ScreenGui keeps a stale 800x600 AbsoluteSize — exactly 4:3, which would fit a desktop as an iPad.

⚠ **The three home positions are snapshotted at startup**, not read live and not hardcoded. `setOpen(false)` can fire mid-entrance, and a home read off a still-sliding panel would strand it away from its authored spot; hardcoded copies would silently revert any layout nudge made in Studio.

⚠ **`AbilitiesLeftMode` is cleared inside the DELAYED exit cleanup**, with the ScreenGui already hidden. AbilitiesPanelClient hides the ability panel the instant that attribute goes blank, which would cut its exit slide short. The early-return path (GUI already disabled) still clears it immediately.

## Dependencies
- **Requires:** [[Refs]], [[State]], [[Catalog]], [[TileVisuals]], [[EquipButton]], [[Preview]], [[Shop]], [[HuntersTab]], [[SkinsTab]], [[TitlesTab]], [[BoostsTab]], [[EmotesTab]], [[EmoteConfig]]
- **Required by:** CollectionGuiController

## Connections
### RemoteEvents
| Remote | Direction | Other script |
|--------|-----------|-------------|
| `RequestBoostState` | → Server | [[BoostService]] fresh boost state on entering BOOSTS |
| `RequestEmoteState` | → Server | [[CollectionService]] fresh emote state on entering EMOTES |
| `RequestTitleState` | → Server | [[CollectionService]] fresh title ownership on TITLES-tab open |

### BindableEvents
| Bindable | Direction | Other script |
|----------|-----------|-------------|
| `BlackBarMenuCovered` | ← | [[MenuHandlerScript]] reveals the panels on the instant black-bar cut to `3CollectionFrame` |

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[Refs]] | both canvases, both tab rows, `REVEAL_DELAY` | What slides and what gets toggled |
| [[State]] | `leftMode`, `rightTab`, `menuOpen`, `openToken` | The view state it owns |
| [[Catalog]] | `getWeaponSkinList()`, `getWeaponSkinTemplate()` | Re-deriving the gun selection on tab entry |
| [[TileVisuals]] | `highlightMenuTab()` | Tab highlight |
| [[EquipButton]] | `refresh()` | Button follows the active tab |
| [[Preview]] | `show()`, `clear()`, `model` | Re-preview on view change, clear on close |
| [[Shop]] | `closeMenu` | Assigns the injected close hook |
| [[HuntersTab]] | `resetToEquipped()`, `rebuildRight` | Selection reset; injects the dispatcher |
| [[SkinsTab]] / [[TitlesTab]] | `clear()`, `rebuild()`, `updateSelection()` | The right-panel dispatch |
| [[BoostsTab]] / [[EmotesTab]] | `frame`, `render()`, `select()`, `resetWindow()` | Left-mode switching |
