---
tags:
  - shared
  - modulescript
  - config
  - progression
path: game.ReplicatedStorage.PVE.Config.ProgressionConfig
type: ModuleScript
lines: 11
---

# ProgressionConfig

Session-only upgrade-track table for PVE runs. Currently required by nothing.

## What it does

1. Declares `SessionOnly=true` and `MaxRank` 3 for every track
2. Sets per-rank bonuses: `DamagePerRank` 0.06 and `HealthPerRank` 10
3. Defines three tracks, each with a display title, a player attribute and three rank costs: Revolver (`PVERevolverLevel`, 75/150/250), Shotgun (`PVEShotgunLevel`, 75/150/250), Grit (`PVEGritLevel`, 100/200/325)
4. Is not read at runtime. ProgressionServer keeps its own inline copy of the same attributes, max rank and costs, so an edit here changes nothing until that duplicate is replaced with a require

## Dependencies

- **Requires:** Nothing
- **Required by:** Nobody

## Connections

None. Pure data module.
