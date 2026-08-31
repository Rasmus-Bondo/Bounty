# Phase 1: Foundation & Architecture - Research

**Researched:** 2026-03-27
**Domain:** Roblox ModuleScript architecture and server-client security
**Confidence:** MEDIUM

## Summary

Phase 1 transforms a mixed-script codebase into a secure, maintainable ModuleScript architecture with proper server-client separation. The core challenge is refactoring standalone scripts into a service-oriented architecture while maintaining functionality, consolidating RemoteEvents for centralized rate limiting, and implementing robust server-side combat validation.

**Primary recommendation:** Follow the existing RoundSystem pattern as the architectural template - use folder-based services with Modules subfolders and a central GameManager as coordinator.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Claude's Discretion
All implementation decisions are at Claude's discretion. The user chose to skip discussion for this phase. Downstream agents should make reasonable choices based on:

- **Module organization:** Restructure standalone scripts (RagdollOnDeath, PlayerCollisionGroup, leaderstat, Footstep, ForceDefaultR15Animate) into ModuleScripts. Create a GameManager as the central coordinator. Follow the existing RoundSystem pattern (folder with Modules subfolder) as the established convention.

- **Townsfolk removal:** Convert the Bandit-vs-Townsfolk round flow to free-for-all deathmatch. Remove Hide phase, remove role assignment (everyone is armed), remove "Townsfolk win"/"Bandit wins" end conditions. Replace with kill-count or time-based round end. Remove Townsfolk UI elements from GameplayGui.

- **RemoteEvent consolidation:** Move all RemoteEvents into a shared folder in ReplicatedStorage with a centralized access module. Current state: GunRemote (RemoteEvent) and EliminatePlayer (BindableEvent) are loose in ReplicatedStorage.

- **Rate limiting:** Add server-side per-player fire rate limiting to prevent RemoteEvent flooding. GunServer already has a FIRE_COOLDOWN (0.4s) but it uses a single shared variable — needs to be per-player.

- **Server combat validation:** GunServer already performs server raycast validation (isShotReasonable, workspace:Raycast). Ensure this is robust and properly validates all hits. Currently only Bandits can damage Townsfolk — needs to allow all players to damage all other players in deathmatch.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| FOUND-01 | Codebase refactored to ModuleScript architecture with clear server/client separation | Service pattern architecture, folder organization |
| FOUND-02 | All RemoteEvents consolidated into a shared folder with centralized access | RemoteEvent organization patterns, rate limiting architecture |
| FOUND-03 | Townsfolk role removed — all players spawn as armed Bandits in deathmatch mode | Role system refactoring, UI cleanup patterns |
| FOUND-04 | Standalone scripts converted to ModuleScripts required by a central GameManager | GameManager pattern, service lifecycle management |
| CMBT-01 | Server performs its own raycast to validate all hits — client sends intent only | Server validation patterns, anti-exploit techniques |
| CMBT-02 | Server rate-limits fire events per player to prevent RemoteEvent flooding | Per-player throttling, RemoteEvent security |
</phase_requirements>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| ModuleScript | Native | Service architecture | Roblox's recommended pattern for reusable code |
| RemoteEvent | Native | Client-server communication | Built-in networking with rate limiting |
| workspace:Raycast | Native | Server-side hit validation | Authoritative collision detection |
| UserInputService | Native | Input handling | Cross-platform input abstraction |
| Debris | Native | Temporary object cleanup | Memory management for effects |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| BindableEvent | Native | Internal communication | Cross-service event dispatching |
| Player:SetAttribute | Native | State management | Network-replicated flags and data |
| ReplicatedStorage | Native | Shared asset storage | Assets accessible to both server and client |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| ModuleScript | Standalone Scripts | ModuleScripts provide reusability and testability |
| RemoteEvent | RemoteFunction | Events don't yield, better for fire-and-forget patterns |
| Centralized RemoteEvents | Scattered RemoteEvents | Central organization enables rate limiting and monitoring |

**Installation:**
```bash
# No external dependencies - using native Roblox services
```

**Version verification:** All components are native Roblox services - no external package management required.

## Architecture Patterns

