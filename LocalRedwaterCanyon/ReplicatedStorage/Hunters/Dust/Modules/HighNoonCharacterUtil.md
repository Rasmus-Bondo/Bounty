---
tags: [shared, modulescript, utility, ultimate]
path: game.ReplicatedStorage.Hunters.Dust.Modules.HighNoonCharacterUtil
type: ModuleScript
lines: 105
---

# HighNoonCharacterUtil

Static utility module for character validation, aim origin, target resolution, and team checks for HighNoon.

## What it does
1. `GetPlayerCharacterData` validates a player has an alive character with humanoid, root part, and head
2. `GetAimOrigin` returns the head position as the aim origin for targeting
3. `GetHumanoidTargetPart` finds the best target part on a model (UpperTorso > Torso > HumanoidRootPart > Head)
4. `AreTargetsEnemies` checks if attacker and target are on different teams (non-team players are enemies)
5. `GetSafeAimDirection` validates and normalizes an aim direction vector

## Team modes

`AreTargetsEnemies` answers false for an ally, so High Noon cannot lock onto a teammate in the
first place -- acquisition, not just damage.

## Dependencies
- **Requires:** [[TeamAffinity]]
- **Required by:** HighNoonModule

## Connections
### RemoteEvents
None

### BindableEvents
None

### Direct require()
None
