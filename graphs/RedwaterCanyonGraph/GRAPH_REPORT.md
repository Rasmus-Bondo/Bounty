# Graph Report - LocalRedwaterCanyon  (2026-09-06)

## Corpus Check
- 250 files · ~316,289 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 245 nodes · 769 edges · 21 communities detected
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- [[_COMMUNITY_Combat|Combat]]
- [[_COMMUNITY_Server Bootstrap|Server Bootstrap]]
- [[_COMMUNITY_Combat|Combat]]
- [[_COMMUNITY_Server Bootstrap|Server Bootstrap]]
- [[_COMMUNITY_Server Bootstrap|Server Bootstrap]]
- [[_COMMUNITY_Round System|Round System]]
- [[_COMMUNITY_UI & HUD|UI & HUD]]
- [[_COMMUNITY_Server Bootstrap|Server Bootstrap]]
- [[_COMMUNITY_Chrono Networking|Chrono Networking]]
- [[_COMMUNITY_Chrono Networking|Chrono Networking]]
- [[_COMMUNITY_Types|Types]]
- [[_COMMUNITY_RevolverRemotes|RevolverRemotes]]
- [[_COMMUNITY_HunterImplementationGuide|HunterImplementationGuide]]
- [[_COMMUNITY_Health|Health]]
- [[_COMMUNITY_CharacterStateLockClient|CharacterStateLockClient]]
- [[_COMMUNITY_DamageVignetteClient|DamageVignetteClient]]
- [[_COMMUNITY_DisableDefaultHealthBar|DisableDefaultHealthBar]]
- [[_COMMUNITY_DisableDefaultLeaderboard|DisableDefaultLeaderboard]]
- [[_COMMUNITY_FortunaCardsWorldVisibilityClient|FortunaCardsWorldVisibilityClient]]
- [[_COMMUNITY_Audio|Audio]]
- [[_COMMUNITY_SlowVignetteClient|SlowVignetteClient]]

## God Nodes (most connected - your core abstractions)
1. `RoundController` - 35 edges
2. `Main` - 32 edges
3. `FPSRevolverClient` - 30 edges
4. `RevolverModule` - 29 edges
5. `BotCombat` - 28 edges
6. `GrudgekeeperClient` - 27 edges
7. `TeamAffinity` - 25 edges
8. `CardsServer` - 25 edges
9. `SunspikeModule` - 23 edges
10. `SunspikeClient` - 23 edges

## Surprising Connections (you probably didn't know these)
- `BattlePassService` --calls--> `BattlePassConfig`  [EXTRACTED]
  LocalRedwaterCanyon/ServerScriptService/PlayerServices/BattlePassService.md → LocalRedwaterCanyon/ReplicatedStorage/Config/BattlePassConfig.md
- `RoundController` --calls--> `EmoteConfig`  [EXTRACTED]
  LocalRedwaterCanyon/ServerScriptService/RoundSystem/RoundController.md → LocalRedwaterCanyon/ReplicatedStorage/Config/EmoteConfig.md
- `CapturePointVisualClient` --calls--> `MapConfig`  [EXTRACTED]
  LocalRedwaterCanyon/StarterPlayer/StarterPlayerScripts/CapturePointVisualClient.md → LocalRedwaterCanyon/ReplicatedStorage/Config/MapConfig.md
- `HighNoonCharacterUtil` --calls--> `TeamAffinity`  [EXTRACTED]
  LocalRedwaterCanyon/ReplicatedStorage/Hunters/Dust/Modules/HighNoonCharacterUtil.md → LocalRedwaterCanyon/ReplicatedStorage/Modules/TeamAffinity.md
- `BotCombat` --calls--> `HighNoonServerConfig`  [EXTRACTED]
  LocalRedwaterCanyon/ServerScriptService/Bots/BotCombat.md → LocalRedwaterCanyon/ReplicatedStorage/Hunters/Dust/Modules/HighNoonServerConfig.md

## Communities

### Community 0 - "Combat"
Cohesion: 0.13
Nodes (49): AimAssistController, BotCombat, BotFXAudience, BramWorldFXClient, BreachCarryGeometry, BreachChargeService, BulletPenetration, DamageGate (+41 more)

### Community 1 - "Server Bootstrap"
Cohesion: 0.08
Nodes (45): AnnouncementController, BotBrain, BotController, BotVisualClient, BountyListClient, BulletHitAudioService, CapturePointVisualClient, CardsConfig (+37 more)

### Community 2 - "Combat"
Cohesion: 0.11
Nodes (29): CardsClient, CombatChecker, FPSRevolverClient, HunterAutoReload, HunterFirstPersonClient, HunterGuiClient, HunterHudShake, HunterMobileClusterLayout (+21 more)

### Community 3 - "Server Bootstrap"
Cohesion: 0.14
Nodes (26): AnimationLoader, BramWorldIdleClient, CardsWorldVisualClient, EmoteConfig, FortunaCardsWorldIdleClient, HideLocalWorldGrudgekeeper, HideLocalWorldRevolver, HideLocalWorldSniper (+18 more)

