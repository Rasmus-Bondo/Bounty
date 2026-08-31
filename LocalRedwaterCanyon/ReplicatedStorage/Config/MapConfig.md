---
tags:
  - shared
  - modulescript
path: game.ReplicatedStorage.Config.MapConfig
type: ModuleScript
lines: 81
---

# MapConfig

Per-place declaration of everything true of THIS map — the one file that is deliberately
excluded from the cross-place mirror.

## What it does
1. Declares `Id` (`"redwater"`) and `DisplayName`, the stable keys telemetry, the match
   directory and the lobby picker use to name this map.
2a. Declares `Instances.TeamBases` — the names of this map's two spawn houses (`RedTeamBase` /
   `BlueTeamBase`), each holding a `Points` folder of authored spawn markers whose rotation is
   the spawn facing. Team modes resolve every spawn through it.
2b. Declares `Instances.TeamModeRemovals` — the workspace instances the houses **replace**. Both
   sets stand on the same ground, so TeamBaseService swaps one for the other on every mode change.
   Redwater lists `TeamDeathmatchRemove` and `VesperHookSpotsBot.VesperHookSpotsRemove`; Frostbite
   Claim lists `RedTeamObjectRemove` and `BlueTeamObjectRemove`. Dotted entries are paths from
   `workspace`.
2. Declares `Gamemodes` — the list of gamemodes this map can run. Gamemode is
   runtime-selected code every match place carries, so this is data rather than a PlaceId
   per map x mode combination.
3. Declares `Zone` — the map's zone geometry: `Shape = "linear"`, `Axis = "Z"`,
   `Start = -700`, `End = 200`. A radial map declares `Shape = "radial"` with a Vector2
   `Center` and a `StartRadius` instead. Replaces the former `Config.ZONE_START_Z` /
   `ZONE_END_Z`.
3a. **`Shape` is live, not aspirational** (2026-08-13): ZoneService branches on it for
   both the geometry and the fire rendering, and SpawnService for its wall-speed
   derivation. Both shapes are driven by the same phase fractions out of Config —
   only the mapping differs (`halfSpan = span * f / 2` vs `radius = StartRadius *
   sqrt(f)`). A radial map without a Vector2 `Center` and a positive `StartRadius`,
   or a linear one declaring a non-Z `Axis`, asserts when ZoneService loads rather
   than running with a silently wrong zone.
4. Declares `Instances` — the names of the workspace instances the round system resolves
   by name (`SpawnPoints`, `JailSpawn`, `FinishSpawns`, `Tutorial`), so a map may name its
   own geometry freely. `Tutorial` (added 2026-08-16) names the onboarding lesson's
   authored geometry folder (`Areas/` pads with their `Stand` parts, `Walls/` gate walls
   and signs, `BotSpawns/` hidden markers); Frostbite never runs the tutorial and omits
   the entry entirely — every consumer treats nil as "this map has no tutorial". The
   former `Zone.TutorialCenterOffset` left with the tutorial zone in the same pass: the
   relocated lesson runs zoneless.

## Notes
Lives at the ReplicatedStorage root rather than inside `RoundSystem` on purpose: anything
map-specific stored inside a mirrored tree is overwritten by the next sync with no error.

Only names actually read through `Instances` are listed there. `WallMap` is deliberately
absent — it is resolved by a string literal in 15 combat scripts, and listing it while
those sites ignore the list would be worse than omitting it. `CorpseFolder` is absent
because it has no consumers left in the codebase at all.

The dividing line against `Config`: "the zone takes 25% off per phase" is gamemode tuning
and stays in Config, which is mirrored; "this map's zone runs from Z -700" is map data and
lives here.

## Domination (2026-08-22)

`Gamemodes` gained `"domination"`, and `Instances.CapturePoints = "CapturePoint"` names the three
workspace-root capture pad Models (`CapturePointA/B/C`, each carrying a `Letter` attribute) and the
`CapturePointBeam` parts beside them. Frostbite's copy carries the same two additions — its pads use
the same prefix — and is 97 lines.

## Dependencies
- **Requires:** Nothing
- **Required by:** Domination, CapturePointService, CapturePointVisualClient, ZoneService, SpawnService, RoundController, BotPathing, ZoneAtmosphere, TutorialDirector, TutorialClient, TeamBaseService

## Connections
### RemoteEvents
None.

### BindableEvents
None.

### Direct require()
None.
