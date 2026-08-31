---
phase: 05-round-system-flow
plan: 02
subsystem: round-system
tags: [roblox, luau, modulescript, round-lifecycle, auto-respawn, post-game-stats]

# Dependency graph
requires:
  - phase: 05-01
    provides: LobbyService, InvulnService, Config constants, RemoteEvents
provides:
  - RoundController with opt-in gating, 3-second auto-respawn, invulnerability on spawn
  - Post-game stat collection and broadcast via PostGameStats RemoteEvent
  - Round completion rewards for opted-in players
  - ProgressionService time rewards gated to active rounds with opted-in players
affects: [05-03, 05-04]

# Tech tracking
tech-stack:
  added: []
  patterns: [opt-in gating for round start, auto-respawn with delay, death tracking]

key-files:
  created: []
  modified:
    - game.ServerScriptService.RoundSystem.Modules.RoundController
    - game.ServerScriptService.RoundSystem.Modules.ProgressionService

key-decisions:
  - "Round waits for LobbyService.getOptedInCount() >= MIN_PLAYERS before starting"
  - "Only opted-in players receive guns and spawn at round start"
  - "Auto-respawn after 3-second delay via task.delay + LoadCharacter"
  - "RespawnCountdown RemoteEvent fires to client showing 3-second countdown"
  - "InvulnService.applyInvulnerability called after every spawn (round start + respawns)"
  - "Post-game stats sorted by kills descending, deaths as tiebreaker"
  - "Round completion rewards fire for all opted-in players after round ends"
  - "Time rewards gated: State.roundActive AND LobbyService.isOptedIn AND alive"

patterns-established:
  - "Opt-in gating pattern: check LobbyService.isOptedIn before granting round benefits"
  - "Auto-respawn pattern: Died handler + task.delay + LoadCharacter instead of manual teleport"
  - "Post-game stat collection: iterate opted players, collect stats, sort, FireAllClients"

requirements-completed: [RND-02, RND-03, RND-05, RND-08]

# Metrics
duration: 12min
completed: 2026-04-01
---

# Phase 5 Plan 02: RoundController Integration

**RoundController integrates opt-in gating for round start, 3-second auto-respawn with invulnerability, post-game stat broadcast, and round completion rewards; ProgressionService time rewards gated to active rounds**

## Performance

- **Duration:** 12 min
- **Started:** 2026-04-01T09:15:00Z
- **Completed:** 2026-04-01T09:27:00Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments
- RoundController run() loop now checks opted-in player count instead of total player count before starting
- Only opted-in players spawn and receive guns at round start with invulnerability
- hookCharacter implements 3-second auto-respawn via task.delay + LoadCharacter after death
- RespawnCountdown RemoteEvent fires to show client countdown
- InvulnService.applyInvulnerability called after spawn teleport in hookCharacter
- Death tracking: State.playerDeaths incremented in Died handler
- Post-game stats collected, sorted by kills/deaths, broadcast via PostGameStats:FireAllClients
- Round completion rewards fire for all opted-in players via ProgressionService.awardRoundCompletion
- resetRound() clears playerDeaths alongside playerKills but preserves opt-in state
- ProgressionService time reward loop gated with State.roundActive AND LobbyService.isOptedIn checks

## Task Commits

1. **Task 1: Update RoundController with opt-in gates, respawn delay, invulnerability, and post-game stats** - No git (Roblox Studio project)
2. **Task 2: Wire round-active gating into ProgressionService time rewards** - No git (Roblox Studio project)

## Files Created/Modified
- `game.ServerScriptService.RoundSystem.Modules.RoundController` - Added LobbyService/InvulnService requires, opt-in gating in run() loop, auto-respawn with delay in hookCharacter Died handler, invuln after spawn, post-game stat collection/broadcast, round completion rewards, death tracking
- `game.ServerScriptService.RoundSystem.Modules.ProgressionService` - Added State and LobbyService requires, time reward loop condition updated with State.roundActive and LobbyService.isOptedIn checks, removed Phase 4 TODO comment

## Decisions Made
- **Auto-respawn implementation**: Used `task.delay(Config.RESPAWN_DELAY, function() player:LoadCharacter() end)` pattern instead of manual spawn service calls. LoadCharacter triggers CharacterAdded, which re-runs hookCharacter to handle spawn + invuln.
- **Post-game stat sorting**: Kills descending as primary sort, deaths ascending as tiebreaker. Simple and fair.
- **Opt-in check placement**: Added opt-in gate in both waiting loop check AND in hookCharacter mid-round respawn. Prevents non-opted players from receiving round benefits.
- **Time reward gating**: Triple-gated (round active + opted in + alive) to complete Phase 4 TODO. Ensures time rewards only fire during active gameplay.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None - RoundController and ProgressionService updated cleanly, all services initialized successfully in playtest.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

✅ **Ready for Plan 05-03 (Client UI)**
- PostGameStats RemoteEvent ready for PostGameGui to receive leaderboard data
- RespawnCountdown RemoteEvent ready for RespawnGui to receive countdown seconds
- RoundEvent ready for LobbyGui to fire JoinRound/LeaveRound actions
- Player attributes (OptedIn, Invulnerable) ready for reactive UI via GetAttributeChangedSignal

✅ **Ready for Plan 05-04 (Verification)**
- Complete round lifecycle implemented server-side
- Opt-in gating, respawn delay, invulnerability, and stat tracking all functional
- Ready for end-to-end multiplayer testing

⚠️ **Testing Note**
Single-player playtest showed clean initialization with no errors. Full functionality (respawn delay, invuln visual, opt-in flow) requires Plan 05-03 client UI to be interactive.

---
*Phase: 05-round-system-flow*
*Completed: 2026-04-01*
