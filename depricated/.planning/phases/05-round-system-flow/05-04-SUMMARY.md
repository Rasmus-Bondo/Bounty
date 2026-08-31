---
phase: 05-round-system-flow
plan: 04
subsystem: round-system
tags: [roblox, luau, round-lifecycle, verification, ui-fix]

# Dependency graph
requires:
  - phase: 05-02
    provides: RoundController with full round lifecycle
  - phase: 05-03
    provides: LobbyGui, PostGameGui, RespawnGui client UIs
provides:
  - RoundTimeLeft workspace attribute for lobby timer display
  - Verified complete round system across all 8 RND requirements
  - UI fixes for RespawnGui, PostGameGui, LobbyGui
  - RoundStartGui removed (redundant with LobbyGui)
affects: [phase-6]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "workspace:SetAttribute for cross-script data sharing"
    - "TextScaled with UITextSizeConstraint for overflow-safe labels"
    - "FireClient per opted-in player instead of FireAllClients"

key-files:
  created: []
  modified:
    - game.ServerScriptService.RoundSystem.Modules.RoundController
    - game.StarterGui.LobbyGui.LobbyScript
    - game.StarterGui.PostGameGui.PostGameScript
    - game.StarterGui.RespawnGui.CountdownFrame
    - game.StarterGui.PostGameGui.Overlay

key-decisions:
  - "RoundTimeLeft attribute already existed from plan 05-02 — no code change needed for Task 1"
  - "RoundStartGui deleted as redundant — status info merged into LobbyGui"
  - "PostGameGui title shows winner name from RoundStatus instead of static 'ROUND OVER'"
  - "PostGameStats fires only to opted-in players, not all clients"
  - "LobbyGui shows 'Time left X:XX' during fight instead of 'Fight! X:XX'"
  - "LobbyGui filters winner announcements — only shows phase statuses"
  - "LobbyGui button has 4 states: Join Queue, Join Match, Leave Queue, Leave Game"
  - "RoundController sets winner text before firing PostGameStats so client can read it"

patterns-established:
  - "Whitelist-based status display: only show known phase statuses, filter post-game messages"
  - "Per-player event firing for opt-in-gated features"

requirements-completed: [RND-01, RND-02, RND-03, RND-04, RND-05, RND-06, RND-07, RND-08]

# Metrics
duration: 45min
completed: 2026-04-03
---

# Phase 5 Plan 04: RoundTimeLeft Wiring + Round System Verification

**RoundTimeLeft attribute verified in place, full round system verified across 9 test scenarios covering all 8 RND requirements. Multiple UI fixes applied during verification.**

## Performance

- **Duration:** 45 min
- **Started:** 2026-04-03
- **Completed:** 2026-04-03
- **Tasks:** 2
- **Files modified:** 5 (1 server script, 3 client scripts, 1 deleted GUI)

## Accomplishments
- Confirmed RoundTimeLeft attribute already implemented in RoundController from plan 05-02
- Fixed RespawnGui CountdownFrame — had zero size/position, now properly centered at 250x80
- Fixed PostGameGui Overlay and LeaderboardFrame — had zero sizes, now properly sized and centered
- Deleted RoundStartGui (redundant with LobbyGui)
- Merged round status display into LobbyGui (Waiting/Intermission/Time left)
- PostGameGui now shows winner name in title instead of static "ROUND OVER"
- PostGameStats now fires only to opted-in players
- LobbyGui button restored to 4-state logic (Join Queue/Join Match/Leave Queue/Leave Game)
- LobbyGui filters winner announcements — only shows game-phase statuses
- LobbyGui shows "Time left X:XX" instead of "Fight! X:XX" during rounds
- InfoFrame text uses TextScaled to prevent overflow on long status messages
- All 9 verification scenarios passed in multiplayer test

## Task Commits

1. **Task 1: RoundTimeLeft attribute** - Already in place from plan 05-02 (no changes needed)
2. **Task 2: Human verification** - All 9 test scenarios approved by user

## Files Created/Modified
- `game.ServerScriptService.RoundSystem.Modules.RoundController` - Winner text set before PostGameStats fire, FireClient per opted-in player instead of FireAllClients
- `game.StarterGui.LobbyGui.LobbyScript` - 4-state button, round status display with phase filtering, "Time left" label, TextScaled info labels
- `game.StarterGui.PostGameGui.PostGameScript` - Winner name in title from RoundStatus value
- `game.StarterGui.RespawnGui.CountdownFrame` - Fixed Size/Position/AnchorPoint/BackgroundColor3/CountdownLabel properties
- `game.StarterGui.PostGameGui.Overlay` - Fixed Size/BackgroundColor3, LeaderboardFrame sizing and positioning
- `game.StarterGui.RoundStartGui` - DELETED (redundant with LobbyGui)

## Decisions Made
- **RoundStartGui removal**: Redundant with LobbyGui — both showed round status/timer. Winner info moved to PostGameGui.
- **Selective event firing**: PostGameStats uses FireClient per opted-in player instead of FireAllClients to avoid showing leaderboard to lobby spectators.
- **Status filtering**: LobbyGui only displays known phase statuses (Waiting/Intermission/Fight), not winner announcements.

## Deviations from Plan
- Task 1 required no code changes (already implemented in plan 05-02)
- RoundStartGui deletion and LobbyGui/PostGameGui refactoring were user-directed improvements during verification
- PostGameStats changed from FireAllClients to per-player FireClient

## Issues Encountered
- RespawnGui CountdownFrame had zero size — invisible during death. Fixed by setting proper Size/Position/AnchorPoint.
- PostGameGui Overlay and LeaderboardFrame had zero sizes — same root cause, fixed identically.
- LobbyGui timer text overflowed InfoFrame on "Draw!" message — fixed with TextScaled + UITextSizeConstraint.

## Verification Results

All 9 test scenarios passed:
1. Lobby opt-in (RND-01) - PASS
2. Round start (RND-05) - PASS
3. Invulnerability (RND-06, RND-07) - PASS
4. Death + respawn - PASS
5. Mid-match join (RND-02) - PASS
6. Round end + stats (RND-03, RND-04, RND-08) - PASS
7. Auto restart (RND-05) - PASS
8. Map reset (RND-08) - PASS
9. Round timer - PASS

---
*Phase: 05-round-system-flow*
*Completed: 2026-04-03*
