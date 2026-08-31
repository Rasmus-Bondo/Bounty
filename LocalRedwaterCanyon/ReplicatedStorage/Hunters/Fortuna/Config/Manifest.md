---
tags: [shared, modulescript, hunter-manifest, fortuna]
path: game.ReplicatedStorage.Hunters.Fortuna.Config.Manifest
type: ModuleScript
lines: 128
---

# Fortuna Manifest

Declarative description of Fortuna consumed by HunterServerRuntime (server) and HunterClientRuntime (client). Phase 2 + Phase 3.

## What it does
1. Declares `HunterName = "Fortuna"`, `KillFeedWeaponName = "Cards"`, `DefaultSourceType = "Basic"`
2. Declares `HunterFolder = { "Hunters", "Fortuna" }`
3. Declares 11 RemoteEvents to be ensured under `Hunters/Fortuna/Remotes`: ThrowRequest, Ability1AimUpdate, RecallRequest, UltimateRequest, UltimateState, CardFlyFX, CardRecallFX, CardThrowVFX, UltimateChargeUpdate, CardsHandVisibilityUpdate, DashRequest (fired at the start of Ability1 to drive the opening dash — server-authoritative via RevolverDashService)
4. Server-side `Remotes.Bindables` intentionally absent — Fortuna's client-internal bindables are declared under `Client.ClientEvents` and ensured under `Hunters/Fortuna/ClientEvents` by HunterServerRuntime (folder authority) and re-ensured by HunterClientRuntime (idempotent). The standalone `CardsRemoteSetup` server Script was removed as part of this consolidation.
5. Declares the Fortuna UltimateCharge config (MaxCharge 100; per-source Hit/Headshot/Kill values for Basic/Ability1/Recall/Ultimate matching CardsConfig.UltimateCharge; PassiveChargePerSecond 0.1 = `PassiveRegenAmount / PassiveRegenInterval` = `0.1 / 1`; ChargeUpdateRemote "UltimateChargeUpdate"; DisplayPrecision 0.1)
6. Phase 3: declares `Client.ViewmodelTemplate = { "Hunters", "Fortuna", "Weapon", "Viewmodel", "Default", "ArmsViewModel" }` and `Client.ClientEvents` (11 BindableEvents: AmmoChanged, Reloaded, Ability1CooldownStarted, RecallCooldownStarted, UltimateCooldownStarted, UltimateChargeChanged, Ability1Requested, RecallRequested, UltimateRequested, ReloadRequested, FireRequested — the last drives the mobile FIRE button). HunterServerRuntime ensures them under `Hunters/Fortuna/ClientEvents` (server folder authority — replaces the deleted `CardsRemoteSetup` script) and HunterClientRuntime re-ensures them idempotently, exposing via `runtime.ClientEvents.*`

7. Declares the `Abilities` block read by HunterAbilityIntroClient for the first-spawn intro tags: three `Slots` (`Q` RECALL / `E` SURGE / `F` VANISHING HAND), each with a `Name`, a one-line `Blurb` and a `Tag`. Slot order is HUD order — note her Q is Recall, not the dash. **`Tag` is the only field Redwater draws** — the 2-4 word action phrase shown above that ability's HUD icon (`YANK CARDS BACK` / `DASH + CARD SPREAD` / `VANISH, THEN BURST`); it says what the button *does*, since the name is only useful once you already know the ability. `Name`/`Blurb` are the long-form copy, kept **verbatim** in step with the authored ABILITIES panel in Bounty's Collection menu (`CollectionGui.AbilityPanelNew.Fortuna`). The `Passive` line is retained for that parity but is no longer displayed in Redwater — it is not something the player presses. Icon ids are deliberately absent: the tags are parented into the live HUD icon they describe, so they cannot drift from what CardsHunterGuiClient sets at runtime

8. Declares the `Animations` table (2026-08-29) — the ONE home of Fortuna's clip ids, resolved by HunterAnimations for every loader: 10 `Viewmodel` clips (1CardThrow/2CardThrow/3CardThrow in bracket syntax — numeric-prefixed names are not Lua identifiers — plus Basic, Idle, Recall, Reload, Run, Ultimate, Walk) and 3 `World` clips (Idle, Shooting, Ultimate — the world Ultimate is players-only; no bot loads it), plus an empty `Skins` override table. A skin override is an explicit entry here, never a rig id that happens to differ; the rig Animation instances and the ViewmodelAnimations drop-zone are unread until Phase 2 deletes them

## Dependencies
- **Requires:** Nothing
- **Required by:** CardsServer, CardsClient, CardsHunterGuiClient, HunterAbilityIntroClient, HunterAnimations (plain text — reads the `Animations` table; its own file declares the require), WorldAnimationPrewarmClient (plain text — that script's own file declares the require)

## Connections
### RemoteEvents
None

### BindableEvents
None

### Direct require()
None
