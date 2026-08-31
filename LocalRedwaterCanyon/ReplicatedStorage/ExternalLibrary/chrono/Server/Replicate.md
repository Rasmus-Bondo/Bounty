---
tags:
  - server
  - modulescript
  - external
path: game.ReplicatedStorage.ExternalLibrary.chrono.Server.Replicate
type: ModuleScript
lines: ~
---

# Replicate (Server)

Server-side replication loop. Ticks entities, collects CFrame changes, and sends snapshot packets to clients via UnreliableRemoteEvents.

## What it does

1. Runs the server tick loop — iterates registered entities per entity-type ticker
2. Reads entity CFrame changes and batches them into per-player packets based on distance (normal tick, half tick, or skip)
3. Sends snapshot data to clients via the `Replicate` and `ReplicateFull` RemoteEvents
4. Uses EntityGrid for spatial partitioning to efficiently determine which entities are relevant to each player

## Dependencies

- **Requires:** Config, Entity, Holder, Sender, EntityGrid, Ticker, Events
- **Required by:** chrono (server path), ChronoServerBootstrap

## Connections

### RemoteEvents

| Remote | Direction | Other script |
|--------|-----------|-------------|
| `Replicate` | -> Client | Client.Receiver |
| `ReplicateFull` | -> Client | Client.Receiver |
