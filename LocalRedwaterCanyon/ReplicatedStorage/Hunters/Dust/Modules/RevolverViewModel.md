---
tags: [client, modulescript, viewmodel, combat]
path: game.ReplicatedStorage.Hunters.Dust.Modules.RevolverViewModel
type: ModuleScript
lines: 319
---

# RevolverViewModel

Factory module that creates the first-person viewmodel from a template and provides animation helpers.

## What it does
1. Clones the viewmodel template and parents it to the camera
2. Sets up Root as PrimaryPart (anchored), all other parts unanchored for Motor6D animations
3. Disables CanCollide, CanTouch, CanQuery on all BaseParts and sets them Massless
4. Returns structured references: Model, Root, Revolver, Handle, MuzzlePart, MuzzleAttachment, LeftArm, LeftArmParts, AnimationController
5. Resolves `LeftArmParts` — every instance the left arm is visually made of, for callers that hide it. The smooth arm meshes added 2026-08-11 sit **alongside** the blocky originals rather than inside them: `LeftArmSmooth` is a sibling MeshPart at the model root, welded by a Motor6D that lives *inside* `LeftArm`. Anything walking `LeftArm:GetDescendants()` therefore finds only that Motor6D and misses the mesh, which left Dust's new smooth left arm on screen permanently. A `IsDescendantOf` guard keeps a part out of the set twice if a future template ever nests it. `LeftArm` is still returned unchanged for back-compat
6. `GetAnimator` creates or finds an Animator under the AnimationController
7. `LoadTrack(animator, name, priority, looped)` resolves the clip id from the **Dust manifest** via `HunterAnimations.id("Dust", "Viewmodel", name, EquippedSkinName())` — the clone's own Animation instances are unread — and builds the track through `AnimationLoader.loadCached` (a bare `LoadAnimation` returns a valid track for a clip that never downloads, so a failed fetch used to read as success and leave the gun still). A clip the manifest lacks **warns and returns nil**; every caller already tolerates a nil track. `EquippedSkinName()` is public and reads the `EquippedWeaponSkin_Dust` player attribute so a manifest `Animations.Skins` override wins (HighNoonGunFX resolves through it too)
8. `FindRevolverModel(viewModel)` is the **public** gun-model resolver — the three authored names (`RevolverDefault` / `Revolver` / `Default`) and then a structural fallback to any child Model containing a `Base`. Exported 2026-08-24 because the ultimate's gun FX and camera orbit each carried their own copy of the name list and neither had the fallback; a weapon skin names its gun model whatever it likes (Icefang's was `Ice`, since renamed), so both resolved nil and the whole ultimate shot went silent
9. Calls `HunterViewmodelContract.Normalize(viewModel, "Dust")` on the fresh clone **before anything below reads it** — the weapon model takes the default rig's name (the contract's clip back-fill is gone; clip ids resolve through the manifest, so the clone's Animation instances are unread). With that in place the canonical name is a fact rather than something each caller re-resolves: even the old hardcoded `RevolverDefault` / `Revolver` / `Default` lookup succeeds on every skin

## Dependencies
- **Requires:** [[HunterViewmodelContract]], [[HunterAnimations]] (clip ids, in `LoadTrack` — from `ReplicatedStorage.Hunters.Shared`); [[AnimationLoader]] (`loadCached`, in `LoadTrack` — from `ReplicatedStorage.Modules`)
- **Required by:** FPSRevolverClient, HighNoonGunFX, HighNoonViewModelOrbit

## Connections
### RemoteEvents
None

### BindableEvents
None

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[HunterViewmodelContract]] | `HunterViewmodelContract.Normalize()` | Reconcile the equipped skin's clone against Dust's default rig |
| [[HunterAnimations]] | `HunterAnimations.id()` | Resolve every viewmodel clip id from the Dust manifest |
