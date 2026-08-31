---
tags:
  - client
  - localscript
path: game.StarterPlayer.StarterPlayerScripts.HunterPortraitClient
type: LocalScript
lines: 198
---

# HunterPortraitClient

Fills the HUD player-frame ViewportFrame with the local player's equipped hunter and skin, playing a looped idle.

## What it does

1. Resolves the equipped model from the `SelectedHunterCategory` / `SelectedHunterSubfolder` / `SelectedHunterModelName` player attributes
2. When that lookup misses, degrades to the same hunter's `Character.Default` model (read out of the folder, not assembled from the hunter name) and warns once per distinct bad selection, so an unresolvable skin never renames the player's hunter on screen
3. Finds `Canvas.PlayerFrame.PlayerHunterFrame.ViewportFrame.WorldModel` in every ScreenGui under PlayerGui and swaps in a clone of that model, reusing the previous rig's pivot so framing is preserved
4. Strips scripts from the clone and anchors only its HumanoidRootPart — anchoring every part pins them in world space, and the joint transforms the idle animation writes can never move an anchored part, so the portrait stands frozen
5. Loads and loops the shared idle animation on the clone's Animator at a randomized start time so portraits are not in lockstep
6. Re-runs whenever a hunter/skin selection attribute changes or a new ScreenGui is added to PlayerGui, which covers mid-match hunter switches

The HUD viewport ships with a baked Dust `Rig` (Motor6D, root-anchored, own `Animate` script) that this replaces on join; that rig is the reference for how a portrait rig should be anchored. It is also why step 2 exists: an early return on an unresolvable selection left that Dust rig on screen for a player of any other hunter.

## Dependencies

- **Requires:** [[AnimationLoader]]
- **Required by:** Nobody

## Connections

### RemoteEvents

_None_

### BindableEvents

_None_

### Direct require()

| Target | Function | Purpose |
|--------|----------|---------|
| [[AnimationLoader]] | `AnimationLoader.load()` | Load the portrait idle only once the clip is confirmed fetched, so a failed fetch warns instead of silently leaving the portrait in a T-pose |
| [[AnimationLoader]] | `AnimationLoader.prewarm()` | Warm the clip at script start; the portrait rebuilds on every hunter-selection change |
