---
tags: [client, modulescript, ui, collection, catalog]
path: game.StarterGui.CollectionGui.CollectionGuiController.Catalog
type: ModuleScript
lines: 173
---

# Catalog

What EXISTS: the hunter, skin, gun-skin and title catalogs, read out of `ReplicatedStorage.Characters`, `ReplicatedStorage.WeaponSkins` and [[TitlesConfig]].

## What it does
1. `findFirstModel` — a skin is authored either as a Model directly or as a Folder holding one, so every lookup goes through this
2. `getHunterTemplate`, `getSkinTemplate`, `getSkinList` (Default first, the rest alphabetical)
3. `resolveWeaponSource` — hunters without an authored gun borrow the fallback hunter's folder as a temporary display model. Vesper and Bram have their own `DefaultSniper` / `Grudgekeeper` now so this is dormant, but a **borrowed gun always reads EQUIPPED and never fires the equip remote**, so the distinction stays visible to callers via `hasOwnWeaponFolder`
4. `isCardWeapon` — Fortuna's deck needs different framing from a gun
5. `getWeaponSkinList` — default gun first, rest alphabetical; a borrowed folder exposes only its default gun (the donor's skins stay theirs). "Default" is read from `Catalog.DEFAULT_WEAPON_SKINS` (a mirror of DataService's `EquippedWeaponSkins` defaults) as well as a `^Default` name test: three hunters name their free gun `Default<something>` and Bram's is just `Grudgekeeper`, so the name test alone put his paid `FrostbiteGrudgekeeper` first in the grid
6. `getWeaponSkinTemplate`, `getTitleList` (titles are hunter-locked, so this is a flat per-hunter list)
7. `prettySkinName` — `CrimsonRevenant` → "CRIMSON REVENANT". `IvoryGambler` is special-cased because the authored name drops the hunter it belongs to

Deliberately knows nothing about what the player OWNS or has EQUIPPED (that is State) and nothing about how any of it is drawn (Viewport / TileVisuals). Pure lookup, safe to call from anywhere at any time.

## Dependencies
- **Requires:** [[Refs]], [[TitlesConfig]]
- **Required by:** CollectionGuiController, State, Viewport, Preview, HuntersTab, SkinsTab, TitlesTab, EmotesTab, Panels

## Connections
### RemoteEvents
None

### BindableEvents
None

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[Refs]] | `charactersFolder`, `weaponSkinsFolder`, `WEAPON_FALLBACK_HUNTER` | The content folders |
| [[TitlesConfig]] | `Titles` | Per-hunter title catalog |
