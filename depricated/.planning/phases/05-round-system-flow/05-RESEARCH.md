# Phase 5: Round System & Flow - Research

**Researched:** 2026-04-01
**Domain:** Roblox round lifecycle, lobby systems, spawn invulnerability, post-game UI
**Confidence:** HIGH

## Summary

Phase 5 builds a complete round lifecycle on top of the existing RoundController infrastructure. The existing `RoundController.run()` already implements a waiting-intermission-fight-ended state machine with 10-minute rounds -- this phase adds lobby opt-in gating, mid-match joining, post-game stats display, respawn invulnerability with flickering visuals, and map reset between rounds. All eight RND requirements are achievable with modifications to existing services plus two new systems (LobbyService for opt-in state, InvulnerabilityService for spawn protection).

The core technical challenges are: (1) character transparency manipulation for the flickering invulnerability visual across all body parts, (2) integrating the opt-in gate into the existing hookCharacter respawn flow without breaking mid-round joining, and (3) preventing invulnerable players from dealing damage while still allowing them to move freely. The existing codebase patterns (service ModuleScripts, attribute-based state, RemoteEvent actions) provide clear templates for all new code.

**Primary recommendation:** Extend the existing RoundController state machine rather than replacing it. Add LobbyService as a thin opt-in state manager, use ForceField with `Visible = false` for server-side damage protection combined with a client-side transparency flicker loop for visuals, and build the post-game stat board as a ScreenGui overlay matching Phase 4's stat menu pattern.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Button to join/leave -- Players click a "Join Round" button in lobby to opt in. Button changes to "Leave Queue" after joining.
- **D-02:** Center screen button placement -- Large button in middle of screen for high visibility and easy tap on mobile.
- **D-03:** No spectating -- Lobby players stay in lobby area. No camera switching or spectate mode.
- **D-04:** Show timer + player count -- Lobby UI displays round time remaining and number of active players.
- **D-05:** Immediate spawn on join -- Player teleports to round spawn right away when clicking Join Round.
- **D-06:** First spawn gets invuln -- Initial spawn when joining mid-match receives same invulnerability as regular respawns (~10s).
- **D-07:** Auto-respawn after death -- Players automatically respawn 3 seconds after death during active rounds.
- **D-08:** 3-second respawn delay -- Quick return to action.
- **D-09:** Leaderboard + personal stats -- Show top 5 players (ranked by kills) plus your own stats highlighted if not in top 5. Displays rank, player name, kills, deaths, K/D ratio.
- **D-10:** 10-second intermission -- Update Config.INTERMISSION_TIME from 5 to 10 seconds.
- **D-11:** Center overlay UI -- Full-screen semi-transparent panel for post-game stats.
- **D-12:** Stats tracked: Kills + Deaths + K/D -- Standard FPS leaderboard format.
- **D-13:** 10-second duration for invulnerability.
- **D-14:** Flickering transparent visual -- Character rapidly blinks between visible and semi-transparent (50% opacity).
- **D-15:** Accelerating fade pattern -- Flicker speed increases in final 3 seconds.
- **D-16:** 50% transparency level -- Character alternates between 0 and 0.5 transparency.
- **D-17:** Cancel on firing gun -- Invulnerability ends immediately when player shoots.
- **D-18:** Reset between rounds -- Clear corpses, reset player state, clear round-specific values. Destructibles deferred to Phase 6.

### Claude's Discretion
- Flicker timing exact values (frequency, acceleration curve)
- Death screen feedback during 3-second respawn delay
- Lobby button styling (colors, size, fonts, animations)
- Post-game stat sorting tiebreaker logic
- Sound effects (spawn, despawn, invuln-end warning)
- Opt-in persistence across rounds vs reset each intermission
- Invulnerability visual implementation approach

