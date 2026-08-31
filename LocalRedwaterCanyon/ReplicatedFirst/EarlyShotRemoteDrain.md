---
tags: [client, localscript, networking]
path: game.ReplicatedFirst.EarlyShotRemoteDrain
type: LocalScript
lines: 70
---

# EarlyShotRemoteDrain

Connects no-op handlers to high-traffic shot FX remotes during client load so their invocation queues never overflow and unreliable remotes never discard.

## What it does
1. Runs from ReplicatedFirst, i.e. before any StarterPlayerScripts start, while the client is still loading
2. Waits (30s timeout, non-blocking `task.spawn` per remote) for the player shot FX remotes and connects an empty `OnClientEvent` handler to each: `Hunters.Dust.Remotes.ReplicateShot`, `Hunters.Dust.Remotes.WorldRevolverShotSound`, `Hunters.Vesper.Remotes.ReplicateShot`, `Hunters.Bram.Remotes.ReplicateShot`
3. This prevents "Remote event invocation queue exhausted; events dropped" warnings when other players shoot while this client is still loading — the queued events are drained instead of overflowing
4. Also drains the two bot FX remotes, `Hunters.Shared.Remotes.BotShotFX` and `Hunters.Shared.Remotes.BotTransformUpdate`. These are **UnreliableRemoteEvents**, which have no invocation queue at all: a single event arriving before `OnClientEvent` is connected is discarded on the spot and logged as "Remote event invocation discarded event". BotVisualClient does not connect its `BotShotFX` handler until it has finished resolving its VFX assets, so that exposure window is wide
5. The `IsA` guard is `BaseRemoteEvent`, not `RemoteEvent` — `UnreliableRemoteEvent` does **not** inherit from `RemoteEvent`, so an `IsA("RemoteEvent")` check silently skips both bot remotes and the drain does nothing
6. The real FX handlers (tracers/audio) connect independently later; extra connections on a remote are harmless
7. **Draining cannot close the bot window on its own, and since 2026-08-07 it does not try to.** A client cannot attach a handler to an instance that has not replicated to it yet, and `ReplicatedStorage` is over 7,000 descendants — so the `WaitForChild` walk down to `Hunters.Shared.Remotes` is itself seconds long on a slow connection, while the server is already broadcasting transforms at 10-20Hz. Once both bot remotes are drained this script fires `BotFXReady`, and [[BotFXAudience]] holds both remotes back server-side until it arrives
8. The two bot remotes are therefore resolved **sequentially in one `task.spawn`** rather than via the parallel `drainAsync` used for the four player remotes — the ready signal must not fire until both handlers are attached. The shared path walk was factored into a `resolve(names)` helper used by both paths

## Dependencies
- **Requires:** Nothing
- **Required by:** Nobody

## Connections
### RemoteEvents
| Remote | Direction | Other script |
|--------|-----------|-------------|
| `ReplicateShot` (Revolver) | ← Server | [[RevolverModule]] fires on every Dust shot; drained no-op here |
| `WorldRevolverShotSound` | ← Server | [[RevolverWorldModelServer]] fires on every Dust shot; drained no-op here |
| `ReplicateShot` (Vesper) | ← Server | [[SunspikeModule]] / [[StarfallSightModule]] fire on Vesper shots; drained no-op here |
| `ReplicateShot` (Bram) | ← Server | [[GrudgekeeperModule]] fires on Bram shots; drained no-op here |
| `BotShotFX` | ← Server | [[BotCombat]] fires on every bot shot (UnreliableRemoteEvent); drained no-op here |
| `BotTransformUpdate` | ← Server | [[BotService]] batches bot pivots every tick (UnreliableRemoteEvent); drained no-op here |
| `BotFXReady` | → Server | Fired once after both bot FX remotes are drained; [[BotFXAudience]] gates `BotShotFX` and `BotTransformUpdate` on it |

### BindableEvents
None

### Direct require()
None
