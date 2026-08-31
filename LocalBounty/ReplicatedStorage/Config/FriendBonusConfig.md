---
tags: [shared, modulescript, friendbonus, config, economy]
path: game.ReplicatedStorage.Config.FriendBonusConfig
type: ModuleScript
lines: 39
---

# FriendBonusConfig

Shared catalog for the friend-group Cash/XP bonus. Identical copy must exist in both places — edit both together (same rule as BoostConfig / BattlePassConfig).

## What it does
1. Exports the rule constants: `PERCENT_PER_FRIEND = 5` (% Cash & XP per Roblox friend on the server) and `MAX_FRIENDS_COUNTED = 9` (cap → +45% max — 9, not 10, because Redwater holds 10 humans and one of them is you, so a cap of 10 advertised a bonus that was arithmetically unreachable)
2. `clampFriends(count)` — clamps a raw friend count into `[0, MAX_FRIENDS_COUNTED]`
3. `percentForFriends(count)` — bonus percent for a friend count (clamped × `PERCENT_PER_FRIEND`)
4. The bonus is ADDITIVE with boost potions and the daily-streak passive — one shared stack `1 + friend% + potion% + passive%`

## Dependencies
- **Requires:** Nothing
- **Required by:** FriendBonusService (reads constants + math)

## Connections
### RemoteEvents
None

### BindableEvents
None

### Direct require()
None
