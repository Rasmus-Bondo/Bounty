# Graph Report - LocalRedwaterCanyon  (2026-09-03)

## Corpus Check
- 247 files · ~313,046 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 242 nodes · 761 edges · 25 communities detected
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- [[_COMMUNITY_Combat|Combat]]
- [[_COMMUNITY_Server Bootstrap|Server Bootstrap]]
- [[_COMMUNITY_Combat|Combat]]
- [[_COMMUNITY_Round System|Round System]]
- [[_COMMUNITY_Combat|Combat]]
- [[_COMMUNITY_UI & HUD|UI & HUD]]
- [[_COMMUNITY_UI & HUD|UI & HUD]]
- [[_COMMUNITY_Server Bootstrap|Server Bootstrap]]
- [[_COMMUNITY_Round System|Round System]]
- [[_COMMUNITY_Server Bootstrap|Server Bootstrap]]
- [[_COMMUNITY_High Noon Ultimate|High Noon Ultimate]]
- [[_COMMUNITY_Chrono Networking|Chrono Networking]]
- [[_COMMUNITY_Server Bootstrap|Server Bootstrap]]
- [[_COMMUNITY_Movement|Movement]]
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
- `HunterAbilityIntroClient` --calls--> `Manifest`  [EXTRACTED]
  LocalRedwaterCanyon/StarterPlayer/StarterPlayerScripts/HunterAbilityIntroClient.md → LocalRedwaterCanyon/ReplicatedStorage/Hunters/Vesper/Config/Manifest.md
- `HighNoonMovement` --calls--> `HunterMovement`  [EXTRACTED]
  LocalRedwaterCanyon/ReplicatedStorage/Hunters/Dust/Modules/HighNoonMovement.md → LocalRedwaterCanyon/ReplicatedStorage/Hunters/Shared/HunterMovement.md

## Communities

### Community 0 - "Combat"
Cohesion: 0.09
Nodes (55): AimAssistController, BotVisualClient, BramHunterGuiClient, CardsClient, CardsHunterGuiClient, CombatChecker, FPSRevolverClient, GrudgekeeperClient (+47 more)

### Community 1 - "Server Bootstrap"
Cohesion: 0.12
Nodes (27): AnimationLoader, BramWorldIdleClient, CardsConfig, CardsWorldVisualClient, CardsWorldVisualServer, EmoteConfig, FortunaCardsWorldIdleClient, GrudgekeeperConfig (+19 more)

### Community 2 - "Combat"
Cohesion: 0.23
Nodes (21): BotController, BulletHitAudioService, CardsServer, DamageDirectionClient, DashDustVFX, DashDustVFXServer, FortunaCardsFXClient, HealthBarSpawnerClient (+13 more)

### Community 3 - "Round System"
Cohesion: 0.22
Nodes (21): BotConfig, BotPathing, BotService, CapturePointService, Deathmatch, Domination, GamemodeConfig, MapCatalog (+13 more)

### Community 4 - "Combat"
Cohesion: 0.22
Nodes (18): BotCombat, BramWorldFXClient, BreachCarryGeometry, BreachChargeService, GrudgekeeperDamageService, GrudgekeeperModule, HunterActionLock, HunterCharacterUtil (+10 more)

### Community 5 - "UI & HUD"
Cohesion: 0.18
Nodes (18): BoostConfig, BoostService, CharacterStateLockServer, CodeRedemptionService, DailyRewardConfig, DailyRewardService, DataService, FriendBonusConfig (+10 more)

### Community 6 - "UI & HUD"
Cohesion: 0.15
Nodes (13): BountyListClient, CapturePointVisualClient, DominationAudioClient, DominationClient, HealthBarController, RoundStatusClient, StatMenuScript, TeamView (+5 more)

### Community 7 - "Server Bootstrap"
Cohesion: 0.21
Nodes (12): BattlePassConfig, GameEnvironment, HunterSelectionService, HunterSwitchClient, HunterSwitchService, SkinService, SoftShutdown, Telemetry (+4 more)

