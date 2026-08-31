---
phase: 06-map-features-polish
plan: 02
status: complete
completed: "2026-04-05"
---

# Plan 06-02 Summary: GunServer Window Passthrough + RoundController Zone Timing

## What Was Done

### Task 1: GunServer Window Passthrough
- Modified `game.ServerStorage.BanditGun.GunServer` (lines 535-559)
- Added DestructibleService require at top of script
- After raycast hit, checks if hitPart is named "Window":
  - If intact: breaks window via DestructibleService.breakWindow(), excludes window from filter, continues ray to hit targets behind
  - If already destroyed: passes through, excludes from filter, continues ray
- Both paths reset rayParams filter after continued raycast
- Bullets pass through broken windows without interaction

### Task 2: RoundController Zone Integration
- Modified `game.ServerScriptService.RoundSystem.Modules.RoundController`
- Added requires for DestructibleService and ZoneService
- `resetRound()`: calls DestructibleService.resetDestructibles() and ZoneService.resetZone() before character respawn
- `run()`: calls ZoneService.startZone(tick()) after round start sound, before fight timer loop
- Calls ZoneService.resetZone() when round ends (after State.roundActive = false)

## Key Decisions
- Window passthrough uses continued raycast with same origin/direction but excluded window part
- Reset calls placed before LoadCharacter() so players spawn into fresh state
- Zone starts after round sound plays for clean player experience
