# Graph Report - LocalSecret  (2026-10-14)

## Corpus Check
- 69 files · ~20,362 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 69 nodes · 69 edges · 20 communities detected
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- [[_COMMUNITY_Server Bootstrap|Server Bootstrap]]
- [[_COMMUNITY_Server Bootstrap|Server Bootstrap]]
- [[_COMMUNITY_Server Bootstrap|Server Bootstrap]]
- [[_COMMUNITY_Server Bootstrap|Server Bootstrap]]
- [[_COMMUNITY_Server Bootstrap|Server Bootstrap]]
- [[_COMMUNITY_Server Bootstrap|Server Bootstrap]]
- [[_COMMUNITY_Server Bootstrap|Server Bootstrap]]
- [[_COMMUNITY_Server Bootstrap|Server Bootstrap]]
- [[_COMMUNITY_ProgressionConfig|ProgressionConfig]]
- [[_COMMUNITY_WadingServer|WadingServer]]
- [[_COMMUNITY_UI & HUD|UI & HUD]]
- [[_COMMUNITY_Health|Health]]
- [[_COMMUNITY_Main Menu|Main Menu]]
- [[_COMMUNITY_Player Data|Player Data]]
- [[_COMMUNITY_BoneHorseIKClient|BoneHorseIKClient]]
- [[_COMMUNITY_HorseIKClient|HorseIKClient]]
- [[_COMMUNITY_HorseRiderPoseClient|HorseRiderPoseClient]]
- [[_COMMUNITY_WadingClient|WadingClient]]
- [[_COMMUNITY_DisableReset|DisableReset]]
- [[_COMMUNITY_Input|Input]]

## God Nodes (most connected - your core abstractions)
1. `MissionServer` - 16 edges
2. `WorldRuntime` - 9 edges
3. `CombatServer` - 8 edges
4. `EnemyService` - 8 edges
5. `ClientMenuState` - 6 edges
6. `HorseServer` - 5 edges
7. `WorldGenerationConfig` - 4 edges
8. `chrono` - 4 edges
9. `ChunkEnemyServer` - 4 edges
10. `MissionVariety` - 4 edges

## Surprising Connections (you probably didn't know these)
- `HorseClient` --calls--> `ClientMenuState`  [EXTRACTED]
  LocalSecret/StarterPlayer/StarterPlayerScripts/Mounts/HorseClient.md → LocalSecret/ReplicatedStorage/PVE/Modules/ClientMenuState.md
- `MissionServer` --calls--> `ReviveServer`  [EXTRACTED]
  LocalSecret/ServerScriptService/Missions/MissionServer.md → LocalSecret/ServerScriptService/Combat/ReviveServer.md
- `TrailMapClient` --calls--> `WorldRuntime`  [EXTRACTED]
  LocalSecret/StarterPlayer/StarterPlayerScripts/World/TrailMapClient.md → LocalSecret/ServerScriptService/World/WorldRuntime.md
- `CombatServer` --calls--> `CombatConfig`  [EXTRACTED]
  LocalSecret/ServerScriptService/Combat/CombatServer.md → LocalSecret/ReplicatedStorage/PVE/Config/CombatConfig.md
- `MissionServer` --calls--> `WorldGenerationConfig`  [EXTRACTED]
  LocalSecret/ServerScriptService/Missions/MissionServer.md → LocalSecret/ReplicatedStorage/PVE/Config/WorldGenerationConfig.md

## Communities

### Community 0 - "Server Bootstrap"
Cohesion: 0.16
Nodes (14): AbilityClient, AbilityServer, Ballistics, ClientMenuState, CombatClient, CombatConfig, CombatServer, DamageNumbersClient (+6 more)

### Community 1 - "Server Bootstrap"
Cohesion: 0.17
Nodes (13): BossArena, EscortPacing, HorseClient, HorseServer, LobbyReturn, LobbyReturnConfig, MineSupplyMission, MissionClient (+5 more)

### Community 2 - "Server Bootstrap"
Cohesion: 0.31
Nodes (9): BuildPlotTools, ChunkEnemyServer, ExplorationEncounterService, TerrainTemplateService, WorldClient, WorldGenerationConfig, WorldGenerator, WorldRuntime (+1 more)

