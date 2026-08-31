---
tags: [server, modulescript, networking, bots]
path: game.ServerScriptService.Bots.BotFXAudience
type: ModuleScript
lines: 109
---

# BotFXAudience

Tracks which clients have confirmed their bot FX remote handlers are attached, so the server never fires the two bot `UnreliableRemoteEvent`s at a client that cannot receive them yet.

## What it does
1. Owns the `BotFXReady` handshake: creates the remote if absent (recreating it if a non-`RemoteEvent` is found), listens on `OnServerEvent`, and records the firing player in a ready set.
2. `isReady(player)` is the gate read by BotService's transform broadcast and BotCombat's `fireBotShotFX`. Both remotes it guards are `UnreliableRemoteEvent`s, which have **no invocation queue** — an event arriving before the client has connected `OnClientEvent` is discarded on the spot and logged as "Remote event invocation discarded event", rather than being buffered the way a reliable `RemoteEvent` would.
3. **The window this closes cannot be closed from the client.** `EarlyShotRemoteDrain` attaches no-op handlers as early as a client possibly can, but it still has to `WaitForChild` its way down `ReplicatedStorage.Hunters.Shared.Remotes`, and `ReplicatedStorage` is over 7,000 descendants (421 under `Hunters` alone). A client cannot attach a handler to an instance it has not received yet, so on a slow connection that is seconds during which the transform loop is already broadcasting at 10-20Hz. The only fix is to not send.
4. **Fails open in two senses.** Per-player, a `READY_TIMEOUT` of 10s marks a player ready regardless, so a client that errored out of ReplicatedFirst still sees bots. Wholesale, a `gating` flag stays false if `start()` could not install the listener, and `isReady` then returns true for everyone. Both degrade to the pre-gate behaviour — some discarded events at join — rather than a player who never sees a bot move for an entire round.
5. **Self-starting, and `start()` is idempotent.** BotCombat gates its shots on this module without being the thing that starts it, so starting on `require` removes that ordering dependency. The self-start is `pcall`ed because a throw would propagate out of `require()` and take BotCombat and BotService down with it — breaking bots entirely to fix a log warning. `gating` is set last so a throw part-way leaves the gate open rather than half-installed.
6. `PlayerRemoving` clears the flag; the flag is otherwise per-session and one-way, since the client's ReplicatedFirst script runs once and its handlers stay attached.
7. **`BotUltimateFX` and `BotFortunaCardFX` are deliberately not gated here.** They are reliable remotes carrying paired state transitions (ultimate `Start`/`End`, card `Stick`/`Remove`/`Recall`/`Clear`); a reliable remote queues for a client with no handler rather than discarding, so they were never part of this problem, and dropping one would strand a highlight or looping sound on indefinitely.

## Dependencies
- **Requires:** Nothing
- **Required by:** BotService, BotCombat

## Connections
### RemoteEvents
| Remote | Direction | Other script |
|--------|-----------|-------------|
| `BotFXReady` | ← Client | [[EarlyShotRemoteDrain]] fires it once, after it has attached no-op handlers to both bot FX remotes; until it arrives the server holds those two remotes back for that player |

### BindableEvents
None

### Direct require()
None
