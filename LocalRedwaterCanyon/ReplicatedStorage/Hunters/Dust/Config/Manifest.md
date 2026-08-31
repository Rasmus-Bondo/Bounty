---
tags: [shared, modulescript, hunter-manifest, dust]
path: game.ReplicatedStorage.Hunters.Dust.Config.Manifest
type: ModuleScript
lines: 110
---

# Dust Manifest

Declarative description of Dust consumed by HunterServerRuntime (server) and HunterClientRuntime (client). Phase 2 + Phase 3 — single source of truth for Dust's hunter name, folder paths, remotes, ultimate-charge config, viewmodel template, and client-side bindables.

## What it does
1. Declares `HunterName = "Dust"`, `KillFeedWeaponName = "Revolver"`, `DefaultSourceType = "Revolver"`
2. Declares `HunterFolder = { "Hunters", "Dust" }` — both runtimes resolve this from ReplicatedStorage
3. Declares 12 RemoteEvents to be ensured under `Hunters/Dust/Remotes`: FireBullet, ReloadRequest, Skill2Request, ReplicateShot, DashRequest, HighNoonRequest, HighNoonVisual, HighNoonShot, HighNoonAimUpdate, HighNoonShootRequest, HighNoonChargeUpdate, WorldRevolverShotSound
4. Declares 1 BindableEvent under `Hunters/Dust/ServerEvents`: WorldRevolverShotVFX (the legacy `HighNoonChargeAward` BindableEvent is intentionally omitted — Phase 2's runtime-owned ChargeService replaces the BindableEvent bridge between RevolverModule and HighNoonModule; the orphaned event is still created by RevolverRemoteSetup for now and will be removed in a follow-up cleanup)
5. Declares the Dust UltimateCharge config (MaxCharge 100, Sources.Revolver.Hit/Headshot/Kill = 2.5/6/5, PassiveChargePerSecond 0.125, ChargeUpdateRemote "HighNoonChargeUpdate") — these mirror HighNoonServerConfig.Ultimate verbatim
6. Phase 3: declares `Client.ViewmodelTemplate = { "Hunters", "Dust", "Weapon", "Viewmodel", "Default", "ArmsViewModelRevolverNew" }` (resolved by client runtime) and `Client.ClientEvents` (8 BindableEvents: AmmoChanged, Reloaded, DashCooldownStarted, Skill2CooldownStarted, DashRequested, Skill2Requested, FireRequested, HighNoonAimNudge) — the client runtime ensures them under `Hunters/Dust/ClientEvents` and exposes via `runtime.ClientEvents.*`. Replaces inline bindable-creation boilerplate previously duplicated in HunterGuiClient and FPSRevolverClient. `FireRequested` was added when mobile shooting moved from TouchTap (delayed by Roblox's tap-vs-drag heuristic) to a dedicated visible Fire button

7. Declares the `Abilities` block read by HunterAbilityIntroClient for the first-spawn intro tags: three `Slots` (`Q` QUICK DRAW / `E` FAN THE HAMMER / `F` DEAD EYE), each with a `Name`, a one-line `Blurb` and a `Tag`. Slot order is HUD order. **`Tag` is the only field Redwater draws** — the 2-4 word action phrase shown above that ability's HUD icon (`DASH + RELOAD` / `RAPID FIRE` / `LOCK ON, THEN FIRE`); it says what the button *does*, since the name is only useful once you already know the ability. `Name`/`Blurb` are the long-form copy, kept **verbatim** in step with the authored ABILITIES panel in Bounty's Collection menu (`CollectionGui.AbilityPanelNew.Dust`). The `Passive` line is retained for that parity but is no longer displayed in Redwater — it is not something the player presses. Icon ids are deliberately absent: the tags are parented into the live HUD icon they describe, so they cannot drift from it the way a duplicated asset id would

8. Declares the `Animations` table (2026-08-29) — the ONE home of Dust's clip ids, resolved by HunterAnimations for every loader: 7 `Viewmodel` clips (Fanning, Idle, Reload, Run, Shoot, Ultimate, Walk) and 2 `World` clips (Idle, Shooting — these two ids replaced string literals duplicated across FOUR files with nothing enforcing agreement), plus an empty `Skins` override table. A skin override is an explicit entry here, never a rig id that happens to differ; the rig Animation instances and the ViewmodelAnimations drop-zone are unread until Phase 2 deletes them

## Dependencies
- **Requires:** Nothing
- **Required by:** RevolverModule, FPSRevolverClient, HunterGuiClient, HunterAbilityIntroClient, HunterAnimations (plain text — reads the `Animations` table; its own file declares the require), WorldAnimationPrewarmClient (plain text — that script's own file declares the require)

## Connections
### RemoteEvents
None

### BindableEvents
None

### Direct require()
None