### Deferred Ideas (OUT OF SCOPE)
None -- discussion stayed within phase scope.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| RND-01 | Players spawn in lobby and can opt-in to join current round | LobbyService with player attributes + LobbyGui with Join/Leave button |
| RND-02 | Players can join a round already in progress (mid-match join) | hookCharacter() opt-in gate + immediate spawn with invulnerability |
| RND-03 | Round runs for ~10 minutes then transitions to intermission | Already implemented in Config.ROUND_TIME = 600; update INTERMISSION_TIME to 10 |
| RND-04 | Post-game stat board shows kills, deaths, performance | PostGameGui ScreenGui with leaderboard overlay during intermission |
| RND-05 | After intermission, new round starts automatically | Already implemented in RoundController.run() loop; add opt-in player count check |
| RND-06 | Respawned players invulnerable ~10s with flickering visual | ForceField (Visible=false) + client transparency flicker loop |
| RND-07 | During invulnerability, player cannot deal damage | Server-side attribute check in GunServer before processing shots |
| RND-08 | Map resets between rounds | Extend existing resetRound() -- corpse clearing already exists |
</phase_requirements>

## Project Constraints (from CLAUDE.md)

- **Platform:** Roblox Studio -- all game code is Luau scripts within the Roblox data model
- **Architecture:** Client-server model (LocalScripts on client, Scripts on server, RemoteEvents for communication)
- **Networking:** RemoteEvents for client-to-server actions, NOT for damage or state changes
- **Input:** Must support keyboard/mouse and touchscreen; use UserInputService + ContextActionService
- **Performance:** Must run smoothly on mobile devices
- **Avoid:** Roact/React-lua, Raw DataStoreService (already using raw per D-01 Phase 4), BodyVelocity/BodyForce (deprecated), Mouse object, RemoteFunction for combat, client-side hit detection
- **UI:** ScreenGui > Frame > child elements, UISizeConstraint/UIAspectRatioConstraint for responsive scaling, minimum 44x44px touch targets

## Standard Stack

### Core (Roblox Built-in)
| Component | Purpose | Why Standard |
|-----------|---------|--------------|
| ForceField | Server-side invulnerability | Built-in Roblox class; `Humanoid:TakeDamage()` respects it automatically |
| Player Attributes | Opt-in state (`OptedIn`), invulnerability state (`Invulnerable`) | Established project pattern from Phase 1; replicates to client automatically |
| RemoteEvent | JoinRound/LeaveRound client-to-server actions | Established project pattern; action-string consolidation |
| ScreenGui/Frame | LobbyGui, PostGameGui, RespawnGui | Established project UI pattern |
| task.delay / task.spawn | Invulnerability timer, respawn delay, flicker loop | Standard Roblox Luau scheduling |

### Supporting
| Component | Purpose | When to Use |
|-----------|---------|-------------|
| Debris:AddItem() | Auto-cleanup of ForceField after duration | When creating timed ForceFields |
| RunService.Heartbeat | Client-side flicker animation loop | For smooth transparency oscillation |
| TweenService | Optional smooth transparency transitions | If flicker needs interpolation (likely not needed for rapid blink) |

## Architecture Patterns

### New Service Structure
```
ServerScriptService/
  RoundSystem/
    Modules/
      LobbyService        -- NEW: opt-in state management
      InvulnService        -- NEW: spawn protection + damage blocking
      RoundController      -- MODIFY: add opt-in checks, post-game display, respawn delay
      SpawnService          -- EXISTING: already has lobby/round spawn methods
      State                 -- MODIFY: add playerDeaths table, optedInPlayers tracking
      Config                -- MODIFY: INTERMISSION_TIME 5→10, add RESPAWN_DELAY, INVULN_DURATION

StarterGui/
  LobbyGui/               -- NEW: Join/Leave button + round info display
    LobbyScript            -- LocalScript driving button state
  PostGameGui/             -- NEW: intermission stat board overlay
    PostGameScript         -- LocalScript for leaderboard display
  RespawnGui/              -- NEW: respawn countdown overlay
    RespawnScript          -- LocalScript for "Respawning in 3...2...1"

StarterPlayerScripts/
  InvulnVisualScript       -- NEW: LocalScript for client-side flicker effect
```

