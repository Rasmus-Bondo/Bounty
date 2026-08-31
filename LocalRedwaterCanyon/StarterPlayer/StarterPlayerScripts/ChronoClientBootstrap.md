---
tags:
  - client
  - localscript
  - networking
path: game.StarterPlayer.StarterPlayerScripts.ChronoClientBootstrap
type: LocalScript
lines: 15
---

# ChronoClientBootstrap

Initializes the Chrono networking library on the client by requiring its Player, Receiver, and Replicate modules.

## What it does

1. Locates the Chrono library at `ReplicatedStorage.ExternalLibrary.chrono`
2. Requires `Player` from the Client folder (registers local player with Chrono)
3. Requires `Receiver` (starts receiving server snapshots)
4. Requires `Replicate` (starts client-side replication processing)
5. Prints a confirmation message to output

## Dependencies

- **Requires:** Player, Receiver, Replicate (from `ReplicatedStorage.ExternalLibrary.chrono.Client`)
- **Required by:** Nobody

## Connections

### RemoteEvents

None

### BindableEvents

None

### Direct require()

| Target | Function | Purpose |
|--------|----------|---------|
| Player | (side-effect on require) | Registers local player with Chrono |
| Receiver | (side-effect on require) | Starts receiving server snapshots |
| [[Replicate]] | (side-effect on require) | Starts client-side replication |
