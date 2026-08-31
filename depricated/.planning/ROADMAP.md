# Roadmap: Bullets and Bounty

**Created:** 2026-03-27
**Strategy:** Fix/polish → Core gameplay → Features
**Coverage:** 34/34 v1 requirements mapped

## Phases

- [x] **Phase 1: Foundation & Architecture** - Secure, refactored codebase with proper module structure (2026-03-27)
- [x] **Phase 2: Combat & Audio Polish** - Server-authoritative combat with polished feedback systems (2026-03-29)
- [x] **Phase 3: Mobile & Input Systems** - Cross-platform controls with mobile optimization (2026-03-30)
- [ ] **Phase 4: Progression & Persistence** - Player data systems and XP/cash progression
- [ ] **Phase 5: Round System & Flow** - Complete round lifecycle with lobby and spawning
- [x] **Phase 6: Map Features & Polish** - Destructibles, match pacing, and final polish (2026-04-05)

## Phase Details

### Phase 1: Foundation & Architecture
**Goal**: Secure, maintainable codebase with proper server-client separation and consolidated RemoteEvents
**Depends on**: Nothing (first phase)
**Requirements**: FOUND-01, FOUND-02, FOUND-03, FOUND-04, CMBT-01, CMBT-02
**Success Criteria** (what must be TRUE):
  1. All scripts converted to ModuleScript architecture with clear server/client separation
  2. RemoteEvents consolidated in shared folder with centralized access and rate limiting
  3. Server performs independent raycast validation for all combat hits
  4. Townsfolk role completely removed - all players spawn as armed Bandits
  5. GameManager successfully coordinates all module services
**Plans**: 3 plans in 2 waves

Plans:
- [x] 01-01-PLAN.md — Create GameManager service architecture with PlayerService, CombatService, EventService
- [x] 01-02-PLAN.md — Consolidate RemoteEvents with centralized access and server-side combat validation
- [x] 01-03-PLAN.md — Remove Townsfolk role and convert to deathmatch mode with UI cleanup

### Phase 2: Combat & Audio Polish
**Goal**: Gunplay feels responsive and satisfying with proper audio feedback
**Depends on**: Phase 1
**Requirements**: SND-01, SND-02, VIEW-01, VIEW-02, CMBT-03, CMBT-04, CMBT-05
**Success Criteria** (what must be TRUE):
  1. Gun sounds play from weapon position, not server-wide
  2. Crosshair displays clearly during combat
  3. Weapon recoil provides appropriate camera kick and accuracy spread
  4. Arms position correctly in both first-person and third-person views
  5. Bullet impacts produce material-appropriate sounds and effects at hit locations
**Plans**: 4 plans in 2 waves

Plans:
- [ ] 02-01-PLAN.md — Fix positional audio system for gunfire, reloads, and material impact sounds
- [ ] 02-02-PLAN.md — Fix crosshair alignment and weapon arm positioning in 1st/3rd person
- [ ] 02-03-PLAN.md — Expand bullet impact system to 5 material types with unique particle effects
- [ ] 02-04-PLAN.md — Implement heavy weapon recoil with camera kick and accuracy spread

### Phase 3: Mobile & Input Systems
**Goal**: Smooth cross-platform experience with optimized mobile controls and performance
**Depends on**: Phase 2
**Requirements**: MOBI-01, MOBI-02, MOBI-03, MOV-01, MOV-02, MOV-03
**Success Criteria** (what must be TRUE):
  1. Touch controls work intuitively - virtual joystick for movement, dedicated action buttons
  2. UI scales correctly across all mobile screen sizes and aspect ratios
  3. Game maintains acceptable frame rate on mid-range mobile devices
  4. Players can sprint and crouch with appropriate speed/hitbox changes
  5. Stamina system limits sprint duration and regenerates appropriately
**Plans**: 3 plans in 2 waves

