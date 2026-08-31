---
tags: [client, modulescript, ui, collection, viewport, animation]
path: game.StarterGui.CollectionGui.CollectionGuiController.Viewport
type: ModuleScript
lines: 264
---

# Viewport

Turning a template Model into something safe to show: stripping scripts and physics off a clone, playing an idle or an emote on it, and rendering it into a round `IconDisplay` ViewportFrame.

## What it does
1. `cleanModel` — strips scripts, disables collision/query, and **anchors the root ONLY**, leaving every other part free so the rig's joints can still play an animation. Anchoring the whole model freezes it in its authored pose
2. `cleanWeaponModel` — a gun has no rig, so everything anchors
3. `playIdle` — loads the shared idle. `offsetSeed` hashes a string to a start time so a grid of rigs does not all breathe in lockstep; `track.Length` reads 0 until the asset loads, hence the deferred seek with a fallback length
4. `playEmoteAnim` — a specific emote, looped, Action priority
5. `clear`, `makeTileViewport` — the authored `IconDisplay` is a circle carrying its own `UICorner` and is left fill-less on purpose, so the viewport clones that corner rather than assuming one
6. `renderHunter` — same closeup framing as the Trading Post hunter grid. **Framed off the HEAD, not the bounding box**, so a coat or hat cannot pull the closeup off the face
7. `renderWeapon` — same bounding-box framing as the Trading Post weapon grid, using the shared [[WeaponDisplayConfig]] for per-hunter orientation and scale

⚠ **Never create a UIStroke in here.** The designer's authored thickness on `IconDisplay` is `0.03`, so thickness in this GUI is plainly not pixels — a plain `1` renders a ring hundreds of pixels thick. Scale the authored value.

Framing is deliberately identical to the Trading Post's (HuntersBuyController) so the same gun reads the same in both menus; the per-hunter tuning both read now lives in one shared module rather than two copied tables.

## Dependencies
- **Requires:** [[Refs]], [[Catalog]], [[WeaponDisplayConfig]], [[AnimationLoader]]
- **Required by:** CollectionGuiController, Preview, HuntersTab, SkinsTab, EmotesTab

## Connections
### RemoteEvents
None

### BindableEvents
None

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[Refs]] | `IDLE_ANIMATION_ID` | The shared idle asset |
| [[Catalog]] | `getSkinTemplate()`, `getWeaponSkinTemplate()`, `isCardWeapon()` | What to clone, and whether it is a card |
| [[WeaponDisplayConfig]] | `get()` | Per-hunter gun orientation, scale and icon camera distance |
| [[AnimationLoader]] | `AnimationLoader.load()` | `playIdle` only. One shared clip, prewarmed at module load, so in practice it never blocks — but it is authoritative, so a tile that cannot fetch warns instead of sitting in a T-pose |
| [[AnimationLoader]] | `AnimationLoader.loadCached()` | `playEmoteAnim` only. Unlike `playIdle` this takes a **different id per tile**, so there is no single clip to prewarm and a blocking fetch would stall the EMOTES tab for one round-trip per emote while it built the grid |
| [[AnimationLoader]] | `AnimationLoader.prewarm()` | Warm `Refs.IDLE_ANIMATION_ID` at module load; `playIdle` cannot spawn its load because callers keep the returned track |
