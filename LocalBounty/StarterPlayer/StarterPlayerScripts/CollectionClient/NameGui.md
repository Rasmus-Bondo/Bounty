---
tags: [client, modulescript, ui, character-select]
path: game.StarterPlayer.StarterPlayerScripts.CollectionClient.NameGui
type: ModuleScript
lines: 93
---

# NameGui

Per-carousel-button "skin name" overlay. Prefers a cloned SurfaceGui template (`ReplicatedStorage.ScrollWheelMenuTemplate`); falls back to a plain BillboardGui if the template isn't there.

## What it does
1. `NameGui.create(buttonObject, displayName, parent, template)` finds an adornee BasePart on the button (handles Model with PrimaryPart, Model without PrimaryPart, and raw BasePart)
2. If a template is supplied, clones it, adornees to the part, parents under the player's PlayerGui (passed in), populates `Canvas.SkinText` with `displayName`, disables Active on both Canvas and SkinText, leaves the GUI disabled
3. If no template, falls back to a hand-built BillboardGui with a single TextLabel using GothamBold, white text, scaled, slight stroke transparency
4. `NameGui.setTransparency(gui, transparency)` walks to `SkinText`, sets `TextTransparency` and a slightly-bumped `TextStrokeTransparency` (max 1)

## Dependencies
- **Requires:** Nothing
- **Required by:** Reel

## Connections
### RemoteEvents
None

### BindableEvents
None

### Direct require()
None
