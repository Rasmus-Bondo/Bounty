---
tags: [shared, modulescript, config, weapons, display]
path: game.ReplicatedStorage.Config.WeaponDisplayConfig
type: ModuleScript
lines: 145
---

# WeaponDisplayConfig

Per-hunter weapon-skin display tuning, shared by every Bounty surface that puts a gun on screen.

## What it does
1. `Hunters` — a per-hunter table of orientation and framing values, with `get(hunterName)` as the accessor. Nothing here is required, so a hunter with no entry is legitimate rather than a bug: Fortuna's card deck reads correctly off the shared base rotation
2. Fields: `rotationOffset` (applied on top of the caller's base rotation), `explicitOrient` / `explicitIconOrient` (absolute world poses replacing the shared lookAt), `displayScale` (normalizes the model's longest axis to N studs so raw model scale never matters), `iconDistanceScale`, `standRaise`, `standCenterOffset`, and `previewDistanceScale`
3. Carries the full measured rationale for each hunter's entry — why Vesper's sniper and Bram's Grudgekeeper both lie horizontal with the muzzle to screen-left, why Dust's `displayScale = 6` reproduces the old union revolver's on-screen length, and why `standCenterOffset` pins the bounding-box centre instead of bottom-aligning

## Why this is a module
It used to be a `WEAPON_DISPLAY` table copied **byte-for-byte** into both HuntersBuyController and the Collection menu, with a standing instruction that every shared key stay identical between them. Drift there fails silently and looks like an art bug rather than a code one: without the right entry Bram's Grudgekeeper renders mis-angled, Vesper's `DefaultSniper` lies on its side, and Dust's two revolvers come out upside down and at different sizes. One table means a new gun is tuned once. Consolidated 2026-07-30; the two copies were verified field-by-field identical before one was deleted.

**`previewDistanceScale` is the Collection menu's alone** and is applied **before** the 4-14 stud clamp, not after. The size-derived distance alone is not enough: Vesper's 9-stud sniper computes to 18 and Bram's 8-stud shotgun to 16, so both landed pinned at the back of the room behind the barrels while Dust's revolver sat forward at 12.14 — the clamp was flattening them together. Scaling first lands both at ~11.2. The Trading Post stand does not read this field at all.

⚠ **Bounty-only.** This is display tuning for lobby menus, **not** one of the 16 modules mirrored into Redwater — Redwater has its own viewmodels and never frames a gun in a viewport. Do not add it to the mirror list.

## Dependencies
- **Requires:** Nothing
- **Required by:** HuntersBuyController, Viewport, Preview

## Connections
### RemoteEvents
None

### BindableEvents
None

### Direct require()
None
