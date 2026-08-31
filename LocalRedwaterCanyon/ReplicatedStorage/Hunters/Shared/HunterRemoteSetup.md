---
tags: [shared, modulescript, networking, setup]
path: game.ReplicatedStorage.Hunters.Shared.HunterRemoteSetup
type: ModuleScript
lines: 70
---

# HunterRemoteSetup

Shared idempotent get-or-create helpers for Folder, RemoteEvent, and BindableEvent instances. Used by every hunter's remote-setup script to avoid duplicating the boilerplate.

## What it does
1. `EnsureFolder(parent, name)` returns the existing child Folder by that name, creating one if missing
2. `EnsureRemoteEvent(parent, name)` returns the existing RemoteEvent by that name, creating one if missing; warns (and returns the existing instance unchanged) if the name is taken by a wrong-class instance
3. `EnsureBindableEvent(parent, name)` same as #2 for BindableEvents
4. `EnsureRemoteEvents(parent, names)` runs `EnsureRemoteEvent` over a list, returns `{name = RemoteEvent}` table
5. `EnsureBindableEvents(parent, names)` runs `EnsureBindableEvent` over a list, returns `{name = BindableEvent}` table

## Dependencies
- **Requires:** Nothing
- **Required by:** RevolverRemoteSetup, HunterSharedRemoteSetup, HunterServerRuntime, CardsHunterGuiClient. (CardsServer used to require this directly; after Phase 2 the runtime owns remote ensuring. The standalone `CardsRemoteSetup` Script was deleted — its folder/bindable creation is now done by the server runtime from `manifest.Client.ClientEvents`.)

## Connections
### RemoteEvents
None

### BindableEvents
None

### Direct require()
None