### Pattern 1: Attribute-Gated Server Actions
**What:** Use player attributes to gate gameplay mechanics on the server
**When to use:** Any time a player's participation state affects game logic

```lua
-- Server: LobbyService
function LobbyService.optIn(player)
    player:SetAttribute("OptedIn", true)
    -- If round is active, immediately spawn into round
    if State.roundActive then
        SpawnService.sendPlayerToRoundSpawn(player)
        BanditService.giveBanditGun(player)
        InvulnService.applyInvulnerability(player)
    end
end

-- Server: RoundController hookCharacter modification
-- Only respawn if player is opted in
if State.roundActive and player:GetAttribute("OptedIn") then
    SpawnService.sendPlayerToRoundSpawn(player)
    BanditService.giveBanditGun(player)
    InvulnService.applyInvulnerability(player)
end
```

### Pattern 2: ForceField + Custom Visual
**What:** Use invisible ForceField for damage protection, separate client script for visual
**When to use:** Spawn invulnerability with custom visual feedback

```lua
-- Server: InvulnService
function InvulnService.applyInvulnerability(player)
    local character = player.Character
    if not character then return end

    player:SetAttribute("Invulnerable", true)

    local forceField = Instance.new("ForceField")
    forceField.Visible = false  -- Hide default particle effect
    forceField.Parent = character

    -- Remove after duration
    task.delay(Config.INVULN_DURATION, function()
        if forceField and forceField.Parent then
            forceField:Destroy()
        end
        player:SetAttribute("Invulnerable", false)
    end)
end

-- Server: GunServer shot validation addition
-- Before processing damage, check if target is invulnerable
if targetPlayer:GetAttribute("Invulnerable") then
    return -- No damage dealt
end

-- Also check if SHOOTER is invulnerable (RND-07: can't deal damage while invuln)
if shooterPlayer:GetAttribute("Invulnerable") then
    return -- Invulnerable players can't deal damage either
end
```

### Pattern 3: Client-Side Flicker with Accelerating Fade
**What:** LocalScript monitors Invulnerable attribute and animates character transparency
**When to use:** Visual feedback for invulnerability state

```lua
-- Client: InvulnVisualScript (StarterPlayerScripts)
local player = game.Players.LocalPlayer

local function startFlicker(character)
    local startTime = tick()
    local duration = 10  -- matches server INVULN_DURATION
    local warningStart = duration - 3  -- last 3 seconds accelerate

    task.spawn(function()
        while player:GetAttribute("Invulnerable") do
            local elapsed = tick() - startTime
            -- Base interval 0.3s, accelerates to 0.1s in final 3s
            local interval
            if elapsed < warningStart then
                interval = 0.3
            else
                -- Linear interpolation from 0.3 to 0.1 over final 3 seconds
                local progress = (elapsed - warningStart) / 3
                interval = 0.3 - (0.2 * math.min(progress, 1))
            end

            -- Set all parts to 50% transparent
            for _, part in character:GetDescendants() do
                if part:IsA("BasePart") then
                    part.Transparency = 0.5
                end
            end
            task.wait(interval)

            -- Set back to opaque
            for _, part in character:GetDescendants() do
                if part:IsA("BasePart") then
                    part.Transparency = 0
                end
            end
            task.wait(interval)
        end

        -- Ensure fully opaque when done
        for _, part in character:GetDescendants() do
            if part:IsA("BasePart") then
                part.Transparency = 0
            end
        end
    end)
end
```

### Pattern 4: Cancel Invulnerability on Fire
**What:** When an invulnerable player fires their gun, end invulnerability immediately
**When to use:** Prevents camping/exploiting spawn protection

