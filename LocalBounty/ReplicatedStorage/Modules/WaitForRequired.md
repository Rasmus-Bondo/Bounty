---
tags: [shared, modulescript, client, streaming, diagnostics]
path: game.ReplicatedStorage.Modules.WaitForRequired
type: ModuleScript
lines: 51
---

# WaitForRequired

Waits for an instance the caller genuinely cannot proceed without, without the engine's "Infinite yield possible" warning.

## What it does
1. Returns a **single function**, `waitForRequired(parent, childName)` — the module has no table and no other API.
2. Returns immediately via `FindFirstChild` when the child is already present.
3. Otherwise loops `parent:WaitForChild(childName, 30)` until it resolves. **Never returns nil**, so no call site needs a fallback and nothing can index a nil.
4. Warns every 30s while unresolved, naming `parent:GetFullName()` and the child — a message that identifies the wait without needing a stack trace.

## Why it exists
Every lobby script that reaches into Workspace for a Persistent model — `CameraFolder`, `SkinMenu`, `PlayModel`, `FeaturedItems`, `VaultDoor`, `InviteButtons` — has to wait for it to replicate, and an **untimed `WaitForChild` warns at 5 seconds**. Studio replicates a local place far faster than a real client pulls one over the network, so a wait that never trips the threshold in a playtest trips it routinely in production. Those warnings **are listed on the Creator Hub**, where they bury real errors.

**Passing any timeout suppresses that warning** — verified empirically rather than assumed: an untimed wait on a missing name warned at 5s, while a 30s-timed wait on the same missing name stayed silent for as long as it was outstanding. Looping a timed wait therefore preserves the exact semantics the call sites already rely on while moving the report to a threshold that means something. Thirty seconds is not replication lag; if this warns, something is actually wrong.

## When NOT to use it
- **Never on the server.** There is no replication delay there, so an untimed `WaitForChild` that warns is a real "this instance is missing" signal, and muting it throws that away. `LobbyService`'s `JailSpawn` wait deliberately stays plain.
- **Not for optional instances.** Something that may legitimately be absent wants `FindFirstChild`, or a timed `WaitForChild` with a real fallback — LoadingScreen's `IntroCameraPart` (1.5s, falls back to a computed sky CFrame) is the model there. This helper is only for the case where waiting forever is correct.
- **Not for children of an instance this already returned.** A Persistent model's descendants arrive with it, so `cameraFolder:WaitForChild("CameraPart")` resolves instantly and needs no helper. LoadingScreen is the one exception — it runs in `ReplicatedFirst`, the earliest point on the client, so its `CameraPart` wait goes through the helper defensively.

## Not mirrored
Bounty-only. The waits it exists for are all lobby Workspace models, so it is **not** part of the 17-file mirror set and `/preflight` gains no new gate.

## Dependencies
- **Requires:** Nothing
- **Required by:** LoadingScreen, CollectionClient, ReworkedUIPlay, MenuHandlerScript, ReworkedPartyClient, TradingPostController, HuntersBuyController, Refs, FeaturedSequence — deliberately **plain text, not wikilinks**. Each of those files declares the `require()` itself, which is the edge the graph needs; writing it here too creates a reciprocal pair, and the dedupe keeps whichever direction it parsed first.

## Connections
### RemoteEvents
None.

### BindableEvents
None.

### Direct require()
None.
