# Phase 1: Foundation & Architecture - Context

**Gathered:** 2026-03-27
**Status:** Ready for planning

<domain>
## Phase Boundary

Refactor the codebase into a clean ModuleScript architecture with a central GameManager, consolidate RemoteEvents into a shared folder with centralized access and rate limiting, add server-side combat validation, and remove the Townsfolk role so all players are armed Bandits in deathmatch mode.

</domain>

<decisions>
## Implementation Decisions

### Claude's Discretion

All implementation decisions are at Claude's discretion. The user chose to skip discussion for this phase. Downstream agents should make reasonable choices based on:

- **Module organization:** Restructure standalone scripts (RagdollOnDeath, PlayerCollisionGroup, leaderstat, Footstep, ForceDefaultR15Animate) into ModuleScripts. Create a GameManager as the central coordinator. Follow the existing RoundSystem pattern (folder with Modules subfolder) as the established convention.

- **Townsfolk removal:** Convert the Bandit-vs-Townsfolk round flow to free-for-all deathmatch. Remove Hide phase, remove role assignment (everyone is armed), remove "Townsfolk win"/"Bandit wins" end conditions. Replace with kill-count or time-based round end. Remove Townsfolk UI elements from GameplayGui.

- **RemoteEvent consolidation:** Move all RemoteEvents into a shared folder in ReplicatedStorage with a centralized access module. Current state: GunRemote (RemoteEvent) and EliminatePlayer (BindableEvent) are loose in ReplicatedStorage.

- **Rate limiting:** Add server-side per-player fire rate limiting to prevent RemoteEvent flooding. GunServer already has a FIRE_COOLDOWN (0.4s) but it uses a single shared variable — needs to be per-player.

- **Server combat validation:** GunServer already performs server raycast validation (isShotReasonable, workspace:Raycast). Ensure this is robust and properly validates all hits. Currently only Bandits can damage Townsfolk — needs to allow all players to damage all other players in deathmatch.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

No external specs — requirements fully captured in decisions above and the following project files:

### Project Documents
- `.planning/PROJECT.md` -- Project vision, constraints, and key decisions
- `.planning/REQUIREMENTS.md` -- Full v1 requirements with traceability (FOUND-01 through FOUND-04, CMBT-01, CMBT-02 are this phase)
- `.planning/ROADMAP.md` -- Phase goals and success criteria

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **RoundSystem modules** (Config, State, References, SpawnService, RoleService, BanditService, RoundController): Established modular pattern — this is the template for how other systems should be organized
- **GunServer**: 492-line server script with existing raycast validation, muzzle flash, tracer, bullet hole, impact spark, wood impact, and breakable part systems
- **GunClient/RevolverGuiClient**: Client-side gun and ammo UI already functional

### Established Patterns
- **ModuleScript services**: RoundSystem uses `require(script.Parent.ModuleName)` pattern with a Modules folder
- **RemoteEvent communication**: GunRemote uses action-string pattern (`"Fire"`, `"Reload"`, `"Ammo"`, `"ReloadStarted"`, etc.)
- **Attribute-based state**: Player roles stored as `player:SetAttribute("Role", value)`, ragdoll flags as attributes
- **SFX organization**: Sounds stored in ReplicatedStorage.SFX folder, cloned to workspace for playback
- **Debris cleanup**: Consistent use of `Debris:AddItem()` for temporary objects

### Integration Points
- **ServerScriptService**: Entry point for server scripts — MainServer requires RoundController
- **ReplicatedStorage**: Shared assets (SFX, particles, RemoteEvents, Values)
- **ServerStorage**: BanditGun tool, animations, DefaultR15Animate
- **StarterGui**: 4 ScreenGuis (RoundStartGui, GameplayGui, RevolverGui, CurrencyGui) — GameplayGui has Townsfolk/Bandit role reveal text that needs cleanup
- **StarterPlayer**: FirstPersonCamera and DefaultFootStepRemover LocalScripts

</code_context>

<specifics>
## Specific Ideas

No specific requirements — open to standard approaches

</specifics>

<deferred>
## Deferred Ideas

None — discussion was skipped, no scope creep to capture

</deferred>

---

*Phase: 01-foundation-architecture*
*Context gathered: 2026-03-27*
