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
`Animator:LoadAnimation` returns a track **immediately, without downloading the clip** — the fetch resolves asynchronously afterwards. A `pcall` around it therefore reports success for a clip that never arrives, which is silent, and which makes a retry loop that tests a `playXxx()` helper's return value exit on pass 1 on a false success. That is what left Dust's world revolver in its default hold pose after a transient CDN failure on 2026-08-07 with nothing in the log.

`ContentProvider:PreloadAsync(instances, callback)` blocks until the fetch resolves and reports a real `Enum.AssetFetchStatus` — the only mechanism that tells the two cases apart.

## Two hazards at every call site
1. **`load()` yields.** Anything that can be superseded while parked — a newer character, a newer menu build, a mid-match hunter switch — must re-check its own token or state *after* the call returns.
2. **Never `load()` on a per-shot or per-tile path.** Use `loadCached`, or prewarm the whole set first and then `load`.

## The server/client split
Server-side callers (HunterWorldModel, BotController) guard the **server's** own load only. A server-played track replicates as an id and each client fetches it independently, so a client-side fetch failure can only be closed by a client-side prewarm of the same ids. That is what WorldAnimationPrewarmClient does — ungated at the root of `StarterPlayerScripts`, warming the 12 hunter world clips at start and the 48 bot clips after the local character spawns, with two retries and a warn for anything that never arrives.

## Mirroring
This module is one of the **17 shared modules mirrored VERBATIM across both places**. Edit both copies in the same pass and verify with a byte-length + checksum compare; `/preflight` gates it.

## Dependencies
- **Requires:** Nothing (uses the `ContentProvider` service directly)
- **Required by:** HunterWorldModel, WorldRevolverAimIdleClient, FortunaCardsWorldIdleClient, BramWorldIdleClient, VesperWorldIdleClient, HunterPortraitClient, BotController, WorldAnimationPrewarmClient, CardsClient, RevolverDashService, RevolverViewModel, HighNoonGunFX, GrudgekeeperClient, VesperViewModelAnimationClient, VictoryShowcaseClient — the last five added 2026-08-29, closing the first-person viewmodel, which was the uncovered half of the 2026-08-07 guard. Deliberately **plain text, not wikilinks**. Each of those files declares the `require()` itself, which is the edge the graph needs; writing it here too creates a reciprocal pair, and the dedupe keeps whichever direction it parsed first. That is exactly how `animationloader -> hunterworldmodel` once landed in the graph backwards, reading as though this module required the hunter world model.

## Connections
### RemoteEvents
None.

### BindableEvents
None.

### Direct require()
None.
