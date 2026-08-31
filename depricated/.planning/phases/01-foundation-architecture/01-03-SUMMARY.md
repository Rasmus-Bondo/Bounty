---
phase: 01-foundation-architecture
plan: 03
subsystem: ui-architecture
tags: [ui-cleanup, architecture, module-consolidation, game-manager]
dependencies:
  requires: [01-01]
  provides: [FOUND-01, FOUND-03, FOUND-04]
  affects: [ui-system, server-architecture]
tech_stack:
  added: []
  patterns: [service-module-pattern, central-coordinator, initialize-pattern]
key_files:
  created:
    - game.ServerScriptService.RoundSystem.Modules.RagdollService
    - game.ServerScriptService.RoundSystem.Modules.CollisionService
    - game.ServerScriptService.RoundSystem.Modules.LeaderstatService
    - game.ServerScriptService.RoundSystem.Modules.FootstepService
    - game.ServerScriptService.RoundSystem.Modules.AnimateService
  modified:
    - game.ServerScriptService.RoundSystem.MainServer
    - game.StarterGui.GameplayGui.Canvas.RoleRevealClient
    - game.StarterGui.GameplayGui.Canvas.BanditText
    - game.StarterGui.GameplayGui.Canvas.BanditTextShadow
decisions:
  - Removed TownsfolkText and TownsfolkTextShadow UI elements
  - Changed role reveal to show "FIGHT!" for deathmatch mode
  - Converted 5 standalone scripts to ModuleScripts with Initialize() pattern
  - Disabled original scripts for rollback safety (not deleted)
  - MainServer acts as central coordinator (GameManager pattern)
metrics:
  duration: "prior session"
  completed: "2026-03-27T12:40:00Z"
---

# Phase 01 Plan 03: UI Cleanup + Architecture Consolidation Summary

**One-liner:** Removed Townsfolk UI, updated role reveal to "FIGHT!", and consolidated 5 standalone scripts into RoundSystem service modules.

## Execution Status

**COMPLETE** - All 4 tasks verified via MCP tools.

## Task Results

### Task 01-03-01: Remove Townsfolk UI elements from GameplayGui
**Status:** Complete
- TownsfolkText and TownsfolkTextShadow deleted from Canvas
- BanditText and BanditTextShadow retained for "FIGHT!" display

### Task 01-03-02: Update RoleRevealClient for deathmatch mode
**Status:** Complete
- Shows "FIGHT!" when role set to Bandit (all players in deathmatch)
- No Townsfolk text references
- SHOW_TIME reduced to 3 seconds

### Task 01-03-03: Rename BanditText UI labels
**Status:** Complete
- BanditText.Text = "FIGHT!"
- BanditTextShadow.Text = "FIGHT!"

### Task 01-03-04: Convert standalone scripts to ModuleScripts
**Status:** Complete
- RagdollOnDeath → RagdollService (ModuleScript)
- PlayerCollisionGroup → CollisionService (ModuleScript)
- leaderstat → LeaderstatService (ModuleScript)
- Footstep → FootstepService (ModuleScript)
- ForceDefaultR15Animate → AnimateService (ModuleScript)
- All originals disabled (Enabled=false)
- MainServer requires and calls Initialize() on all 5 services

## Deviations from Plan

None — all tasks completed as specified.

## Self-Check: PASSED

- [x] No Townsfolk UI elements in GameplayGui
- [x] Role reveal shows "FIGHT!" for deathmatch mode
- [x] All 5 standalone scripts converted to ModuleScripts
- [x] MainServer coordinates all service initialization (GameManager pattern)
- [x] Original standalone scripts disabled (not deleted)
