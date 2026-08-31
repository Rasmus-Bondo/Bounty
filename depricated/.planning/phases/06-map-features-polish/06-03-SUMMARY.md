---
phase: 06-map-features-polish
plan: 03
status: complete
completed: "2026-04-05"
---

# Plan 06-03 Summary: Map Windows + Fire Effects + Zone UI

## What Was Done

### Task 1: Window Placement
- Found 5 existing glass parts in the map (Glass material, transparency > 0.3, window-like dimensions)
- Renamed all 5 from "Part" to "Window" for DestructibleService discovery
- Locations: 2 in house Model 1 (Z ~-515/-491), 2 in house Model 2 (Z ~-236/-260), 1 standalone (Z ~-557)
- No random windows added — used existing architectural glass already in the map

### Task 2: Fire Zone Visual Effects
- Already built into ZoneService during Plan 06-01 execution
- Fire ParticleEmitter effects on invisible Parts at zone boundaries
- Orange color sequence fire particles, auto-update when zone shrinks, cleanup on reset

### Task 3: ZoneIndicatorGui
- Created `game.StarterGui.ZoneIndicatorGui` ScreenGui with:
  - ZoneFrame: top-center, dark background, gold UIStroke, UICorner, UISizeConstraint (150-300px width)
  - PhaseLabel: gold text "Zone: [phase]", TextScaled, GothamBold
  - TimerLabel: white text "Next phase: X:XX", TextScaled, Gotham
- Created ZoneIndicatorScript LocalScript:
  - Reads workspace attributes (ZonePhase, ZonePhaseName, ZonePhaseTimeLeft)
  - Phase-specific colors: gold (Exploration) -> orange (Pressure) -> red (Event/Final)
  - Hides when zone inactive (phase 0), shows "Final zone!" in phase 4
  - Updates via GetAttributeChangedSignal + 1s polling loop

## Key Decisions
- Used existing map windows rather than adding new geometry
- Phase colors progress warm-to-hot to match escalating danger
- Mobile-friendly top-center position avoids control overlaps
