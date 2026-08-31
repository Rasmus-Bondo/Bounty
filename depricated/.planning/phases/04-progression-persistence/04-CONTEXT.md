# Phase 4: Progression & Persistence - Context

**Gathered:** 2026-03-30
**Status:** Ready for planning

<domain>
## Phase Boundary

Player data persistence and progression systems — implement DataStore saving for cash/level/XP, add XP and cash rewards for kills and round performance, create level progression with thresholds, and build a stat menu showing player metrics during gameplay.

Requirements: DATA-01, DATA-02, PROG-01, PROG-02, PROG-03, PROG-04, STAT-01, STAT-02, STAT-03

</domain>

<decisions>
## Implementation Decisions

### Data Persistence Strategy
- **D-01:** Use raw DataStore API (not ProfileService) — small game, session locking not needed for now. Simple pcall error handling sufficient.
- **D-02:** Save comprehensive data structure — Cash, Level, XP + session kills, session deaths, session time alive, session time dead + lifetime kills, lifetime deaths, total playtime. Allows full stat menu display.
- **D-03:** Data key format — Use UserId as DataStore key (`player.UserId`). Standard Roblox pattern.

### Save Triggers & Frequency
- **D-04:** Periodic auto-save + disconnect — Auto-save every 5 minutes during gameplay + save on PlayerRemoving event.
- **D-05:** BindToClose handling — Use game:BindToClose() to save all player data on server shutdown. Critical for preventing data loss.
- **D-06:** Save interval — 5 minutes balances data safety with DataStore rate limits (12 saves/hour/player max).

### Reward Formulas
- **D-07:** XP per kill — 100 XP per kill. Make this value easily tunable (constant at top of module).
- **D-08:** Cash per kill — $10 per kill. Make this value easily tunable (constant at top of module).
- **D-09:** Round completion bonus — 50 XP + $5 for completing a round (even with 0 kills). Rewards participation.
- **D-10:** Time-based rewards — 25 XP + $2.50 every 2 minutes during active round gameplay. Passive income for engagement. Tick every 2 minutes while player is alive and round is active.
- **D-11:** Level progression curve — Linear progression. Each level requires 1000 XP (consistent across all levels). Level 1→2 = 1000 XP, Level 2→3 = 1000 XP, etc.
- **D-12:** Level cap — Unlimited levels. Players can progress forever (Level 1, 2, 3... 999+).
- **D-13:** Reward constants — Store all XP/cash values as constants at top of ProgressionService for easy tuning: `XP_PER_KILL`, `CASH_PER_KILL`, `ROUND_BONUS_XP`, `ROUND_BONUS_CASH`, `TIME_REWARD_XP`, `TIME_REWARD_CASH`, `TIME_REWARD_INTERVAL`, `XP_PER_LEVEL`.

### Stat Menu UI & Access
- **D-14:** Access method — Tab key on PC, dedicated stat button on mobile. Toggle open/close.
- **D-15:** Stats to display — Everything including lifetime:
  - **Progression:** Cash, Level, Current XP, XP to next level
  - **Session stats:** Kills (this session), Deaths (this session), K/D ratio (this session), Time alive (this session), Time dead (this session)
  - **Lifetime stats:** Total kills (all-time), Total deaths (all-time), Lifetime K/D ratio, Total playtime
- **D-16:** Menu placement — Center overlay with semi-transparent background panel. Standard menu UI pattern.
- **D-17:** Mobile button — Add stat menu button to mobile controls (near other action buttons). Only visible on mobile (UserInputService.TouchEnabled check).

