---
tags: [server, modulescript, enemies, boss]
path: game.ServerScriptService.Enemies.BossAttackRules
type: ModuleScript
lines: 17
---

# BossAttackRules

Pure geometry tests for the Warden boss's area attacks.

## What it does
1. `Rules.InSlam(center, position, radius, heightTolerance)`: true when the position is within the flat radius and the vertical tolerance.
2. `Rules.InSweep(center, position, forward, radius, halfAngleDegrees, heightTolerance)`: true when the position is inside a flat cone of the given half-angle in front of the boss.
3. No state and no services, so it can be tested in isolation.

## Dependencies
- **Requires:** Nothing
- **Required by:** EnemyService

## Connections
None.