### Community 3 - "Server Bootstrap"
Cohesion: 0.29
Nodes (8): BossAttackRules, BossTelegraphClient, chrono, ChronoConfig, EnemyRenderer, EnemyService, ReviveServer, RoamingServer

### Community 4 - "Server Bootstrap"
Cohesion: 0.4
Nodes (5): MissionArtService, MissionVariety, NuclearEffects, NuclearLaunchController, NuclearLeverSequence

### Community 5 - "Server Bootstrap"
Cohesion: 0.83
Nodes (4): CoinDropClient, CoinDropConfig, CoinDropServer, CoinLedger

### Community 6 - "Server Bootstrap"
Cohesion: 1.0
Nodes (2): ProfileService, PVEDataService

### Community 7 - "Server Bootstrap"
Cohesion: 1.0
Nodes (2): ProgressionClient, ProgressionServer

### Community 8 - "ProgressionConfig"
Cohesion: 1.0
Nodes (1): ProgressionConfig

### Community 9 - "WadingServer"
Cohesion: 1.0
Nodes (1): WadingServer

### Community 10 - "UI & HUD"
Cohesion: 1.0
Nodes (1): HideBuildPlots

### Community 11 - "Health"
Cohesion: 1.0
Nodes (1): Health

### Community 12 - "Main Menu"
Cohesion: 1.0
Nodes (1): MenuModalGuard

### Community 13 - "Player Data"
Cohesion: 1.0
Nodes (1): ExplorationFeedback

### Community 14 - "BoneHorseIKClient"
Cohesion: 1.0
Nodes (1): BoneHorseIKClient

### Community 15 - "HorseIKClient"
Cohesion: 1.0
Nodes (1): HorseIKClient

### Community 16 - "HorseRiderPoseClient"
Cohesion: 1.0
Nodes (1): HorseRiderPoseClient

### Community 17 - "WadingClient"
Cohesion: 1.0
Nodes (1): WadingClient

### Community 18 - "DisableReset"
Cohesion: 1.0
Nodes (1): DisableReset

### Community 19 - "Input"
Cohesion: 1.0
Nodes (1): PromptClickGuard

## Knowledge Gaps
- **40 isolated node(s):** `ChronoConfig`, `ProgressionConfig`, `Ballistics`, `WeaponAudio`, `FastCastRedux` (+35 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **Thin community `Server Bootstrap`** (2 nodes): `ProfileService`, `PVEDataService`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Server Bootstrap`** (2 nodes): `ProgressionClient`, `ProgressionServer`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `ProgressionConfig`** (1 nodes): `ProgressionConfig`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `WadingServer`** (1 nodes): `WadingServer`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `UI & HUD`** (1 nodes): `HideBuildPlots`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Health`** (1 nodes): `Health`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Main Menu`** (1 nodes): `MenuModalGuard`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Player Data`** (1 nodes): `ExplorationFeedback`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `BoneHorseIKClient`** (1 nodes): `BoneHorseIKClient`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `HorseIKClient`** (1 nodes): `HorseIKClient`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `HorseRiderPoseClient`** (1 nodes): `HorseRiderPoseClient`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `WadingClient`** (1 nodes): `WadingClient`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `DisableReset`** (1 nodes): `DisableReset`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Input`** (1 nodes): `PromptClickGuard`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `MissionServer` connect `Server Bootstrap` to `Server Bootstrap`, `Server Bootstrap`, `Server Bootstrap`, `Server Bootstrap`?**
  _High betweenness centrality (0.345) - this node is a cross-community bridge._
- **Why does `CombatServer` connect `Server Bootstrap` to `Server Bootstrap`?**
  _High betweenness centrality (0.154) - this node is a cross-community bridge._
- **Why does `WorldRuntime` connect `Server Bootstrap` to `Server Bootstrap`, `Server Bootstrap`?**
  _High betweenness centrality (0.136) - this node is a cross-community bridge._
- **What connects `ChronoConfig`, `ProgressionConfig`, `Ballistics` to the rest of the system?**
  _40 weakly-connected nodes found - possible documentation gaps or missing edges._