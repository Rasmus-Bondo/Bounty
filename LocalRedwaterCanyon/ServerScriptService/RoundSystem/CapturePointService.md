---
tags: [server, modulescript, roundsystem, gamemode, domination, map]
path: game.ServerScriptService.RoundSystem.CapturePointService
type: ModuleScript
lines: 99
---

# CapturePointService

Parks the Domination capture pads and their ownership beams out of the world in every mode that does
not use them, and restores them for the one that does. Built 2026-08-22, modelled on TeamBaseService.

## What it does
1. **Resolves once, at boot, while everything is still where it was authored:** every workspace-root
   Model whose name starts with `MapConfig.Instances.CapturePoints` and carries a `Letter` attribute
   (the three pads), and every workspace-root BasePart named `<prefix>Beam` (the three beam anchors) —
   the same match Gamemodes.Domination and CapturePointVisualClient make. Each record keeps its own
   parent. A map that names no prefix has nothing to park and `Apply` is a no-op; a prefix that
   matches nothing warns once.
2. **`Apply(usesCapturePoints)`** reparents every record into `ServerStorage.ParkedMapGeometry` —
   the same folder TeamBaseService parks the spawn houses in — or back to its recorded parent.
   Reparent, never Destroy: reversible, symmetric, and it takes the geometry off every client for
   free. Attributes survive a park, so the `Letter` stamped on a beam at Domination's `Init` outlives
   a stint in FFA.
3. **Called by RoundController before the mode's `Init`** — at boot, on the tutorial path
   (`Apply(false)`) and on every mode ballot switch — with `rules.UsesCapturePoints == true`. The
   order is the contract: Domination's `Init` resolves the pads' geometry out of the workspace and
   asserts they are there, so a server that booted into FFA (pads parked) has to get them back before
   that `Init` runs. TeamBaseService's call sits after `Init`; this one cannot.
4. Nothing physical rides on the swap: the pad parts are authored `CanCollide = false`, so parking
   moves no fighter and carves nothing out of the navmesh. Between rounds only, for the same reason
   as the houses.

## Dependencies
- **Requires:** [[MapConfig]] (the per-place pad / beam name prefix)
- **Required by:** RoundController (the three dressing call sites)

## Connections
### RemoteEvents
None.

### BindableEvents
None.

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[MapConfig]] | `MapConfig.Instances.CapturePoints` | Which workspace-root Models and `<prefix>Beam` parts this map swaps |

## Notes

The flag it keys on, `UsesCapturePoints`, is declared by Gamemodes.Domination only; Deathmatch and
TeamDeathmatch leave it nil, which `Apply(nil == true)` reads as "park". A future objective mode that
wants the pads declares the same flag and gets them for free.

CapturePointVisualClient (client) needs nothing from this module: it tracks
`workspace.ChildAdded/ChildRemoved`, so a park or restore is just pads leaving or arriving.
