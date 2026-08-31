# Phase 4: Progression & Persistence - Research

**Researched:** 2026-03-30
**Domain:** Roblox DataStore persistence, XP/cash progression, stat menu UI
**Confidence:** HIGH

## Summary

Phase 4 introduces player data persistence via Roblox DataStoreService and builds progression systems (XP, cash, levels) on top of it, plus a stat menu UI. The user has locked the decision to use raw DataStore API (not ProfileService) with pcall error handling. The data model is well-defined: Cash, Level, XP, session stats, and lifetime stats.

The technical domain is straightforward Roblox DataStore usage with pcall wrapping, periodic auto-saves (5 minutes), PlayerRemoving saves, and BindToClose for server shutdown. Progression is purely server-side math (award XP/cash, check level thresholds). The stat menu is a standard ScreenGui overlay toggled by Tab (PC) or a mobile button.

**Primary recommendation:** Build DataService as the persistence layer (load/save/auto-save), ProgressionService for reward logic and level-ups, then StatMenuGui as a client-side overlay reading from leaderstats and RemoteEvents for lifetime data.

<user_constraints>

## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Use raw DataStore API (not ProfileService) -- small game, session locking not needed. Simple pcall error handling.
- **D-02:** Save comprehensive data structure -- Cash, Level, XP + session kills/deaths/time alive/time dead + lifetime kills/deaths/total playtime.
- **D-03:** Data key format -- Use `player.UserId` as DataStore key.
- **D-04:** Periodic auto-save + disconnect -- Auto-save every 5 minutes + save on PlayerRemoving.
- **D-05:** BindToClose handling -- `game:BindToClose()` to save all player data on server shutdown.
- **D-06:** Save interval -- 5 minutes (balances data safety with DataStore rate limits).
- **D-07:** XP per kill -- 100 XP. Tunable constant.
- **D-08:** Cash per kill -- $10. Tunable constant.
- **D-09:** Round completion bonus -- 50 XP + $5 for completing a round (even with 0 kills).
- **D-10:** Time-based rewards -- 25 XP + $2.50 every 2 minutes during active round gameplay while alive.
- **D-11:** Level progression curve -- Linear, 1000 XP per level (all levels).
- **D-12:** Level cap -- Unlimited.
- **D-13:** Reward constants -- All values as named constants at top of ProgressionService module.
- **D-14:** Stat menu access -- Tab key (PC), dedicated button (mobile). Toggle open/close.
- **D-15:** Stats to display -- Progression (Cash, Level, Current XP, XP to next level) + Session (Kills, Deaths, K/D, Time alive, Time dead) + Lifetime (Total kills, Total deaths, Lifetime K/D, Total playtime).
- **D-16:** Menu placement -- Center overlay with semi-transparent background panel.
- **D-17:** Mobile button -- Add stat menu button to mobile controls, only visible on mobile.

### Claude's Discretion
- DataStore error handling specifics -- retry count, retry delay, fallback behavior on repeated failures
- Stat menu styling -- colors, fonts, layout grid, transparency values
- K/D ratio display format -- decimal places, division by zero handling
- Time display format -- minutes:seconds vs hours:minutes vs human-readable
- Level-up visual feedback -- particle effect, sound, screen flash (not blocking for functionality)
- Session stat reset timing -- on respawn, round end, or never until disconnect

### Deferred Ideas (OUT OF SCOPE)
None -- discussion stayed within phase scope.

</user_constraints>

