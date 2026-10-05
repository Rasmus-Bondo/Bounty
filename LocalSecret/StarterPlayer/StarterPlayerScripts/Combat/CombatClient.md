---
tags: [client, localscript, combat, ui, input]
path: game.StarterPlayer.StarterPlayerScripts.Combat.CombatClient
type: LocalScript
lines: 481
---

# CombatClient

First-person PVE gunplay client: viewmodel, input, local shot prediction, combat HUD and replicated tracer/reload FX for other players.

## What it does
1. Builds the weapon viewmodel from `PVE.Assets.<Weapon>.Viewmodel` under the camera, loads its Idle/Walk/Run/Shoot/Reload tracks, preloads clips and plays a looping world-idle hold (`Config.Weapons[w].WorldIdle`) on the character's Animator.
2. Handles input (LMB / touch Fire button, R reload, Shift sprint, 1/2 weapon, hold LeftAlt to free the cursor) and sends `Fire` / `Reload` / `Equip` / `Sprint` / `Sync` on `Remotes.Action`; fire is gated on cadence, ammo, menus (`ClientMenuState.IsOpen()`), mount, downed/eliminated/revive-deadline attributes and encounter membership during combat phases.
3. Predicts revolver shots locally: muzzle flash + `BulletTrailDust` beam from the viewmodel muzzle to a camera raycast, before the server confirms.
4. Applies authoritative weapon state from `Remotes.State` (weapon, ammo, reload window, sprint, reload ack); retries `Sync` every 0.5 s for up to 10 s after spawn until state arrives.
5. Draws other players' shots from `ShotFX` (tracer from their `PVEWorldWeapon` muzzle, positional fire audio), pooled impact sparks from `CastImpact`, and positional reload audio from `ReloadFX`.
6. A `PVEViewmodel` render step (Camera+2) drives sway/bob/recoil, Walk/Run blending, reload left-arm fade, sprint FOV, cursor lock, hides the local body in first person, and swaps between LockFirstPerson and Classic when `PVEMounted` toggles.
7. Owns the `PVE_CombatHUD` weapon panel, loadout buttons, hint line and touch cluster; hides the Roblox touch jump button and the Backpack CoreGui.
8. Cursor release: holding LeftAlt (released on key-up, window focus loss or respawn) and an open menu both show `StarterGui.AltCursorGui.ModalButton`; the button is permanently `Modal`, so only its `Visible` is toggled. It is found with a 10 s `WaitForChild` and falls back to a dummy table if missing.
9. Shows a text hit line from `Remotes.Hit` (`HIT` / `HEADSHOT` / `TARGET DOWN` + damage); the `Hit` frame itself is forced invisible in both branches.

## Dependencies
- **Requires:** [[ClientMenuState]], [[CombatConfig]], [[WeaponAudio]]
- **Required by:** Nobody

## Connections
### RemoteEvents
| Remote | Direction | Other script |
|--------|-----------|-------------|
| `Remotes.Action` | → Server | [[CombatServer]] fire/reload/equip/sync/sprint |
| `Remotes.State` | ← Server | [[CombatServer]] authoritative weapon state |
| `Remotes.ShotFX` | ← Server | [[CombatServer]] other players' tracers |
| `Remotes.CastImpact` | ← Server | [[CombatServer]] impact sparks |
| `Remotes.ReloadFX` | ← Server | [[CombatServer]] other players' reload audio |
| `Remotes.Hit` | ← Server | [[CombatServer]] hit confirm text |

### BindableEvents
None

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[ClientMenuState]] | `Menus.IsOpen()` | Block fire/sprint and free the cursor while a menu is open |
| [[CombatConfig]] | `Config.Weapons`, `WalkSpeed`, `SprintSpeed` | Magazine, cadence, reload time, view offset, tracer speed |
| [[WeaponAudio]] | `Audio.Fire()`, `Audio.Reload()` | Local and positional weapon sounds |
