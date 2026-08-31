# Phase 6: Map Features & Polish - Context

**Gathered:** 2026-04-05
**Status:** Ready for planning

<domain>
## Phase Boundary

Signature gameplay features that differentiate the experience — implement destructible windows that shatter on bullet impact with passthrough, a 4-phase shrinking fire zone that closes from both ends of the canyon toward a random center point, and ragdoll consistency audit/fixes.

Requirements: MAP-01, MAP-02, MAP-03, RAG-01

</domain>

<decisions>
## Implementation Decisions

### Destructible Objects
- **D-01:** Windows only — Windows are the single destructible type for Phase 6. Barrels remain indestructible static cover. Focused scope.
- **D-02:** Instant shatter on hit — One shot destroys a window immediately. No health/damage model. Satisfying single-hit break.
- **D-03:** Bullet passthrough — When a bullet hits a window, the window shatters AND the bullet continues through as if the window wasn't there. Server raycast should not stop at broken window geometry.
- **D-04:** Cover removal — Destroyed windows lose collision. Breaking a window removes cover and creates new sightlines. Tactical depth from environmental destruction.

### Zone Shrinking System
- **D-05:** Fire on the ground — Zone boundary is fire spreading on the ground, western-themed. Players outside the safe zone take damage from fire.
- **D-06:** Canyon-following shape — Fire closes from both ends of the canyon, squeezing players toward the middle. Thematic for the western canyon setting. Not a circle or rectangle.
- **D-07:** Random center per round — Final zone center point shifts randomly each round within a range along the canyon. Prevents camping the same spot every game. Keeps rounds fresh.
- **D-08:** 10-minute rounds with 4 equal phases — `Config.ROUND_TIME` set to 600 seconds. Each zone phase lasts 2.5 minutes (150 seconds): Exploration (full map) → Pressure (75% map) → Event (50% map) → Final zone (25% map).
- **D-09:** Consistent damage rate — Same damage per second throughout all 4 phases (e.g., 10 HP/sec). Zone phases only change area size, not damage intensity.
- **D-10:** No special event mechanics — Event phase (phase 3) is just a smaller zone. No unique mechanics, faster shrink, or visual escalation. Simplicity over complexity.

### Ragdoll Consistency
- **D-11:** Audit and fix — RagdollService is the active system (RagdollOnDeath is disabled). No specific known issues yet. Researcher should audit current code for cross-client consistency issues, constraint tuning, and physics behavior. Low priority per PROJECT.md.

### Map Reset Integration
- **D-12:** Claude's discretion on reset approach — Researcher/planner decide between clone-from-template vs property-restore for resetting destroyed windows between rounds. `RoundController.resetRound()` already handles corpse clearing and player state — extend for destructible state.
- **D-13:** Zone reset — Fire zone must fully clear between rounds. Zone state resets to phase 1 (full map open) at round start.

### Claude's Discretion
- Window placement count and locations in the canyon map
- Fire visual implementation (ParticleEmitter, mesh parts, decals)
- Zone damage rate exact value (suggested ~10 HP/sec)
- Window shatter particle effects and glass break sound
- Ragdoll constraint tuning and physics parameters
- Destructible reset strategy (clone-from-template vs property-restore)
- Zone boundary detection method (region-based, distance-based, etc.)
- Zone HUD indicator approach (timer, minimap, directional arrows)

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project Documents
- `.planning/PROJECT.md` — Project vision, core value ("gunplay feels satisfying"), mobile-first constraint
- `.planning/REQUIREMENTS.md` — Full v1 requirements (MAP-01, MAP-02, MAP-03, RAG-01 are this phase)
- `.planning/ROADMAP.md` — Phase 6 goals and success criteria
- `CLAUDE.md` — Technology stack, raycasting with RaycastParams, audio patterns, performance constraints

### Prior Phase Context
- `.planning/phases/01-foundation-architecture/01-CONTEXT.md` — Service ModuleScript pattern, RemoteEvent consolidation, server-authoritative architecture
- `.planning/phases/02-combat-audio-polish/02-CONTEXT.md` — Combat systems, bullet impact material system, audio feedback patterns
- `.planning/phases/03-mobile-input-systems/03-CONTEXT.md` — Mobile UI patterns, performance targets (45-60 FPS mid-range), adaptive quality
- `.planning/phases/04-progression-persistence/04-CONTEXT.md` — Data persistence patterns, stat tracking infrastructure
- `.planning/phases/05-round-system-flow/05-CONTEXT.md` — Round lifecycle, resetRound() integration, Config constants, invulnerability system

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **RoundController.resetRound()** (line 21-47): Clears state, removes guns, clears corpses, reloads characters, teleports to lobby. Hook destructible and zone reset here.
- **Config module** (12 lines): Central constants — add zone timing, damage rate, and round time update here. Currently `ROUND_TIME = 100` (needs update to 600).
- **RagdollService** (183 lines): Active ragdoll system with attribute-based triggering (`ShouldRagdoll`), corpse creation, shot impulse application. Audit target for RAG-01.
- **Ragdoll module** (164 lines): Core ragdoll physics — BallSocketConstraints on Motor6D joints, collision group setup, enable/destroy lifecycle.
- **RagdollOnDeath** (178 lines, DISABLED): Old standalone ragdoll script. Disabled in favor of RagdollService. Can be reference but should not be re-enabled.
- **GunServer fireShot()**: Server raycast validation with RaycastParams and FilterDescendantsInstances. Integration point for window passthrough — raycast should continue through destroyed windows.
- **4 Barrel models** in Workspace: Existing map props. Stay indestructible for Phase 6.

### Established Patterns
- **Service ModuleScript pattern** (Phase 1): Create DestructibleService and ZoneService under ServerScriptService.RoundSystem.Modules
- **Config constants** (Phase 5): Add zone/destructible constants to existing Config module
- **Attribute-based state** (Phase 1): Track destructible state via attributes on instances
- **RemoteEvent actions** (Phase 1): Use consolidated events for zone state replication to clients
- **Particle effects** (Phase 2): Bullet impact system already creates particles at hit locations — reuse pattern for window shatter effects

### Integration Points
- **RoundController.resetRound()** (line 21-47): Add calls to restore destructibles and reset zone state
- **RoundController.run()** fight loop (line 234): Integrate zone phase transitions alongside the round timer countdown
- **GunServer fireShot()** raycast: Modify to handle window passthrough — if ray hits a destructible window, break it and continue raycast
- **Config module**: Add ROUND_TIME=600, ZONE_DAMAGE_PER_SEC, ZONE_PHASE_DURATION, zone boundary positions
- **StarterGui**: Zone indicator UI (timer/directional arrow showing safe zone)
- **Workspace**: Window models placed in map (need to create/place)

### Current Limitations
- No destructible system exists — completely new
- No zone/shrinking system exists — completely new
- No fire visual assets — need to create particle effects
- No window models in the map — need to place them
- ROUND_TIME is 100 (debug value?) — needs update to 600
- Ragdoll may have undiscovered cross-client issues — needs testing

</code_context>

<specifics>
## Specific Ideas

- Fire closing from both canyon ends is the signature visual — should feel like the canyon itself is on fire, pushing gunfighters to a final showdown
- Windows should have a satisfying glass-shatter sound and particle effect on break
- Bullet passthrough on windows: server raycast hits window → break window → continue ray from same origin past the window → check for player hits behind it
- Random center point for final zone along the canyon axis prevents players from pre-positioning at the same spot every round
- Zone timing constants should be easily tunable in Config (like existing INVULN_DURATION pattern)

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 06-map-features-polish*
*Context gathered: 2026-04-05*
