# Architecture Research: Bullets and Bounty

## Current State

The existing codebase has a partially modular structure but needs refactoring:

**Server (ServerScriptService):**
- `RoundSystem/` — folder with MainServer + modules (Config, State, References, SpawnService, RoleService, BanditService, RoundController)
- Standalone scripts: RagdollOnDeath, PlayerCollisionGroup, leaderstat, Footstep, ForceDefaultR15Animate
- `Ragdoll` ModuleScript

**Storage (ServerStorage):**
- `BanditGun` Tool — GunServer, GunClient, RevolverGuiClient, sounds, Handle

**Client (StarterPlayer):**
- `FirstPersonCamera` LocalScript
- `DefaultFootStepRemover` LocalScript

**Shared (ReplicatedStorage):**
- Remote events: GunRemote, EliminatePlayer (BindableEvent)
- Value objects: RoundStatus (StringValue), RoundTime (IntValue)
- SFX folder, footstep assets

**UI (StarterGui):**
- RoundStartGui (timer)
- GameplayGui (role reveal — Bandit/Townsfolk text)
- RevolverGui (ammo wheel)
- CurrencyGui (cash display)

## Recommended Architecture

### Module Organization

```
ServerScriptService/
  Server/
    GameManager.lua          -- Top-level orchestrator (init, player connect/disconnect)
    RoundController.lua      -- Round lifecycle (lobby → countdown → active → intermission)
    CombatManager.lua        -- Damage processing, kills, server-authoritative hit validation
    PlayerDataService.lua    -- ProfileService wrapper, load/save/autosave
    ProgressionService.lua   -- XP, leveling, cash rewards
    SpawnService.lua         -- Spawn point selection, invulnerability
    LobbyService.lua         -- Lobby state, opt-in/opt-out
    MapService.lua           -- Map reset, destructibles, zone management

ReplicatedStorage/
  Shared/
    Remotes/                 -- All RemoteEvents/RemoteFunctions in one folder
    Config.lua               -- Shared constants (damage, speeds, timers)
    Types.lua                -- Type definitions if using strict typing
    Enums.lua                -- Game-specific enums (RoundState, etc.)
  Assets/
    SFX/                     -- Sound assets
    Particles/               -- Particle effects

StarterPlayer/
  StarterPlayerScripts/
    Client/
      InputController.lua    -- Unified input (keyboard + touch)
      CameraController.lua   -- First/third person camera
      WeaponClient.lua       -- Shoot, reload, recoil (visual only)
      UIController.lua       -- Manages all UI screens
      SoundController.lua    -- Client-side positional audio
      EffectsController.lua  -- Bullet tracers, impact particles, hit markers

StarterGui/
  HUD/                      -- Always-visible: crosshair, ammo, health, timer, kill feed
  Menus/                     -- Scoreboard, stat menu, lobby UI
  Screens/                   -- Death screen, round start/end, post-game stats
```

### Client-Server Communication

```
CLIENT                          SERVER
  │                               │
  ├─── ShootRequest ───────────►  │  (ray origin, direction)
  │                               ├── Validate origin near player
  │                               ├── Server raycast
  │                               ├── Apply damage
  │  ◄─── DamageConfirm ────────┤  (hit player, damage, killed?)
  │  ◄─── PlayerEliminated ─────┤  (killer, victim, weapon)
  │                               │
  ├─── ReloadRequest ──────────►  │
  │  ◄─── ReloadConfirm ────────┤
  │                               │
  ├─── SprintRequest ──────────►  │  (start/stop)
  │  ◄─── StaminaUpdate ────────┤  (remaining stamina)
  │                               │
  ├─── OptInRequest ───────────►  │
  │  ◄─── SpawnPlayer ──────────┤
  │                               │
  │  ◄─── RoundStateChanged ────┤  (lobby/countdown/active/intermission)
  │  ◄─── TimerSync ────────────┤  (time remaining)
  │  ◄─── KillFeed ─────────────┤  (recent kills for HUD)
  │  ◄─── StatsUpdate ──────────┤  (player stats for scoreboard)
```

### Data Flow

**Round lifecycle:**
```
GameManager.init()
  → RoundController starts loop:
    LOBBY → players opt in
    COUNTDOWN → 5 second warning
    ACTIVE → 10 min timer, combat enabled
      → CombatManager processes hits
      → ProgressionService awards XP/cash per kill
      → MapService manages zones (if match pacing enabled)
    INTERMISSION → stat board shown, map reset
      → PlayerDataService autosaves
      → MapService.reset()
    → Loop back to LOBBY
```

**Player join flow:**
```
Player connects
  → PlayerDataService.loadProfile(player)
  → LobbyService.addToLobby(player)
  → Player sees lobby UI, can opt-in
  → On opt-in: SpawnService.spawnPlayer(player)
    → Gun given from ServerStorage
    → Player enters active round
```

**Combat flow:**
```
Client: detect click/tap → WeaponClient plays fire animation + sound
  → FireServer(rayOrigin, rayDirection)
Server: CombatManager receives
  → Validate ray origin (anti-cheat)
  → Perform raycast
  → If hit player: apply damage, check kill
  → If kill: award XP/cash, update stats, fire kill events
  → Notify all clients: hit effects, kill feed
Client: receive confirmation → hit marker, kill notification
```

## Refactoring Approach

### Phase 1: Foundation cleanup
1. **Consolidate RemoteEvents** — move GunRemote + create new ones in `Remotes/` folder
2. **Remove RoleService/BanditService** — simplify for deathmatch (everyone is armed)
3. **Convert standalone scripts** to ModuleScripts required by GameManager
4. **Move sound playback** from server scripts to client-side handlers

### Phase 2: Core systems
1. **PlayerDataService** — wrap ProfileService, handle load/save
2. **CombatManager** — extract damage logic from GunServer, add server validation
3. **InputController** — unified input for PC + mobile
4. **SpawnService refactor** — add invulnerability, better spawn point selection

### Phase 3: Game loop
1. **RoundController refactor** — add lobby state, opt-in, intermission
2. **LobbyService** — new, handles player flow
3. **MapService** — map reset, destructibles
4. **ProgressionService** — XP, leveling, cash

## Build Order (dependency-driven)

```
1. Remotes consolidation (everything depends on clean networking)
2. Code cleanup / ModuleScript conversion (foundation)
   ↓
3. PlayerDataService (persistence foundation)
4. CombatManager refactor (core gameplay)
5. InputController + mobile support (largest audience)
   ↓
6. SpawnService + invulnerability
7. RoundController + LobbyService refactor
8. ProgressionService (depends on DataService + Combat)
   ↓
9. UI overhaul (HUD, menus, screens)
10. MapService (reset, destructibles)
11. Match pacing / zones (advanced, last)
```

## Key Architectural Principles

1. **Server authority** — server validates all combat, state changes, and progression. Client is visual only.
2. **Module isolation** — each service has a single responsibility, communicates via function calls (server-side) or RemoteEvents (client-server).
3. **No circular dependencies** — services depend downward, never upward. GameManager orchestrates.
4. **Shared config** — constants in ReplicatedStorage so both client and server reference the same values.
5. **Stateless clients** — client renders what server tells it. No client-side game state that server doesn't know about.
