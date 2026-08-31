---
tags: [shared, modulescript, hunter-manifest, vesper]
path: game.ReplicatedStorage.Hunters.Vesper.Config.Manifest
type: ModuleScript
lines: 145
---

# Vesper Manifest

Declarative description of Vesper consumed by HunterServerRuntime (server) and HunterClientRuntime (client). Single source of truth for her hunter name, folder path, remotes, ultimate-charge config, and client-side bindables.

## What it does
1. Declares `HunterName = "Vesper"`, `KillFeedWeaponName = "Sunspike Carbine"`, `DefaultSourceType = "Basic"`
2. Declares `HunterFolder = { "Hunters", "Vesper" }` — both runtimes resolve this from ReplicatedStorage
3. Declares 15 RemoteEvents to be ensured under `Vesper.Remotes`: FireBullet, ReloadRequest, ReplicateShot, GrappleRequest, GrappleFX, PinningThrowRequest, PinningLaunchFX, PinningImpactFX, PinningZoneUpdate, UltimateRequest, UltimateShotRequest, UltimateState, UltimateChargeUpdate, ScopeStateChanged, ForceScopeExit
4. Declares NO `Remotes.Bindables` — Vesper has no server-side bindable bridges — and a `Client.ViewmodelTemplate` of `{ "Hunters", "Vesper", "Weapon", "Viewmodel", "Default", "ArmsViewModelSniper" }`, her dedicated sniper viewmodel driven through HunterFirstPersonClient
5. Declares the Vesper UltimateCharge config (MaxCharge 100; `Basic` source Hit/Headshot/Kill = **8/16/18**; `Ultimate` source all zeros so Starfall Sight shots award no charge toward the next ultimate; PassiveChargePerSecond **0.4**; ChargeUpdateRemote "UltimateChargeUpdate"). **`Kill` must stay >= `Headshot`**: UltimateChargeService's AwardHit awards exactly one value and tests `didKill` first, and her 125-damage headshot one-shots every hunter, so a headshot kill pays `Kill` and never `Headshot` — the old 4/10/6 made the skill shot charge her *slower* than two body shots. Retuned 2026-07-28 to Dust's charge-per-second (his 2.5/6/5 fires on a 0.4s cadence against Sunspike's 1.8s): ~4 kills / ~26s of clean body shots to full, down from ~10 kills / ~52s. Her Grapple and Pinning Round award no charge at all, so basic shots plus the passive trickle are her only sources
6. Declares 19 `Client.ClientEvents` BindableEvents ensured under `Vesper.ClientEvents`: AmmoChanged, Reloaded, GrappleCooldownStarted, PinningCooldownStarted, UltimateCooldownStarted, UltimateChargeChanged, UltimateActiveChanged, UltimateAmmoChanged, ScopeChanged, SprintChanged, ReloadStarted, ReloadEnded, FireRequested, ShotFired, UltimateShotFired, GrappleRequested, PinningRequested, UltimateRequested, ReloadRequested. `UltimateActiveChanged` / `UltimateAmmoChanged` drive Starfall Sight's own 3-round ammo display above the ult icon (the magazine is untouched by the ultimate)
   - **`SprintChanged` (added 2026-08-11) exists because SprintController cannot be shared.** It owns a per-frame ramp rather than a signal, and `HunterClientRuntime.Start` constructs a **new** SprintController on every call — so the copy handed to VesperViewModelAnimationClient is never `Update()`d and would report "never sprinting". SunspikeClient owns the live one and publishes the edge through this bindable instead. ClientEvents are real BindableEvent instances in a shared folder (`HunterRemoteSetup.EnsureBindableEvents`), which is exactly why they cross scripts where the controller object cannot

7. Declares the `Abilities` block read by HunterAbilityIntroClient for the first-spawn intro tags: three `Slots` (`Q` GRAPPLE HOOK / `E` PINNING ROUND / `F` STARFALL SIGHT), each with a `Name`, a one-line `Blurb` and a `Tag`. Slot order is HUD order. **`Tag` is the only field Redwater draws** — the 2-4 word action phrase shown above that ability's HUD icon (`GRAPPLE TO SURFACES` / `TAG THROUGH WALLS` / `3 PIERCING SHOTS`); it says what the button *does*, since the name is only useful once you already know the ability. Vesper owns the longest copy of the four hunters, which is the worst case for wrapping on a phone. `Name`/`Blurb` are the long-form copy, kept **verbatim** in step with the authored ABILITIES panel in Bounty's Collection menu (`CollectionGui.AbilityPanelNew.Vesper`). The `Passive` line is retained for that parity but is no longer displayed in Redwater — it is not something the player presses. Icon ids are deliberately absent, and Vesper is the reason: VesperHunterGuiClient sets her HUD ultimate icon to a **different asset** from the one on the lobby panel, and a tag parented into the live icon can never disagree with what is on screen

8. Declares the `Animations` table (2026-08-29) — the ONE home of Vesper's clip ids, resolved by HunterAnimations for every loader: 6 `Viewmodel` clips (Idle, Reload, Scope, Shoot, Sprint, Ultimate — `BasicReload` was deleted from both rigs the same day; it posed only 6 of the rig's 12 animated parts and must not be reintroduced) and 3 `World` clips (Idle, Scope, Shooting), plus an empty `Skins` override table. A skin override is an explicit entry here, never a rig id that happens to differ; the rig Animation instances and the ViewmodelAnimations drop-zone are unread until Phase 2 deletes them

## Dependencies
- **Requires:** Nothing
- **Required by:** SunspikeModule, SunspikeClient, VesperScopeController, VesperHunterGuiClient, HunterAbilityIntroClient, HunterAnimations (plain text — reads the `Animations` table; its own file declares the require), WorldAnimationPrewarmClient (plain text — that script's own file declares the require)

## Connections
### RemoteEvents
None

### BindableEvents
None

### Direct require()
None