<phase_requirements>

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| DATA-01 | Player data (cash, level, XP, stats) saved to DataStore with pcall error handling | DataStore API patterns, pcall wrapping, retry with exponential backoff, data structure design |
| DATA-02 | Data auto-saves periodically and on player disconnect (including BindToClose) | 5-minute auto-save loop, PlayerRemoving hook, BindToClose with 30s timeout and parallel saves |
| PROG-01 | Player earns XP per kill and per round completed | ProgressionService with tunable constants, hook into kill events and round-end events |
| PROG-02 | Player levels up when XP threshold is reached | Linear 1000 XP/level check after every XP award, update Level leaderstats value |
| PROG-03 | Player earns cash per kill and bonus cash for round performance | Cash rewards via same hooks as XP, round completion bonus for participation |
| PROG-04 | Cash, level, and XP persist across sessions | DataService load on PlayerAdded, save on PlayerRemoving/BindToClose/auto-save |
| STAT-01 | Stat menu accessible during gameplay showing kills, deaths, time alive, cash, level, XP, time spent dead | StatMenuGui ScreenGui with Tab/button toggle, reads from leaderstats + RemoteEvent for lifetime data |
| STAT-02 | Post-game stat board displayed during intermission with round performance | Hook into round-end event, display session stats overlay (depends on Phase 5 round system -- implement the display component now, hook later) |
| STAT-03 | Scoreboard accessible via tab key / button showing all players, kills, deaths | In-game scoreboard listing all players with current session kills/deaths |

</phase_requirements>

## Project Constraints (from CLAUDE.md)

- **Platform:** Roblox Studio -- all code is Luau scripts within the Roblox data model
- **Architecture:** Client-server model (LocalScripts on client, Scripts on server, RemoteEvents for communication)
- **Storage:** Roblox DataStore API for persistence (rate limits, key size limits apply)
- **No ProfileService:** User explicitly chose raw DataStore API (D-01), overriding CLAUDE.md's recommendation
- **No Roact/React-lua:** Traditional ScreenGui/Frame hierarchy for UI
- **MCP tools required:** All code changes via Roblox Studio MCP tools (create_object, set_script_source, etc.) -- never write .lua files to disk
- **No git operations:** Code lives in Roblox Studio, not filesystem. Planning artifacts written to disk only.
- **Mobile-first:** UI must work on touchscreens, minimum 44x44px touch targets

## Standard Stack

### Core
| Library/API | Purpose | Why Standard |
|-------------|---------|--------------|
| DataStoreService | Persistence layer for player data | Only option for Roblox data persistence; user decision D-01 |
| GlobalDataStore:GetAsync/SetAsync | Load and save player data | Standard pattern for simple key-value persistence |
| pcall() | Error handling for DataStore operations | Required -- DataStore calls can fail due to network/throttling |
| game:BindToClose() | Save all data on server shutdown | Standard Roblox pattern; 30-second timeout for saves |
| Players.PlayerAdded/PlayerRemoving | Player lifecycle hooks | Standard Roblox events for load/save triggers |
| leaderstats (NumberValue) | Client-visible player stats | Standard Roblox pattern; auto-displays on leaderboard |

### Supporting
| API | Purpose | When to Use |
|-----|---------|-------------|
| task.spawn / task.wait | Auto-save loop and time-based reward loop | Periodic server-side operations |
| RunService:IsStudio() | Skip BindToClose in Studio testing | Prevent hanging during Studio test sessions |
| HttpService:JSONEncode/JSONDecode | Serialize complex data for DataStore | If storing nested tables (lifetime stats) |
| RemoteEvent | Send lifetime stats to client for stat menu | Client cannot access DataStore directly |
| UserInputService | Detect touch/keyboard for stat menu toggle | Platform-specific input handling |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Raw DataStore | ProfileService | Session locking, auto-retry -- overkill per user decision D-01 |
| SetAsync | UpdateAsync | Prevents race conditions but costs read+write budget; SetAsync fine for single-server-per-player |
| JSONEncode for nested data | Flat key structure | JSON is cleaner for complex data; flat keys hit 50-char key limit fast |

## Architecture Patterns

### Recommended Module Structure
```
game.ServerScriptService.RoundSystem.Modules/
  DataService        -- ModuleScript: DataStore load/save/auto-save
  ProgressionService -- ModuleScript: XP/cash awards, level-up logic
  LeaderstatService  -- (existing) Extend with Level and XP NumberValues

game.StarterGui/
  StatMenuGui        -- ScreenGui: stat overlay panel
    StatMenuScript   -- LocalScript: toggle, populate, update stats

game.ReplicatedStorage.Events/
  (existing RemoteEvent folder) -- Add ProgressionEvents or reuse existing
```

