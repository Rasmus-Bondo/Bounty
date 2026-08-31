---
tags: [server, modulescript, combat, utility, vesper]
path: game.ServerScriptService.Hunters.VesperServer.PinningRoundService
type: ModuleScript
lines: 299
---

# PinningRoundService

OOP server-authoritative straight-line simulation for Vesper's Pinning Round. Fires like a shot (constant velocity, no gravity) rather than a lob. **Creates no replicated projectile part** — the server raycasts and owns gameplay, while clients render the trail themselves at frame rate from `PinningLaunchFX`. No direct damage: on landing it opens an expanding slow/mark zone that applies effects on a live enter/exit tick via the shared HunterStatusEffects.

## What it does
1. `TryThrow(player, aimDirection)` — validates the aim Vector3, character/humanoid/root/head, alive, and the 12s cooldown (consumed on throw, hit or not). Origin is `head.Position + direction * 2`
2. Broadcasts `PinningLaunchFX(player, origin, direction, ThrowSpeed, MaxFlightTime)` to every client, which each dead-reckon the visible trail locally — no per-frame projectile replication
3. `_simulate` steps the round server-side at ~60Hz: constant velocity `direction * ThrowSpeed` (250) with no gravity, raycasting between steps. Lands on the first surface hit, at MaxFlightTime (2s, ~500 stud reach), or if it drops below Y = -500
4. `_buildRaycastParams` — Exclude filter: the thrower's character, the **`RewindHitboxes` folder** (invisible lag-compensation volumes at historical player positions), and each HealthPack's green `Pickup` + invisible `TouchHitbox` (the solid `Base` stand still stops the round)
5. `_land` opens a zone: broadcasts `PinningImpactFX(thrower, landPos, {}, zoneDuration, zoneDuration, zoneId)` so every client blooms the visual/audio sphere, then runs a `zoneDuration` (6s = max of Slow 5 / Mark 6) scan loop
6. Zone radius **expands** from 0 to Radius (25) over `ZONE_EXPAND_TIME` 0.6s, rescanning every `ZONE_SCAN_INTERVAL` 0.1s, so effects land on the same tick the visible sphere reaches a target
7. `_enterZoneVictim` / `_exitZoneVictim` — per-zone dedupe plus a **shared `ZoneVictimCounts`** refcount across all active zones, so one overlapping zone expiring can never restore speed while another still contains the victim. Effects are refreshed to the zone's remaining lifetime rather than applied once
8. `_findVictims` iterates HunterCharacterUtil.GetHumanoidModels() **and** explicitly scans `workspace.ArenaBots` for `IsBot` models, since a bot can be parented with a live Humanoid between cache updates
9. `PinningZoneUpdate` is fired **only to the throwing Vesper** for each victim enter/exit and once on zone end, driving her through-wall reveal Highlights
10. `CleanupPlayer` clears the cooldown entry on disconnect

**`ResetAll()` clears every pinning cooldown at round start** (2026-08-06), called by SunspikeModule on `ReplicatedStorage.RoundActive`. At 12s this is the longest of Vesper's two and the one that could realistically still be running when the next round begins; see RevolverDashService's note for the full reasoning.

## Dependencies
- **Requires:** Nothing directly (CharacterUtil, StatusEffects, rewind hitbox folder, and the three remotes are injected via constructor config by [[SunspikeModule]])
- **Required by:** SunspikeModule

## Connections
### RemoteEvents
| Remote | Direction | Other script |
|--------|-----------|-------------|
| `PinningLaunchFX` | → All Clients | [[SunspikeClient]] (Vesper) and [[VesperPublicFXClient]] (everyone else) simulate the visible trail locally |
| `PinningImpactFX` | → All Clients | [[SunspikeClient]] / [[VesperPublicFXClient]] bloom the impact sphere; authoritative landing point |
| `PinningZoneUpdate` | → Thrower only | [[SunspikeClient]] adds/removes per-victim reveal Highlights and clears them on zone end |

### BindableEvents
None

### Direct require()
None (all dependencies injected via constructor config)

### CollectionService Tags
| Tag | Usage | Defined by |
|-----|-------|-----------|
| `HealthPack` | Each pack's green `Pickup` + invisible `TouchHitbox` added to the projectile raycast Exclude list (the solid `Base` stand still stops the round) | [[HealthPackSystem]] |

## Notes
Bots fire these same three remotes directly from [[BotCombat]] (`_launchPinningRound` / `_landPinningZone`), passing the bot **Model** as the thrower instead of a Player — both client renderers resolve either through their `resolveVesperCasterCharacter` helper.

That Model is subject to streaming: bots live in `workspace.ArenaBots`, so on a client where the bot is streamed out the thrower argument arrives as **`nil`**. Client renderers must never use a caster Instance directly as a table key — both use a sentinel-substituting `throwerKey` helper for exactly this reason.

Because the visible trail is a local simulation, any divergence between a client's raycast filter and step 4's server filter shows up as the trail stopping somewhere the round did not actually land. Client-side filters must stay in sync with `_buildRaycastParams`.
