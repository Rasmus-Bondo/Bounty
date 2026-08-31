---
tags: [client, modulescript, ui, collection, registry]
path: game.StarterGui.CollectionGui.CollectionGuiController.EquipButton
type: ModuleScript
lines: 103
---

# EquipButton

The one button at the bottom of the right canvas, shared by all six tabs.

## What it does
1. `register(key, { label, activate })` — each tab registers its own pair, keyed by a right-tab name (`"Skins"` / `"Weapon"` / `"Titles"`) or a left-mode name (`"Boosts"` / `"Emotes"`). All five are registered by their own tab module
2. `activeKey()` — the **left mode wins when it is not HUNTERS**, because BOOSTS and EMOTES both hide the right-hand tab row entirely, so the right tab is not meaningful there
3. `refresh()` — calls the active tab's `label` and writes the result. A throwing label is pcall'd so it cannot leave the button showing a stale word from another tab
4. `activate()` — calls the active tab's `activate`. Each is responsible for its own validation, since `refresh` and `activate` are called independently and `activate` must never assume the label it is paired with is still current
5. `registerLockRefresh(fn)` / `refreshLocks()` — grids that draw owned/locked state register a refresher, so a fresh ownership push repaints every grid without this module knowing what grids exist. **pcall per refresher, deliberately**: an unprotected throw in the first would skip every grid after it and leave half the menu painted as locked with no error tying symptom to cause
6. Owns the button's click connection

## Why this is a registry and not an if-chain
This used to be **two parallel `if leftMode / rightTab` chains** of about 100 lines each, a thousand lines apart: one deciding the LABEL, one deciding what CLICKING does. They had to agree with each other and nothing enforced that they did — a tab whose label said PURCHASE while its click path fell through to the equip branch would offer to sell something and then silently do nothing. Adding a seventh tab meant finding and editing both. Now the pair can only ever come from one place.

⚠ **A locked skin, gun or title never reads "LOCKED"** — the button becomes the hand-off and names the destination. This module does not know that: the tab's own `label` calls the Shop helper, which decides both the wording and the route from one call. EMOTES is the only tab that still puts LOCKED on this button, because it is the only one with a free slot for a separate shop button underneath (PREVIEW is hidden on that tab).

## Dependencies
- **Requires:** [[Refs]], [[State]]
- **Required by:** CollectionGuiController, HuntersTab, SkinsTab, TitlesTab, BoostsTab, EmotesTab, Panels

## Connections
### RemoteEvents
None (the tabs fire their own equip remotes from their `activate`)

### BindableEvents
None

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[Refs]] | `equipButton` | The button instance |
| [[State]] | `leftMode`, `rightTab` | Which registration is active |