Plans:
- [x] 03-01-PLAN.md — Server-authoritative sprint/crouch/stamina with MovementService and stamina bar UI
- [x] 03-02-PLAN.md — Mobile touch button cluster and unified InputController for keyboard + touch
- [x] 03-03-PLAN.md — Responsive UI scaling for all ScreenGuis and adaptive performance monitor

### Phase 4: Progression & Persistence
**Goal**: Player data persists across sessions with rewarding progression systems
**Depends on**: Phase 3
**Requirements**: DATA-01, DATA-02, PROG-01, PROG-02, PROG-03, PROG-04, STAT-01, STAT-02, STAT-03
**Success Criteria** (what must be TRUE):
  1. Player data saves reliably to DataStore with error handling
  2. Data auto-saves periodically and on disconnect/shutdown
  3. Players earn XP and cash for kills and round performance
  4. Level progression triggers when XP thresholds are reached
  5. Stat menu displays current player metrics during gameplay
**Plans**: 3 plans in 2 waves

Plans:
- [x] 04-01-PLAN.md — DataService persistence layer with load/save/auto-save and extended leaderstats
- [x] 04-02-PLAN.md — ProgressionService with XP/cash rewards, level-up, and GunServer combat hooks
- [x] 04-03-PLAN.md — Stat menu UI with personal stats, scoreboard, and mobile stat button

### Phase 5: Round System & Flow
**Goal**: Complete round lifecycle with lobby system and seamless player flow
**Depends on**: Phase 4
**Requirements**: RND-01, RND-02, RND-03, RND-04, RND-05, RND-06, RND-07, RND-08
**Success Criteria** (what must be TRUE):
  1. Players spawn in lobby and can opt-in to join current rounds
  2. Mid-match joining works without disrupting ongoing gameplay
  3. 10-minute rounds transition smoothly to intermission with stat display
  4. New rounds start automatically after intermission
  5. Respawned players are invulnerable for ~10 seconds with visual feedback
**Plans**: 4 plans in 3 waves

Plans:
- [x] 05-01-PLAN.md — LobbyService + InvulnService server foundation with Config/State/Events updates
- [x] 05-02-PLAN.md — RoundController integration with opt-in gates, respawn delay, invuln, and post-game stats
- [x] 05-03-PLAN.md — Client UI: LobbyGui, PostGameGui leaderboard, and RespawnGui countdown
- [x] 05-04-PLAN.md — RoundTimeLeft wiring + full round system verification checkpoint

### Phase 6: Map Features & Polish
**Goal**: Signature gameplay features that differentiate the experience
**Depends on**: Phase 5
**Requirements**: MAP-01, MAP-02, MAP-03, RAG-01
**Success Criteria** (what must be TRUE):
  1. Destructible objects break when shot and reset between rounds
  2. Match pacing creates pressure through 4-phase zone shrinking
  3. Exploration, pressure, event, and final zone phases feel distinct
  4. Ragdoll physics work consistently across all clients
**Plans**: 4 plans in 3 waves

Plans:
- [x] 06-01-PLAN.md — DestructibleService + ZoneService foundation with Config constants
- [x] 06-02-PLAN.md — GunServer window passthrough integration + RoundController zone timing
- [x] 06-03-PLAN.md — Strategic window placement + fire zone visual effects with client UI
- [x] 06-04-PLAN.md — Complete reset system integration + ragdoll consistency audit

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Foundation & Architecture | 3/3 | Complete | 2026-03-27 |
| 2. Combat & Audio Polish | 4/4 | Complete (recoil deferred) | 2026-03-29 |
| 3. Mobile & Input Systems | 3/3 | Complete | 2026-03-30 |
| 4. Progression & Persistence | 3/3 | Complete | 2026-03-31 |
| 5. Round System & Flow | 4/4 | Complete | 2026-04-01 |
| 6. Map Features & Polish | 4/4 | Complete | 2026-04-05 |

## Notes

- Sequential execution - phases must complete in order due to dependencies
- Mobile-first design throughout all phases
- Server-authoritative architecture established in Phase 1 protects all subsequent features
- Research findings incorporated into phase structure and priorities

---
*Generated: 2026-03-27*