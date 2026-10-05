---
tags: [client, localscript, ui, input]
path: game.StarterPlayer.StarterPlayerScripts.MenuModalGuard
type: LocalScript
lines: 64
---

# MenuModalGuard

Marks the buttons inside hide-when-closed menu panels `Modal` so an open menu always frees the first-person cursor.

## What it does
1. Exits on touch-only devices.
2. Every GuiButton in `PVERunBoon` and `PVEProgressionGui` (ScreenGuis that are disabled while closed) is set `Modal = true`.
3. In always-enabled screens, only buttons under hide-when-closed panels qualify: `PVE_MissionVote` (`Shade`, `DecisionShade`, `ResultsShade`) and `PVE_TrailMap` (`Shade`, `MapPanel`). It must never touch an always-visible button (such as the trail map's `MapButton`), which would keep the cursor free for good and break shooting.
4. Watches PlayerGui for those screens and marks buttons added later, deferred one frame so the ancestor chain is final.

## Dependencies
- **Requires:** Nothing
- **Required by:** Nobody

## Connections
None. Works on PlayerGui instances by name only.
