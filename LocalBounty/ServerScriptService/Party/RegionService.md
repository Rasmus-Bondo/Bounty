---
tags: [server, modulescript, matchmaking, region, latency]
path: game.ServerScriptService.Party.RegionService
type: ModuleScript
lines: 214
---

# RegionService

Which latency region a player sits in, so the matchmaker can refuse to send them to a match server on the other side of the world.

## What it does

1. **Why it exists.** A player matchmade into a distant datacenter plays the whole round at 250-300ms, which for an FPS is not a worse game but an unplayable one. The call (2026-08-15, the user's explicit instruction) is that a bot-padded LOCAL match beats a full one at 300ms, so the region filter downstream is a **hard gate** with no cross-region fallback. This module only answers "where is this player"; the cost of acting on that answer is documented at `isRegionMatch` in MatchmakingService
2. **What Roblox does and does not give us.** There is no way to measure a player's ping to a server before they join it, and no API that reports which datacenter a reserved server lives in. So this cannot be a measurement — it has to be a **prediction** made at pick time, in the lobby. `LocalizationService:GetCountryRegionForPlayerAsync` is the only pre-join locality signal that exists
3. That call **yields**, so it is resolved **once on `PlayerAdded`** and cached — never on the Play button, which deliberately builds its candidate list from arithmetic alone so a press costs a fixed number of web calls however many servers are live
4. **The buckets are datacenters, not continents.** Each answers "which Roblox datacenter would this country route to", which is why there is no latency table in the file and no threshold to tune: two players in the same bucket reach the same datacenter, so same-bucket is under ~100ms by construction. Splitting NA into east and west would be a ~70ms distinction — well inside playable — and would double the fragmentation for nothing
5. Five buckets: `NA`, `SA`, `EU`, `AS`, `OC`, over 101 explicitly listed country codes. A country with **no nearby datacenter is assigned its nearest one** rather than a bucket of its own — Africa and the Middle East resolve to `EU`, India and Central Asia to `AS`. That is genuinely their best available match, and a bucket of their own would be one that can never fill: every player in it would seed a fresh server and play bots forever
6. Anything unlisted falls through to `FALLBACK_BUCKET` (`EU`), which is correct for the unlisted tail — Europe, Russia, the Middle East and Africa. The listed sets are therefore the ones that have to be right; a missing NA country routing to EU is a real 90ms error
7. **A failed lookup is left unresolved, and that is not the same as a bucket.** `resolved` only ever holds a real answer, so "we do not know" and "they are in EU" can never collide. An unresolved player is routed **unfiltered** by the matchmaker — refusing instead would hand a fresh server, which is to say a bot match, to every player caught by an outage on our own side
8. `bucketForCountry(code)` maps an ISO country code to a bucket. Public because it is the only part of the module checkable without a live player in a live region — everything else needs an IP
9. `bucketOf(player)` returns the cached bucket or nil. Never yields
10. `awaitPartyBucket(players, preferredUserId)` returns the one region a group is matched on, yielding up to 2s. A party is never split, so it gets exactly one region: the preferred member's (callers pass the party owner, since the owner pressed Play). Mixed-region parties are real and no answer is right for both, so the tie-break is deliberately arbitrary rather than clever. The preference is honoured **by order**, not by waiting the owner out — falling through to the next resolved member covers the owner's own lookup having failed. It returns early when nothing is resolved and nothing is still in flight, so a group of failed lookups does not hold the Play press for the full timeout
11. The 2s await exists only for a press within a second of arriving; a player normally has to cross the lobby menu first. Without it that press would route unfiltered and silently punch a hole in the gate
12. Sets a `MatchRegion` attribute on the player. **Diagnostic only — nothing reads it back.** It is the one way to answer "why did that player get a server to themselves" from a live session without a rejoin
13. Resolution is wired up at **require time** rather than behind a `Start()`. This is a leaf lookup with no ordering requirements, and the failure it avoids is silent: a caller reaching `bucketOf` on a service nobody remembered to start gets nil, which reads exactly like "this player has no region" and routes them unfiltered

## Dependencies

- **Requires:** Nothing
- **Required by:** PartyService

## Connections

### RemoteEvents

None

### BindableEvents

None

### Direct require()

None
