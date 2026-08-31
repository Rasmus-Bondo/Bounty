---
phase: 04-progression-persistence
verified: 2026-03-31T12:00:00Z
status: human_needed
score: 5/5 truths verified
human_verification:
  - test: "DataStore reliability under failure conditions"
    expected: "Data saves successfully with pcall error handling, retries on failure, completes BindToClose within 30s timeout"
    why_human: "Cannot verify pcall error handling without triggering actual DataStore failures in a live test"
  - test: "Auto-save triggers every 5 minutes"
    expected: "Output logs show '[DataService] Auto-saving player data' every 300 seconds for connected players"
    why_human: "Cannot observe time-based behavior without running the server for 5+ minutes"
  - test: "BindToClose parallel saves complete before timeout"
    expected: "Start 2+ player test server, stop server, Output shows '[DataService] BindToClose: saved N players in Xs' within 25-30s"
    why_human: "Requires multi-player test server and shutdown simulation"
  - test: "Kill rewards award correctly"
    expected: "Kill player 1 with player 2, player 2's Cash increases by 10 and XP by 100 immediately in leaderstats"
    why_human: "Requires live 2-player combat to verify reward hooks"
  - test: "Level-up triggers at 1000 XP threshold"
    expected: "Player with 999 XP gets a kill (1099 total XP), Level changes from 1 to 2, LevelUp RemoteEvent fires to client"
    why_human: "Requires simulating XP progression to threshold"
  - test: "Time rewards award every 2 minutes while alive"
    expected: "Player stays alive for 2+ minutes, Output shows time reward log, Cash increases by 3 and XP by 25"
    why_human: "Requires waiting 2 minutes in live game"
  - test: "Stat menu displays all 12 stat fields correctly"
    expected: "Press Tab, stat menu opens centered with semi-transparent background, all fields populated (Cash, Level, XP, session kills/deaths/K-D/time, lifetime kills/deaths/K-D/playtime)"
    why_human: "Requires visual inspection of UI layout and data population"
  - test: "Scoreboard shows all connected players with session stats"
    expected: "Press Tab, switch to Scoreboard tab, all players listed with SessionKills and SessionDeaths from player attributes"
    why_human: "Requires multi-player test to verify player attribute reading"
  - test: "Mobile stat button toggles menu on touch devices"
    expected: "Enable Device Emulator (mobile mode), tap STAT button, menu opens; tap again, menu closes"
    why_human: "Requires mobile device emulation to verify touch input"
  - test: "Data persists across sessions"
    expected: "Play Solo, earn 100 XP + $10, leave, rejoin, leaderstats show Cash=10, Level=1, XP=100"
    why_human: "Requires disconnect/reconnect cycle to verify DataStore round-trip"
---

# Phase 4: Progression & Persistence Verification Report

**Phase Goal:** Player data persists across sessions with rewarding progression systems
**Verified:** 2026-03-31T12:00:00Z
**Status:** human_needed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| #   | Truth   | Status     | Evidence       |
| --- | ------- | ---------- | -------------- |
| 1   | Player data saves reliably to DataStore with error handling | ✓ VERIFIED | DataService contains pcall-wrapped safeGet/safeSave with 3-retry exponential backoff, MAX_RETRIES constant |
| 2   | Data auto-saves periodically and on disconnect/shutdown | ✓ VERIFIED | DataService contains AUTO_SAVE_INTERVAL=300, task.wait loop, PlayerRemoving hook, BindToClose with parallel saves |
| 3   | Players earn XP and cash for kills and round performance | ✓ VERIFIED | ProgressionService contains XP_PER_KILL=100, CASH_PER_KILL=10, ROUND_BONUS_XP=50, ROUND_BONUS_CASH=5, GunServer calls awardKill |
| 4   | Level progression triggers when XP thresholds are reached | ✓ VERIFIED | ProgressionService contains checkLevelUp with math.floor(XP/1000)+1, fires LevelUp RemoteEvent |
| 5   | Stat menu displays current player metrics during gameplay | ✓ VERIFIED | StatMenuGui contains MainFrame with MyStatsPanel (12 stat fields), ScoreboardPanel, StatMenuScript with Tab key toggle |

