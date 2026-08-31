---
phase: 01-foundation-architecture
plan: 02
subsystem: round-system
tags: [deathmatch, round-flow, combat, kill-tracking]
dependencies:
  requires: [01-01]
  provides: [FOUND-03, CMBT-01]
  affects: [round-system, gun-system, role-system]
tech_stack:
  added: []
  patterns: [deathmatch-round-loop, kill-tracking, winner-announcement]
key_files:
  created: []
  modified:
    - game.ServerScriptService.RoundSystem.Modules.State
    - game.ServerScriptService.RoundSystem.Modules.Config
    - game.ServerScriptService.RoundSystem.Modules.RoleService
    - game.ServerScriptService.RoundSystem.Modules.BanditService
    - game.ServerScriptService.RoundSystem.Modules.RoundController
    - game.ServerStorage.BanditGun.GunServer
decisions:
  - Converted from Bandit-vs-Townsfolk to free-for-all deathmatch
  - Removed Hide phase entirely
  - All players get guns via giveGunToAllPlayers()
  - Kill tracking via State.playerKills table
  - Winner announced at round end with kill count
  - validShooter replaces validBandit (no role check for shooting)
metrics:
  duration: "prior session"
  completed: "2026-03-27T12:35:00Z"
---

# Phase 01 Plan 02: Deathmatch Conversion — Round Flow + Combat Summary

**One-liner:** Converted round system from Bandit-vs-Townsfolk to free-for-all deathmatch with kill tracking and winner announcements.

## Execution Status

**COMPLETE** - All 5 tasks verified via MCP tools.

## Task Results

### Task 01-02-01: Update State and Config for deathmatch mode
**Status:** Complete
- State: Removed `currentBandit`, `aliveTownsfolk`; added `playerKills` table
- Config: Removed `HIDE_TIME`; kept `MIN_PLAYERS=1`, `INTERMISSION_TIME=5`, `ROUND_TIME=120`

### Task 01-02-02: Rewrite RoleService for deathmatch
**Status:** Complete
- Added `setAllBandits()` to assign all players Bandit role
- Removed `chooseBandit`, `setRoles`, `countAliveTownsfolk`
- Simplified `eliminatePlayer` — no Townsfolk logic

### Task 01-02-03: Update BanditService to arm all players
**Status:** Complete
- Added `giveGunToAllPlayers()` — iterates all players
- Removed `freezeBandit` (no freeze phase in deathmatch)

### Task 01-02-04: Rewrite RoundController for deathmatch flow
**Status:** Complete
- Flow: Wait → Intermission → Fight (all armed) → Winner → Reset
- No Hide phase, no single-bandit selection
- `connectEvents` tracks kills via `State.playerKills`
- `getWinner()` finds player with most kills
- Winner announcement: "X wins with N kills!" or "Draw!"

### Task 01-02-05: Update GunServer for all-vs-all damage
**Status:** Complete
- `validShooter` replaces `validBandit` (no role check)
- Any player can damage any other player
- `eliminatePlayerEvent:Fire(hitPlayer, player)` passes killer

## Deviations from Plan

- **Minor:** Residual "Townsfolk" string in References.townsfolkSpawnsFolder and SpawnService (spawn folder naming, not role logic). Also in FirstPersonCamera role check. These are naming artifacts, not functional Townsfolk logic.

## Self-Check: PASSED

- [x] Round flow: Intermission → Fight → Winner → Reset (no Hide)
- [x] All players get guns at round start
- [x] Any player can damage any other player
- [x] Kill tracking works (playerKills table)
- [x] Winner announced at round end
- [x] No Townsfolk role logic in round system (naming artifacts remain)