### Pattern 1: DataService Module
**What:** Server-side ModuleScript handling all DataStore operations with retry logic.
**When to use:** Any DataStore read/write operation.
**Key design:**
```lua
-- DataService pattern
local DataStoreService = game:GetService("DataStoreService")
local playerStore = DataStoreService:GetDataStore("PlayerData_v1")

-- Version the DataStore name so you can migrate data later
-- Key: tostring(player.UserId)
-- Value: JSON-encoded table of all player data

local DEFAULT_DATA = {
    Cash = 0,
    Level = 1,
    XP = 0,
    LifetimeKills = 0,
    LifetimeDeaths = 0,
    TotalPlaytime = 0,
}

-- pcall with retry
local function safeGet(key)
    local MAX_RETRIES = 3
    for attempt = 1, MAX_RETRIES do
        local success, result = pcall(function()
            return playerStore:GetAsync(key)
        end)
        if success then return result end
        if attempt < MAX_RETRIES then
            task.wait(attempt * 2) -- exponential backoff: 2s, 4s, 6s
        end
    end
    warn("DataStore GetAsync failed after retries for key: " .. key)
    return nil -- fallback to defaults
end
```

### Pattern 2: In-Memory Cache with Periodic Flush
**What:** Load data into a server-side Lua table on PlayerAdded, update in-memory, flush to DataStore periodically.
**When to use:** Always. Never read DataStore mid-session; always write from cache.
**Key design:**
```lua
-- Server-side player data cache
local playerDataCache = {} -- [userId] = { Cash=0, Level=1, ... }

-- On PlayerAdded: load from DataStore into cache, populate leaderstats
-- During gameplay: update cache only (instant, no yields)
-- On auto-save/PlayerRemoving/BindToClose: flush cache to DataStore
```

### Pattern 3: Leaderstats as Client-Readable Proxy
**What:** Keep leaderstats NumberValues in sync with server cache. Client reads leaderstats for real-time display (Cash, Level, XP).
**When to use:** For data the client needs to display continuously.
**Key insight:** Leaderstats auto-replicate to the client. Client uses `GetPropertyChangedSignal("Value")` for reactive updates. No RemoteEvents needed for these values.

### Pattern 4: RemoteEvent for Complex Client Data
**What:** Use a RemoteEvent to send lifetime stats (kills, deaths, playtime) to the client when the stat menu opens.
**When to use:** For data not stored in leaderstats (lifetime aggregates, session stats).
**Key insight:** Don't put everything in leaderstats -- only put values that need continuous display. Send the rest on-demand when the stat menu opens.

### Anti-Patterns to Avoid
- **Reading DataStore every frame/tick:** Load once on join, cache in memory, flush periodically
- **Saving on every kill/reward:** Batch changes and save periodically (5 min) or on disconnect
- **Client-side DataStore access:** DataStore is server-only; always use RemoteEvents to send data to client
- **Unsanitized data keys:** Always use `tostring(player.UserId)` -- never trust player-provided strings
- **Forgetting BindToClose:** Without it, server shutdowns lose all unsaved data since last auto-save
- **Not versioning DataStore name:** Use `PlayerData_v1` so future schema changes can migrate cleanly

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| DataStore retries | Custom retry loop from scratch each call | Shared retry wrapper function in DataService | Consistent retry logic, single place to adjust backoff |
| Session stat tracking | Manual timestamp comparisons | Simple counters incremented on events | Kills/deaths are discrete events, just count them |
| Level calculation | Complex XP curve formulas | `math.floor(totalXP / XP_PER_LEVEL) + 1` | Linear progression is trivial math -- don't overcomplicate |
| Time tracking | Manual os.clock() delta tracking | `tick()` or `os.clock()` stored on join, diff on save | Simple subtraction; Roblox provides time functions |

**Key insight:** The progression math in this phase is intentionally simple (linear XP, fixed rewards). Don't add complexity that the user didn't ask for.

## Common Pitfalls

