# Bullets and Bounty

## What This Is

A western-themed deathmatch FPS built in Roblox. Players spawn in a canyon map armed with revolvers and fight in timed rounds. Between rounds there's a short intermission for stats and map reset, then the cycle continues. New players join from a lobby and can opt into the current round immediately. Designed to play well on both PC and mobile.

## Core Value

Gunplay feels satisfying and rounds are fun to play with friends — solid shooting mechanics, fair spawning, and a smooth round loop that keeps players in the action.

## Requirements

### Validated

<!-- Shipped and confirmed valuable. -->

- Existing round system (timer, round flow, spawning)
- Existing gun system (BanditGun — fire, reload, revolver UI)
- Ragdoll on death
- Player collision groups
- Leaderstats / currency display
- Footstep system with material-based sounds
- First-person camera
- Role reveal UI (to be refactored for deathmatch)
- Sound effects (round start, kill, impacts)

### Active

<!-- Current scope. Building toward these. -->

- [ ] Refactor codebase — clean up, convert scripts to ModuleScripts
- [ ] Remove Townsfolk role — deathmatch only, everyone is a Bandit with a gun
- [ ] Fix viewmodel / arm positioning (1st and 3rd person)
- [ ] Fix sounds — reload/shooting should emit from the gun, not server-wide
- [ ] Ragdoll fix (low priority)
- [ ] Bullet hit material system with per-material impact sounds
- [ ] Persistent storage via DataStore (cash, level, XP)
- [ ] Cash, level, and XP progression system
- [ ] Crosshair UI
- [ ] Stat board after game (kills, deaths, etc.)
- [ ] Stat menu: kills, time alive, cash, level, XP, time spent dead
- [ ] Opt-in / opt-out — lobby with ability to join current round mid-match
- [ ] Player can join mid-match
- [ ] Respawn invulnerability — ghosted for ~10 seconds, flickering transparent
- [ ] Sprint and crouch mechanics
- [ ] Stamina system for sprint
- [ ] Weapon recoil
- [ ] Destructible objects in the map
- [ ] Map reset between rounds
- [ ] Match pacing — 4-phase shrinking zone (exploration, pressure, bridge event, final zone)
- [ ] Mobile controls — touch-friendly UI, virtual joystick/buttons, aim assist for mobile
- [ ] Mobile optimization — performance targets for lower-end mobile devices

### Out of Scope

<!-- Explicit boundaries. Includes reasoning to prevent re-adding. -->

- Weapon skins — cosmetic system deferred, focus on core gameplay first
- Townsfolk role / social deduction — simplified to deathmatch for v1
- Multiple game modes — deathmatch only for now

## Context

- Built in Roblox Studio using Luau
- Codebase lives entirely in Roblox Studio (no external file system / git for game code)
- Planning docs tracked locally via GSD, game code managed through Roblox Studio MCP
- Existing codebase has a round system with RoundController, SpawnService, RoleService, BanditService modules
- Gun system is a Tool (BanditGun) in ServerStorage with GunServer, GunClient, RevolverGuiClient scripts
- UI exists for round timer, role reveal, revolver ammo wheel, and currency display
- Two developers: dobilek and aetria — task list sourced from Discord channel
- R15 character model with custom animations stored in ServerStorage
- Large portion of Roblox players are on mobile — UI and controls must work well on touchscreens

## Constraints

- **Platform**: Roblox Studio — all game code is Luau scripts within the Roblox data model
- **Architecture**: Client-server model enforced by Roblox (LocalScripts on client, Scripts on server, RemoteEvents for communication)
- **Storage**: Roblox DataStore API for persistence (rate limits, key size limits apply)
- **Performance**: Must run smoothly on mobile devices — the majority of Roblox's player base is on phones
- **Input**: Must support both keyboard/mouse and touchscreen input methods

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Deathmatch only for v1 | Simplifies role system, gets to fun faster | -- Pending |
| Fix & polish before new features | Solid foundation prevents compounding bugs | -- Pending |
| Lobby with opt-in system | Players can join/leave freely, no forced waiting | -- Pending |
| 10-minute round timer with intermission | Keeps matches paced, allows stat review between rounds | -- Pending |
| Mobile-first design | Most Roblox players are on mobile — UI and controls must be touch-friendly | -- Pending |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `/gsd:transition`):
1. Requirements invalidated? -> Move to Out of Scope with reason
2. Requirements validated? -> Move to Validated with phase reference
3. New requirements emerged? -> Add to Active
4. Decisions to log? -> Add to Key Decisions
5. "What This Is" still accurate? -> Update if drifted

**After each milestone** (via `/gsd:complete-milestone`):
1. Full review of all sections
2. Core Value check — still the right priority?
3. Audit Out of Scope — reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-03-27 after initialization*