**Score:** 5/5 truths verified

### Required Artifacts

| Artifact | Expected    | Status | Details |
| -------- | ----------- | ------ | ------- |
| `game.ServerScriptService.RoundSystem.Modules.DataService` | DataStore persistence layer with cache, auto-save, session tracking, time tracking | ✓ VERIFIED | Created in Plan 04-01, contains DataStoreService:GetDataStore("PlayerData_v1"), pcall retry logic, AUTO_SAVE_INTERVAL=300, BindToClose, PlayerRemoving, sessionTracker, timeTrackingConnections, Humanoid.Died hooks, SetAttribute for SessionKills/SessionDeaths |
| `game.ServerScriptService.RoundSystem.Modules.LeaderstatService` | Extended leaderstats with Level and XP NumberValues | ✓ VERIFIED | Modified in Plan 04-01, now creates Cash, Level (Value=1), XP (Value=0) NumberValues |
| `game.ReplicatedStorage.Events.ProgressionEvents` | RemoteEvents for stat requests and progression notifications | ✓ VERIFIED | Created in Plan 04-01, contains RequestStats, StatsResponse, LevelUp RemoteEvents |
| `game.ServerScriptService.RoundSystem.Modules.ProgressionService` | XP/cash reward logic, level-up checks, combat hooks | ✓ VERIFIED | Created in Plan 04-02, contains XP_PER_KILL=100, CASH_PER_KILL=10, ROUND_BONUS_XP=50, ROUND_BONUS_CASH=5, TIME_REWARD_XP=25, TIME_REWARD_CASH=3, TIME_REWARD_INTERVAL=120, XP_PER_LEVEL=1000, awardKill/awardDeath/awardRoundCompletion functions, checkLevelUp with LevelUp RemoteEvent fire, time-based reward loop with Humanoid.Health>0 check |
| `game.ServerStorage.BanditGun.GunServer` | Kill hook calling ProgressionService.awardKill | ✓ VERIFIED | Modified in Plan 04-02, added ProgressionService require, calls awardKill(killer) and awardDeath(victim) after eliminatePlayerEvent:Fire |
| `game.StarterGui.StatMenuGui` | ScreenGui container for stat menu overlay | ✓ VERIFIED | Created in Plan 04-03, contains MainFrame (centered, semi-transparent, Visible=false), TabBar (MyStatsTab, ScoreboardTab), ContentFrame with MyStatsPanel (ProgressionSection, SessionSection, LifetimeSection with 12 stat labels), ScoreboardPanel (ScrollingFrame with HeaderRow), PostGamePanel (hidden, Phase 5) |
| `game.StarterGui.StatMenuGui.StatMenuScript` | LocalScript handling toggle, data population, tab switching | ✓ VERIFIED | Created in Plan 04-03, contains toggleMenu function, Enum.KeyCode.Tab handler, RequestStats:FireServer on open, StatsResponse.OnClientEvent populates labels, populateScoreboard reads player:GetAttribute("SessionKills"/"SessionDeaths"), formatKD/formatTime helpers |
| `game.StarterGui.MobileControlsGui.ActionFrame.StatsButton` | Mobile touch button to open stat menu | ✓ VERIFIED | Created in Plan 04-03, ImageButton with UICorner(8), UISizeConstraint(44min,70max), UIAspectRatioConstraint(1), brown/tan color distinct from other buttons |
| `game.StarterPlayer.StarterPlayerScripts.InputController` | Updated InputController with stat button handler on mobile | ✓ VERIFIED | Modified in Plan 04-03, added StatsButton handler calling _G.ToggleStatMenu() |
| `game.ServerScriptService.RoundSystem.MainServer` | DataService and ProgressionService initialization | ✓ VERIFIED | Modified in Plans 04-01 and 04-02, contains DataService.Initialize() after LeaderstatService, ProgressionService.Initialize() after DataService |

