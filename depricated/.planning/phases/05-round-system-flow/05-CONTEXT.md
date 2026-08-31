# Phase 5: Round System & Flow - Context

**Gathered:** 2026-04-01
**Status:** Ready for planning

<domain>
## Phase Boundary

Complete round lifecycle with lobby system and seamless player flow — implement opt-in lobby system where players choose to join from a lobby area, mid-match joining that spawns players immediately into ongoing rounds, 10-minute rounds with 10-second intermission displaying post-game stats (leaderboard + personal), respawn invulnerability with flickering visual feedback, and map reset between rounds.

Requirements: RND-01, RND-02, RND-03, RND-04, RND-05, RND-06, RND-07, RND-08

</domain>

<decisions>
## Implementation Decisions

### Lobby Opt-In System
- **D-01:** Button to join/leave — Players click a "Join Round" button in lobby to opt in. Button changes to "Leave Queue" after joining, allowing players to un-opt before round starts. Clear player agency, mobile-friendly.
- **D-02:** Center screen button placement — Large button in middle of screen for high visibility and easy tap on mobile. Standard lobby pattern from other games.
- **D-03:** No spectating — Lobby players stay in lobby area. No camera switching or spectate mode. Simpler implementation, avoids ghosting/cheating concerns.
- **D-04:** Show timer + player count — Lobby UI displays round time remaining and number of active players. Helps players decide when to join.

### Mid-Match Join Flow
- **D-05:** Immediate spawn on join — Player teleports to round spawn right away when clicking Join Round. Fast, gets them in action. Existing `hookCharacter()` logic already supports this.
- **D-06:** First spawn gets invuln — Initial spawn when joining mid-match receives same invulnerability as regular respawns (~10s). Consistent, gives new joiners orientation time.
- **D-07:** Auto-respawn after death — Players automatically respawn 3 seconds after death during active rounds. Keeps action flowing, standard FPS pattern. No return to lobby required.
- **D-08:** 3-second respawn delay — Quick return to action. Brief enough to not frustrate players but gives killers moment to reposition.

### Post-Game Stat Display
- **D-09:** Leaderboard + personal stats — Show top 5 players (ranked by kills) plus your own stats highlighted if not in top 5. Displays rank, player name, kills, deaths, K/D ratio. Shows winners and personal performance.
- **D-10:** 10-second intermission — Update `Config.INTERMISSION_TIME` from current 5 seconds to 10 seconds. Enough time to review stats and take quick break between rounds.
- **D-11:** Center overlay UI — Full-screen semi-transparent panel in center of screen. Matches stat menu pattern from Phase 4. Works well on mobile.
- **D-12:** Stats tracked: Kills + Deaths + K/D — Standard FPS leaderboard format. Data already tracked in `State.playerKills` for kills. Need to track deaths per round.

### Respawn Invulnerability System
- **D-13:** 10-second duration — Spawn protection lasts exactly 10 seconds. Matches requirement RND-06 (~10 seconds). Standard FPS spawn protection duration.
- **D-14:** Flickering transparent visual — Character rapidly blinks between visible and semi-transparent (50% opacity). Requirement RND-06 mentions "flickering transparent" explicitly. Classic spawn protection visual.
- **D-15:** Accelerating fade pattern — Flicker speed increases in final 3 seconds as warning that protection is ending. Gives player clear signal. Common FPS pattern.
- **D-16:** 50% transparency level — Character alternates between solid (100%) and half-transparent (50%). Clearly visible on mobile screens but obviously different from normal players.
- **D-17:** Cancel on firing gun — Invulnerability ends immediately when player shoots their weapon. Prevents camping/exploit, lets aggressive players engage faster. Requirement RND-07 says player cannot deal damage during invuln — ending on fire enforces this.

### Map Reset (RND-08)
- **D-18:** Reset between rounds — Clear corpses (already handled by `SpawnService.clearCorpses()`), reset player state, clear round-specific Values. Destructibles will be added in Phase 6 and should be reset there.

### Claude's Discretion
- Flicker timing exact values — Frequency of blinks (e.g., 0.2s interval), acceleration curve for final 3 seconds
- Death screen feedback — Any UI shown during 3-second respawn delay (e.g., "Respawning in 3...2...1" or silent)
- Lobby button styling — Colors, exact size (within mobile touch target guidelines), fonts, animations
- Post-game stat sorting — Tiebreaker logic when kills are equal (fewer deaths wins? alphabetical?)
- Sound effects — Spawn sound, despawn sound, invuln-end warning sound (optional)
- Opt-in persistence — Does opt-in state persist across rounds or reset each intermission?
- Invulnerability visual implementation — LocalScript with Transparency loop, or character parts manipulation

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project Documents
- `.planning/PROJECT.md` — Project vision, core value ("rounds are fun to play with friends"), mobile-first constraint
- `.planning/REQUIREMENTS.md` — Full v1 requirements (RND-01 through RND-08 are this phase)
- `.planning/ROADMAP.md` — Phase 5 goals and success criteria
- `CLAUDE.md` — Technology stack, RemoteEvents for round state, server-client architecture

