---
tags:
  - client
  - localscript
  - viewmodel
  - camera
path: game.StarterPlayer.StarterPlayerScripts.HunterFirstPersonClient
type: LocalScript
lines: 471
---

# HunterFirstPersonClient

Generic arms-only first-person viewmodel fallback for any hero that isn't Dust, Fortuna, or Bram (each of which owns a dedicated viewmodel in its own client).

## What it does
1. Waits (up to 10s) for the local player's `SelectedHunter` attribute; exits immediately if it's "Dust", "Fortuna", or "Bram" since those hunters own their full first-person lifecycle in their own dedicated clients (FPSRevolverClient for Dust; the Fortuna Cards client scripts for Fortuna; GrudgekeeperClient for Bram, which drives the Grudgekeeper arms viewmodel + its Idle/Running/Reload/Shoot animations)
2. Clones the hunter's viewmodel template onto the camera — `Hunters.Vesper.Weapon.Viewmodel.Default.ArmsViewModelSniper` for Vesper, `Hunters.Dust.Weapon.Viewmodel.Default.ArmsViewModelRevolverNew` for anyone else — strips collision/physics from its parts, and hides any `RevolverDefault` sub-model (the fallback rig is arms-only)
2b. **Gun-skin viewmodels** resolve before every clone: the `EquippedWeaponSkin_<Hunter>` player attribute is looked up as a sibling of the template under a folder named `Skins` (the same convention RevolverViewModel's resolver reads for Dust — Vesper's `Skins.Frostpiercer` is a full arms+gun model whose gun sub-model is named `Sniper`, which VesperViewModelAnimationClient requires). Default skin names miss the folder and fall through to the template. A change to the attribute destroys and rebuilds the viewmodel hidden; the render step re-enables it next frame — this covers direct joiners, whose attribute can land after this script has already built the default
3. Locks the mouse and forces `LockFirstPerson` camera mode whenever the round is active and the character is alive; restores classic camera/mouse otherwise
4. Every render step, procedurally animates the viewmodel CFrame: idle sway, mouse-look sway, movement bob, strafe tilt/offset, and a jump/land lift-and-dip — reusing the same `RevolverConfig.ViewModel` tuning values as the Dust revolver viewmodel
5. Re-creates the viewmodel if it's ever missing from the camera (e.g. camera swap) and re-parents it if the current camera changes
6. Honours a client-local `HideViewModel` attribute on the local player: while it is true, `setViewModelEnabled` forces the hidden path no matter who calls it, so another client script can suppress the arms/weapon render without fighting the `setViewModelEnabled(true)` this script re-asserts every render step. Vesper's scope controller raises it on ADS (gun + arms vanish behind the scope overlay); clearing it restores the viewmodel on the next render step
7. Runs [[AimAssistController]] each frame before the viewmodel composition, gated to touch-only inputs, using `RevolverConfig.AimAssist` tuning — so non-Dust hunters get the same mobile camera magnetism as Dust

## Dependencies
- **Requires:** [[AimAssistController]], [[HunterViewmodelContract]] (`Normalize`, on every fresh viewmodel clone — reconciles the equipped skin against the hunter's own default rig, and no-ops for a hunter borrowing Dust's arms with no default of its own) (from `ReplicatedStorage.Hunters.Shared`); reads [[RevolverConfig]] directly via `require`, but doesn't appear in that module's "Required by" list since this script is a fallback path, not part of the Dust kit, [[HunterClientState]]
- **Required by:** Nobody

## Connections
### RemoteEvents
None

### BindableEvents
None

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[RevolverConfig]] | `.ViewModel`, `.AimAssist` | Reuses Dust's viewmodel sway/bob/strafe/jump tuning values; aim-assist tuning passed to [[AimAssistController]] |
| [[AimAssistController]] | `.new()`, `:Update()` | Touch-only camera magnetism toward enemies for non-Dust hunters |
