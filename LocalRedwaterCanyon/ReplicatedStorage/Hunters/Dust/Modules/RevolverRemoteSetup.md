---
tags: [shared, modulescript, networking, setup]
path: game.ReplicatedStorage.Hunters.Dust.Modules.RevolverRemoteSetup
type: ModuleScript
lines: 56
---

# RevolverRemoteSetup

Server-side utility that ensures all required RemoteEvents and BindableEvents exist in the Revolver folder.

## What it does
1. Thin wrapper over [[HunterRemoteSetup]] that bundles Dust's Revolver remote/bindable manifest
2. Creates `Remotes`, `ServerEvents`, and `ClientEvents` folders under the Revolver folder
3. `EnsureRemoteEvents` creates RemoteEvents: FireBullet, ReplicateShot, DashRequest, HighNoonRequest, HighNoonVisual, HighNoonShot, HighNoonAimUpdate, HighNoonShootRequest, HighNoonChargeUpdate, WorldRevolverShotSound (cross-hero remotes `HitConfirm`/`HealthBarReveal`/`DamageDirection`/`KillFeed`/`KillCam` now live under `Hunters.Shared.Remotes` — see HunterSharedRemoteSetup)
4. `EnsureServerEvents` creates BindableEvents: HighNoonChargeAward (orphaned after Phase 2 — runtime-owned UltimateChargeService is now shared directly between RevolverModule and HighNoonModule so the BindableEvent bridge is unused; still ensured here for now, slated for deletion in a follow-up cleanup), WorldRevolverShotVFX
5. `EnsureAll` creates everything and returns references in a structured table (`{ Folders, Remotes, ServerEvents }`)
6. Wrong-class warning behavior comes from [[HunterRemoteSetup]] — warns and returns the wrong-class instance unchanged if a name already exists with the wrong class (does NOT overwrite)
7. Does NOT create `KillCam` (or any of the other cross-hero remotes) — those live at the shared hub created by HunterSharedRemoteSetup

## Dependencies
- **Requires:** [[HunterRemoteSetup]]
- **Required by:** DashDustVFXServer. (RevolverModule and HighNoonModule previously required this; after Phase 2 they get their remotes from HunterServerRuntime driven by the Dust Manifest.)

## Connections
### RemoteEvents
| Remote | Direction | Other script |
|--------|-----------|-------------|
| `FireBullet` | created | Client → Server shooting |
| `ReplicateShot` | created | Server → Client shot replication |
| `HitConfirm` | created | Server → Client hit feedback |
| `DashRequest` | created | Client → Server dash |
| `HighNoonRequest` | created | Client → Server HighNoon activation |
| `HighNoonVisual` | created | Server → Client HighNoon visuals |
| `HighNoonShot` | created | HighNoon shot execution |
| `HighNoonAimUpdate` | created | Client → Server aim data |
| `HighNoonShootRequest` | created | Client → Server shoot request |
| `HighNoonChargeUpdate` | created | Server → Client charge state |
| `HealthBarReveal` | created | Server → Client (attacker only), triggers [[HealthBarSpawnerClient]] |

### BindableEvents
| Bindable | Direction | Other script |
|----------|-----------|-------------|
| `HighNoonChargeAward` | created | Server-side charge award event |

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[HunterRemoteSetup]] | `.EnsureFolder()`, `.EnsureRemoteEvents()`, `.EnsureBindableEvents()` | Shared idempotent folder/remote/bindable creation |
