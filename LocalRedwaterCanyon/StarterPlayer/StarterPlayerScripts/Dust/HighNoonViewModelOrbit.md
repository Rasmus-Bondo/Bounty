---
tags:
  - client
  - localscript
  - combat
  - ultimate
  - viewmodel
  - dust
path: game.StarterPlayer.StarterPlayerScripts.Dust.HighNoonViewModelOrbit
type: LocalScript
lines: 251
---

# HighNoonViewModelOrbit

Client-side gunslinger flick animation that rotates the view model toward each High Noon shot target, layered on top of FPSRevolverClient's positioning. Phase 3 moved under `StarterPlayerScripts.Dust/` and migrated its top-level gate to [[HunterGate]].

## What it does

1. Exits immediately via `HunterGate.IsHunter(player, "Dust")` if the local player isn't on Dust
2. Listens to `HighNoonAimNudge` BindableEvent for hit positions during High Noon
2. Calculates yaw/pitch from the view model muzzle to the hit position in camera-local space. The muzzle is reached through `RevolverViewModel.FindRevolverModel` rather than a hardcoded `RevolverDefault` lookup — a weapon skin names its gun model whatever it likes (Icefang's was `Ice`, since renamed), and the old lookup dropped those skins onto the alternating test flick in step 6 instead of aiming at the shot
3. Applies a pivot-based orbit rotation (left-biased pivot at -1, 0.55, 4.8) with roll proportional to yaw
4. Uses exponential smoothing: fast snap to target (speed 36), slower return to rest (speed 10)
5. Runs at RenderPriority.Camera + 1000, after FPSRevolverClient (Camera + 1), so it layers additively via `viewModel:PivotTo()`
6. Forces a visible flick if the target is nearly straight ahead (< 6 deg yaw) — alternates left/right per shot
7. Adds side/down/back translation offsets proportional to orbit intensity
8. Includes a manual test: press B to trigger a test flick
9. Resets all orbit state on `CharacterAdded`

## Dependencies

- **Requires:** [[HunterGate]] (from `ReplicatedStorage.Hunters.Shared`), [[HunterClientState]], [[RevolverViewModel]]; manipulates ClientViewModel directly otherwise
- **Required by:** Nobody

## Connections

### RemoteEvents

None

### BindableEvents

| Bindable | Direction | Other script |
|----------|-----------|--------------|
| `HighNoonAimNudge` | ← | [[HighNoonClient]] fires hit position for each High Noon shot |

### Direct require()

| Target | Function | Purpose |
|--------|----------|---------|
| [[RevolverViewModel]] | `RevolverViewModel.FindRevolverModel()` | Resolve the equipped skin's gun model to read its muzzle position |
