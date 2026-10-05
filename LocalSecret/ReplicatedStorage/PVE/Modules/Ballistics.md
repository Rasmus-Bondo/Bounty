---
tags:
  - shared
  - modulescript
  - combat
path: game.ReplicatedStorage.PVE.Modules.Ballistics
type: ModuleScript
lines: 33
---

# Ballistics

Server-side penetrating raycast and the damage falloff that goes with it.

## What it does

1. `Ballistics.Pierce(origin, direction, range, exclude)` raycasts up to three segments with an exclude filter cloned from `exclude`, ignoring water
2. Returns immediately on any model tagged with the `PracticeTarget` or `PVEEnemy` attribute
3. Penetrates only `Wood` / `WoodPlanks` parts at most 3 studs thick, up to two layers, measuring the exit surface with a second include-only ray cast backwards
4. Anything else, or a wall that is too thick, returns as a hit on cover rather than a miss: `(hit, position, layers)`. A clean miss returns `(nil, endPoint, layers)`
5. `Ballistics.GetDamageMultiplier(layers)` returns `0.7^layers`

## Dependencies

- **Requires:** Nothing
- **Required by:** CombatServer

## Connections

None. Stateless utility.
