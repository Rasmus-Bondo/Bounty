---
tags:
  - shared
  - modulescript
  - combat
  - penetration
path: game.ReplicatedStorage.Hunters.Shared.BulletPenetration
type: ModuleScript
lines: 320
---

# BulletPenetration

Shared "shoot through cover" rules for every hitscan weapon — decides what a bullet can cross, walks the shot through it, and scales the damage.

## What it does

1. `GetAuthoredPenetrable(instance)` answers the **authored** half of the test, highest priority first:
   - `Penetrable` **attribute** (boolean) on the part or any ancestor — an explicit override in either direction, so setting it `false` forces one specific piece of cover solid even if the material rule would pass it
   - `Penetrable` **CollectionService tag** on the part or any ancestor
   - Returns `nil` when neither is present, which is what lets a caller tell "deliberately solid" (`false`) apart from "nobody said" (`nil`)
   - Non-BaseParts and `Terrain` return `false` outright, so the material lookup below is only ever reached for a real part
2. `IsPenetrable(instance)` takes the authored answer when there is one, else falls back to material `Wood`, `WoodPlanks` or `Fabric` (canvas wagon covers, crane tarps, awnings). This is the bullet's test and its behaviour is unchanged
3. `IsAuthoredPenetrable(instance)` is tag-or-attribute **only** — material is not enough. High Noon's target lock passes it as `overrides.IsPenetrable` so a marked cactus or wagon stays see-through to the lock while a wooden building wall does not; the bullet that follows still uses the full test and crosses both
4. `Pierce(origin, directionVector, params, overrides)` walks the shot: raycast → penetrable? → back-cast against that part alone with an `Include` filter to find its exit face → step past it and cast again. Returns `{ Result, Layers, Penetrated, Stopped, StopPosition }`. `overrides.IsPenetrable` swaps the classifier for that one call; it is not a `Config` key, so it bypasses `readSetting` and defaults to `IsPenetrable`
5. Counts **walls, not parts**. The arena's wooden buildings are authored from many overlapping planks (one is 266 parts), so consecutive penetrable hits within `LayerMergeGapStuds` (2) of each other collapse into a single layer. A wagon reads as two walls, a fence as one
6. Stops the bullet when it would cross a third wall (`MaxLayers = 2`), or when a single part is thicker than `MaxDepthPerLayerStuds` (12) — the latter falls out of Roblox ignoring parts a raycast starts inside, so the backward cast returns nil for anything too thick to punch. Prevents tunnelling down the long axis of a beam
7. `GetDamageMultiplier(layers, overrides)` returns `DamageMultiplierPerLayer ^ layers` — 100% clean, 50% behind one wall, 25% behind two
8. Copies the caller's `RaycastParams` before walking (never mutates it) and adds each crossed part to the copy's exclude filter to guarantee forward progress
9. Per-hunter `overrides` tables let one weapon tune penetration without touching the others; anything omitted falls back to `BulletPenetration.Config`. No hunter config defines `IsPenetrable`, so every weapon still classifies cover the same way — only High Noon's lock overrides it

## Team modes

`Pierce` takes the shooter as a fifth argument, and their teammates become fully transparent:
skipped outright, never counted as a penetration layer. A shot past an ally therefore takes no
wall falloff and lands on whatever is behind them. Client FX sims pass their own local shooter,
which is what keeps the tracer and the server's shot agreeing.

## Dependencies

- **Requires:** [[TeamAffinity]]
- **Required by:** RevolverLagCompensation, RevolverHitForgiveness, RevolverShooting, HighNoonTargeting, RevolverModule, SunspikeModule, SunspikeClient, GrudgekeeperModule, CardsServer, AimAssistController — plain text, not wikilinks. A `Required by:` wikilink points the edge dependency → dependent, which is backwards; each caller declares the `require()` in its own file, which is where the graph gets the correct edge from.

## Connections

### RemoteEvents

None

### BindableEvents

None

### Direct require()

None

### CollectionService Tags

| Tag | Usage | Defined by |
|-----|-------|-----------|
| `Penetrable` | Read via `HasTag` walking up from the hit part. Authored on `workspace.Cacti` (Plastic/Grass MeshParts) and on each `workspace.Caravan` wagon (Metal frame + Fabric cover unions) — neither matches the material rule. Also on the `Fence`, `WoodPanels`, `Crates` and `Barrels` folders so mixed wood/metal props behave as one piece of cover instead of letting a bullet through the staves and stopping it on the hoop. The tag now carries a second meaning: it is the **only** thing that keeps cover see-through to High Noon's target lock, since `IsAuthoredPenetrable` ignores the material rule. Tagging a building wall would reopen the through-wall lock the two-tier sight test exists to close | This module (authored on map instances, not created in code) |
