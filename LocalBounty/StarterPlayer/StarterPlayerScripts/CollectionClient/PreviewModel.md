---
tags: [client, modulescript, ui, character-select, animation]
path: game.StarterPlayer.StarterPlayerScripts.CollectionClient.PreviewModel
type: ModuleScript
lines: 113
---

# PreviewModel

Lifecycle for the 3D preview character shown in front of the carousel (on top of SkinMenu.PreviewPart).

## What it does
1. `PreviewModel.create(modelTemplate, parentFolder, previewPart, name)` clones the model into the parent folder
2. `prepare(model)`: strips Scripts/LocalScripts, anchors only HumanoidRootPart so Motor6Ds keep animating, disables CanCollide/CanTouch/CanQuery on every BasePart
3. `scaleModel(model, factor)`: rescales every BasePart's Size and CFrame around the model's pivot, and scales SpecialMeshes; skips the work if factor is 1
4. `place(model, previewPart)`: pivots the model to sit on top of `previewPart`, offset by `Config.previewHeightOffset` and rotated by `Config.previewRotationOffset`
5. `playIdle(model)`: loads `Config.previewIdleAnimationId` into the humanoid's Animator (creates one if missing), plays it looped at idle priority, returns the AnimationTrack
6. Returns `(modelClone, idleTrack)` so the caller can dispose them later
7. `PreviewModel.destroy(model, track)` stops + destroys the track and destroys the model

## Dependencies
- **Requires:** [[Config]], [[AnimationLoader]]
- **Required by:** CollectionClient

## Connections
### RemoteEvents
None

### BindableEvents
None

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[Config]] | `previewHeightOffset`, `previewRotationOffset`, `previewScale`, `previewIdleAnimationId` | Placement and idle anim |
| [[AnimationLoader]] | `AnimationLoader.load()` | Load the preview idle only once the clip is confirmed fetched, so a failed fetch warns instead of standing the preview character in a T-pose. This **yields inside `PreviewModel.create`** and cannot be spawned — `create` returns the track for `destroy` to pair with |
| [[AnimationLoader]] | `AnimationLoader.prewarm()` | Warm the clip at module load, which is what keeps that unavoidable yield off the interactive path |
