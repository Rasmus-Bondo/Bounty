---
tags: [client, localscript, input, ui]
path: game.StarterPlayer.StarterPlayerScripts.AltCursorClient
type: LocalScript
lines: 30
---

# AltCursorClient

Hold ALT to free the mouse while the camera is locked first person (PC only).

## What it does
1. Exits on touch-only devices (touch without keyboard).
2. Shows the authored StarterGui.AltCursorGui.ModalButton (a `Modal = true` GuiButton) while LeftAlt or RightAlt is held, which releases the cursor; hides it on key-up. Never writes `MouseBehavior`, which the camera module rewrites every frame.
3. Also hides it on `WindowFocusReleased`, because alt-tab swallows the key-up and would leave the cursor stuck free.

## Dependencies
- **Requires:** Nothing
- **Required by:** Nobody

## Connections
None. Works on the AltCursorGui instance by name only.
