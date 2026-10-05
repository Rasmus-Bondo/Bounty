---
tags: [server, script, progression]
path: game.ServerScriptService.Progression.ProgressionServer
type: Script
lines: 79
---

# ProgressionServer

Camp upgrade shop: server-validated Revolver, Shotgun and Grit upgrades paid with secured scrap.

## What it does
1. Defines three upgrade tracks, each max level 3: Revolver and Shotgun (75/150/250 scrap) and Grit (100/200/325), stored as player attributes `PVERevolverLevel`, `PVEShotgunLevel`, `PVEGritLevel` (initialised to 0).
2. `Progression` remote `Request` opens the panel; `Buy` validates the player is at camp (`awayFromCamp`: in an encounter and the phase is not `Voting`, since players are still standing at camp while the job vote is open), max level and `PVEScrap` balance, then deducts scrap and bumps the level.
3. Grit sets Humanoid MaxHealth to 100 + 10 per level (healing the difference on purchase) and is re-applied deferred on every spawn.
4. The `OpenLoadout` ProximityPrompt on `workspace.PVE_LoadoutStation` opens the panel (also during Voting), or tells expedition players to return to camp.
5. Replies to the client with a snapshot (scrap + levels) and a status message.
6. Weapon levels are consumed by CombatServer as a +6%/level damage scale.

## Dependencies
- **Requires:** Nothing
- **Required by:** Nobody

## Connections
### RemoteEvents
| Remote | Direction | Other script |
|--------|-----------|-------------|
| `Remotes.Progression` | ← Client / → Client | [[ProgressionClient]] open/buy requests and snapshots |