### Community 4 - "Server Bootstrap"
Cohesion: 0.16
Nodes (25): BattlePassConfig, CharacterStateLockServer, CodeRedemptionService, DataService, GameEnvironment, HealthBarSpawner, HunterSelectionService, HunterSwitchClient (+17 more)

### Community 5 - "Round System"
Cohesion: 0.25
Nodes (19): BotConfig, BotPathing, BotService, CapturePointService, Deathmatch, Domination, MapConfig, MapVoteClient (+11 more)

### Community 6 - "UI & HUD"
Cohesion: 0.29
Nodes (14): BramHunterGuiClient, CardsHunterGuiClient, DashDustVFX, DashDustVFXServer, HighNoonChargeUI, HunterClientRuntime, HunterHudBump, HunterHudCooldown (+6 more)

### Community 7 - "Server Bootstrap"
Cohesion: 0.36
Nodes (12): BattlePassService, BountyMusicClient, BountyService, CombatFeedClient, LevelRewardClient, ProgressionService, QuestConfig, QuestEvents (+4 more)

### Community 8 - "Chrono Networking"
Cohesion: 0.28
Nodes (9): chrono, ChronoClientBootstrap, ChronoServerBootstrap, Config, Entity, GamemodeConfig, MapCatalog, MatchDirectoryService (+1 more)

### Community 9 - "Chrono Networking"
Cohesion: 0.33
Nodes (6): BoostConfig, BoostService, DailyRewardConfig, DailyRewardService, FriendBonusConfig, FriendBonusService

### Community 10 - "Types"
Cohesion: 1.0
Nodes (1): Types

### Community 11 - "RevolverRemotes"
Cohesion: 1.0
Nodes (1): RevolverRemotes

### Community 12 - "HunterImplementationGuide"
Cohesion: 1.0
Nodes (1): HunterImplementationGuide

### Community 13 - "Health"
Cohesion: 1.0
Nodes (1): Health

### Community 14 - "CharacterStateLockClient"
Cohesion: 1.0
Nodes (1): CharacterStateLockClient

### Community 15 - "DamageVignetteClient"
Cohesion: 1.0
Nodes (1): DamageVignetteClient

### Community 16 - "DisableDefaultHealthBar"
Cohesion: 1.0
Nodes (1): DisableDefaultHealthBar

### Community 17 - "DisableDefaultLeaderboard"
Cohesion: 1.0
Nodes (1): DisableDefaultLeaderboard

### Community 18 - "FortunaCardsWorldVisibilityClient"
Cohesion: 1.0
Nodes (1): FortunaCardsWorldVisibilityClient

### Community 19 - "Audio"
Cohesion: 1.0
Nodes (1): RbxCharacterSounds

### Community 20 - "SlowVignetteClient"
Cohesion: 1.0
Nodes (1): SlowVignetteClient

## Knowledge Gaps
- **48 isolated node(s):** `BoostConfig`, `FriendBonusConfig`, `QuestConfig`, `TitleStyles`, `Types` (+43 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **Thin community `Types`** (1 nodes): `Types`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `RevolverRemotes`** (1 nodes): `RevolverRemotes`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `HunterImplementationGuide`** (1 nodes): `HunterImplementationGuide`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Health`** (1 nodes): `Health`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `CharacterStateLockClient`** (1 nodes): `CharacterStateLockClient`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `DamageVignetteClient`** (1 nodes): `DamageVignetteClient`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `DisableDefaultHealthBar`** (1 nodes): `DisableDefaultHealthBar`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `DisableDefaultLeaderboard`** (1 nodes): `DisableDefaultLeaderboard`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `FortunaCardsWorldVisibilityClient`** (1 nodes): `FortunaCardsWorldVisibilityClient`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Audio`** (1 nodes): `RbxCharacterSounds`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `SlowVignetteClient`** (1 nodes): `SlowVignetteClient`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Main` connect `Server Bootstrap` to `Combat`, `Server Bootstrap`, `Server Bootstrap`, `Round System`, `UI & HUD`, `Server Bootstrap`, `Chrono Networking`, `Chrono Networking`?**
  _High betweenness centrality (0.128) - this node is a cross-community bridge._
- **Why does `FPSRevolverClient` connect `Combat` to `Combat`, `Server Bootstrap`, `Server Bootstrap`, `Round System`, `UI & HUD`?**
  _High betweenness centrality (0.125) - this node is a cross-community bridge._
- **Why does `RoundController` connect `Round System` to `Server Bootstrap`, `Server Bootstrap`, `Server Bootstrap`, `Server Bootstrap`, `Chrono Networking`, `Chrono Networking`?**
  _High betweenness centrality (0.091) - this node is a cross-community bridge._
- **What connects `BoostConfig`, `FriendBonusConfig`, `QuestConfig` to the rest of the system?**
  _48 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Combat` be split into smaller, more focused modules?**
  _Cohesion score 0.13 - nodes in this community are weakly interconnected._
- **Should `Server Bootstrap` be split into smaller, more focused modules?**
  _Cohesion score 0.08 - nodes in this community are weakly interconnected._
- **Should `Combat` be split into smaller, more focused modules?**
  _Cohesion score 0.11 - nodes in this community are weakly interconnected._