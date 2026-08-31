---
tags: [client, modulescript, ui, ultimate, targeting]
path: game.ReplicatedStorage.Hunters.Dust.Modules.HighNoonTargetUI
type: ModuleScript
lines: 414
---

# HighNoonTargetUI

OOP controller for HighNoon target lock-on visuals including highlights and billboard GUIs. Highlights and GUIs are keyed per-target so individual targets can be added/removed as they enter and leave the live cone.

## What it does
1. Creates orange Highlight instances on targeted enemy characters (always on top), tracked per-target so a single target can be removed (`HighlightTarget` / `RemoveHighlight` / `RemoveTarget`)
2. Creates billboard GUIs on targets showing a shrinking lock-in frame during targeting phase
3. Transitions to skull mark icon when a target is fully locked
4. Manages GUI transparency via tween for smooth fade in/out
5. `UpdateTargets(targeting, locked, lockInTime)` reconciles the live cone each server tick: new targets start the shrink animation, newly-locked targets swap to the skull, and targets that left the cone are removed outright (a re-entry starts a fresh lock-in). This is the primary entry point driven by HighNoonClient's `"TargetUpdate"` handler
6. `StartLockVisuals` / `ShowLockedTargets` remain for the legacy one-shot snapshot flow but are no longer called
7. `IsLocalPlayerTargeted` checks if the local player is being targeted (for victim feedback)

## Dependencies
- **Requires:** Nothing
- **Required by:** HighNoonClient

## Connections
### RemoteEvents
None

### BindableEvents
None

### Direct require()
None
