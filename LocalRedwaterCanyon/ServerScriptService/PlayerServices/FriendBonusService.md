---
tags: [server, modulescript, friendbonus, economy]
path: game.ServerScriptService.PlayerServices.FriendBonusService
type: ModuleScript
lines: 102
---

# FriendBonusService

Owns the friend-group Cash/XP bonus for the match: snapshots how many Roblox friends each player has on the server and exposes it to BoostService `getMultiplier`, which applies it to every gameplay earn via ProgressionService. Rules: [[FriendBonusConfig]].

## What it does
1. Counts each player's Roblox friends currently on the server (`Player:IsFriendsWith`, per-pair cached), capped by [[FriendBonusConfig]] `MAX_FRIENDS_COUNTED`. Bots are Rig models, not Players, so they never count
2. Recomputes ("snapshots") every player's count whenever the roster changes (PlayerAdded/PlayerRemoving) — the only thing that moves the count. It does NOT tick with time and is fully independent of the timed potion budget in BoostService
3. `getBonusPercent(player)` — additive bonus percent (0..50) read by BoostService `getMultiplier`
4. Mirrors each player's live bonus onto the `FriendBonusPercent` attribute for optional client display/debug
5. Clears a leaving player's friendship-cache entries on PlayerRemoving

## Dependencies
- **Requires:** [[FriendBonusConfig]]
- **Required by:** Main (starts it), BoostService (`getBonusPercent` in the multiplier)

## Connections
### RemoteEvents
None

### BindableEvents
None

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[FriendBonusConfig]] | `percentForFriends()`, `clampFriends()` | Rule constants + clamp/percent math |