```lua
-- Server: In GunServer's fire handling
-- When a player fires (before the invuln damage check):
if shooterPlayer:GetAttribute("Invulnerable") then
    InvulnService.removeInvulnerability(shooterPlayer)
    -- Don't process this shot (they were invuln when they pulled trigger)
    -- OR: process the shot since invuln just ended -- Claude's discretion
end

-- InvulnService
function InvulnService.removeInvulnerability(player)
    player:SetAttribute("Invulnerable", false)
    local character = player.Character
    if character then
        local forceField = character:FindFirstChildOfClass("ForceField")
        if forceField then
            forceField:Destroy()
        end
    end
end
```

### Anti-Patterns to Avoid
- **Client-side invulnerability checks:** Never trust the client to enforce invulnerability -- server must check `Invulnerable` attribute before applying damage
- **Setting Health directly for protection:** Don't set Health to math.huge or override TakeDamage -- ForceField is the proper mechanism and works with the existing damage pipeline
- **Replicating full leaderboard data via RemoteEvent:** For 5 players, use `FireAllClients` with a simple table during intermission -- don't create a polling system
- **Storing opt-in in a separate table only:** Use player attributes so client can read state for UI without additional remotes

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Damage protection | Custom health override / damage interceptor | ForceField (Visible=false) | ForceField is natively respected by TakeDamage(); any custom system risks bypasses |
| Character transparency | Server-side transparency replication | Client-side LocalScript reacting to Invulnerable attribute | Client handles visual; attribute replication is automatic; avoids server performance cost |
| Respawn timer | Custom death detection + manual character reload | Humanoid.Died event + task.delay + Player:LoadCharacter() | Standard Roblox pattern; CharacterAdded fires after LoadCharacter, hookCharacter already handles setup |
| Opt-in state sync | Custom RemoteEvent polling for opt-in state | Player attributes (SetAttribute/GetAttribute) | Attributes auto-replicate; client can read with GetAttribute or GetAttributeChangedSignal |

## Common Pitfalls

### Pitfall 1: ForceField Only Blocks TakeDamage()
**What goes wrong:** Direct `Humanoid.Health` modifications bypass ForceField protection entirely.
**Why it happens:** ForceField only intercepts the `Humanoid:TakeDamage()` method, not direct Health property writes.
**How to avoid:** Verify that all damage paths in GunServer use `TakeDamage()`. If any path sets Health directly, add an explicit `Invulnerable` attribute check before that code.
**Warning signs:** Invulnerable players still dying from gunfire.

### Pitfall 2: Transparency Affects Accessories and Tools
**What goes wrong:** Setting Transparency on all BasePart descendants also affects the gun, hat accessories, and other items, making them flicker too.
**Why it happens:** GetDescendants() returns everything including tools and accessories.
**How to avoid:** Filter to only character body parts -- check `part.Parent == character` or exclude parts inside Tools and Accessories. Alternatively, only modify parts that are direct children of the character Model (Head, Torso, arms, legs).
**Warning signs:** Gun flickering in/out during invulnerability.

### Pitfall 3: Race Condition on Respawn + Invulnerability
**What goes wrong:** Player respawns, invulnerability starts, but CharacterAdded fires before the character is fully loaded, so ForceField parents to an incomplete character.
**Why it happens:** CharacterAdded fires when the character model is created but descendants may still be streaming in.
**How to avoid:** Wait for `character:WaitForChild("Humanoid")` before applying ForceField. The existing hookCharacter pattern likely already does this.
**Warning signs:** Invulnerability sometimes not working on respawn.

### Pitfall 4: LoadCharacter During Active Round Teleports to Default Spawn
**What goes wrong:** Calling `Player:LoadCharacter()` spawns the player at the default SpawnLocation, not a round spawn.
**Why it happens:** Roblox's default spawn behavior uses SpawnLocations in Workspace.
**How to avoid:** Use hookCharacter pattern -- LoadCharacter triggers CharacterAdded, which then calls `sendPlayerToRoundSpawn()` to override the default spawn position. Existing code already handles this.
**Warning signs:** Respawned players appearing at lobby spawn during active round.

