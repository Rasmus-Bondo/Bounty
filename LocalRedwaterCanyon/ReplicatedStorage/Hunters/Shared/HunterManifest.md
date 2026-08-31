---
tags: [shared, modulescript, hunter-runtime]
path: game.ReplicatedStorage.Hunters.Shared.HunterManifest
type: ModuleScript
lines: 129
---

# HunterManifest

Schema documentation + `Validate(manifest)` for the declarative hunter description consumed by HunterServerRuntime and HunterClientRuntime. Each hunter ships a manifest at `Hunters.<Name>.Config.Manifest` declaring its hunter name, kill-feed weapon, hunter folder path, hunter-local remotes, ultimate-charge config, and (since Phase 3) optional client-side viewmodel + ClientEvents declarations.

## What it does
1. Documents the manifest shape in a header comment (HunterName, KillFeedWeaponName, DefaultSourceType, HunterFolder, RemotesFolder, ServerEventsFolder, ClientEventsFolder, Remotes.Events, Remotes.Bindables, UltimateCharge, ConfigModule, Client = { ViewmodelTemplate, ClientEvents, ViewmodelConfig })
2. `Validate(manifest)` returns `(true, nil)` if the table is well-formed, or `(false, errMessage)` with a precise reason — checks required string fields, that `HunterFolder` is a non-empty array of strings, that `Remotes.Events` / `Remotes.Bindables` are string arrays if present, that `UltimateCharge.Sources` is a table, that `UltimateCharge.ChargeUpdateRemote` (if set) is a string, and that `Client.ViewmodelTemplate` / `Client.ClientEvents` are string arrays if present
3. The `Client` section's `ViewmodelTemplate` + `ViewmodelConfig` are opaque to HunterServerRuntime; its `ClientEvents` list is now used by **both** runtimes — HunterServerRuntime ensures the bindables under `HunterFolder/<ClientEventsFolder>` (default "ClientEvents") so the folder is guaranteed to exist server-side, and HunterClientRuntime re-ensures them idempotently for client-only consumers

## Dependencies
- **Requires:** Nothing
- **Required by:** HunterServerRuntime, HunterClientRuntime

## Connections
### RemoteEvents
None

### BindableEvents
None

### Direct require()
None
