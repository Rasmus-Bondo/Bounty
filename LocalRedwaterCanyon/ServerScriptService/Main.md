---
tags:
  - server
  - script
path: game.ServerScriptService.Main
type: Script
lines: 78
---

# Main

Entry-point server script that bootstraps all server-side modules.

## What it does

1. Waits for all ServerScriptService subfolders (Combat, Hunters, Testing, Networking, VFX, UI, PlayerServices, RoundSystem) to load. (`Combat.Ultimate` folder is gone after Phase 2 — HighNoonModule moved to `Hunters.DustServer`.)
2. Requires each server module and calls `.Start()` on them in order
3. Sets `Players.CharacterAutoLoads = false` so all character spawning is manually controlled
4. Phase 2: `RevolverModule.Start()` returns the Dust [[HunterServerRuntime]] handle; `HighNoonModule.Start(dustRuntime)` consumes it so both Dust systems share the single [[UltimateChargeService]] instance
4a. Also hands that runtime to [[TutorialDirector]] via `TutorialDirector.Init(dustRuntime)` — the director's only path to `ChargeService:Set` for the tutorial's ultimate step. Inert on a normal server; the lesson itself only starts from RoundController's tutorial session
5. Boot order: HunterSelectionService, SkinService, DataService, TesterGrantService, Telemetry, HunterSwitchService, TitleDisplayService, ProgressionService, BountyService, QuestService, BattlePassService, FriendBonusService, BoostService, DailyRewardService, CodeRedemptionService, LeaveToLobbyService, MouseSensitivityService, PlayerSettingsService, ChronoServerBootstrap, RevolverModule (returns runtime), HighNoonModule (receives runtime), BotService, DashDustVFXServer, RevolverWorldModelServer, HealthBarSpawner, MatchDirectoryService, RoundController, CharacterStateLockServer

## Dependencies

- **Requires:** [[HunterSelectionService]], [[SkinService]], [[DataService]], [[TesterGrantService]], [[Telemetry]], [[HunterSwitchService]], [[TitleDisplayService]], [[ProgressionService]], [[BountyService]], [[QuestService]], [[BattlePassService]], [[FriendBonusService]], [[BoostService]], [[DailyRewardService]], [[CodeRedemptionService]], [[LeaveToLobbyService]], [[MouseSensitivityService]], [[PlayerSettingsService]], [[ChronoServerBootstrap]], [[RevolverModule]], [[HighNoonModule]], [[BotService]], [[DashDustVFXServer]], [[RevolverWorldModelServer]], [[HealthBarSpawner]], [[MatchDirectoryService]], [[RoundController]], [[CharacterStateLockServer]], [[TutorialDirector]]
- **Required by:** Nobody

## Connections

### Direct require()

| Target | Function | Purpose |
|--------|----------|---------|
| [[HunterSelectionService]] | `HunterSelectionService.Start()` | Read teleport hunter selection (Dust/Fortuna) and wire PlayerAdded/PlayerRemoving |
| [[SkinService]] | `SkinService.Start()` | Read teleport skin selections and control character spawning |
| [[DataService]] | `DataService.Start()` | Initialize player data persistence |
| [[TesterGrantService]] | `TesterGrantService.Start()` | Hold the external playtester accounts at 999,999 Cash/Tokens. Started right after DataService because that is what it reads; a no-op on every live server, since it gates on `GameEnvironment.env == "Dev"` |
| [[Telemetry]] | `Telemetry.Start()` | Wire the `ReportPlatform` / `ReportClientPerf` remotes, start session-length timing, and fire `SessionEnd` on leave. Started right after DataService so profiles are loading before any event can reference one |
| [[HunterSwitchService]] | `HunterSwitchService.Start()` | Wire the death-gated mid-match hunter swap remotes |
| [[TitleDisplayService]] | `TitleDisplayService.Start()` | Publish each player's equipped cosmetic title (for their match hunter) as the replicated `EquippedTitle` attribute |
| [[ProgressionService]] | `ProgressionService.Start()` | Initialize progression/reward system |
| [[BountyService]] | `BountyService.Start()` | Initialize bounty/kill streak system |
| [[QuestService]] | `QuestService.Start()` | Initialize quest tracking system |
| [[BattlePassService]] | `BattlePassService.Start()` | Initialize battle-pass XP earning, weekly quest tracking, and the Dead Man's Hand tracker |
| [[FriendBonusService]] | `FriendBonusService.Start()` | Initialize friend-group bonus snapshotting (roster-change recompute) feeding [[BoostService]] `getMultiplier` |
| [[BoostService]] | `BoostService.Start()` | Initialize XP/Cash boost activation, the round-gated tick loop, and its RemoteEvents |
| [[DailyRewardService]] | `DailyRewardService.Start()` | Initialize daily play-streak earning (round-end credit) + the DailyRewardEarned toast remote |
| [[CodeRedemptionService]] | `CodeRedemptionService.Start()` | Initialize redeem-code RemoteEvent handler |
| [[LeaveToLobbyService]] | `LeaveToLobbyService.Start()` | Initialize leave-to-Bounty RemoteEvent handler |
| [[MouseSensitivityService]] | `MouseSensitivityService.Start()` | Initialize mouse sensitivity persistence RemoteEvent handlers |
| [[PlayerSettingsService]] | `PlayerSettingsService.Start()` | Initialize the unified settings-persistence RemoteEvent handlers (crosshair, HUD, graphics, audio) |
| [[ChronoServerBootstrap]] | `ChronoServerBootstrap.Start()` | Initialize Chrono networking |
| [[RevolverModule]] | `RevolverModule.Start()` → returns Dust runtime | Initialize revolver combat system; constructs the Dust [[HunterServerRuntime]] |
| [[HighNoonModule]] | `HighNoonModule.Start(dustRuntime)` | Initialize High Noon ultimate ability; consumes the runtime so it shares [[UltimateChargeService]] |
| [[BotService]] | `BotService.Start()` | Initialize the arena bot system (spawning, difficulty fill, `workspace.ArenaBots`) |
| [[DashDustVFXServer]] | `DashDustVFXServer.Start()` | Initialize dash dust VFX replication |
| [[RevolverWorldModelServer]] | `RevolverWorldModelServer.Start()` | Initialize revolver world model, muzzle VFX, and shot sound replication |
| [[HealthBarSpawner]] | `HealthBarSpawner.Start()` | Hides Roblox's native overhead name/health display on every character (custom bar itself is now spawned by [[HealthBarSpawnerClient]]) |
| [[MatchDirectoryService]] | `MatchDirectoryService.Start()` | Start publishing this server's state (phase, time left, roster, openness) so the Bounty lobby can route or withhold players |
| [[RoundController]] | `RoundController.Start()` | Initialize round system and start round loop |
| [[CharacterStateLockServer]] | `CharacterStateLockServer.Start()` | Initialize character state locking and angular velocity clamping |
