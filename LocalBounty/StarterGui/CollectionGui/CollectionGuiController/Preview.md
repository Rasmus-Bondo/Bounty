---
tags: [client, modulescript, ui, collection, preview, 3d, titles]
path: game.StarterGui.CollectionGui.CollectionGuiController.Preview
type: ModuleScript
lines: 353
---

# Preview

The middle 3D stage: a cleaned clone of whatever is selected, standing in the world in front of `CameraPartActualCollection`.

## What it does
1. `Preview.show()` is the **router** — it reads [[State]] to decide which path to build, so callers just say "the selection changed, re-show" and never pick a path themselves. BOOSTS shows the equipped hunter; EMOTES shows the equipped hunter playing the selected emote; WEAPON floats the gun; everything else stands the hunter/skin
2. `showHunterPreview` — stands the rig on the ground ~10 studs out, facing the camera, playing the idle. **Grounding aligns the rig's body-part bottom (`bodyBottomY`, excluding `Accessory` descendants) to the raycast floor, not `GetBoundingBox()`**, so accessories and 3D clothing that hang below the feet (Fortuna's coat, Dust's Crimson Revenant) don't float the hunter upward
3. `showWeaponPreview` — floats the gun dead-centre on the camera's view axis. Normalizes the model's longest axis to `displayScale` studs, then scales distance with the bounding size (factor 2.0, clamped 4–14 studs) **times a per-hunter `previewDistanceScale` applied BEFORE the clamp.** The size-derived distance alone is not enough: Vesper's 9-stud sniper computes to 18 and Bram's 8-stud shotgun to 16, so both landed pinned at the very back of the room behind the barrels while Dust's revolver sat forward at 12.14 — the clamp was flattening them together. Scaling first lands both at ~11.2
4. **TITLES nameplate billboard** — on the TITLES tab the hunter wears a `TitlePreviewTag` showing the player's name with the selected title beneath, styled through [[TitleRenderer]], so browsing a title previews it exactly as it renders in the lobby. **Neither line is `TextScaled`:** a local `fitTagTextSize` measures with `TextService:GetTextSize` and assigns the largest whole `TextSize` that fits, mirroring LobbySpawn's `fitTextSize`. TextScaled rasterises glyphs at one size and rescales, and that resample leaves a faint ghost row of the font atlas a few pixels above the line
5. `Preview.clear()` — disconnects the bob and destroys the model

⚠ `Preview.model` and `Preview.bobConnection` are **fields, not locals**, because they are reassigned on every re-show and PreviewMode reads them live to spin and freeze the model. An alias would capture one stale clone and then spin a destroyed instance.

⚠ MenuHandlerScript's `getFinalCameraCFrame` rotates the camera part 180° (`cameraPart.CFrame * CFrame.Angles(0, rad(180), 0)`), so the actual view direction is the part's **negative** LookVector. Both preview paths use the flipped CFrame — read the raw LookVector and the model lands behind the camera.

## Dependencies
- **Requires:** [[Refs]], [[State]], [[Catalog]], [[Viewport]], [[TitlesConfig]], [[EmoteConfig]], [[TitleRenderer]], [[WeaponDisplayConfig]]
- **Required by:** CollectionGuiController, PreviewMode, HuntersTab, SkinsTab, TitlesTab, BoostsTab, EmotesTab, Panels

## Connections
### RemoteEvents
None

### BindableEvents
None

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[Refs]] | `collectionCameraPart`, `cameraFolder`, preview distances | Where the stage is, and the raycast filter for grounding |
| [[State]] | selection + equipped fields | Decides which path to build |
| [[Catalog]] | `getSkinTemplate()`, `getWeaponSkinTemplate()`, `isCardWeapon()` | What to clone |
| [[Viewport]] | `cleanModel()`, `cleanWeaponModel()`, `playIdle()`, `playEmoteAnim()` | Prepare and animate the clone |
| [[TitlesConfig]] | `LabelById` | The title text for the nameplate |
| [[EmoteConfig]] | `get()`, `isValid()` | The emote animation to play on the dummy |
| [[TitleRenderer]] | `apply()` | Styles the nameplate exactly as the lobby does |
| [[WeaponDisplayConfig]] | `get()` | `displayScale`, `explicitOrient`, `previewDistanceScale` |