### Community 8 - "Round System"
Cohesion: 0.35
Nodes (11): BotFXAudience, DamageGate, EarlyShotRemoteDrain, GrappleHookService, HealthPackSystem, HealthPackVisuals, PinningRoundService, SpawnProtectionService (+3 more)

### Community 9 - "Server Bootstrap"
Cohesion: 0.42
Nodes (11): BattlePassService, BountyMusicClient, BountyService, CombatFeedClient, ProgressionService, QuestConfig, QuestEvents, QuestService (+3 more)

### Community 10 - "High Noon Ultimate"
Cohesion: 0.33
Nodes (9): BulletPenetration, HighNoonCharacterUtil, HighNoonModule, HighNoonMovement, HighNoonServerConfig, HighNoonTargeting, RevolverHitForgiveness, RevolverLagCompensation (+1 more)

### Community 11 - "Chrono Networking"
Cohesion: 0.47
Nodes (6): chrono, ChronoClientBootstrap, ChronoServerBootstrap, Config, Entity, Replicate

### Community 12 - "Server Bootstrap"
Cohesion: 0.4
Nodes (5): HealingVignette, HealthPackPickupFeedbackClient, HunterAbilityIntroClient, HunterIntroTags, TutorialClient

### Community 13 - "Movement"
Cohesion: 0.5
Nodes (4): BotBrain, HunterMovement, MovementChecker, SprintController

### Community 14 - "Types"
Cohesion: 1.0
Nodes (1): Types

### Community 15 - "RevolverRemotes"
Cohesion: 1.0
Nodes (1): RevolverRemotes

### Community 16 - "HunterImplementationGuide"
Cohesion: 1.0
Nodes (1): HunterImplementationGuide

### Community 17 - "Health"
Cohesion: 1.0
Nodes (1): Health

### Community 18 - "CharacterStateLockClient"
Cohesion: 1.0
Nodes (1): CharacterStateLockClient

### Community 19 - "DamageVignetteClient"
Cohesion: 1.0
Nodes (1): DamageVignetteClient

### Community 20 - "DisableDefaultHealthBar"
Cohesion: 1.0
Nodes (1): DisableDefaultHealthBar

### Community 21 - "DisableDefaultLeaderboard"
Cohesion: 1.0
Nodes (1): DisableDefaultLeaderboard

### Community 22 - "FortunaCardsWorldVisibilityClient"
Cohesion: 1.0
Nodes (1): FortunaCardsWorldVisibilityClient

### Community 23 - "Audio"
Cohesion: 1.0
Nodes (1): RbxCharacterSounds

### Community 24 - "SlowVignetteClient"
Cohesion: 1.0
Nodes (1): SlowVignetteClient

## Knowledge Gaps
- **47 isolated node(s):** `BoostConfig`, `FriendBonusConfig`, `QuestConfig`, `TitleStyles`, `Types` (+42 more)
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

- **Why does `Main` connect `UI & HUD` to `Server Bootstrap`, `Combat`, `Round System`, `Server Bootstrap`, `Server Bootstrap`, `High Noon Ultimate`, `Chrono Networking`?**
  _High betweenness centrality (0.130) - this node is a cross-community bridge._
- **Why does `FPSRevolverClient` connect `Combat` to `Server Bootstrap`, `Combat`, `Round System`, `Combat`, `High Noon Ultimate`?**
  _High betweenness centrality (0.126) - this node is a cross-community bridge._
- **Why does `RoundController` connect `Round System` to `Server Bootstrap`, `UI & HUD`, `UI & HUD`, `Server Bootstrap`, `Server Bootstrap`, `Chrono Networking`, `Movement`?**
  _High betweenness centrality (0.092) - this node is a cross-community bridge._
- **What connects `BoostConfig`, `FriendBonusConfig`, `QuestConfig` to the rest of the system?**
  _47 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Combat` be split into smaller, more focused modules?**
  _Cohesion score 0.09 - nodes in this community are weakly interconnected._
- **Should `Server Bootstrap` be split into smaller, more focused modules?**
  _Cohesion score 0.12 - nodes in this community are weakly interconnected._