### Pitfall 5: Opt-In State Not Cleared on Disconnect
**What goes wrong:** Player disconnects while opted-in, playerCount stays inflated, next round may start with ghost count.
**Why it happens:** PlayerRemoving not cleaning up opt-in state from the active players list.
**How to avoid:** In LobbyService, hook PlayerRemoving to remove the player from optedInPlayers and update any count attributes.
**Warning signs:** Round starts with "2 players" but only 1 is actually present.

### Pitfall 6: Post-Game Stats Sent Before All Deaths Registered
**What goes wrong:** Final kill of the round doesn't show in the post-game leaderboard.
**Why it happens:** Round ends and stat board fires before the last kill's death event propagates.
**How to avoid:** Add a brief `task.wait(0.1)` after setting roundActive = false but before collecting stats for display. Or collect stats right as the round ends but before state reset.
**Warning signs:** Leaderboard showing one fewer kill than expected for the round winner.

## Code Examples

### Respawn with Delay (Server)
```lua
-- In hookCharacter or dedicated respawn handler
humanoid.Died:Connect(function()
    if State.roundActive and player:GetAttribute("OptedIn") then
        task.delay(Config.RESPAWN_DELAY, function()
            if player.Parent and State.roundActive and player:GetAttribute("OptedIn") then
                player:LoadCharacter()
                -- CharacterAdded will fire, hookCharacter handles the rest
            end
        end)
    end
end)
```

### Post-Game Stat Collection (Server)
```lua
-- Collect round stats for leaderboard
local function collectRoundStats()
    local stats = {}
    for _, player in ipairs(game.Players:GetPlayers()) do
        if player:GetAttribute("OptedIn") then
            table.insert(stats, {
                name = player.DisplayName,
                kills = State.playerKills[player] or 0,
                deaths = State.playerDeaths[player] or 0,
            })
        end
    end
    -- Sort by kills descending, deaths ascending as tiebreaker
    table.sort(stats, function(a, b)
        if a.kills == b.kills then
            return a.deaths < b.deaths
        end
        return a.kills > b.kills
    end)
    return stats
end
```

### Lobby UI Button State (Client)
```lua
-- LobbyScript in LobbyGui
local player = game.Players.LocalPlayer
local joinButton = script.Parent.JoinButton
local Events = game.ReplicatedStorage:WaitForChild("Events")

local function updateButton()
    local optedIn = player:GetAttribute("OptedIn")
    if optedIn then
        joinButton.Text = "Leave Queue"
        joinButton.BackgroundColor3 = Color3.fromRGB(180, 60, 60) -- Red
    else
        joinButton.Text = "Join Round"
        joinButton.BackgroundColor3 = Color3.fromRGB(60, 140, 60) -- Green
    end
end

joinButton.Activated:Connect(function()
    local optedIn = player:GetAttribute("OptedIn")
    if optedIn then
        Events.RoundEvent:FireServer("LeaveRound")
    else
        Events.RoundEvent:FireServer("JoinRound")
    end
end)

player:GetAttributeChangedSignal("OptedIn"):Connect(updateButton)
updateButton()
```