### Prior Phase Context
- `.planning/phases/01-foundation-architecture/01-CONTEXT.md` — Service ModuleScript pattern, RemoteEvent consolidation
- `.planning/phases/02-combat-audio-polish/02-CONTEXT.md` — Combat systems, audio feedback patterns
- `.planning/phases/03-mobile-input-systems/03-CONTEXT.md` — Mobile UI patterns, touch button placement (50x50px minimum), UserInputService.TouchEnabled detection, ContextActionService for buttons
- `.planning/phases/04-progression-persistence/04-CONTEXT.md` — Stat tracking infrastructure (session kills, deaths, K/D), leaderstats pattern, UI reactive updates

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **RoundController.run()** (line 111-205): Existing round loop — waiting → intermission → fight → ended. Already handles 10-minute rounds (`Config.ROUND_TIME = 600`). Needs lobby opt-in check added before starting rounds.
- **RoundController.hookCharacter()** (line 39-67): Already respawns players mid-round with `sendPlayerToRoundSpawn()` and `giveBanditGun()`. Needs opt-in gate added — only respawn if player is opted in.
- **RoundController.resetRound()** (line 14-28): Clears roles, removes guns, clears corpses, reloads characters, teleports to lobby. Map reset foundation already exists.
- **RoundController.getWinner()** (line 97-109): Returns best player and kill count from `State.playerKills`. Ready for leaderboard display.
- **SpawnService.sendPlayerToLobby()** (line 57-65): Teleports player to random lobby spawn. Ready to use.
- **SpawnService.teleportAllToLobby()** (line 82-84): Sends all players to lobby. Called in resetRound().
- **SpawnService.sendPlayerToRoundSpawn()** (line 85-93): Teleports player to random round spawn. Used in hookCharacter().
- **State.playerKills** (table): Tracks kills per player per round. Ready for leaderboard. Need to add `State.playerDeaths` table for death tracking.
- **Config.ROUND_TIME** (600): 10-minute rounds already configured. Matches RND-03.
- **Config.INTERMISSION_TIME** (5): Currently 5 seconds. Needs update to 10 seconds per D-10.
- **Config.MIN_PLAYERS** (1): Minimum players to start round. May want to adjust for multiplayer.

### Established Patterns
- **Service ModuleScript pattern** (Phase 1): Create LobbyService as ModuleScript under ServerScriptService.RoundSystem.Modules for opt-in state management
- **RemoteEvent actions** (Phase 1): Use consolidated RemoteEvents with action strings ("JoinRound", "LeaveRound")
- **Attribute-based state** (Phase 1): Store player opt-in state as `player:SetAttribute("OptedIn", true/false)`
- **Stat tracking** (Phase 4): Session kills/deaths tracked in State table, displayed via leaderstats NumberValues
- **Mobile UI pattern** (Phase 3): ScreenGui with ContextActionService for touch buttons, UserInputService.TouchEnabled detection

### Integration Points
- **RoundController.run()** intermission loop (line 126-137): Add opt-in check — only start round if >= MIN_PLAYERS opted-in players exist
- **RoundController.run()** end-of-round (line 187-200): Display post-game stat board before resetRound()
- **RoundController.hookCharacter()** respawn logic (line 48-66): Gate mid-round respawn with opt-in check
- **ServerScriptService.RoundSystem.Modules**: Create new LobbyService for opt-in management
- **StarterGui**: Create LobbyGui ScreenGui with Join/Leave button (only visible in lobby) and PostGameGui for stat display
- **ReplicatedStorage.Events** (from Phase 1 consolidation): Add JoinRound and LeaveRound RemoteEvents
- **State module**: Add `playerDeaths` table, `optedInPlayers` table

### Current Limitations
- No opt-in state tracking — need to add player opt-in attribute and service
- No death tracking per round — `State.playerKills` exists but no deaths counterpart
- No invulnerability system — completely new mechanic
- No post-game stat UI — need to create from scratch
- Intermission is 5 seconds — too short for stat viewing, needs Config update

</code_context>

<specifics>
## Specific Ideas

- RoundController.hookCharacter() line 59-62 already implements mid-round respawn: checks if `State.roundActive`, then calls `sendPlayerToRoundSpawn()` and `giveBanditGun()`. Just needs opt-in gate added before these lines.
- Config.INTERMISSION_TIME at line 3 needs update from 5 to 10
- State.playerKills table (used in getWinner() line 101-106) is already per-round — resets in run() line 147. Add State.playerDeaths table with same pattern.
- SpawnService.sendPlayerToLobby() (line 57-65) and teleportAllToLobby() (line 82-84) are ready to use for lobby system
- LobbySpawns folder already exists in Workspace with 4 Part spawn locations
- Phase 4 created session stat tracking — can reuse for post-game display (session kills/deaths are already tracked in DataService and ProgressionService)
- Mobile button patterns from Phase 3: 50x50px minimum size, ContextActionService.BindAction with touch button support
- Stat menu UI pattern from Phase 4: center overlay with semi-transparent background — reuse this visual style for post-game board

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 05-round-system-flow*
*Context gathered: 2026-04-01*
