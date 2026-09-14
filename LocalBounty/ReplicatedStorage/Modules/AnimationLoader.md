---
tags: [shared, modulescript, server, client]
path: game.ReplicatedStorage.Modules.AnimationLoader
type: ModuleScript
lines: 186
---

# AnimationLoader

Loads an AnimationTrack only after its clip is confirmed fetched, so a failed CDN download reports as a failure instead of a silent default pose.

## What it does
1. `AnimationLoader.load(animator, animationId, opts) -> track, status` — **blocks** on the fetch and is authoritative. `track` is nil unless `status == Enum.AssetFetchStatus.Success`
2. `AnimationLoader.loadCached(animator, animationId, opts) -> track, status` — **never yields**. Skips a clip already known bad, trusts one already known good, otherwise loads optimistically while warming the cache in the background. For per-shot and per-tile paths
3. `AnimationLoader.prewarm({ ids })` — fire-and-forget cache warming; resolves each id on its own thread so N clips cost one round-trip rather than N
4. `AnimationLoader.isRetryable(status) -> boolean` — true for `Failure`, `TimedOut`, `None`
5. `AnimationLoader.getStatus(animationId) -> Enum.AssetFetchStatus?` — the cached status, or nil if never resolved
6. `opts = { Priority, Looped, Name }`; the module sets all three on the returned track, so callers do not assign them
7. Normalises a bare digit string (`"507766666"`) into `rbxassetid://507766666`
8. Statuses are cached per asset id, so the yield is paid once per clip per session

## Why it exists
`Animator:LoadAnimation` returns a track **immediately, without downloading the clip** — the fetch resolves asynchronously afterwards. A `pcall` around it therefore reports success for a clip that never arrives, which is silent, and which makes a retry loop that tests a `playXxx()` helper's return value exit on pass 1 on a false success. In this place the same bug shape leaves a lobby dummy, a collection tile or a shop card standing in a T-pose with nothing in the log.

`ContentProvider:PreloadAsync(instances, callback)` blocks until the fetch resolves and reports a real `Enum.AssetFetchStatus` — the only mechanism that tells the two cases apart.

## Two hazards at every call site
1. **`load()` yields.** Anything that can be superseded while parked — a rebuilt menu, a re-rendered grid, a new carousel selection — must re-check its own model or token *after* the call returns. Every caller in this place re-checks `model.Parent`.
2. **Never `load()` on a per-tile path without prewarming first.** Either `prewarm` the whole set in one call and then `load` (LobbySpawn, BattlePassClient, EmoteBuyController), or use `loadCached` when the ids differ per tile and there is no set to warm (`Viewport.playEmoteAnim`).

## Mirroring
This module is one of the **21 shared modules mirrored VERBATIM across all three places**. Edit both copies in the same pass and verify with a byte-length + checksum compare; `/preflight` gates it.

## Dependencies
- **Requires:** Nothing (uses the `ContentProvider` service directly)
- **Required by:** LobbySpawn, PreviewModel, ViewportIcon, BattlePassClient, Viewport, EmoteBuyController, HuntersBuyController — deliberately **plain text, not wikilinks**. Each of those files declares the `require()` itself, which is the edge the graph needs; writing it here too creates a reciprocal pair, and the dedupe keeps whichever direction it parsed first. In Redwater that is exactly how `animationloader -> hunterworldmodel` once landed in the graph backwards.

## Connections
### RemoteEvents
None.

### BindableEvents
None.

### Direct require()
None.
