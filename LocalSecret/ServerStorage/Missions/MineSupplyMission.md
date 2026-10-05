---
tags: [server, modulescript, missions]
path: game.ServerStorage.Missions.MineSupplyMission
type: ModuleScript
lines: 55
---

# MineSupplyMission

Supply-crate objective for the underground mine mission.

## What it does
1. `Prepare(markers, model)` clears the previous run, then creates three wooden supply crates in `workspace.PVEMineSupplies` at the template's `SupplySpawns.Supply_N` markers (falling back to `EnemySpawns`), each snapped to the local floor with a disabled "Recover supplies" ProximityPrompt and a label.
2. `Floor(position, model)` raycasts against terrain and the template presentation to find the floor under a marker (asserts if none).
3. `Enable(predicate, onChange)` turns the prompts on and installs the eligibility check and the progress callback.
4. `TryCollect(player, crate)` validates eligibility, 12-stud range and line of sight, then marks the crate collected and reports the new count.
5. `Count()` returns crates collected; `Cleanup()` disconnects prompts and destroys the folder.

## Dependencies
- **Requires:** Nothing
- **Required by:** MissionServer

## Connections
None.
