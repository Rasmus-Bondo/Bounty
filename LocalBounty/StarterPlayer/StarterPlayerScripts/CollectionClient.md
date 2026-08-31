---
tags: [client, localscript, ui, character-select, skins, data]
path: game.StarterPlayer.StarterPlayerScripts.CollectionClient
type: LocalScript
lines: 1333
---

# CollectionClient

> **DISABLED (`Disabled = true`) since 2026-07-31 — legacy.** Superseded by the 2D
> CollectionGui / CollectionGuiController panel on the `3CollectionFrame` tab. Its own tab
> (`2LootFrame` → `CameraPartCollection`) is `Visible = false` in the bottom bar, so the 3D
> carousel had been unreachable for a while; every flow below (equip, purchase, join-time
> restore) is now covered by CollectionGuiController, HuntersBuyController and the server's
> `EquippedCharacter` / `EquippedSkin` attributes. It was still costing an early-boot
> `Workspace:WaitForChild("SkinMenu")` — a Persistent model is not replicated until the
> client's initial streaming completes, and this ran first in StarterPlayerScripts, so it
> printed *Infinite yield possible* on every join. The script and `Workspace.SkinMenu` are
> kept in place rather than deleted; the sections below describe what it did when enabled.

Orchestrator for the 3D hunter and skin selection system in the Bounty lobby. Holds shared state and wires together nine child ModuleScripts; heavy lifting (carousel rendering, surface animation, viewport icons, preview model lifecycle) lives in those modules.

## What it does
1. Resolves studio references (SkinMenu pivot/template/PreviewPart, HunterListMenu / EquipHunterMenu SurfaceGuis adornee'd to InfoSkinFrame / UnlockSkinFrame, remote events, characters folder, SFX). `Workspace.SkinMenu` is a Persistent model (streaming-safe) and `InfoSkinFrame` / `UnlockSkinFrame` live inside it, so all lookups go through `WaitForChild("SkinMenu")`
2. Owns the mutable session state: ownedSkins, currentCharacterName, equippedCharacterName/Skin, realSkins/skins, selectedIndex/carouselPosition, collectionOpen/previewModeActive, drag and preview-spin state
3. Builds a [[Reel]] instance for the carousel buttons and a [[HunterList]] instance for the hunter panel, wiring the hunter-list select callback to rebuild skins and refresh the reel
4. Implements `loadCharacterSkins` and `buildCarouselSkinSlots` which read ReplicatedStorage.Characters and produce the slot table the Reel renders
5. Implements `updateEquipMenu` (OWNED / EQUIPPED / EQUIP SKIN / UNLOCK SKIN states, price text, button visuals) and `updatePreviewModel` (delegates to [[PreviewModel]]). Group-perk skins (currently only Dust's `Wraith`, per [[GroupPerkConfig]]) have no price here because membership rather than currency unlocks them, so an unowned one reads **FREE FOR GROUP MEMBERS** with the price hidden and a VISIT TRADING POST button — the trading post panel is where the full "join the group" description and the `JOIN GROUP TO UNLOCK` prompt live. Once [[DataService]] has granted it, Wraith falls through to the normal owned/equip states
6. Implements visibility orchestration: `setCollectionSurfaceGuisVisible` (delegates to [[SurfaceAnimator]]), `setPreviewMode`, `returnFromPreviewMode`, `openCollectionAfterCameraTween` (waits `COLLECTION_CAMERA_TWEEN_WAIT` then reveals), `closeCollectionSurfaces`
7. Runs the carousel physics loop (click-target smoothing, selection change detection, preview spin) on RenderStepped and calls `reel:update(dt, carouselPosition)` while the collection is open and not in preview mode
8. Handles input: keyboard (A/D/arrows/Enter), drag-to-step on mouse and touch, raycast click selection via `reel:raycastIndex`, preview-mode spin drag, equip menu hover on PreviewButton/SkinsButton
9. Wires the bottom main menu: pressing its own `2LootFrame` tab opens the collection (or returns from preview mode), and it closes whenever the menu moves off that tab. **The close reads the `SelectedMenuFrame` attribute** on `MainMenuGui` (published by MenuHandlerScript from `selectMenuFrame`, the one function every navigation route passes through) rather than hooking the other four tabs' buttons, which only fire for navigation that *starts* on the bottom bar — any hand-off left these surfaces up over the page underneath
10. Builds a small in-script `PreviewBackGui` (ScreenGui + TextButton) used only while preview mode is active
11. Listens to `SkinDataEvent` from the server on join (and after purchases) to populate `ownedSkins` and the equipped selection, then re-fires `CharacterSelectEvent` with the saved selection so the lobby model is restored automatically. Immediately after connecting that handler it fires `RequestSkinData` — the join push is one-shot, and a RemoteEvent fire that lands before its listener exists is dropped for good
12. Fires `PurchaseSkinEvent` / `EquipSkinEvent` / `CharacterSelectEvent` to the server on player actions

## Dependencies
- **Requires:** [[Config]], [[Tween]], [[CarouselMath]], [[SurfaceAnimator]], [[PreviewModel]], [[ViewportIcon]], [[HunterList]], [[Reel]], [[WaitForRequired]], [[GroupPerkConfig]]
- **Required by:** Nobody

## Connections
### RemoteEvents
| Remote | Direction | Other script |
|--------|-----------|-------------|
| `CharacterSelectEvent` | → Server | [[PartyService]] character model swap |
| `PurchaseSkinEvent` | → Server | [[DataService]] deducts cash, writes OwnedSkins |
| `EquipSkinEvent` | → Server | [[DataService]] persists EquippedCharacter/EquippedSkin |
| `SkinDataEvent` | ← Server | [[DataService]] sends owned skins + equipped selection on join and after purchase |
| `RequestSkinData` | → Server | [[DataService]] asks for a resend of that payload once at startup, so a join push that arrived before this handler existed isn't lost |

### BindableEvents
None

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[Config]] | constants table | Carousel layout, animation durations, prices, palette |
| [[Tween]] | `Tween.run()` | Equip-button hover scale tweens |
| [[CarouselMath]] | `wrapIndex`, `roundToNearest`, `clamp`, `signedCircularOffset`, `circularDistance` | Selection/position math + preview-spin velocity clamp |
| [[SurfaceAnimator]] | `setVisible()` | Animate hunter list + equip menu SurfaceGuis open/closed |
| [[PreviewModel]] | `create()`, `destroy()` | 3D preview character lifecycle |
| [[ViewportIcon]] | `render()` | Equip menu icon viewport |
| [[GroupPerkConfig]] | `isGroupSkin()` | Which skins are Outlaw Syndicate perks, driving the `FREE FOR GROUP MEMBERS` label and the `VISIT TRADING POST` button. Replaced an inline `name == "Dust" and skin == "Wraith"` comparison (2026-08-12) |
| [[HunterList]] | `HunterList.new()`, `:updateSelection()` | Hunter list panel + selection visuals |
| [[Reel]] | `Reel.new()`, `:build()`, `:update()`, `:setVisible()`, `:playBounce()`, `:raycastIndex()` | Carousel buttons (state, render, click hit-test) |
| [[WaitForRequired]] | `waitForRequired(Workspace, "SkinMenu")` | Resolve the Persistent skin-menu model without the engine's 5s "Infinite yield possible" warning; the frames and parts beneath it need no helper, since a Persistent model's descendants arrive with it |
