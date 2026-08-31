---
tags: [server, modulescript, documentation, reference]
path: game.ServerScriptService.HunterImplementationGuide
type: ModuleScript
lines: 812
---

# HunterImplementationGuide

Documentation-only ModuleScript. Reference for adding a new hunter to Bullets and Bounty. Catalogs the shared infrastructure under `ReplicatedStorage.Hunters.Shared` and the manifest schema both runtimes consume. Returns `{}` so it is safe to `require`; it is never executed at runtime.

## What it does
1. Mental-model overview: declarative `Manifest` + two `Runtime` consumers (server, client), hunter-agnostic shared modules under `Shared/`, hunter-specific code under `Hunters.<Name>/`
2. Folder-layout convention for a new hunter across `ReplicatedStorage`, `ServerScriptService`, and `StarterPlayerScripts`
3. Full manifest schema with required and optional fields (`HunterName`, `KillFeedWeaponName`, `HunterFolder`, `Remotes.Events/Bindables`, `UltimateCharge`, `ConfigModule`, `Client.{ViewmodelTemplate, ClientEvents, ViewmodelConfig}`, folder-name overrides, `Abilities`, and — since 2026-08-29 — the `Animations` table: the ONE home of the hunter's clip ids, resolved by HunterAnimations for every loader, with skin overrides as explicit `Skins` entries and priority/looped staying at the call site)
3a. Documents the optional `Abilities` block (`Passive` + three `Slots` of `{ Key, Name, Blurb }`, slot order = HUD order Q/E/F) that HunterAbilityIntroClient reads for the first-spawn intro card, with its two rules: keep the wording identical to the hunter's authored ABILITIES panel in Bounty's Collection menu, and put **no icon ids** in it — the card reads icons off the live HUD because each hunter's GUI client overrides them at runtime and they do not always match the lobby panel's. Neither runtime reads this block; omitting it just means that hunter gets no card
4. `HunterServerRuntime.Start(manifest)` API: every field on the runtime handle and what to use each for
5. `HunterClientRuntime.Start(manifest)` API: yield semantics + every field on the runtime handle, plus a CAUTION that `SelectedHunter` appearing is the *only* thing that unblocks `Start` — any other player attribute read after it must already be final, because the standard pattern reads it once and never looks again
6. Catalog of every Shared module (HunterManifest, HunterRemoteSetup, HunterCharacterUtil, UltimateChargeService, HunterHitPipeline, HunterPositionHistory, HunterWorldModel, HunterGate, HunterViewModelMotion, HunterMobileAbilityButton, HunterMobileFireButton, HunterAutoReload) with WHY + entry point
7. Step-by-step wiring recipe for a new hunter (folder skeleton -> manifest -> HunterSelectionService entry -> server bootstrap -> per-shot HitPipeline call -> client bootstrap -> mobile ability + FIRE buttons -> world model -> hunter-switch registration). Step 8 now also documents the world-idle client twin rule: every hunter with a world gun needs a `*WorldIdleClient` at the ROOT of StarterPlayerScripts, because a player character's Animator is owned by that player's own client and the server's looped hold does not reliably hold on other people's screens — and it must not sit in the per-hunter folder HunterClientLoader disables. Every hunter must declare `FireRequested` in `Client.ClientEvents` and create a HunterMobileFireButton so touch players can shoot. Step 3 also requires adding the hunter to HunterSelectionService's `DEFAULT_WEAPON_SKINS` *before* it has any skins to sell — `applyWeaponSkinAttributes` iterates that table, so a missing hunter never gets an `EquippedWeaponSkin_<Hunter>` attribute at all (Vesper and Bram both shipped with this). Step 6 covers resolving the skinned viewmodel template from that attribute and why the clone must be a re-callable function re-run on its changed signal
8. Mid-match hunter swap wiring: HUNTER_ROSTER + FREE_HUNTERS in HunterSwitchService; HUNTER_FOLDERS in HunterClientLoader; per-script `registerCleanup` contract with a full teardown checklist (UnbindFromRenderStep, UnbindAction, connections, viewmodel, mobile buttons, SprintController, CameraMode, FOV, shared persistent GUIs, sub-controllers) and generation-based safety net
9. Conventions and gotchas: **player attributes are the client's boot signal — never publish a placeholder you intend to overwrite** (HunterSelectionService's `deferPublish` / `publishAttributes` barrier holds a direct joiner's loadout in memory until the profile resolves, then flushes hunter + all gun skins in one shot before releasing the spawn gate; the giveaway symptom is a cosmetic that is right for every player *except* its owner, since the server world model self-heals off a changed listener and a once-at-boot client read does not — added 2026-07-28 after the friends-list-join gun-skin bug), server-authoritative damage, headshot detection via attribute, shooting cancels sprint (the fire handler calls `sprintController:Cancel()`) and the sprint FOV must be a single smoothDamp owner of `camera.FieldOfView` (never two writers, or an ADS/sprint handoff snaps), Studio MCP save semantics, mobile parity, RemoteEvents-only, the HighNoonDamage parallel-chain regression that prompted the 2026-06-28 stats fix, vault + graph sync
10. Pointers to the existing Dust + Fortuna manifests, server modules, and client scripts to study as concrete templates
11. Notes on when to evolve the shared layer further (HunterHudKit, ViewmodelKit deferred until a third hunter)

## Dependencies
- **Requires:** Nothing
- **Required by:** Nobody (documentation only; do not require this in shipping code)

## Connections
### RemoteEvents
None

### BindableEvents
None

### Direct require()
None
