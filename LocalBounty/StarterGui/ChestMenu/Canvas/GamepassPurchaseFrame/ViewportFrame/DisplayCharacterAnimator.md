---
tags: [client, localscript, ui, lootbox, menu, viewport]
path: game.StarterGui.ChestMenu.Canvas.GamepassPurchaseFrame.ViewportFrame.DisplayCharacterAnimator
type: LocalScript
lines: 295
---

# DisplayCharacterAnimator

Renders the BOUNTY+ panel's diorama — the outlaw, the coins at his feet, six chests, a cactus and a covered wagon — inside the panel's `ViewportFrame`: rig clean-up, the sit pose, and a camera that re-fits itself to the frame's aspect.

## What it does
1. **Boots the rig fully anchored.** Every `BasePart` anchored with `CanCollide` / `CanTouch` / `CanQuery` off, and any `BaseScript` inside disabled rather than destroyed (removing a rig's `Animate` stops a Motor6D rig from DRAWING inside a ViewportFrame — this rig is AnimationConstraint-jointed and unaffected, but a joint type is an export detail nobody checks). The Humanoid loses its name tag, health bar and state machine. This is the safe state, and it is what the rig stays in if anything below fails
2. **A WorldModel SIMULATES PHYSICS** — which is the whole reason an AnimationConstraint rig can play a clip inside a ViewportFrame at all — and there is no floor in one. The rig shipped twice as a heap of loose plates on a real phone (owner, 2026-09-07) because nothing drove its AnimationConstraints while its BallSocketConstraints slowly folded it up. **Edit mode runs no physics, which is why both breakages looked perfect in Studio**
3. **Welds the four accessory Handles before anything is unanchored.** Beard, Duster, Vest and Belt carry no weld of their own: a Humanoid builds those when it assembles a character, and one sitting in a WorldModel never did, so they fell away independently of the body. Each Handle's Attachment is matched **by name against the rig's direct BasePart children only** — Duster and Vest both mount on `BodyFrontAttachment`, so a search across all descendants finds the other garment's Handle before it finds `UpperTorso` and welds the two coats to each other. Bandana, CowboyHat and Hair already carry WeldConstraints and are left alone
4. **Plays the sit pose only once the clip is proven, then releases the body.** `CoolSitPose` (`rbxassetid://110021104195913`) is prewarmed and loaded through `AnimationLoader`, which blocks on the real CDN fetch and reports an `AssetFetchStatus`; `Animator:LoadAnimation` does not — it hands back a valid track while the clip is still downloading, so a failed fetch read as a success. Only after the track is playing does the rig unanchor everything except `HumanoidRootPart` and set `Massless`, the same shape as CollectionGuiController's `Viewport.cleanModel`, which drives these very templates in the Collection grid. It waits a frame between the two so the AnimationConstraints already hold the pose's targets before any part is free to move toward them, or the rig visibly swings out of bind pose. **A clip that never arrives leaves it anchored in bind pose** — the safe state, not a heap
5. **The camera fits the WHOLE SCENE, never the subject.** An earlier fix sized it from the rig's head-to-foot height and cut the scene off on all four sides: `ChestMenu` boots disabled, so the measurement was skipped until the LOOT tab opened, by which time the rig had already collapsed and reported a fraction of its real height. `buildCorners` collects all eight corners of every visible part in camera-axis coordinates and `frameScene` runs a fixed-point fit (`FIT_PASSES`) that pans and pushes the eye back until every corner sits inside the frame with `FRAME_MARGIN` to spare. That is a hard no-clip guarantee at any aspect rather than a tuned number, which is what the panel needs — the ViewportFrame is transparent over the live lobby, so a clipped edge reads as a rendering glitch rather than a cropped picture
6. **An explicit Camera, because a `ViewportFrame` with `CurrentCamera` nil auto-frames its whole WorldModel** — so the outlaw's size and position were a side effect of scene dressing nobody was looking at, and moved with the aspect. `CAMERA_FOV` is 50 and **FieldOfView is VERTICAL**, so the height a subject fills is aspect-independent and the width is not: the fit has to follow `AbsoluteSize`. Ambient `150,165,195` under a `235,242,255` key is the Collection tiles' pair (the authored one was flat grey on grey), with `LightDirection` over the viewer's shoulder
7. **Re-fits on the viewport's `AbsoluteSize` and on the ScreenGui's `Enabled`.** The Enabled signal is the one that does the work: the panel is built while `ChestMenu` is disabled, a disabled ScreenGui does not re-lay, and so the first fit almost always bails on a zero size. A re-fit for an unchanged aspect is skipped, and the fit runs again once the sit pose lands because the pose moves the bounds it measures
8. **Known cost, deliberately left** (owner deferred, 2026-09-07): the scene is 15.93 studs wide against the outlaw's 4.37 in a near-square frame, so fitting all of it leaves him **53 px tall on a 799×359 phone** — against 96 px framed on him and the coins at his feet, or 152 px on him alone. A ViewportFrame renders at its on-screen size and has no quality setting, so this is the whole of the panel's image quality. Trimming the wagon (10–26 studs back) and the 11-stud cactus, or turning the panel's own card background on — its `UICorner` and `UIGradient` are authored but inert at `BackgroundTransparency = 1`, unlike its twin `ChestPurchaseFrame` — are the two ways out, and both are art calls

## Dependencies
- **Requires:** [[AnimationLoader]]
- **Required by:** Nobody

## Connections
### RemoteEvents
None.

### BindableEvents
None.

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[AnimationLoader]] | `AnimationLoader.prewarm()`, `AnimationLoader.load()` | Fetches the sit pose and reports a real `AssetFetchStatus`, so a failed fetch cannot read as success and leave the rig to collapse when it unanchors |

The panel around this viewport — the price row, the purchase prompt and the owned swap — belongs to ChestController, which does not require this script; the two only share the instance tree. The rig clean-up follows CollectionGuiController's `Viewport` module by convention, not by calling it.
