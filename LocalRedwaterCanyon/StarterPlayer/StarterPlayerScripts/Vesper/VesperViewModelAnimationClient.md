---
tags: [client, localscript, vesper, animation, viewmodel]
path: game.StarterPlayer.StarterPlayerScripts.Vesper.VesperViewModelAnimationClient
type: LocalScript
lines: 543
---

# VesperViewModelAnimationClient

Drives the dedicated Sunspike viewmodel animations (Idle / Shoot / Reload / Scope / Sprint / Ultimate) from Vesper's existing client events. Gates via [[HunterClientRuntime]]`.Start()` (returns nil off-hunter). Idle loops underneath every action; shoot fills the `Basic.Cooldown` window, reload fills `Basic.ReloadTime`, and scope eases to/from its held ADS pose over `Scope.TransitionTime`. Sprint and Ultimate are held loops driven by state rather than timed to a window. It binds to whatever `ClientViewModel` (containing a `Sniper`) appears under the current camera, reloading its tracks when the viewmodel is rebuilt.

**Track priority ladder, lowest first:** `Idle` (Core) < `Ultimate` (Idle) < `Scope` / `Sprint` (Movement) < `Reload` / `Shoot` (Action4). Ultimate sits *under* Scope by deliberate choice — Starfall Sight is a 12s window the player scopes and fires inside of, and keeping ADS reading correctly was judged more important than holding the ult stance. The consequence, which is expected rather than a bug: the ult pose only surfaces while unscoped and outside the 1.8s each shot occupies at Action4, so across a three-shot window it is a narrow slice. Scope and Sprint share Movement safely because SunspikeClient's `SetCanSprintCheck` refuses to sprint while scoped.

## What it does
1. Requires [[HunterClientRuntime]] + the [[Manifest|Vesper Manifest]]; exits silently when not on Vesper. Reads [[VesperConfig]] `Basic`/`Scope` timing and the `Hunters.Vesper.SFX` sound folder
2. `watchCamera` / `bindViewModel` — binds to the camera's `ClientViewModel` (ChildAdded + on CurrentCamera change), builds the Idle/Ultimate/Scope/Sprint/Reload/Shoot AnimationTracks from ids resolved out of the **Vesper manifest** via HunterAnimations (the clone's Animation instances are unread; the `EquippedWeaponSkin_Vesper` attribute is passed as the override key), prewarming the whole set in one pass first, and plays Idle. Held state is then restored onto the fresh tracks (scope, reload, sprint, ultimate), because a respawn or hunter switch rebuilds the viewmodel mid-state. The readiness wait before that only requires a resolved `Length` on the three **time-scaled** tracks (Shoot / Reload / Scope) — Idle, Sprint and Ultimate play at a fixed speed, so waiting on them would just burn the whole 2s budget
3. Consumes Vesper's `ClientEvents` bindables (from [[SunspikeClient]] / [[VesperScopeController]]): `AmmoChanged` (drives the shot sequence with rifle-report SFX), `UltimateShotFired` (drives the **same** sequence with the rifle report suppressed — Starfall supplies its own layered report from [[SunspikeClient]]), `PinningCooldownStarted` (firing-pose only), `ReloadStarted`/`ReloadEnded` (reload anim + SFX), `ScopeChanged` (ADS pose)
   - **Why the ultimate needs its own trigger, and the shape of launch issue #4:** Starfall spends its own shot pool and freezes the magazine, so `AmmoChanged` never fires for an ultimate shot — [[SunspikeClient]] documents the same fact where it hand-kicks auto-reload at the end of the window. This handler used to only set a "suppress the next normal shot" flag and wait for an `AmmoChanged` that never came, so the flag survived the ultimate and silenced the player's **next basic shot** instead, while the ultimate shot itself played no viewmodel animation at all. The suppression flag is gone; each trigger now drives the sequence directly
   - The bolt-cycle `SniperReloadRefresh` layer is part of the sequence and plays for an ultimate shot too — only the `SniperShoot`/`SniperShoot2` rifle report is gated, which is what the suppression was always scoped to
   - Consumes `SprintChanged` (from SunspikeClient) and `UltimateActiveChanged` for the two held loops, played through a shared `setHeldLoop` helper that guards on `IsPlaying` so a repeated "on" cannot restart a loop mid-cycle and takes an optional playback speed (applied after `Play`, which resets speed to 1x). Sprint passes `SPRINT_ANIMATION_SPEED`; Ultimate passes none. Both flags are cleared in the teardown, or a swap back to Vesper would restore a pose that ended while she was benched
4. Plays matching `Hunters.Vesper.SFX` layers, stretching each clip's `PlaybackSpeed` so its final duration matches the authored animation timing
5. Registers a [[HunterClientState]] teardown cleanup: drops the client-event/camera listeners, disconnects the viewmodel watcher, and stops + destroys the loaded tracks and active sounds so a swap away from Vesper leaves no track playing and a swap back rebinds cleanly