### Recommended Project Structure
```
ServerScriptService/
├── GameManager/              # Central coordinator
│   ├── init.lua             # GameManager main script
│   └── Modules/             # Service modules
│       ├── PlayerService.lua
│       ├── CombatService.lua
│       └── EventService.lua
├── RoundSystem/             # Existing pattern (template)
│   ├── RoundController.lua
│   └── Modules/
└── MainServer.lua           # Entry point

ReplicatedStorage/
├── Events/                  # Consolidated RemoteEvents
│   ├── CombatEvents.lua     # Centralized access module
│   ├── GunRemote            # RemoteEvent instance
│   └── PlayerEvents         # Additional RemoteEvents
├── SFX/                     # Audio assets
└── Particles/               # Visual effects

StarterGui/
├── RoundStartGui/
├── GameplayGui/             # Remove Townsfolk elements
├── RevolverGui/
└── CurrencyGui/
```

### Pattern 1: Service Module Architecture
**What:** Folder-based services with ModuleScript organization
**When to use:** For any reusable system (combat, players, rounds)
**Example:**
```lua
-- GameManager/Modules/CombatService.lua
-- Source: Established RoundSystem pattern
local CombatService = {}

function CombatService:Initialize()
    -- Service initialization
end

function CombatService:ValidateShot(player, targetPosition, direction)
    -- Server-side raycast validation
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.FilterDescendantsInstances = {player.Character}

    local result = workspace:Raycast(player.Character.Head.Position, direction * 1000, raycastParams)
    return result
end

return CombatService
```

### Pattern 2: Centralized RemoteEvent Access
**What:** Single module controlling all RemoteEvent interactions
**When to use:** For all client-server communication
**Example:**
```lua
-- ReplicatedStorage/Events/CombatEvents.lua
-- Source: RemoteEvent best practices
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CombatEvents = {}

local gunRemote = ReplicatedStorage.Events.GunRemote
local lastFireTime = {} -- Per-player rate limiting

function CombatEvents.FireGun(player, ...)
    local currentTime = tick()
    local lastTime = lastFireTime[player] or 0

    if currentTime - lastTime < 0.4 then -- Rate limit
        return false
    end

    lastFireTime[player] = currentTime
    -- Process gun fire
    return true
end

return CombatEvents
```

### Anti-Patterns to Avoid
- **Scattered RemoteEvents:** Makes rate limiting and monitoring impossible
- **Client-authoritative combat:** Security vulnerability - server must validate all damage
- **Global cooldowns:** Use per-player rate limiting instead of shared timers

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Input validation | Custom parameter checking | Roblox type checking + server validation | Edge cases around Instance validity and type coercion |
| Rate limiting | Custom throttling system | Per-player timestamp tracking | Built-in RemoteEvent limits work with proper implementation |
| Network communication | Custom protocols | RemoteEvent with action strings | Roblox optimizes network serialization and handles disconnections |
| Raycast validation | Client-side hit detection | Server workspace:Raycast | Exploits can manipulate client raycasting |

**Key insight:** Roblox's security model assumes all client data is potentially compromised - always validate on server.

## Common Pitfalls

### Pitfall 1: Mixed Script Types in Services
**What goes wrong:** Combining LocalScript and Script functionality in the same service folder
**Why it happens:** Misunderstanding of Roblox's execution context separation
**How to avoid:** Keep strict server/client separation - ModuleScripts can be required by both but execute separately
**Warning signs:** RemoteEvents firing in ModuleScripts, client-side validation logic

### Pitfall 2: RemoteEvent Parameter Limits
**What goes wrong:** Hitting Roblox's parameter count or size limits on RemoteEvents
**Why it happens:** Sending large data structures or too many parameters
**How to avoid:** Use tables for complex data, validate parameter counts server-side
**Warning signs:** Network errors, missing data on reception

### Pitfall 3: Circular Module Dependencies
**What goes wrong:** ModuleScripts requiring each other in a loop, causing script hangs
**Why it happens:** Poor service boundary design
**How to avoid:** Use dependency injection or event-based communication between services
**Warning signs:** Scripts freezing during require(), infinite loading

### Pitfall 4: Per-Player State Leaks
**What goes wrong:** Rate limiting tables growing infinitely as players join/leave
**Why it happens:** Not cleaning up per-player data on PlayerRemoving
**How to avoid:** Connect PlayerRemoving event to clean up tracking tables
**Warning signs:** Memory usage growing over time, server performance degradation

## Code Examples

Verified patterns from official sources:

