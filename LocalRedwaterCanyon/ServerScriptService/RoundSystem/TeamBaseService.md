---
tags: [server, modulescript, roundsystem, teamdeathmatch, map, collision]
path: game.ServerScriptService.RoundSystem.TeamBaseService
type: ModuleScript
lines: 212
---

# TeamBaseService

Swaps the two spawn houses in and out with the gamemode, and owns the collision matrix that makes each base's force-field doors one-way.

## What it does

1. **Swaps two alternative map dressings.** The spawn houses (`RedTeamBase` / `BlueTeamBase`) and the props they stand on occupy the same ground — 36 of Redwater's `TeamDeathmatchRemove` parts sit inside `RedTeamBase`'s bounding box — so exactly one set is in the workspace at a time. Team modes get the houses; every other mode gets the props back.
2. **Resolves both sets by name from `MapConfig.Instances`** (`TeamBases` and `TeamModeRemovals`), so each place names its own geometry. Redwater lists `TeamDeathmatchRemove` and `VesperHookSpotsBot.VesperHookSpotsRemove`; Frostbite Claim lists `RedTeamObjectRemove` and `BlueTeamObjectRemove`. Dotted entries are paths from `workspace`.
3. **Resolves once, at boot, and records each instance's own parent.** A restore therefore never has to walk a path through a tree that is half parked, which is what makes the swap symmetric — `tdm → dm` puts back exactly what `dm → tdm` removed, including returning `VesperHookSpotsRemove` inside `VesperHookSpotsBot` rather than at the workspace root.
4. **Parks by reparenting into `ServerStorage.ParkedMapGeometry`,** never by destroying: reversible, and it takes the geometry off every client for free.
5. **Registers six collision groups** — `TeamRed`/`TeamBlue` (rig bodies), `BaseDoorRed`/`BaseDoorBlue` (the door slabs), `ShotRed`/`ShotBlue` (raycasts only, never assigned to a part) — plus `Characters`, defensively, because nothing orders `SkinService`'s registration against `RoundController`'s boot and `CollisionGroupSetCollidable` throws on an unregistered group.
6. **Makes a door solid to the enemy alone,** for bodies and bullets from the one matrix. Own side, unstamped rigs, FFA (`Characters`), world parts and every ordinary raycast (`Default`) all pass through. Bodies and shots need separate groups because fighters deliberately pass through each other — a ray wearing a body group would pass through every fighter too.
7. **Prepares doors on activation only.** They are authored inert (`CanCollide` and `CanQuery` both false), so a server that never activates a base leaves them as decoration. The door's *name* carries its side, so there is no attribute to keep in sync.
8. **Exposes `baseFor(team)`** so `TeamDeathmatch` can read its spawn markers out of the house.

Everything fails **open**: an unstamped rig, FFA, a shot with no shooter and a server that never activates all resolve to groups the doors ignore, so the worst case is a door nobody notices — never a wall nobody can cross.

## Dependencies
- **Requires:** [[MapConfig]] (per-place names for the bases and the dressing they replace), [[TeamAffinity]] (the collision-group name tables, shared with the client)
- **Required by:** Domination (enemy base position for the bot objective tiering), RoundController (on boot and on every mode switch), TeamDeathmatch (spawn marker lookup), StarfallSightModule (enemy-spawn-house occlusion for Vesper's ultimate)

## Connections
### RemoteEvents
None.

### BindableEvents
None.

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[MapConfig]] | `MapConfig.Instances` | `TeamBases` and `TeamModeRemovals` — which workspace instances this map swaps |
| [[TeamAffinity]] | `TeamAffinity.BODY_GROUP` / `.DOOR_GROUP` / `.SHOT_GROUP` | The collision-group names the matrix is keyed on |

## Notes

Doors each carry a `PathfindingModifier` with `PassThrough = true`. The navmesh has no concept of collision groups, so a collidable door would otherwise carve a hole at every doorway and no bot could path into any base.

`Apply` is called between rounds only — a house appearing under a fighter mid-round would be a teleport nobody asked for.

`CapturePointService` parks the Domination capture pads and beams into the same `ParkedMapGeometry` folder — one place in ServerStorage for every piece of mode-swapped dressing.

Each base model carries a `Penetrable = false` attribute. The houses are built almost entirely from `Wood`, which BulletPenetration treats as shoot-through cover by material, so without this override a spawn house would be a building you could kill people through. The attribute is the highest-priority rule in that test and applies to every descendant, so it is one attribute per house rather than a per-part sweep — and it leaves ordinary wooden cover elsewhere on the map penetrable.

Spawn markers live in `<base>.Points` and are generated rather than hand-placed. Three constraints the generator has to respect, all learned the hard way:

1. **Sample the floor in world space.** Both maps' base models have rotated pivots — Frostbite's is tipped so the bounding box's local Z axis points straight down, which collapses a naive local-space grid onto a single point.
2. **Require the ceiling above a candidate to belong to the house,** or markers land on the foundation apron outside the walls. The floor level itself comes from a raycast beneath that storey's doors, which is the only anchor that means "the floor players walk on".
3. **Clear the spawn volume with a solid-part overlap test, never a ray.** A Roblox raycast whose origin is *inside* a part does not report that part, so a candidate standing inside a decorative crate passes every ray-based "is anything above me" check and bots then spawn stuck in the decor. The generator sweeps a 3 x 6.5 x 3 probe through `GetPartsInPart` and rejects any candidate overlapping a `CanCollide` part. The 6.5 height is deliberate: it spans both the standing rig and the rig at the moment of the +4 spawn lift. `GetPartBoundsInBox` is not a substitute — it tests bounding boxes, and a large rotated MeshPart's AABB reports false hits across half the room.
