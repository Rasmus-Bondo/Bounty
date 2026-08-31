# Requirements: Bullets and Bounty

**Defined:** 2026-03-27
**Core Value:** Gunplay feels satisfying and rounds are fun to play with friends

## v1 Requirements

Requirements for initial playable deathmatch. Each maps to roadmap phases.

### Code Foundation

- [x] **FOUND-01**: Codebase refactored to ModuleScript architecture with clear server/client separation
- [x] **FOUND-02**: All RemoteEvents consolidated into a shared folder with centralized access
- [ ] **FOUND-03**: Townsfolk role removed — all players spawn as armed Bandits in deathmatch mode
- [x] **FOUND-04**: Standalone scripts converted to ModuleScripts required by a central GameManager

### Combat

- [x] **CMBT-01**: Server performs its own raycast to validate all hits — client sends intent only
- [x] **CMBT-02**: Server rate-limits fire events per player to prevent RemoteEvent flooding
- [ ] **CMBT-03**: Crosshair displayed on screen during gameplay
- [ ] **CMBT-04**: Weapon recoil — camera kick and accuracy spread on fire, recovers over time
- [ ] **CMBT-05**: Bullet hit material system — per-material impact sounds and particle effects (wood splinters, dust, sparks)

### Sound

- [ ] **SND-01**: Gun fire and reload sounds play from the gun's position (positional audio), not server-wide
- [ ] **SND-02**: Impact sounds play at hit location with material-appropriate sound

### Viewmodel

- [ ] **VIEW-01**: Arm positioning fixed in first-person view — no dislocated/inverted bending
- [ ] **VIEW-02**: Arm positioning correct in third-person view

### Movement

- [ ] **MOV-01**: Player can sprint (increased speed) with a sprint key/button
- [ ] **MOV-02**: Player can crouch (reduced speed, smaller hitbox) with a crouch key/button
- [ ] **MOV-03**: Stamina system — sprinting drains stamina, regenerates when not sprinting

### Mobile

- [ ] **MOBI-01**: Touch controls — virtual joystick for movement, dedicated buttons for shoot, reload, sprint, crouch
- [ ] **MOBI-02**: UI scales correctly on all mobile screen sizes and aspect ratios
- [ ] **MOBI-03**: Game runs at acceptable frame rate on mid-range mobile devices

### Persistence

- [ ] **DATA-01**: Player data (cash, level, XP, stats) saved to Roblox DataStore with pcall error handling
- [ ] **DATA-02**: Data auto-saves periodically and on player disconnect (including server shutdown via BindToClose)

### Progression

- [ ] **PROG-01**: Player earns XP per kill and per round completed
- [ ] **PROG-02**: Player levels up when XP threshold is reached
- [ ] **PROG-03**: Player earns cash per kill and bonus cash for round performance
- [ ] **PROG-04**: Cash, level, and XP persist across sessions

### Round System

- [ ] **RND-01**: Players spawn in a lobby area and can opt-in to join the current round
- [ ] **RND-02**: Players can join a round that is already in progress (mid-match join)
- [ ] **RND-03**: Round runs for ~10 minutes, then transitions to intermission
- [ ] **RND-04**: During intermission, post-game stat board shows kills, deaths, and performance
- [ ] **RND-05**: After intermission, new round starts automatically (continuous loop)
- [ ] **RND-06**: Respawned players are invulnerable for ~10 seconds with flickering transparent visual
- [ ] **RND-07**: During invulnerability, player cannot deal damage (prevents exploit)
- [ ] **RND-08**: Map resets between rounds (destructibles restored, state cleared)

### Stats

- [ ] **STAT-01**: Stat menu accessible during gameplay showing: kills, deaths, time alive, cash, level, XP, time spent dead
- [ ] **STAT-02**: Post-game stat board displayed during intermission with round performance
- [ ] **STAT-03**: Scoreboard accessible via tab key / button showing all players, kills, deaths

### Map Events