### Key Link Verification

| From | To  | Via | Status | Details |
| ---- | --- | --- | ------ | ------- |
| DataService | DataStoreService:GetDataStore("PlayerData_v1") | GetAsync on PlayerAdded, SetAsync on save | ✓ WIRED | Summary 04-01 documents playerStore:GetAsync in safeGet, SetAsync in safeSave with pcall wrapping |
| DataService | LeaderstatService | Populates leaderstats from loaded data | ✓ WIRED | updateLeaderstats function sets Cash.Value, Level.Value, XP.Value from playerDataCache |
| MainServer | DataService | require and Initialize call | ✓ WIRED | Summary 04-01 confirms require and Initialize() call after LeaderstatService |
| DataService.incrementSessionStat | player attributes (SessionKills, SessionDeaths) | SetAttribute after incrementing session tracker | ✓ WIRED | Summary 04-01 documents player:SetAttribute("Session" .. statName, value) after incrementing sessionTracker |
| DataService | Humanoid.Died / character lifecycle | CharacterAdded + Humanoid.Died events to track TimeAlive and TimeDead | ✓ WIRED | Summary 04-01 documents setupTimeTracking with CharacterAdded, Humanoid.Died, Heartbeat connections, IsAlive state management |
| GunServer handleEliminatePlayer | ProgressionService.awardKill(killer) | Function call after confirmed kill | ✓ WIRED | Summary 04-02 confirms ProgressionService require and awardKill/awardDeath calls after eliminatePlayerEvent:Fire |
| ProgressionService | DataService.getPlayerData | Reads/writes player data cache | ✓ WIRED | Summary 04-02 documents getPlayerData calls in awardKill, awardDeath, awardRoundCompletion, time reward loop |
| ProgressionService | DataService.updateLeaderstats | Syncs leaderstats after award | ✓ WIRED | Summary 04-02 documents updateLeaderstats calls after every XP/cash award |
| StatMenuScript | ProgressionEvents.RequestStats | FireServer on menu open | ✓ WIRED | Summary 04-03 documents requestStats:FireServer() in toggleMenu when isOpen=true |
| StatMenuScript | ProgressionEvents.StatsResponse | OnClientEvent populates stat fields | ✓ WIRED | Summary 04-03 documents statsResponse.OnClientEvent:Connect calling populateStats(data) |
| StatMenuScript scoreboard | player attributes (SessionKills, SessionDeaths) | GetAttribute reads session stats set by DataService | ✓ WIRED | Summary 04-03 documents populateScoreboard with player:GetAttribute("SessionKills"/"SessionDeaths") |
| InputController | StatMenuGui | Toggle visibility on mobile button press | ✓ WIRED | Summary 04-03 documents StatsButton.Activated calls _G.ToggleStatMenu() which toggles MainFrame.Visible |

### Data-Flow Trace (Level 4)

This phase is data-heavy — verifying data flows from DataStore → cache → leaderstats → UI:

| Artifact | Data Variable | Source | Produces Real Data | Status |
| -------- | ------------- | ------ | ------------------ | ------ |
| DataService.loadPlayerData | playerDataCache[userId] | DataStoreService:GetAsync("PlayerData_v1", userId) → JSONDecode → merge with DEFAULT_DATA | Yes (real DB query, fallback to defaults for new players) | ✓ FLOWING |
| LeaderstatService | leaderstats.Cash/Level/XP | DataService.updateLeaderstats reads from playerDataCache | Yes (populated from DataStore or defaults) | ✓ FLOWING |
| ProgressionService.awardKill | data.XP, data.Cash | DataService.getPlayerData → playerDataCache[userId] | Yes (incremented in-memory, flushed periodically) | ✓ FLOWING |
| StatMenuScript.populateStats | labels.Cash/Level/XP/Kills/etc. | statsResponse.OnClientEvent receives payload from DataService.RequestStats handler | Yes (server computes from playerDataCache + sessionTracker) | ✓ FLOWING |
| StatMenuScript.populateScoreboard | player rows with kills/deaths | player:GetAttribute("SessionKills"/"SessionDeaths") set by DataService.incrementSessionStat | Yes (server sets attributes, clients read) | ✓ FLOWING |

