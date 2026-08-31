---
phase: 05-round-system-flow
plan: 03
subsystem: ui
tags: [roblox, luau, gui, round-system, client-ui, screengui, localscript]

# Dependency graph
requires:
  - phase: 05-01
    provides: RemoteEvents (RoundEvent, PostGameStats, RespawnCountdown) and server services
  - phase: 04-03
    provides: UI pattern conventions (semi-transparent overlays, gold western theme, mobile sizing)
provides:
  - LobbyGui with join/leave toggle button and round info display
  - PostGameGui with top-5 leaderboard and personal stats highlight during intermission
  - RespawnGui with 3-second countdown display on death
affects: [05-04, phase-6]

# Tech tracking
tech-stack:
  added: []
  patterns: 
    - "Client-side attribute polling for player count (OptedIn attribute)"
    - "workspace:GetAttribute('RoundTimeLeft') for round timer display"
    - "Dynamic leaderboard row creation with rank-based highlighting"
    - "10-second auto-hide for intermission overlay"

key-files:
  created:
    - game.StarterGui.LobbyGui
    - game.StarterGui.LobbyGui.LobbyScript
    - game.StarterGui.PostGameGui
    - game.StarterGui.PostGameGui.PostGameScript
    - game.StarterGui.RespawnGui
    - game.StarterGui.RespawnGui.RespawnScript
  modified: []

key-decisions:
  - "LobbyGui button always visible (not hidden during rounds) — opted-in players see 'Leave Queue' option"
  - "Round timer reads workspace:GetAttribute('RoundTimeLeft') — requires RoundController update in plan 05-04"
  - "PostGameGui shows top 5 + local player with separator if not in top 5"
  - "10-second auto-hide for PostGameGui intermission overlay (matches intermission duration)"
  - "K/D ratio formatted to 1 decimal for zero deaths, 2 decimals otherwise"

patterns-established:
  - "Semi-transparent overlay pattern: BackgroundColor3 = (0,0,0), BackgroundTransparency = 0.3-0.5"
  - "Gold western theme for headers: Color3.new(0.706, 0.588, 0.314)"
  - "UICorner + UISizeConstraint + UIStroke for modern, responsive UI elements"
  - "Attribute polling with 1-second update loops for lightweight UI synchronization"
  - "Local player highlighting with distinct background and bold font"

requirements-completed: [RND-01, RND-04]

# Metrics
duration: 35min
completed: 2026-04-01
---

# Phase 5-03: Client UI for Round System Summary

**Three client ScreenGuis for complete round lifecycle: lobby opt-in with join/leave toggle, intermission leaderboard with top-5 + personal stats, and respawn countdown display**

## Performance

- **Duration:** 35 min
- **Started:** 2026-04-01T11:30:00Z
- **Completed:** 2026-04-01T12:05:00Z
- **Tasks:** 2
- **Files modified:** 6 created (3 ScreenGuis + 3 LocalScripts)

## Accomplishments
- LobbyGui with reactive join/leave button that toggles based on OptedIn attribute
- Round info display showing player count and round timer (reads workspace attribute)
- PostGameGui intermission overlay with top-5 leaderboard, K/D stats, and personal highlight
- Local player shown below separator if not in top 5
- RespawnGui with countdown display for 3-second death delay
- All GUIs follow Phase 4 visual patterns (semi-transparent, gold theme, mobile-friendly)

## Task Commits

**Note:** Config has `commit_docs: false` — commits skipped per project settings.

1. **Task 1: Create LobbyGui** - LobbyGui ScreenGui with JoinButton, InfoFrame, and LobbyScript
2. **Task 2: Create PostGameGui and RespawnGui** - PostGameGui leaderboard overlay + RespawnGui countdown

## Files Created/Modified
- `game.StarterGui.LobbyGui` - ScreenGui with DisplayOrder 15, persistent across respawns
- `game.StarterGui.LobbyGui.JoinButton` - Toggle button (green Join Round / red Leave Queue) with UICorner, UIStroke, UISizeConstraint
- `game.StarterGui.LobbyGui.InfoFrame` - Round timer and player count display
- `game.StarterGui.LobbyGui.LobbyScript` - Fires RoundEvent on button click, reactively updates from OptedIn attribute, polls workspace:GetAttribute("RoundTimeLeft")
- `game.StarterGui.PostGameGui` - ScreenGui with DisplayOrder 25, intermission overlay
- `game.StarterGui.PostGameGui.Overlay` - Full-screen semi-transparent overlay (Visible = false initially)
- `game.StarterGui.PostGameGui.Overlay.LeaderboardFrame` - Centered panel with gold border, header row, scrolling player list
- `game.StarterGui.PostGameGui.PostGameScript` - Creates top-5 leaderboard rows, highlights local player, auto-hides after 10 seconds
- `game.StarterGui.RespawnGui` - ScreenGui with DisplayOrder 30, ResetOnSpawn = true
- `game.StarterGui.RespawnGui.CountdownFrame` - Semi-transparent countdown display (Visible = false initially)
- `game.StarterGui.RespawnGui.RespawnScript` - Listens to RespawnCountdown event, counts down from delay value

## Decisions Made
- **Button visibility:** LobbyGui button remains visible during rounds (shows "Leave Queue" for opted-in players) rather than hiding completely. Simpler logic, gives players exit option mid-round.
- **Timer dependency:** Round timer reads `workspace:GetAttribute("RoundTimeLeft")` which must be set by RoundController in plan 05-04. Timer shows "Round: Waiting" when attribute is 0 or nil.
- **Local player highlight:** PostGameGui highlights local player with gold text and distinct background (60, 50, 30) regardless of rank position.
- **Separator logic:** If local player not in top 5, shows separator line (gray, 1px) before displaying their rank below the top 5.
- **Auto-hide timing:** PostGameGui auto-hides after 10 seconds to match intermission duration (matches round system design from plan 05-02).

## Deviations from Plan

None - plan executed exactly as written. All UI elements created per plan specifications with established visual patterns from Phase 4.

## Issues Encountered

None. All RemoteEvents from plan 05-01 were in place. UI creation followed existing patterns from StatMenuGui and MobileControlsGui.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- All client UI for round system complete
- Plan 05-04 must add `workspace:SetAttribute("RoundTimeLeft", remainingTime)` to RoundController fight loop for timer display to work
- PostGameStats and RespawnCountdown events wired and ready for server-side broadcasts
- RoundEvent:FireServer("JoinRound"/"LeaveRound") ready for LobbyService handlers
- Ready for plan 05-04 (RoundTimeLeft wiring + full system verification checkpoint)

---
*Phase: 05-round-system-flow*
*Completed: 2026-04-01*