### Pitfall 1: DataStore Throttling on Server Shutdown
**What goes wrong:** BindToClose tries to save all players sequentially; exceeds 30-second timeout.
**Why it happens:** Each save takes ~0.5-2 seconds with network latency. 30 players x 1.5s = 45 seconds > 30s limit.
**How to avoid:** Save all players in parallel using `task.spawn` for each save, then track completion with a counter or event. The BindToClose callback should yield until all spawned saves complete (or timeout hits).
**Warning signs:** Data loss on server shutdown, especially in populated servers.

### Pitfall 2: PlayerRemoving Race Condition
**What goes wrong:** Player leaves, PlayerRemoving fires, save starts -- but BindToClose also fires if server is shutting down, causing a double-save attempt on the same key.
**Why it happens:** BindToClose and PlayerRemoving can fire in quick succession during shutdown.
**How to avoid:** Track which players have already been saved in a `savedPlayers` set. Check before saving in BindToClose.

### Pitfall 3: Data Loss on First Join
**What goes wrong:** GetAsync returns nil for new players, code tries to index nil.
**Why it happens:** New players have no DataStore entry.
**How to avoid:** Always fall back to `DEFAULT_DATA` when GetAsync returns nil. Deep-copy the default table so modifications don't affect the template.

### Pitfall 4: Leaderstats Not Ready When Client Reads
**What goes wrong:** Client LocalScript tries to read leaderstats before DataService has loaded and populated them.
**Why it happens:** DataStore GetAsync yields; leaderstats NumberValues may not exist yet when client scripts run.
**How to avoid:** Client uses `player:WaitForChild("leaderstats")` then `leaderstats:WaitForChild("Cash")` with timeouts. This is already the established pattern from CurrencyDisplayScript.

### Pitfall 5: Studio Testing Without DataStore Access
**What goes wrong:** DataStore calls fail silently in Studio if API access is not enabled.
**Why it happens:** Studio requires "Enable Studio Access to API Services" in Game Settings > Security.
**How to avoid:** Check `RunService:IsStudio()` and either enable API access or provide mock data for testing. Warn in output if DataStore calls fail in Studio.

### Pitfall 6: Session Stats vs Lifetime Stats Confusion
**What goes wrong:** Session kills get saved as lifetime kills, or lifetime stats get reset on new session.
**Why it happens:** Mixing up which counters to increment vs which to persist.
**How to avoid:** Clear naming: `sessionKills` (reset on join, never saved) vs `lifetimeKills` (loaded from DataStore, incremented and saved). On kill: increment BOTH session and lifetime counters.

### Pitfall 7: Cash as Float Precision Issues
**What goes wrong:** $2.50 time rewards accumulate float imprecision (2.4999999... instead of 2.5).
**Why it happens:** IEEE 754 floating point arithmetic.
**How to avoid:** Store cash in cents (integer). $10 = 1000 cents, $2.50 = 250 cents. Display as dollars with formatting. OR just use whole numbers and adjust the reward values (e.g., $3 instead of $2.50).

## Code Examples

### DataStore Load with Retry and Defaults
```lua
-- Source: Roblox DataStore official docs pattern
local function loadPlayerData(player)
    local key = tostring(player.UserId)
    local data = safeGet(key)

    if data then
        -- JSONDecode if stored as string
        if type(data) == "string" then
            data = HttpService:JSONDecode(data)
        end
    end

    -- Merge with defaults (handles schema additions)
    local merged = {}
    for k, v in pairs(DEFAULT_DATA) do
        merged[k] = (data and data[k] ~= nil) and data[k] or v
    end

    playerDataCache[player.UserId] = merged
    return merged
end
```

### BindToClose Parallel Save
```lua
-- Source: Roblox BindToClose official docs
game:BindToClose(function()
    if RunService:IsStudio() then
        task.wait(1) -- Short wait in Studio, don't hang
        return
    end

    local players = Players:GetPlayers()
    local finished = 0

    for _, player in players do
        task.spawn(function()
            safeSave(player) -- pcall-wrapped SetAsync
            finished += 1
        end)
    end

    -- Wait for all saves or timeout
    local start = tick()
    while finished < #players and (tick() - start) < 25 do
        task.wait(0.1)
    end
end)
```