## Reworked animation set (2026-08-11)

Vesper's clips were replaced with a reworked set authored by Outlaw Syndicate. `Reload` and `Shoot` were swapped in place; `Sprint` and `Ultimate` are **new slots**, created as Animation instances under `Hunters.Vesper.Weapon.Viewmodel.Default.ArmsViewModelSniper.AnimationController` (Vesper had no sprint or ultimate pose before — sprint was FOV and speed only).

| Slot | Asset | Authored length | Played at |
|---|---|---|---|
| `Reload` | 73583544224104 | 3.183s | scaled to `Basic.ReloadTime` 3.0s (1.06x) |
| `Shoot` | 84860686696858 | 1.383s | scaled to `Basic.Cooldown` 1.8s (0.77x) |
| `Sprint` | 125036411554611 | 0.650s | `SPRINT_ANIMATION_SPEED` 0.75x → ~0.87s, looped |
| `Ultimate` | 121214634495022 | 1.000s | authored speed, looped |

**The reworked `Shoot` clip merges the shot and the bolt-cycle**, which the old set played as two chained tracks (`Shoot` 0.400s then `BasicReload` 0.533s, time-scaled together to fill the cooldown). `playShotSequence` collapsed to a single track accordingly, and **`BasicReload` is no longer loaded or played by any code**.

**The orphaned `BasicReload` Animation instances were deleted on 2026-08-29** from both Vesper rigs (`Default.ArmsViewModelSniper` and `Skins.Frostpiercer`) in both match places — four instances, all `rbxassetid://107224384288403`. Measuring the clip is what settled it — it poses only **6** of the rig's 12 animated parts (Base, HeadViewport, LeftArm, Reload, RightArm, Root), missing `Bullet1`-`3`, `Magazine`, `Scope` and `Star`, all of which the live `Shoot` and `Reload` both pose. So it is not a usable clip on the current rig under any wiring, only the back half of the superseded two-clip shot. The Vesper manifest's `Animations` comment says the same thing so it is never reintroduced. Restore path if ever needed: the id above, or `ServerStorage.Unused.SniperDefaultViewmodel.Backup` in Redwater, which retains two copies and is not replicated.

Losing the second track also removed the thing the bolt-cycle sound hung off: `SniperReloadRefresh` used to start exactly when the cycle track did. It now fires at `CYCLE_SOUND_START_FRACTION` (0.43) of the shot window — the same proportion the old split produced — and is named at the top of the file because it is a tuning value, not a derived one.

## Verified

Both new slots load and play (confirmed in a playtest 2026-08-11). Note that this script and the viewmodel template are both snapshotted at playtest start, so edits to either need a **fresh** session: a running client keeps a `ClientViewModel` cloned from the old template, which has no `Sprint` or `Ultimate` child at all.

## Dependencies
- **Requires:** [[HunterClientRuntime]] (`.Start(manifest)` gate + client events), [[Manifest|Vesper Manifest]], [[VesperConfig]], [[HunterClientState]] (teardown registry), [[HunterAnimations]] (every clip id, from the manifest — from `ReplicatedStorage.Hunters.Shared`), [[AnimationLoader]] (`prewarm` for the whole clip set, then `load` per track — from `ReplicatedStorage.Modules`)
- **Required by:** Nobody

## Connections
### RemoteEvents
None

### BindableEvents
| Bindable | Direction | Other script |
|----------|-----------|-------------|
| `AmmoChanged` | ← | [[SunspikeClient]] fires on ammo change → shoot/cycle animation sequence |
| `UltimateShotFired` | ← | [[SunspikeClient]] fires per Starfall shot → the shoot/cycle animation sequence with the rifle report suppressed |
| `PinningCooldownStarted` | ← | [[SunspikeClient]] → Pinning Round firing pose |
| `ReloadStarted` / `ReloadEnded` | ← | [[SunspikeClient]] → play / stop the reload animation + SFX |
| `ScopeChanged` | ← | [[VesperScopeController]] → ADS scope pose |
| `SprintChanged` | ← | [[SunspikeClient]] publishes the sprint edge → held Sprint loop |
| `UltimateActiveChanged` | ← | [[SunspikeClient]] Starfall Sight start/end → held Ultimate loop |

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[HunterClientRuntime]] | `.Start(manifest)` | Hunter gate + resolved client events |
| [[Manifest|Vesper Manifest]] | (table return) | Declarative description of Vesper |
| [[VesperConfig]] | `.Basic`, `.Scope` | Animation timing (cooldown, reload time, transition time) |
| [[HunterClientState]] | `.registerCleanup()` | Stop tracks + drop listeners on a mid-match hunter swap |
| [[HunterAnimations]] | `set()`, `id()` | Resolve the whole Vesper viewmodel set (prewarm) and each clip id (track builds) from the manifest |
