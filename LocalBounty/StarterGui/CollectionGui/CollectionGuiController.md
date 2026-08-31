---
tags: [client, localscript, ui, collection, entry-point]
path: game.StarterGui.CollectionGui.CollectionGuiController
type: LocalScript
lines: 144
---

# CollectionGuiController

Entry point for the styled Collection menu (`CollectionGui`). Requires the 15 child modules, mirrors a few replicated player attributes into [[State]], and runs the startup sequence. **All behaviour lives in the children.**

## What it does
1. Requires the child modules. **Require order is load-bearing for [[State]] only:** its ownership prefetch must connect before any tab builds a grid, because `SkinDataEvent` is a one-shot push and a fire that lands before the listener exists is dropped for good — which used to leave every owned skin rendering as LOCKED for the whole session
2. Re-push handler for `SkinDataEvent`: hands the payload to `State.applySkinData` and then refreshes lock states, which is what a purchase actually needs (the join push itself is already handled by State's prefetch)
3. Mirrors `EquippedCharacter` / `EquippedSkin` / `EquippedWeaponSkin_<Hunter>` attribute changes into [[State]] and refreshes the EQUIP button
4. Seeds per-hunter equipped titles from the `EquippedTitle_<Hunter>` attributes and keeps them in sync
5. Startup sequence: hide the ScreenGui, `SkinsTab.init()`, `TitlesTab.build()`, highlight the default tabs, `BoostsTab.build()`, `EmotesTab.build()`, `HuntersTab.build()`, reset selection to equipped, refresh lock states — then **`Panels.init()` last**, because that can immediately open the menu if the player joined straight onto the Collection tab and must not do so before the grids exist

## History
This was a single **3872-line** chunk sitting **on** Luau's 200 top-level-local ceiling, and a dozen design decisions in it existed only to dodge that limit: state hung off unrelated tables (`titleShop`, `emoteState`), `require`s buried inside function bodies, constants reused across unrelated features because no name was free. It was split into the modules below in 2026-07-30. The ceiling workarounds are gone; the `emoteState` history is deliberately preserved in [[EmotesTab]]'s header so the pattern is not re-adopted.

## Dependencies
- **Requires:** [[Refs]], [[State]], [[Catalog]], [[Viewport]], [[TileVisuals]], [[Preview]], [[PreviewMode]], [[Shop]], [[EquipButton]], [[HuntersTab]], [[SkinsTab]], [[TitlesTab]], [[BoostsTab]], [[EmotesTab]], [[Panels]], [[TitlesConfig]]
- **Required by:** Nobody (top-level LocalScript)

## Connections
### RemoteEvents
| Remote | Direction | Other script |
|--------|-----------|-------------|
| `SkinDataEvent` | ← Server | [[DataService]] re-push after a purchase; adds the lock-state refresh on top of what State's prefetch already applied |

### BindableEvents
None (the navigation bindables are used by [[Panels]] and [[Shop]])

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[Refs]] | table | Instances + constants |
| [[State]] | `applySkinData()`, fields | The session; required early for its prefetch |
| [[Panels]] | `init()` | Bottom-bar wiring, called last |
| [[TitlesConfig]] | `Titles` | Iterate hunters to seed equipped titles |
| others | `build()` / `init()` | Startup sequence |
