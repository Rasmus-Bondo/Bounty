---
tags: [client, modulescript, ui, collection, boosts]
path: game.StarterGui.CollectionGui.CollectionGuiController.BoostsTab
type: ModuleScript
lines: 503
---

# BoostsTab

The BOOSTS view: the left grid is six potion/coin tiles, the right panel a hero medallion over a description card, with the shared EQUIP button relabelled USE / IN USE / NONE.

## What it does
1. `build()` — clones `HuntersFrame` → `BoostsFrame` (retitled "BOOSTS") and `SkinFrame` → `BoostInfoFrame` (grid removed), **once at startup while both source frames are still pristine** (before viewports render into the hunter tiles). Publishes both frames for Panels to toggle
2. Fills the grid with one tile per [[BoostConfig]] id (XP 15/30/60 then Cash 15/30/60), each showing that boost's potion/coin artwork inside the authored round `IconDisplay` ring, plus a `kind · duration` caption and a top-right `CountBadge` (`xN` owned). **`BOOST_ICONS` is derived from the catalog** (`entry.icon`) rather than holding its own asset ids — BattlePassClient paints the same art on reward cards, so the ids live on the catalog entry and both readers pick up a new boost automatically
3. `updateInfo()` — the right panel: a **hero medallion** (`BoostArtHolder` → `BoostArtRing` → `BoostArtIcon`) cloning the grid tile's own `IconDisplay` ring so stroke and gradients match, held square by a `UIAspectRatioConstraint` (the ring's `UICorner` is a full 1-scale radius, so a non-square frame smears the circle into an ellipse) and wearing the ring's *selected* gradient. Below it a rounded card holds the wrapped description, the owned count and an active/time-remaining line
4. `useSelected()` — fires `ActivateBoost` only when usable
5. Registers the `"Boosts"` EQUIP pair, the `BoostStateEvent` handler and the startup warm-up

**Vertical budget:** `MenuInfo` ends at ~0.18 of the panel and the shared EQUIP button starts at ~0.83, so the medallion (0.335 ± 0.13) and the card (0.645 ± 0.15) both have to sit inside that band or they render under the button.

⚠ **A boost tile has NO card background** — the tile is the ring, the caption and the badge, exactly like a hunter tile. `1Dust`, the tile these clone, is `BackgroundTransparency = 1` and holds **no `UICorner`**, so anything added at tile scale has nothing to round itself against and renders as a hard-edged near-black **square** behind the round potion. A full-tile `BoostBackground` + wash was deleted 2026-07-28 for exactly this. Put art inside `IconDisplay`, which does carry a corner.

⚠ **Never assign an absolute `UIStroke.Thickness` here.** The authored value on `IconDisplay` is `0.03`; setting one to `2` renders a ~300px ring that swallows the right canvas. Scale the authored value (the medallion uses the same `* 1.8` bump `setTileSelected` applies).

Tiles the player owns 0 of are greyed with the shared `LOCKED_TINT`. Remaining time is the **paused lobby value** — there is no live countdown, because boosts only tick down inside a Redwater round. The server blocks a second potion of the same kind until the first expires, which is what `IN USE` reports.

## Dependencies
- **Requires:** [[Refs]], [[State]], [[TileVisuals]], [[EquipButton]], [[Preview]], [[BoostConfig]]
- **Required by:** CollectionGuiController, Panels

## Connections
### RemoteEvents
| Remote | Direction | Other script |
|--------|-----------|-------------|
| `ActivateBoost` | → Server | [[BoostService]] activates the selected owned boost |
| `RequestBoostState` | → Server | [[BoostService]] asks for a fresh boost state on open / entering BOOSTS / at startup |
| `BoostStateEvent` | ← Server | [[BoostService]] pushes `{ Inventory, Active }`; re-renders the grid + panel |

### BindableEvents
None

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[Refs]] | `huntersFrame`, `skinFrame`, the three boost remotes, `LOCKED_TINT` | The frames it clones and what it fires |
| [[State]] | `boostState`, `selectedBoost` | Inventory, active kinds and selection |
| [[TileVisuals]] | `fitLeftGrid()`, `setTileSelected()`, `tween()`, `playShopSound()` | Card sizing, selection, SFX |
| [[EquipButton]] | `register()`, `refresh()` | The USE / IN USE / NONE pair |
| [[Preview]] | `show()` | Keeps the middle preview on the equipped hunter |
| [[BoostConfig]] | `list()`, `get()`, `BOOSTS` | Grid order, kind/percent/minutes/label, and the per-boost `icon` |
