---
tags:
  - client
  - localscript
  - gamemode
  - visuals
  - teams
path: game.StarterPlayer.StarterPlayerScripts.CapturePointVisualClient
type: LocalScript
lines: 335
---

# CapturePointVisualClient

Paints the Domination capture pads in the owning team's colour, relative to the viewer
(DOMINATION_SPEC 5.4). Built 2026-08-22. Client-side for the same reason the rig outline is: team
colour is per viewer (own side blue, enemy red), and a colour written on the server is one value
replicated to everybody.

## What it does
1. Returns at once on a map whose `MapConfig.Instances.CapturePoints` is nil (no pads to paint).
2. Tracks every workspace-root Model named `<prefix>*` with a `Letter` attribute and every
   `<prefix>Beam` BasePart. Beams are matched to pads by the `Letter` attribute the Domination rules
   module stamps on them at boot (by proximity, on the server); that attribute is watched because it
   can land after the part replicates.
3. Per pad caches four surface sets: the BaseParts that carry a `TeamGui` SurfaceGui, the
   `UIGradient`s inside those guis, the `Beam`s on the matched anchor parts, and — added 2026-08-23 —
   the BaseParts that carry **no** `TeamGui` at all, which are the pad body itself. That last set is
   keyed on the ABSENCE of the SurfaceGui rather than on a name: Redwater calls the part
   `CapturePointBase` and Frostbite has no such part, so a name test paints one map and silently
   skips the other. Where the body is a `PartOperation` its `UsePartColor` is forced true while
   owned and restored to the authored value when neutral (the authored value is captured with an
   explicit nil test, because folding it through `and`/`or` collapses an authored `false` to nil and
   leaves the flag stuck on). Each set holds its **authored** value, captured on first sight, so neutral restores exactly what was authored.
4. Paints on `DomOwner_<Letter>` changes: both the SurfaceGui parts and the pad body take
   `TeamView.DOOR` (lit ForceField, like the spawn-house doors — the body is the same material as
   the walls, so it takes the same pair), gradients and beams take `TeamView.WORLD`, all through `TeamView.color` so the
   owning side renders blue to its own players and red to the enemy; `""`/nil restores the authored
   values. Repaints everything on `TeamView.onChanged`.
5. Streaming: the pads are `ModelStreamingMode = Default`, so each pad model's `DescendantAdded` /
   `DescendantRemoving` queue one deferred rebuild of that pad's surface cache (one `GetDescendants`
   per burst of streaming, never per ownership change) followed by a repaint — a part that streams
   in after a flip is painted the moment it lands. `workspace.ChildAdded/Removed` handle whole pads
   and beam parts arriving or leaving.

## Dependencies
- **Requires:** [[MapConfig]], [[TeamView]]
- **Required by:** Nobody

## Connections
### RemoteEvents
None

### BindableEvents
None

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[MapConfig]] | `Instances.CapturePoints` | The pad / beam name prefix for this map |
| [[TeamView]] | `color()`, `onChanged()`, `DOOR`, `WORLD` | Relative team colour and the repaint trigger |

Reads (no edges): the `DomOwner_<Letter>` workspace attributes published by Gamemodes.Domination, and
the `Letter` attributes on the pad models (authored) and beam parts (stamped at boot).

Outside Domination the pads and beams are not in the workspace at all — `CapturePointService` (server)
parks them in `ServerStorage.ParkedMapGeometry` and restores them when a mode declaring
`UsesCapturePoints` takes over — so the `workspace.ChildAdded/ChildRemoved` handlers in (5) are also
what follows a mode swap. Nothing here needs to know which mode is running.
