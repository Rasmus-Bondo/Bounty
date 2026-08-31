---
tags: [shared, modulescript, combat, ultimate, charge]
path: game.ReplicatedStorage.Hunters.Shared.UltimateChargeService
type: ModuleScript
lines: 195
---

# UltimateChargeService

OOP service that tracks each player's ultimate charge, awards charge on hits/kills per ability source, and grows charge passively over time. Generalized from Dust's former `HighNoonChargeService` to support arbitrary hunters with per-source charge tables.

## What it does
1. `.new(config)` — accepts a `Sources` table keyed by ability source name (e.g. `Revolver`, `Basic`, `Ability1`, `Recall`, `Ultimate`), each with `{ Hit, Headshot, Kill }` charge values; plus `MaxCharge`, `PassiveChargePerSecond`, `BlockPredicate(player)`, `ChargeUpdateRemote`, `ChargeAwardEvent`, `RoundActive`, `DisplayPrecision`, optional `DefaultSourceType`
2. `:Get(player)` / `:Set(player, amount)` / `:Add(player, amount)` — basic charge accessors; Set clamps to `[0, MaxCharge]` and fires `ChargeUpdateRemote` to the client (rounded to `DisplayPrecision` if set), **gated on `IsBlocked(player)`** so the remote is never fired to players the BlockPredicate excludes (prevents queue exhaustion for hero-mismatched players)
3. `:AwardHit(player, sourceType, isHeadshot, didKill)` — looks up `Sources[sourceType]`, picks `Kill | Headshot | Hit` based on flags (with fallback to `Hit` if Headshot/Kill not specified), adds to charge
4. `:IsBlocked(player)` — calls the user-supplied `BlockPredicate` (e.g. "is ultimate currently active?") to gate `:Add` and passive regen
5. `:SetupPlayer(player)` / `:CleanupPlayer(player)` — explicit per-player init/cleanup; `:Start()` automatically wires PlayerAdded/PlayerRemoving if `Players` is provided
6. `:ResetAll()` — sets every player's charge to 0; auto-called on `RoundActive` going true if `RoundActive` BoolValue is provided
7. `:Start()` — connects to `ChargeAwardEvent` BindableEvent (signature: `(player, sourceType, isHeadshot, didKill)`), connects player lifecycle, and starts a Heartbeat loop that adds `PassiveChargePerSecond * elapsed` to each non-blocked player every `PassiveTickInterval` (default 0.25s)

## Dependencies
- **Requires:** Nothing
- **Required by:** HunterServerRuntime — constructs and starts one per hunter from each manifest's `UltimateCharge` declaration, exposes it as `runtime.ChargeService`. (HighNoonModule and CardsServer previously required it directly; after Phase 2 they consume it via the runtime.)

## Connections
### RemoteEvents
None (uses externally-supplied `ChargeUpdateRemote` if provided)

### BindableEvents
None (uses externally-supplied `ChargeAwardEvent` if provided)

### Direct require()
None