### Config Additions
```lua
-- Add to Config module
Config.RESPAWN_DELAY = 3        -- seconds before auto-respawn
Config.INVULN_DURATION = 10     -- seconds of spawn protection
Config.INVULN_FLICKER_BASE = 0.3  -- base flicker interval (seconds)
Config.INVULN_FLICKER_FAST = 0.1  -- fast flicker in final warning
Config.INVULN_WARNING_TIME = 3    -- seconds before end to accelerate flicker
Config.INTERMISSION_TIME = 10     -- updated from 5
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| SpawnLocation.Duration for auto-ForceField | Manual ForceField with Visible=false + custom visual | Long-standing pattern | Full control over duration, visual, and cancellation |
| BodyVelocity for knockback | LinearVelocity / VectorForce | 2022+ | Not applicable this phase but noted per CLAUDE.md |
| Polling attribute values | GetAttributeChangedSignal | Available since attributes launched | Event-driven UI updates, no polling needed |

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Manual Roblox Studio playtesting (no automated Luau test framework established) |
| Config file | None -- Roblox Studio project |
| Quick run command | Play Solo in Roblox Studio (F5) |
| Full suite command | Play with 2+ local servers (Test > Start with 2 Players) |

### Phase Requirements to Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| RND-01 | Lobby opt-in button appears, clicking joins round | manual | Play Solo, verify button + spawn | N/A |
| RND-02 | Mid-match join spawns player into active round | manual | Start 2-player test, join second player mid-round | N/A |
| RND-03 | 10-min round transitions to intermission | manual | Set ROUND_TIME to 10 for quick test, verify transition | N/A |
| RND-04 | Post-game stat board shows during intermission | manual | Complete a round, verify leaderboard overlay | N/A |
| RND-05 | New round auto-starts after intermission | manual | Watch full intermission-to-round transition | N/A |
| RND-06 | Respawned player flickers for ~10s | manual | Die and respawn, observe flicker visual | N/A |
| RND-07 | Invulnerable player cannot deal damage | manual | Shoot during invuln, verify no damage applied | N/A |
| RND-08 | Map resets between rounds (corpses cleared, state reset) | manual | End round, verify clean state | N/A |

### Sampling Rate
- **Per task commit:** Play Solo (F5) to verify basic functionality
- **Per wave merge:** 2-player server test to verify multiplayer interactions
- **Phase gate:** Full 2+ player test covering all 8 requirements

### Wave 0 Gaps
None -- Roblox Studio playtesting is the established test method for this project. No automated test framework to set up.

## Open Questions

1. **Opt-in persistence across rounds**
   - What we know: Players opt-in to join a round. After intermission, a new round starts.
   - What's unclear: Should players remain opted-in for the next round automatically, or must they re-opt-in each intermission?
   - Recommendation: Keep players opted-in across rounds (persist the attribute). More fluid experience -- players who want to leave can click "Leave" during intermission. Reduces friction for continuous play.

2. **Death during invulnerability from environmental hazards**
   - What we know: ForceField only blocks TakeDamage(). Environmental kills (falling off map) bypass it.
   - What's unclear: Should invulnerable players be protected from fall damage / void kills?
   - Recommendation: Don't worry about it. Map is a canyon -- no void kill zones expected. If needed, add Humanoid.StateChanged check for FallingDown.

3. **Other players seeing the flicker visual**
   - What we know: Client-side transparency changes via BasePart.Transparency DO replicate to other clients because Transparency is a replicated property. But if done via LocalScript, changes are local only.
   - What's unclear: Should all players see the invulnerable player flickering, or just the invulnerable player themselves?
   - Recommendation: All players should see the flicker (communicates "don't bother shooting this player"). Implement the transparency changes on the SERVER via InvulnService, not a client LocalScript. Use a server-side `task.spawn` loop. Alternative: fire a RemoteEvent to all clients to start/stop the visual, letting each client run the loop locally -- this offloads work from server but adds complexity.

## Sources

### Primary (HIGH confidence)
- Roblox ForceField documentation (create.roblox.com/docs/reference/engine/classes/ForceField) -- ForceField mechanics, Visible property, TakeDamage interaction
- Roblox BasePart documentation (create.roblox.com/docs/reference/engine/classes/BasePart) -- Transparency property (0-1 range)
- Existing codebase patterns documented in Phase 1-4 CONTEXT.md files

### Secondary (MEDIUM confidence)
- Roblox Humanoid documentation -- TakeDamage, Health, Died event
- Standard Roblox game development patterns for round systems and lobbies

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- all components are built-in Roblox APIs or established project patterns
- Architecture: HIGH -- extends existing RoundController and follows established service ModuleScript pattern
- Pitfalls: HIGH -- based on well-documented Roblox behavior (ForceField/TakeDamage interaction, Transparency replication)
- Invulnerability visual: MEDIUM -- server-side vs client-side transparency replication needs validation in practice (see Open Question 3)

**Research date:** 2026-04-01
**Valid until:** 2026-05-01 (stable -- Roblox APIs change slowly)
