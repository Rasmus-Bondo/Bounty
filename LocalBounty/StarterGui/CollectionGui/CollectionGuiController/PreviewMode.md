---
tags: [client, modulescript, ui, collection, preview, fullscreen, input]
path: game.StarterGui.CollectionGui.CollectionGuiController.PreviewMode
type: ModuleScript
lines: 267
---

# PreviewMode

Fullscreen preview: clicking PREVIEW hides **every** bit of UI and lets the player spin the shown hunter / skin / weapon around by dragging.

## What it does
1. `enter()` — sweeps `PlayerGui` and disables every currently-enabled `LayerCollector` (the Collection panels, the bottom nav bar, all lobby HUD), **recording each one so it can be restored**, and separately saves and clears the per-`CoreGuiType` core UI state via `StarterGui:SetCoreGuiEnabled`
2. Builds its own **"← BACK" button in a high-`DisplayOrder` ScreenGui**, once, and **excludes it from the hide sweep** — which is why it survives its own blackout. It is the only exit
3. Disconnects [[Preview]]'s bob so the model holds still, then drives a **yaw-only turntable** on RenderStepped with an inertia model (accel 25 / friction 7 / drag-mult 0.18 / max-vel 12, matching the old carousel CollectionClient), rotating about the model's bounding-box centre
4. `exit()` — restores every hidden GUI and the core UI, then re-runs `Preview.show()` to reset any dragged rotation
5. Owns the PREVIEW button's click connection

The menu's open state is deliberately left alone throughout, so there is no desync to undo on the way back: the bottom bar is hidden, so BACK is the only exit. Gates on `State.menuOpen` so it cannot be entered from a closed menu.

## Dependencies
- **Requires:** [[Refs]], [[Preview]], [[State]]
- **Required by:** CollectionGuiController

## Connections
### RemoteEvents
None

### BindableEvents
None

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[Refs]] | `previewButton`, `screenGui`, `playerGui`, `UserInputService` | The button, the sweep target, drag input |
| [[Preview]] | `model`, `bobConnection`, `show()` | What to spin, and resetting rotation on exit |
| [[State]] | `menuOpen` | Cannot enter from a closed menu |