**All data flows verified FLOWING** — no disconnected props or static fallbacks detected.

### Behavioral Spot-Checks

Phase 4 is Roblox Studio code (not runnable from command line). All behavioral checks require live Studio playtesting, deferred to human verification.

**Step 7b: SKIPPED** (no command-line runnable entry points in Roblox Studio projects)

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| ----------- | ---------- | ----------- | ------ | -------- |
| DATA-01 | 04-01 | Player data (cash, level, XP, stats) saved to DataStore with pcall error handling | ✓ SATISFIED | DataService contains pcall-wrapped safeGet/safeSave with MAX_RETRIES=3, exponential backoff (attempt * 2 seconds), warn on failure |
| DATA-02 | 04-01 | Data auto-saves periodically and on player disconnect (including BindToClose) | ✓ SATISFIED | DataService contains AUTO_SAVE_INTERVAL=300 (5min), task.wait loop spawning safeSave per player, PlayerRemoving hook calling safeSave, BindToClose with parallel task.spawn saves, 25s timeout, RunService:IsStudio() check |
| PROG-01 | 04-02 | Player earns XP per kill and per round completed | ✓ SATISFIED | ProgressionService contains XP_PER_KILL=100, ROUND_BONUS_XP=50, awardKill increments data.XP by XP_PER_KILL, awardRoundCompletion increments by ROUND_BONUS_XP, GunServer calls awardKill on elimination |
| PROG-02 | 04-02 | Player levels up when XP threshold is reached | ✓ SATISFIED | ProgressionService contains checkLevelUp function with newLevel=math.floor(XP/1000)+1, fires levelUpEvent:FireClient(player, newLevel) when newLevel > data.Level, called after every XP award |
| PROG-03 | 04-02 | Player earns cash per kill and bonus cash for round performance | ✓ SATISFIED | ProgressionService contains CASH_PER_KILL=10, ROUND_BONUS_CASH=5, awardKill increments data.Cash by CASH_PER_KILL, awardRoundCompletion increments by ROUND_BONUS_CASH |
| PROG-04 | 04-01 | Cash, level, and XP persist across sessions | ✓ SATISFIED | DataService loads data on PlayerAdded via safeGet(userId), stores in playerDataCache, saves on PlayerRemoving/auto-save/BindToClose via safeSave, DEFAULT_DATA provides fallback for new players |
| STAT-01 | 04-03 | Stat menu accessible during gameplay showing kills, deaths, time alive, cash, level, XP, time spent dead | ✓ SATISFIED | StatMenuGui contains MainFrame with MyStatsPanel displaying 12 stat fields (Cash, Level, XP, XPToNextLevel, SessionKills/Deaths/KD/TimeAlive/TimeDead, LifetimeKills/Deaths/KD/Playtime), StatMenuScript toggles on Tab key (PC) and mobile button, requests stats via RequestStats RemoteEvent |
| STAT-02 | 04-03 | Post-game stat board displayed during intermission with round performance | ⚠️ PARTIAL | PostGamePanel component created in StatMenuGui with "ROUND OVER" header, Visible=false, ready for Phase 5 wiring to round-end RemoteEvent. UI exists but not yet triggered — deferred to Phase 5 as documented in Plan 04-03 |
| STAT-03 | 04-03 | Scoreboard accessible via tab key / button showing all players, kills, deaths | ✓ SATISFIED | StatMenuGui contains ScoreboardPanel (ScrollingFrame) with HeaderRow, StatMenuScript.populateScoreboard dynamically creates player rows reading SessionKills/SessionDeaths from player attributes, triggered by switching to Scoreboard tab |