### Auto-Save Loop
```lua
-- 5-minute auto-save loop
local AUTO_SAVE_INTERVAL = 300 -- seconds

task.spawn(function()
    while true do
        task.wait(AUTO_SAVE_INTERVAL)
        for _, player in Players:GetPlayers() do
            task.spawn(function()
                safeSave(player)
            end)
        end
    end
end)
```

### XP Award with Level-Up Check
```lua
-- ProgressionService pattern
local XP_PER_KILL = 100
local CASH_PER_KILL = 10
local XP_PER_LEVEL = 1000

function ProgressionService.awardKill(player)
    local data = DataService.getPlayerData(player)
    if not data then return end

    -- Award XP and cash
    data.XP += XP_PER_KILL
    data.Cash += CASH_PER_KILL
    data.LifetimeKills += 1

    -- Session tracking (not persisted)
    local sessionData = sessionTracker[player.UserId]
    if sessionData then
        sessionData.Kills += 1
    end

    -- Check for level-up
    local newLevel = math.floor(data.XP / XP_PER_LEVEL) + 1
    if newLevel > data.Level then
        data.Level = newLevel
        -- Fire level-up event for visual feedback
    end

    -- Update leaderstats (replicates to client automatically)
    local leaderstats = player:FindFirstChild("leaderstats")
    if leaderstats then
        leaderstats.Cash.Value = data.Cash
        leaderstats.Level.Value = data.Level
        leaderstats.XP.Value = data.XP
    end
end
```