### Claude's Discretion
- DataStore error handling specifics — Retry count, retry delay, fallback behavior on repeated failures
- Stat menu styling — Colors, fonts, layout grid, transparency values
- K/D ratio display format — Decimal places, handling division by zero (0 deaths)
- Time display format — Minutes:seconds vs hours:minutes, or human-readable strings
- Level-up visual feedback — Particle effect, sound, screen flash, etc. (not blocking for functionality)
- Session stat reset — When session stats reset (on respawn, on round end, or never until disconnect)

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project Documents
- `.planning/PROJECT.md` — Project vision, constraints, mobile-first design
- `.planning/REQUIREMENTS.md` — Full v1 requirements (DATA-01, DATA-02, PROG-01, PROG-02, PROG-03, PROG-04, STAT-01, STAT-02, STAT-03 are this phase)
- `.planning/ROADMAP.md` — Phase 4 goals and success criteria
- `CLAUDE.md` — Technology stack, Persistence section (ProfileService vs DataStore trade-offs), DataStore API patterns

### Prior Phase Context
- `.planning/phases/01-foundation-architecture/01-CONTEXT.md` — Service ModuleScript architecture pattern, RemoteEvent consolidation
- `.planning/phases/02-combat-audio-polish/02-CONTEXT.md` — Combat systems context (kill detection, reward triggers)
- `.planning/phases/03-mobile-input-systems/03-CONTEXT.md` — Mobile UI patterns, touch button placement, UserInputService.TouchEnabled detection

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **LeaderstatService** (game.ServerScriptService.RoundSystem.Modules.LeaderstatService): Creates leaderstats folder with Cash NumberValue. Pattern to extend for Level and XP values.
- **CurrencyDisplayScript** (game.StarterGui.CurrencyGui.CurrencyDisplayScript): Client-side cash display that reads from leaderstats.Cash. Pattern to follow for XP/Level displays.
- **MainServer** (game.ServerScriptService.RoundSystem.MainServer): Initializes all services. DataService will be required and initialized here following existing pattern.

### Established Patterns
- **Service ModuleScript pattern** (Phase 1): Create DataService and ProgressionService as ModuleScripts under ServerScriptService.RoundSystem.Modules
- **PlayerAdded/PlayerRemoving** (LeaderstatService lines 6-15, 17-28): Existing player lifecycle hooks. Add DataService hooks here for load/save.
- **Leaderstats folder** (LeaderstatService lines 7-14): Player.leaderstats with NumberValue children. Add Level and XP NumberValues alongside existing Cash.
- **GetPropertyChangedSignal** (CurrencyDisplayScript line 21): Client pattern for reactive UI updates when leaderstats values change.

### Integration Points
- **LeaderstatService.Initialize()**: Extend to create Level and XP NumberValues in leaderstats folder
- **MainServer**: Require DataService and ProgressionService, call Init() on both
- **GunServer fireShot() success**: Hook ProgressionService.awardKill(killer) after confirmed hit
- **RoundController round end**: Hook ProgressionService.awardRoundCompletion(player) for all active players
- **MobileControlsGui** (from Phase 3): Add stat menu button to ActionFrame for mobile
- **StarterGui**: Create new StatMenuGui ScreenGui for the stat overlay

### Current Limitations
- No DataStore usage yet — completely new system
- No XP or Level tracking — need to add to leaderstats
- No stat menu UI — need to create from scratch
- No kill event tracking for progression — need to connect to combat system
- No round completion tracking — need to connect to RoundController

</code_context>

<specifics>
## Specific Ideas

- LeaderstatService already creates leaderstats folder with Cash NumberValue at lines 7-14 — extend this to add Level (starts at 1) and XP (starts at 0) NumberValues
- CurrencyDisplayScript pattern (lines 11-21) shows how to create reactive UI: `WaitForChild` leaderstats value, `GetPropertyChangedSignal("Value"):Connect` for updates
- Kill tracking: GunServer's `fireShot()` function (lines 352-467) validates hits and calls `handleEliminatePlayer(player)` (line 447) — hook ProgressionService here
- 5-minute auto-save interval: Use `task.spawn` with `while true` loop and `task.wait(300)` in DataService.Init()
- Time-based rewards: Similar loop pattern with `task.wait(120)` (2 minutes), but only tick when player is alive and round is active
- Mobile stat button: Add to ActionFrame in MobileControlsGui (created in Phase 3) near existing buttons (ShootButton, ReloadButton, SprintButton, CrouchButton)

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 04-progression-persistence*
*Context gathered: 2026-03-30*
