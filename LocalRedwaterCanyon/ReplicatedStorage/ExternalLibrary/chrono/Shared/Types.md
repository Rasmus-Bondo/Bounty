---
tags:
  - shared
  - modulescript
  - external
path: game.ReplicatedStorage.ExternalLibrary.chrono.Shared.Types
type: ModuleScript
lines: 224
---

# Types

Type definitions for the Chrono library. Defines all core data structures used across client, server, and shared modules.

## What it does

1. Defines `Entity` type — the main networked object with id, model, CFrame, snapshot, network owner, config, mount data
2. Defines `EntityConfig` / `EntityConfigInput` — tick rate, buffer, rotation, replication mode, tick distances
3. Defines `Snapshot<Value, Velocity>` — ring buffer for timestamped CFrame data with interpolation
4. Defines `ClientClock` — client-side time synchronization for interpolation targeting
5. Defines `EntityReceivePacket` — wire format for entity state sent from server to client
6. Defines utility types: Signal, Event, Connection, Ticker, InterpolationBuffer

## Dependencies

- **Requires:** Nothing
- **Required by:** Nearly all Chrono modules