### Stat Menu Toggle (Client)
```lua
-- StatMenuScript (LocalScript) pattern
local UIS = game:GetService("UserInputService")
local frame = script.Parent:WaitForChild("MainFrame")
local isOpen = false

local function toggleMenu()
    isOpen = not isOpen
    frame.Visible = isOpen
    if isOpen then
        -- Request lifetime stats from server
        remoteEvent:FireServer("RequestStats")
    end
end

-- PC: Tab key
UIS.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.Tab then
        toggleMenu()
    end
end)

-- Mobile: Button (only if touch enabled)
if UIS.TouchEnabled then
    local mobileButton = -- reference to mobile stat button
    mobileButton.Activated:Connect(toggleMenu)
end
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| DataStore v1 | DataStore v2 (current) | 2022 | v2 supports versioning, metadata; v1 still works fine for simple use |
| BodyVelocity for knockback | LinearVelocity | 2022 | Not relevant to this phase but noted in CLAUDE.md |
| Flat DataStore keys per stat | Single JSON blob per player | Standard practice | Reduces API calls; one GetAsync loads everything |

**Deprecated/outdated:**
- `DataStore:GetAsync()` with direct value storage is fine but consider JSON encoding for structured data
- BindToClose has always had a 30-second limit; this hasn't changed

## DataStore Rate Limits Reference

| Operation | Base Limit/min | Per Player Added | With 10 Players |
|-----------|---------------|------------------|-----------------|
| Get/Set/Remove | 60 | +10 | 160 |
| Ordered Get | 5 | +2 | 25 |
| Ordered Set | 30 | +5 | 80 |

- **Data value max:** 4 MB per key (more than enough for player data)
- **Key name max:** 50 characters (`tostring(UserId)` is well under this)
- **BindToClose timeout:** 30 seconds
- **Per-key write throughput:** 4 MB/min (not a concern for small player data)
- **Throttling queue:** Max 30 queued requests per type; beyond that, requests are dropped (error 301-306)

**Rate limit math for 5-minute auto-save with 10 players:**
- 10 SetAsync calls every 5 minutes = 2 calls/min (well under 160 limit)
- PlayerRemoving adds 1 extra call per departure
- BindToClose adds up to 10 parallel calls (burst, but within budget)

## Open Questions

1. **STAT-02 (Post-game stat board) timing**
   - What we know: Requires display during intermission after round ends
   - What's unclear: Phase 5 builds the round system with intermission. STAT-02 may need to be a placeholder or partial implementation.
   - Recommendation: Build the stat board UI component now. Wire it to display on a RemoteEvent signal. Phase 5 will fire that signal during intermission. This avoids blocking and keeps the component ready.

2. **STAT-03 (Scoreboard) vs STAT-01 (Stat menu) overlap**
   - What we know: STAT-01 is a personal stat menu (your stats). STAT-03 is a multi-player scoreboard (all players).
   - What's unclear: Whether these should be the same UI with tabs, or separate UIs.
   - Recommendation: Combine into one UI with two sections/tabs: "My Stats" (STAT-01) and "Scoreboard" (STAT-03). Both triggered by Tab key. Reduces UI clutter and feels natural (Tab = scoreboard in most FPS games).

3. **Session stat reset timing**
   - What we know: User left this at Claude's discretion.
   - What's unclear: When exactly session stats should reset.
   - Recommendation: Session stats track from the moment the player joins the server until they leave. They never reset mid-session. This is the simplest approach and matches player expectations ("this session" = "since I joined").

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Manual in-game testing (Roblox Studio Play Solo + Play Server) |
| Config file | None -- Roblox has no external test framework |
| Quick run command | Play Solo in Roblox Studio (F5) |
| Full suite command | Play Server with 2+ test clients in Studio |

### Phase Requirements to Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| DATA-01 | Player data saves to DataStore with error handling | manual | Play Solo, check Output for save success logs | N/A |
| DATA-02 | Auto-save every 5 min + save on disconnect + BindToClose | manual | Play Solo, wait 5 min for auto-save log; stop play to trigger PlayerRemoving | N/A |
| PROG-01 | XP awarded per kill and round completion | manual | Kill another player, check XP leaderstats value changed | N/A |
| PROG-02 | Level up when XP threshold reached | manual | Award enough kills to cross 1000 XP, verify Level increments | N/A |
| PROG-03 | Cash awarded per kill and round bonus | manual | Kill player, check Cash value; complete round, check bonus | N/A |
| PROG-04 | Cash/Level/XP persist across sessions | manual | Play, earn stats, leave, rejoin, verify values restored | N/A |
| STAT-01 | Stat menu shows player metrics | manual | Press Tab, verify all stat fields populated correctly | N/A |
| STAT-02 | Post-game stat board during intermission | manual | Complete a round, verify stat board appears (partial -- needs Phase 5) | N/A |
| STAT-03 | Scoreboard shows all players | manual | Press Tab, verify all players listed with kills/deaths | N/A |

### Sampling Rate
- **Per task:** Play Solo test after each major code change
- **Per wave:** Play Server with 2 test clients to verify multi-player behavior
- **Phase gate:** Full Play Server test verifying all 9 requirements

### Wave 0 Gaps
None -- Roblox testing is inherently manual via Studio. No test framework to install.

## Sources

### Primary (HIGH confidence)
- Roblox DataStoreService official docs (create.roblox.com/docs/cloud-services/data-stores) -- API patterns, rate limits, error codes
- Roblox DataModel:BindToClose official docs -- 30-second timeout, parallel save pattern
- Roblox DataStore error codes and limits page -- rate limits per minute, data size constraints, throttling behavior

### Secondary (MEDIUM confidence)
- CONTEXT.md code_context section -- existing code patterns from LeaderstatService, CurrencyDisplayScript, MainServer integration points
- Prior phase CONTEXT files -- established architecture patterns (service modules, leaderstats, RemoteEvents)

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- DataStoreService is well-documented, patterns are standard Roblox
- Architecture: HIGH -- follows established project patterns (service modules, leaderstats), straightforward data flow
- Pitfalls: HIGH -- DataStore pitfalls are well-known in Roblox development community
- Progression math: HIGH -- linear XP, fixed rewards, trivial calculations
- UI patterns: HIGH -- follows existing project patterns (CurrencyDisplayScript, HealthDisplayGui)

**Research date:** 2026-03-30
**Valid until:** 2026-04-30 (stable Roblox APIs, no upcoming breaking changes)
