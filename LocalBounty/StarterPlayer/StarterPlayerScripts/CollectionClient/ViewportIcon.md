---
tags: [client, modulescript, ui, viewport, animation]
path: game.StarterPlayer.StarterPlayerScripts.CollectionClient.ViewportIcon
type: ModuleScript
lines: 146
---

# ViewportIcon

Renders a character model into a GuiObject as a ViewportFrame icon. Used by the hunter list panel and the equip menu's IconDisplay.

## What it does
1. `ViewportIcon.render(iconDisplay, modelTemplate)` clears any existing ViewportFrame inside the GuiObject and inserts a fresh `ViewportFrame` (anchored at center, 90% size, transparent background) with a `WorldModel`
2. Clones the model template into the WorldModel and runs `cleanModelForViewport`: strips scripts, anchors only HumanoidRootPart (so Motor6Ds still animate), disables CanCollide/CanTouch/CanQuery on all parts
3. Frames the model with `setupCamera`: pivots model to origin facing the camera, computes a distance from the bounding box (1.25× the largest extent, minimum 1.8), positions a Camera at FOV 35
4. Loads `Config.previewIdleAnimationId` into the humanoid's Animator and plays it looped at idle priority
5. Uses `CarouselMath.stableAnimationOffset` (seeded by `modelTemplate:GetFullName() .. iconDisplay:GetFullName()`) so icons don't all sync at the same animation frame

## Dependencies
- **Requires:** [[CarouselMath]], [[Config]], [[AnimationLoader]]
- **Required by:** CollectionClient, HunterList

## Connections
### RemoteEvents
None

### BindableEvents
None

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[CarouselMath]] | `stableAnimationOffset()` | Deterministic time offset per icon |
| [[Config]] | `previewIdleAnimationId` | Idle animation asset ID |
| [[AnimationLoader]] | `AnimationLoader.load()` | Load the icon idle only once the clip is confirmed fetched — a failed fetch used to read as success and leave the icon in the T-pose this function exists to prevent. `render` calls `playIdle` through `task.spawn` because it now yields |
| [[AnimationLoader]] | `AnimationLoader.prewarm()` | Warm the one shared clip at module load; a grid renders many tiles in a row |
