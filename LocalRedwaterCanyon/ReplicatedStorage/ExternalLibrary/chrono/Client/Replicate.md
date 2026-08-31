---
tags:
  - client
  - modulescript
  - external
path: game.ReplicatedStorage.ExternalLibrary.chrono.Client.Replicate
type: ModuleScript
lines: ~
---

# Replicate (Client)

Client-side replication consumer. Receives entity snapshots from the server and interpolates model positions each frame.

## What it does

1. Connects to RenderStepped to update entity model positions each frame using snapshot interpolation
2. For non-owned entities: reads from the interpolation buffer and applies Hermite-interpolated CFrames
3. For client-owned entities: sends local position data back to the server via the Sender module
4. Handles entity creation/destruction when the server registers/unregisters entities

## Dependencies

- **Requires:** Config, Entity, Holder, Receiver, Sender, ClientClock, ModelResolver, InterpolationMath
- **Required by:** chrono (client path), ChronoClientBootstrap

## Connections

### RemoteEvents

| Remote | Direction | Other script |
|--------|-----------|-------------|
| `Replicate` | <- Server | Server.Replicate |
| `ReplicateFull` | <- Server | Server.Replicate |
