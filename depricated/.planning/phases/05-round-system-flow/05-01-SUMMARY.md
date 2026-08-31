---
phase: 05-round-system-flow
plan: 01
subsystem: round-system
tags: [roblox, luau, modulescript, player-attributes, forcefield, remoteevents]

# Dependency graph
requires:
  - phase: 01-foundation-architecture
    provides: Service ModuleScript pattern, RemoteEvent consolidation
  - phase: 04-progression-persistence
    provides: Player attribute patterns, service initialization in MainServer
provides:
  - LobbyService with opt-in state management via player attributes
  - InvulnService with ForceField-based spawn protection and server-side flicker visual
  - Config constants for respawn timing and invulnerability
  - State tables for playerDeaths and optedInPlayers
  - RemoteEvents for round actions (RoundEvent, PostGameStats, RespawnCountdown)
affects: [05-02, 05-03]

# Tech tracking
tech-stack:
  added: []
  patterns: [server-side transparency flicker for all-client visibility, player attribute replication for state sync]

key-files:
  created:
    - game.ServerScriptService.RoundSystem.Modules.LobbyService
    - game.ServerScriptService.RoundSystem.Modules.InvulnService
    - game.ReplicatedStorage.Events.RoundEvent
    - game.ReplicatedStorage.Events.PostGameStats
    - game.ReplicatedStorage.Events.RespawnCountdown
  modified:
    - game.ServerScriptService.RoundSystem.Modules.Config
    - game.ServerScriptService.RoundSystem.Modules.State
    - game.ServerScriptService.RoundSystem.MainServer
    - game.ServerStorage.BanditGun.GunServer

key-decisions:
  - "Server-side flicker loop in InvulnService so all clients see invulnerable players flickering"
  - "Opt-in state persists across rounds for fluid continuous play experience"
  - "ForceField with Visible=false for damage protection, blocks TakeDamage() natively"
  - "Invulnerability cancelled immediately when player fires weapon (D-17)"
  - "GunServer checks both shooter invuln (cancel) and target invuln (block damage)"

patterns-established:
  - "Player attributes for replicated state (OptedIn, Invulnerable) with GetAttributeChangedSignal for reactive UI"
  - "Service.Initialize() pattern for PlayerRemoving cleanup hooks"
  - "Server-side visual effects via task.spawn loops for multiplayer consistency"

requirements-completed: [RND-01, RND-06, RND-07]

# Metrics
duration: 15min
completed: 2026-04-01
---

# Phase 5 Plan 01: LobbyService + InvulnService Foundation

**LobbyService manages opt-in state via player attributes, InvulnService applies 10-second ForceField-based invulnerability with server-side flickering visual, Config/State/Events foundations established**

## Performance

- **Duration:** 15 min
- **Started:** 2026-04-01T09:00:00Z
- **Completed:** 2026-04-01T09:15:00Z
- **Tasks:** 2
- **Files modified:** 9 (5 created, 4 modified)

## Accomplishments
- LobbyService tracks player opt-in via SetAttribute("OptedIn") with server-side cleanup on disconnect
- InvulnService applies invisible ForceField + server-side transparency flicker loop (0.5 opacity, accelerating in final 3s)
- Config extended with 5 new constants: RESPAWN_DELAY (3s), INVULN_DURATION (10s), flicker timing constants, INTERMISSION_TIME updated to 10s
- State extended with playerDeaths table and optedInPlayers tracking
- Three new RemoteEvents created for round lifecycle communication
- GunServer invulnerability checks: shooter cancels invuln on fire, targets block damage when invulnerable

## Task Commits

1. **Task 1: Create LobbyService + Config/State/Events updates** - No git (Roblox Studio project)
2. **Task 2: Create InvulnService with ForceField + cancel-on-fire** - No git (Roblox Studio project)

## Files Created/Modified
- `game.ServerScriptService.RoundSystem.Modules.LobbyService` - Opt-in state management, RoundEvent handler, mid-match spawn logic
- `game.ServerScriptService.RoundSystem.Modules.InvulnService` - ForceField creation, server-side flicker loop, invuln removal
- `game.ServerScriptService.RoundSystem.Modules.Config` - Added RESPAWN_DELAY=3, INVULN_DURATION=10, flicker constants, INTERMISSION_TIME=10
- `game.ServerScriptService.RoundSystem.Modules.State` - Added playerDeaths={} and optedInPlayers={} tables
- `game.ReplicatedStorage.Events.RoundEvent` - RemoteEvent for JoinRound/LeaveRound client actions
- `game.ReplicatedStorage.Events.PostGameStats` - RemoteEvent for server-to-client post-game stat broadcast
- `game.ReplicatedStorage.Events.RespawnCountdown` - RemoteEvent for respawn timer display
- `game.ServerScriptService.RoundSystem.MainServer` - Added LobbyService and InvulnService requires + Initialize() calls
- `game.ServerStorage.BanditGun.GunServer` - Added InvulnService require, shooter invuln cancel check, target invuln block check

## Decisions Made
- **Server-side flicker visual**: InvulnService runs transparency loop on server so all clients see flickering via property replication (Research Open Question 3 recommendation). Alternative client-side approach rejected for consistency.
- **Opt-in persistence**: Players remain opted-in across rounds (resetAllOptIns exists but not called). Fluid continuous play experience - players who want out click Leave during intermission.
- **ForceField for damage protection**: Uses Roblox built-in ForceField (Visible=false) which natively blocks Humanoid:TakeDamage(). Clean solution, no custom health manipulation needed.
- **Cancel on fire implementation**: GunServer checks player:GetAttribute("Invulnerable") BEFORE raycast. If true, calls removeInvulnerability and returns (shot consumed, no damage dealt).
- **Target protection implementation**: After raycast hits player, GunServer checks hitPlayer:GetAttribute("Invulnerable") before TakeDamage. Early return if true.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

**1. GunServer syntax error during initial implementation**
- **Problem:** First invulnerability check inserted inside wrong if block, created extra `end` statement causing parse error
- **Resolution:** Edited script lines to properly place check after isShotReasonable() block
- **Verification:** Playtest showed clean initialization with no errors

**2. Sound asset loading warnings**
- **Problem:** Multiple "Failed to load sound" errors in Output
- **Resolution:** Pre-existing issue unrelated to this plan, not blocking functionality
- **Impact:** None on plan goals

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

✅ **Ready for Plan 05-02 (RoundController Integration)**
- LobbyService.optIn/optOut/isOptedIn/getOptedInCount ready for RoundController to call
- InvulnService.applyInvulnerability ready to be called from hookCharacter after respawn
- Config constants ready for RoundController to reference (RESPAWN_DELAY, INVULN_DURATION, INTERMISSION_TIME)
- State.playerDeaths table ready for death tracking
- RemoteEvents ready for RoundController and client UI to use

✅ **Ready for Plan 05-03 (Client UI)**
- RoundEvent ready for LobbyGui to fire JoinRound/LeaveRound
- PostGameStats ready for PostGameGui to receive leaderboard data
- RespawnCountdown ready for RespawnGui to receive countdown updates
- Player attributes (OptedIn, Invulnerable) ready for client-side reactive UI via GetAttributeChangedSignal

---
*Phase: 05-round-system-flow*
*Completed: 2026-04-01*