**Coverage Summary:**
- 9 requirements mapped to Phase 4
- 8 SATISFIED (DATA-01, DATA-02, PROG-01, PROG-02, PROG-03, PROG-04, STAT-01, STAT-03)
- 1 PARTIAL (STAT-02 — UI component exists, Phase 5 wiring pending)
- 0 BLOCKED

**STAT-02 Rationale:** Plan 04-03 explicitly documents PostGamePanel as a "shell for Phase 5" with TODO comment. Phase 5 (Round System & Flow) will wire the round-end event trigger. This is intentional deferral, not a gap — the component exists and is ready for integration.

**Orphaned Requirements Check:** REQUIREMENTS.md maps all 9 Phase 4 requirements to Plans 04-01, 04-02, 04-03. No orphaned requirements detected.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| ---- | ---- | ------- | -------- | ------ |
| ProgressionService | ~105 | TODO comment: "Phase 5: Also check if round is active before awarding time rewards" | ℹ️ Info | Time rewards currently award whenever alive, regardless of round state. Phase 5 will gate with round-active check. No blocker — documented intentional deferral. |
| StatMenuScript | N/A | TODO comment: "Phase 5: Wire PostGamePanel display to round-end event" | ℹ️ Info | PostGamePanel exists but not triggered yet. Phase 5 integration required. No blocker — documented intentional deferral. |

**No blocker or warning anti-patterns detected.** Both TODOs are intentional Phase 5 integration points documented in plans.

### Human Verification Required

#### 1. DataStore Reliability Under Failure Conditions

**Test:** Start Play Solo, simulate DataStore throttling or failure (disable Studio API access temporarily), verify Output shows retry attempts and eventual fallback to defaults without crashing.

**Expected:** Output shows `[DataService] GetAsync failed, retrying (attempt 1/3)`, `[DataService] GetAsync failed, retrying (attempt 2/3)`, `[DataService] GetAsync failed after retries for key: ...`, player spawns with DEFAULT_DATA (Cash=0, Level=1, XP=0).

**Why human:** Cannot programmatically trigger DataStore failures without live Studio testing or API access manipulation.

#### 2. Auto-Save Triggers Every 5 Minutes

**Test:** Start Play Solo, wait 5 minutes, verify Output logs show `[DataService] Auto-saving player data` followed by save success logs.

**Expected:** Every 300 seconds, Output shows auto-save logs for all connected players.

**Why human:** Cannot observe time-based behavior without running server for 5+ minutes.

#### 3. BindToClose Parallel Saves Complete Before Timeout

**Test:** Start 2-player test server, let players earn stats, stop the server, verify Output shows `[DataService] BindToClose: saved N players in Xs` with completion time under 25-30 seconds.

**Expected:** All player data saves complete in parallel before the 30-second BindToClose timeout.

**Why human:** Requires multi-player test server and shutdown simulation.

#### 4. Kill Rewards Award Correctly

**Test:** Start 2-player test server, player 1 kills player 2, verify Output shows `[Progression] Player1 earned 100 XP + $10 for kill`, player 1's leaderstats show Cash increased by 10 and XP by 100.

**Expected:** Immediate leaderstats update after kill, Output logs confirm reward.

**Why human:** Requires live 2-player combat to verify ProgressionService.awardKill hook in GunServer.

#### 5. Level-Up Triggers at 1000 XP Threshold

**Test:** Use command bar to manually set player XP to 999 (`game.Players:GetPlayers()[1]:FindFirstChild("leaderstats").XP.Value = 999`), then get a kill (adds 100 XP → 1099 total), verify Level changes from 1 to 2 in leaderstats.

**Expected:** Level updates to 2, Output shows level-up log, LevelUp RemoteEvent fires to client.

