---
tags:
  - client
  - localscript
  - combat
  - viewmodel
  - dust
path: game.StarterPlayer.StarterPlayerScripts.Dust.HideLocalWorldRevolver
type: LocalScript
lines: 62
---

# HideLocalWorldRevolver

Hides the local player's own third-person world-model revolver cosmetic so it doesn't visually clash with the first-person viewmodel. Phase 3 moved under `StarterPlayerScripts.Dust/` and migrated its gate to [[HunterGate]].

## What it does
1. Exits immediately via `HunterGate.IsHunter(player, "Dust")` if the local player isn't on Dust — this only applies to the revolver hunter
2. Finds the `WorldRevolverCosmetic` instance on the local character (created server-side by RevolverWorldModelServer via HunterWorldModel) and sets `LocalTransparencyModifier` to 1 on every part, plus disables decals/particles/beams/trails/lights — this hides it only for the local client, other players still see it
3. Re-applies the hide whenever a new `WorldRevolverCosmetic` is added to the character (handles respawns and re-attachment)

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