### GameManager Service Coordinator
```lua
-- Source: RoundSystem pattern (established in codebase)
-- GameManager/init.lua
local GameManager = {}

local Services = {
    PlayerService = require(script.Modules.PlayerService),
    CombatService = require(script.Modules.CombatService),
    EventService = require(script.Modules.EventService)
}

function GameManager:Initialize()
    for serviceName, service in pairs(Services) do
        if service.Initialize then
            service:Initialize()
            print(serviceName, "initialized")
        end
    end
end

return GameManager
```

### Server Raycast Validation
```lua
-- Source: Roblox workspace:Raycast documentation
function CombatService:ValidatePlayerShot(player, targetPosition, gunPosition)
    local character = player.Character
    if not character then return false end

    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.FilterDescendantsInstances = {character}

    local direction = (targetPosition - gunPosition).Unit
    local result = workspace:Raycast(gunPosition, direction * 1000, raycastParams)

    -- Validate shot is reasonable (anti-exploit)
    local distance = (gunPosition - character.Head.Position).Magnitude
    if distance > 10 then -- Gun too far from player
        return false
    end

    return result
end
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Standalone Scripts | ModuleScript Services | Roblox 2019+ | Better code organization and reusability |
| Scattered RemoteEvents | Centralized Event Management | Community best practice 2020+ | Easier rate limiting and monitoring |
| Client hit detection | Server raycast validation | Security requirement always | Prevents exploitation |
| Global cooldowns | Per-player rate limiting | Performance improvement | Fairer gameplay, better scaling |

**Deprecated/outdated:**
- **BodyVelocity/BodyForce**: Replaced by VectorForce and LinearVelocity
- **Mouse object**: Replaced by UserInputService for input handling
- **FilteringEnabled = false**: Security nightmare, always use FilteringEnabled (default since 2019)

## Open Questions

1. **Existing RoundSystem Integration**
   - What we know: RoundSystem already exists with modular pattern
   - What's unclear: How much of the role system logic needs to be extracted vs. modified
   - Recommendation: Study RoleService module to understand Bandit/Townsfolk separation points

2. **Combat State Transition**
   - What we know: Current system has Bandit-only damage to Townsfolk
   - What's unclear: Whether damage system needs complete rewrite or just permission changes
   - Recommendation: Test existing GunServer raycast with all-vs-all damage model

3. **UI Element Dependencies**
   - What we know: GameplayGui has Townsfolk-specific elements
   - What's unclear: How deeply integrated role-based UI is throughout the interface
   - Recommendation: Audit all ScreenGuis for role-dependent elements before removal

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Roblox TestService + custom test runner |
| Config file | none — see Wave 0 |
| Quick run command | `game:GetService("TestService"):Run()` |
| Full suite command | Custom test harness in ServerStorage |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| FOUND-01 | ModuleScript architecture works | integration | Custom test harness | ❌ Wave 0 |
| FOUND-02 | RemoteEvent consolidation | unit | Test RemoteEvent access | ❌ Wave 0 |
| FOUND-03 | Townsfolk removal complete | integration | Role assignment test | ❌ Wave 0 |
| FOUND-04 | GameManager coordinates services | unit | Service initialization test | ❌ Wave 0 |
| CMBT-01 | Server raycast validation | unit | Combat validation test | ❌ Wave 0 |
| CMBT-02 | Rate limiting works | unit | Rapid fire test | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** Basic functionality test (service require works)
- **Per wave merge:** Full integration test (all services coordinate)
- **Phase gate:** Complete validation suite before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] `ServerStorage/TestRunner.lua` — test harness setup
- [ ] `Tests/ArchitectureTests.lua` — covers FOUND-01 through FOUND-04
- [ ] `Tests/CombatTests.lua` — covers CMBT-01, CMBT-02
- [ ] Test framework install: Manual setup in Roblox Studio

## Sources

### Primary (HIGH confidence)
- Roblox ModuleScript documentation - ModuleScript patterns and execution contexts
- Roblox RemoteEvent documentation - Rate limiting and communication patterns
- Project CONTEXT.md - Existing codebase patterns and requirements

### Secondary (MEDIUM confidence)
- CLAUDE.md project instructions - Technology stack recommendations
- Established RoundSystem pattern - Architectural template from existing code

### Tertiary (LOW confidence)
- General Roblox community practices - May need validation against current best practices

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - All native Roblox services with established patterns
- Architecture: MEDIUM - Following existing RoundSystem pattern but need to verify integration points
- Pitfalls: MEDIUM - Based on common Roblox development issues and security requirements

**Research date:** 2026-03-27
**Valid until:** 2026-04-27 (30 days for stable Roblox platform)