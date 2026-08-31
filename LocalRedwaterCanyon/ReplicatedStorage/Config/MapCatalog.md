---
tags: [shared, modulescript, maps, matchmaking, mirrored]
path: game.ReplicatedStorage.Config.MapCatalog
type: ModuleScript
lines: 131
---

# MapCatalog

Every map in the experience, in one table, in every place — the universe-wide answer to "what maps exist", as opposed to `MapConfig`'s per-place "what is THIS map".

## What it does
1. **The 18th universe-tier mirrored module** (2026-08-14, `FROSTBITE_CLAIM_SPEC` §9.2). Byte-identical in Bounty, Redwater Canyon and Frostbite Claim; edit all three in one pass and verify with `/mirror universe`. A drifted catalog is the EmoteConfig failure with a worse blast radius: a lobby offering a map the match place has never heard of routes players at a place that cannot run it, and nothing errors
2. One row per map: `id`, `displayName`, `thumbnail`, `siblingKey`, `gamemodes`, `live`. `id` must equal that place's `MapConfig.Id` — the one value the two files share, sitting in different mirror tiers, which is why `assertLocalMap` exists. `thumbnail` is the vote tile art, repeated here so tiles are built from data rather than typed into labels. `gamemodes` is declared and read by nothing yet (one gamemode, no picker — spec §9.0/§9.7). `live` is what puts a map in rotation, deliberately separate from existing at all
3. **`siblingKey` indexes GameEnvironment's exported `<key>PlaceId` fields rather than storing a PlaceId outright** — that is what keeps the no-hardcoded-PlaceId rule intact: a DEV lobby resolves DEV siblings from its own `game.PlaceId` and cannot reserve a live server no matter what this table says
4. `get(id)` returns the row or nil; nil is an ordinary case, not a bug — a match directory entry outlives the publish that wrote it, so a server on the next build can advertise a map this build lacks
5. `placeIdFor(id)` resolves where a map physically is, through GameEnvironment on every call, because the row is shared by every environment and the answer is not
6. `listLive()` returns every map in rotation, dropping rows whose sibling id does not resolve — an unreachable destination is worse than a shorter list
7. `randomLiveId()` — uniform random across live maps, deliberately NOT rotation: rotation is per-server state and Bounty runs many lobby servers, so a per-lobby counter rotates nothing
8. `assertLocalMap(mapId)` — called by the match place at boot (MatchDirectoryService) against `MapConfig.Id`. Without it a catalog/MapConfig mismatch is silent and permanent: the server publishes a map id the lobby filters out and never receives a player for its whole life
9. In this place it is required by MatchDirectoryService (the boot assert) and RoundController (the end-of-match vote's options and liveness checks, and resolving where a winning vote teleports to)

## Domination (2026-08-22)

Both maps' `gamemodes` lists now read `{ "deathmatch", "tdm", "domination" }`.

## Dependencies
- **Requires:** [[GameEnvironment]]
- **Required by:** RoundController, MatchDirectoryService

## Connections
### RemoteEvents
None

### BindableEvents
None

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[GameEnvironment]] | `GameEnvironment[siblingKey .. "PlaceId"]` | Resolve each row's map to a PlaceId per-universe, so the catalog can be shared verbatim across environments without hardcoding a PlaceId |