- [ ] **MAP-01**: Destructible objects in the map (barrels, crates) that break when shot or damaged
- [ ] **MAP-02**: Match pacing — outer areas become dangerous over time, pushing players inward
- [ ] **MAP-03**: 4-phase match pacing: Exploration (0-2min), Pressure (2-4min), Event (~3-4min), Final zone (last minutes)

### Ragdoll

- [ ] **RAG-01**: Ragdoll on death works consistently across all clients (low priority)

## v2 Requirements

Deferred to future release. Tracked but not in current roadmap.

### Cosmetics

- **COSM-01**: Weapon skins system — visual customization for revolvers
- **COSM-02**: Character outfits — western-themed clothing options

### Map Events (Advanced)

- **MAP-04**: Bridge collapse scripted event during Phase 3 of match pacing

### Combat (Advanced)

- **CMBT-06**: Hit markers with visual/audio feedback on successful hits
- **CMBT-07**: Kill feed showing recent eliminations on HUD

### Mobile (Advanced)

- **MOBI-04**: Aim assist for touch input — slight auto-correction toward nearest visible target

### Social

- **SOCL-01**: Global leaderboard (OrderedDataStore) for top players
- **SOCL-02**: Achievement / badge system

## Out of Scope

| Feature | Reason |
|---------|--------|
| Multiple weapon types | Revolver-only is the identity — adds balancing complexity |
| Vehicles | Map too small, adds physics complexity |
| Building / fortification | Wrong genre — fast FPS, not Fortnite |
| Clans / teams | Deathmatch is FFA |
| Voice chat (custom) | Roblox handles natively if enabled |
| Custom character models | R15 with western clothing is sufficient |
| Townsfolk / social deduction | Simplified to deathmatch for v1 |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| FOUND-01 | Phase 1 | Complete |
| FOUND-02 | Phase 1 | Complete |
| FOUND-03 | Phase 1 | Pending |
| FOUND-04 | Phase 1 | Complete |
| CMBT-01 | Phase 1 | Complete |
| CMBT-02 | Phase 1 | Complete |
| SND-01 | Phase 2 | Pending |
| SND-02 | Phase 2 | Pending |
| VIEW-01 | Phase 2 | Pending |
| VIEW-02 | Phase 2 | Pending |
| CMBT-03 | Phase 2 | Pending |
| CMBT-04 | Phase 2 | Pending |
| CMBT-05 | Phase 2 | Pending |
| MOBI-01 | Phase 3 | Pending |
| MOBI-02 | Phase 3 | Pending |
| MOBI-03 | Phase 3 | Pending |
| MOV-01 | Phase 3 | Pending |
| MOV-02 | Phase 3 | Pending |
| MOV-03 | Phase 3 | Pending |
| DATA-01 | Phase 4 | Pending |
| DATA-02 | Phase 4 | Pending |
| PROG-01 | Phase 4 | Pending |
| PROG-02 | Phase 4 | Pending |
| PROG-03 | Phase 4 | Pending |
| PROG-04 | Phase 4 | Pending |
| STAT-01 | Phase 4 | Pending |
| STAT-02 | Phase 4 | Pending |
| STAT-03 | Phase 4 | Pending |
| RND-01 | Phase 5 | Pending |
| RND-02 | Phase 5 | Pending |
| RND-03 | Phase 5 | Pending |
| RND-04 | Phase 5 | Pending |
| RND-05 | Phase 5 | Pending |
| RND-06 | Phase 5 | Pending |
| RND-07 | Phase 5 | Pending |
| RND-08 | Phase 5 | Pending |
| MAP-01 | Phase 6 | Pending |
| MAP-02 | Phase 6 | Pending |
| MAP-03 | Phase 6 | Pending |
| RAG-01 | Phase 6 | Pending |

**Coverage:**
- v1 requirements: 34 total
- Mapped to phases: 34
- Unmapped: 0

✅ 100% coverage achieved

---
*Requirements defined: 2026-03-27*
*Last updated: 2026-03-27 after roadmap creation*