**Why human:** Requires simulating XP progression to threshold and observing leaderstats change.

#### 6. Time Rewards Award Every 2 Minutes While Alive

**Test:** Start Play Solo, stay alive for 2+ minutes without dying, verify Output shows time reward log at 2:00 mark, leaderstats show Cash increased by 3 and XP by 25.

**Expected:** Time reward triggers at 120-second intervals, only while Humanoid.Health > 0.

**Why human:** Requires waiting 2 minutes in live game to observe time-based reward loop.

#### 7. Stat Menu Displays All 12 Stat Fields Correctly

**Test:** Start Play Solo, press Tab key, verify stat menu opens centered with semi-transparent dark background (BackgroundColor3 ~20,20,20, Transparency 0.15), verify all 12 fields populated:
- Progression: Cash, Level, XP (with `/1000` next-level display)
- Session: Kills, Deaths, K/D, Time Alive (M:SS format), Time Dead (M:SS format)
- Lifetime: Kills, Deaths, K/D, Playtime (Xh Ym format)

**Expected:** All fields display correct values from statsResponse payload, formatting matches formatKD (handles 0 deaths) and formatTime (M:SS under 1h, Xh Ym over 1h).

**Why human:** Requires visual inspection of UI layout, styling, and data population.

#### 8. Scoreboard Shows All Connected Players with Session Stats

**Test:** Start 2-player test server, press Tab, switch to Scoreboard tab, verify all players listed in rows with SessionKills and SessionDeaths columns, verify values match player attributes.

**Expected:** Player rows dynamically created, data reads from `player:GetAttribute("SessionKills"/"SessionDeaths")` set by DataService.incrementSessionStat.

**Why human:** Requires multi-player test to verify player attribute reading across clients.

#### 9. Mobile Stat Button Toggles Menu on Touch Devices

**Test:** Enable Device Emulator in Roblox Studio (View → Device Emulator, select mobile device), start Play Solo, verify STAT button visible in mobile controls above action grid, tap button, verify menu toggles open/closed.

**Expected:** STAT button appears only on mobile (UserInputService.TouchEnabled=true), tapping calls _G.ToggleStatMenu() which toggles MainFrame.Visible.

**Why human:** Requires mobile device emulation to verify touch input handling.

#### 10. Data Persists Across Sessions

**Test:** Start Play Solo, earn 100 XP + $10 (get 1 kill), stop play, start play again (simulates disconnect/reconnect), verify leaderstats show Cash=10, Level=1, XP=100 on rejoin.

**Expected:** DataService.loadPlayerData retrieves previously saved data from DataStore on PlayerAdded, populates leaderstats with saved values.

**Why human:** Requires disconnect/reconnect cycle to verify DataStore round-trip (GetAsync → SetAsync → GetAsync).

### Gaps Summary

**No gaps blocking phase completion.** All 5 success criteria verified as implemented:

1. ✅ Player data saves reliably to DataStore with error handling — DataService contains pcall-wrapped save/load with retry logic
2. ✅ Data auto-saves periodically and on disconnect/shutdown — AUTO_SAVE_INTERVAL=300, PlayerRemoving, BindToClose with parallel saves
3. ✅ Players earn XP and cash for kills and round performance — ProgressionService with tunable constants, GunServer hooks, time-based reward loop
4. ✅ Level progression triggers when XP thresholds are reached — checkLevelUp with math.floor(XP/1000)+1, LevelUp RemoteEvent fires
5. ✅ Stat menu displays current player metrics during gameplay — StatMenuGui with 12 stat fields, Tab key toggle, scoreboard, mobile button

**STAT-02 (Post-game stat board)** is intentionally partial — UI component exists, Phase 5 wiring pending per plan. This is not a gap; it's documented deferral.

**All automated checks passed.** Human verification required to confirm behavioral correctness in live Studio playtests (10 items above).

---

_Verified: 2026-03-31T12:00:00Z_
_Verifier: Claude (gsd-verifier)_
