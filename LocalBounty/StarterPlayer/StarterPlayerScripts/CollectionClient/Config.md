---
tags: [client, modulescript, ui, character-select, config]
path: game.StarterPlayer.StarterPlayerScripts.CollectionClient.Config
type: ModuleScript
lines: 76
---

# Config

Tuning constants for the collection / skin select system. Pure data — no Roblox instances touched.

## What it does
1. Carousel layout: `minimumCarouselSlots`, `visibleRange`, `angleSpacing`
2. Drag-to-step input: `dragStepDistance`, `dragStepCooldown`
3. Click-to-target smoothing: `clickMoveSpeed`, `clickStopDistance`, `clickMovementLimit`
4. Selected-button bounce on focus change: `bounceDuration`, `bounceShrinkAmount`
5. Reel button scale targets: `selectedScale`, `normalScale`
6. Preview model (3D character in front of carousel): `previewHeightOffset`, `previewRotationOffset`, `previewScale`, `previewIdleAnimationId`
7. Preview spin (touch/drag rotation): `previewSpinAcceleration`, `previewSpinFriction`, `previewSpinMaxVelocity`, `previewSpinDragVelocityMultiplier`
8. Hunter list selected stroke: `HUNTER_STROKE_NORMAL_THICKNESS`, `HUNTER_STROKE_SELECTED_THICKNESS`, `hunterStrokeTweenInfo`
9. Skins button (equip / purchase) palette: normal/equipped background + text colors
10. Surface GUI open/close animation: durations and scale targets
11. `COLLECTION_CAMERA_TWEEN_WAIT` delay from menu Collection button to surfaces becoming visible
12. `skinPrices` table (per character → per skin) and `DEFAULT_SKIN_PRICE` fallback

## Dependencies
- **Requires:** Nothing
- **Required by:** CollectionClient, SurfaceAnimator, PreviewModel, HunterList, Reel, ViewportIcon

## Connections
### RemoteEvents
None

### BindableEvents
None

### Direct require()
None
