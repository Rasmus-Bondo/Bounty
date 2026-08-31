---
tags:
  - client
  - localscript
  - combat
  - fortuna
  - cards
path: game.StarterPlayer.StarterPlayerScripts.Fortuna.CardsWorldVisualClient
type: LocalScript
lines: 113
---

# CardsWorldVisualClient

Hides the local Fortuna player's own third-person `CardsWorldCards` model so it doesn't clash with their first-person viewmodel. Fortuna's counterpart to HideLocalWorldRevolver.

## What it does
1. Exits immediately via `HunterGate.IsHunter(player, "Fortuna")` if the local player isn't on Fortuna (Phase 3 — replaced inline `waitForSelectedHunter` with [[HunterGate]])
2. Watches the local character for a `CardsWorldCards` instance (created server-side by CardsWorldVisualServer) and sets `LocalTransparencyModifier`/Transparency/Enabled to hidden on every descendant part/decal/particle/beam/trail — local-only, other players still see it normally
3. Re-applies the hide every `RunService.RenderStepped` in case anything resets transparency, and re-watches whenever a new `CardsWorldCards` is added on respawn

## Dependencies
- **Requires:** [[HunterGate]] (from `ReplicatedStorage.Hunters.Shared`), [[HunterClientState]]
- **Required by:** Nobody

## Connections
### RemoteEvents
None

### BindableEvents
None

### Direct require()
None
