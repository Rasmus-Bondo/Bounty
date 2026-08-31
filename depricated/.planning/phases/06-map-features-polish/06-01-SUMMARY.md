---
phase: 06-map-features-polish
plan: 01
status: complete
completed: "2026-04-05"
---

# Plan 06-01 Summary: DestructibleService + ZoneService Foundation

## What Was Done

### Task 1: DestructibleService (ModuleScript)
- Created `game.ServerScriptService.RoundSystem.Modules.DestructibleService`
- Discovers windows by scanning workspace for BaseParts named "Window" on Initialize()
- `breakWindow()`: sets CanCollide=false, Transparency=0.8, plays glass shatter sound (rbxassetid://280667448) with InverseTapered rolloff
- `isWindowDestroyed()`: returns boolean state from tracking table
- `resetDestructibles()`: restores all windows to original state (CanCollide=true, original transparency)
- Tracks original transparency per window for accurate reset

### Task 2: ZoneService (ModuleScript)
- Created `game.ServerScriptService.RoundSystem.Modules.ZoneService`
- 4-phase zone system: Exploration (0-2.5min), Pressure (2.5-5min), Event (5-7.5min), Final (7.5-10min)
- Zone shrinks along Z-axis (canyon runs Z[-700, 200]) from both ends toward random center
- Random center offset +/-40 studs per round for variety
- 10 HP/sec damage applied every 0.5s via Heartbeat to opted-in alive players outside safe zone
- Fire ParticleEmitter effects at zone boundaries (orange color sequence, invisible host parts)
- Sets workspace attributes: ZonePhase, ZonePhaseName, ZonePhaseTimeLeft for client UI
- Full API: Initialize(), startZone(), resetZone(), isPlayerInSafeZone(), getCurrentPhase(), getPhaseName()

### Task 3: Config + MainServer Updates
- Changed Config.ROUND_TIME from 100 to 600 (10-minute rounds)
- Added zone constants: ZONE_DAMAGE_PER_SEC=10, ZONE_PHASE_DURATION=150, ZONE_DAMAGE_INTERVAL=0.5
- Added canyon bounds: ZONE_START_Z=-700, ZONE_END_Z=200, ZONE_CENTER_RANDOM_RANGE=40
- MainServer requires and initializes both DestructibleService and ZoneService

## Key Decisions
- Canyon runs along Z-axis, not X — zone constants adjusted to match actual map geometry
- Fire effects built directly into ZoneService (not separate) for tighter coupling with zone boundaries
- Zone uses workspace attributes for client communication (no RemoteEvents needed)
