# Graph Report - LocalRedwaterCanyon  (2026-10-05)

## Corpus Check
- 253 files · ~323,451 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 248 nodes · 772 edges · 19 communities detected
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- [[_COMMUNITY_Server Bootstrap|Server Bootstrap]]
- [[_COMMUNITY_Server Bootstrap|Server Bootstrap]]
- [[_COMMUNITY_Combat|Combat]]
- [[_COMMUNITY_Combat|Combat]]
- [[_COMMUNITY_Server Bootstrap|Server Bootstrap]]
- [[_COMMUNITY_Combat|Combat]]
- [[_COMMUNITY_Chrono Networking|Chrono Networking]]
- [[_COMMUNITY_RevolverRemotes|RevolverRemotes]]
- [[_COMMUNITY_HunterImplementationGuide|HunterImplementationGuide]]
- [[_COMMUNITY_PreflightGates|PreflightGates]]
- [[_COMMUNITY_Health|Health]]
- [[_COMMUNITY_CharacterStateLockClient|CharacterStateLockClient]]
- [[_COMMUNITY_DamageVignetteClient|DamageVignetteClient]]
- [[_COMMUNITY_DisableDefaultHealthBar|DisableDefaultHealthBar]]
- [[_COMMUNITY_DisableDefaultLeaderboard|DisableDefaultLeaderboard]]
- [[_COMMUNITY_FortunaCardsWorldVisibilityClient|FortunaCardsWorldVisibilityClient]]
- [[_COMMUNITY_Player Data|Player Data]]
- [[_COMMUNITY_Audio|Audio]]
- [[_COMMUNITY_SlowVignetteClient|SlowVignetteClient]]

## God Nodes (most connected - your core abstractions)
1. `RoundController` - 36 edges
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
- `RoundController` --calls--> `EmoteConfig`  [EXTRACTED]
  LocalRedwaterCanyon/ServerScriptService/RoundSystem/RoundController.md → LocalRedwaterCanyon/ReplicatedStorage/Config/EmoteConfig.md
- `HighNoonModule` --calls--> `HighNoonCharacterUtil`  [EXTRACTED]
  LocalRedwaterCanyon/ServerScriptService/Hunters/DustServer/HighNoonModule.md → LocalRedwaterCanyon/ReplicatedStorage/Hunters/Dust/Modules/HighNoonCharacterUtil.md
- `HighNoonModule` --calls--> `HighNoonMovement`  [EXTRACTED]
  LocalRedwaterCanyon/ServerScriptService/Hunters/DustServer/HighNoonModule.md → LocalRedwaterCanyon/ReplicatedStorage/Hunters/Dust/Modules/HighNoonMovement.md
- `BotVisualClient` --calls--> `HighNoonPublicFX`  [EXTRACTED]
  LocalRedwaterCanyon/StarterPlayer/StarterPlayerScripts/BotVisualClient.md → LocalRedwaterCanyon/ReplicatedStorage/Hunters/Dust/Modules/HighNoonPublicFX.md
- `HighNoonModule` --calls--> `HighNoonServerConfig`  [EXTRACTED]
  LocalRedwaterCanyon/ServerScriptService/Hunters/DustServer/HighNoonModule.md → LocalRedwaterCanyon/ReplicatedStorage/Hunters/Dust/Modules/HighNoonServerConfig.md

## Communities

### Community 0 - "Server Bootstrap"
Cohesion: 0.1
Nodes (52): AnnouncementController, BattlePassService, BotConfig, BotPathing, BotService, BountyListClient, BountyMusicClient, BountyService (+44 more)

### Community 1 - "Server Bootstrap"
Cohesion: 0.1
Nodes (44): AnimationLoader, BramHunterGuiClient, BramWorldIdleClient, CardsHunterGuiClient, CardsWorldVisualClient, EmoteConfig, FortunaCardsWorldIdleClient, GrudgekeeperWorldVisualServer (+36 more)

### Community 2 - "Combat"
Cohesion: 0.12
Nodes (42): BotBrain, BotCombat, BotFXAudience, BramWorldFXClient, BreachCarryGeometry, BreachChargeService, BulletPenetration, DamageGate (+34 more)

### Community 3 - "Combat"
Cohesion: 0.12
Nodes (36): AimAssistController, BotVisualClient, CardsClient, CombatChecker, FPSRevolverClient, GrudgekeeperClient, HunterActionLock, HunterAutoReload (+28 more)

### Community 4 - "Server Bootstrap"
Cohesion: 0.12
Nodes (31): BattlePassConfig, BoostConfig, BoostService, BountyPlusConfig, CharacterStateLockServer, CodeRedemptionService, DailyRewardConfig, DailyRewardService (+23 more)

### Community 5 - "Combat"
Cohesion: 0.15
Nodes (30): BotController, BulletHitAudioService, CardsConfig, CardsServer, CardsWorldVisualServer, DamageDirectionClient, DamageNumberClient, DashDustVFX (+22 more)

### Community 6 - "Chrono Networking"
Cohesion: 1.0
Nodes (1): Types

### Community 7 - "RevolverRemotes"
Cohesion: 1.0
Nodes (1): RevolverRemotes

### Community 8 - "HunterImplementationGuide"
Cohesion: 1.0
Nodes (1): HunterImplementationGuide

### Community 9 - "PreflightGates"
Cohesion: 1.0
Nodes (1): PreflightGates

### Community 10 - "Health"
Cohesion: 1.0
Nodes (1): Health

### Community 11 - "CharacterStateLockClient"
Cohesion: 1.0
Nodes (1): CharacterStateLockClient

### Community 12 - "DamageVignetteClient"
Cohesion: 1.0
Nodes (1): DamageVignetteClient

### Community 13 - "DisableDefaultHealthBar"
Cohesion: 1.0
Nodes (1): DisableDefaultHealthBar

### Community 14 - "DisableDefaultLeaderboard"
Cohesion: 1.0
Nodes (1): DisableDefaultLeaderboard

### Community 15 - "FortunaCardsWorldVisibilityClient"
Cohesion: 1.0
Nodes (1): FortunaCardsWorldVisibilityClient

### Community 16 - "Player Data"
Cohesion: 1.0
Nodes (1): HunterXPBarClient

### Community 17 - "Audio"
Cohesion: 1.0
Nodes (1): RbxCharacterSounds

### Community 18 - "SlowVignetteClient"
Cohesion: 1.0
Nodes (1): SlowVignetteClient

## Knowledge Gaps
- **49 isolated node(s):** `BountyPlusConfig`, `FriendBonusConfig`, `QuestConfig`, `TitleStyles`, `Types` (+44 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **Thin community `Chrono Networking`** (1 nodes): `Types`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `RevolverRemotes`** (1 nodes): `RevolverRemotes`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `HunterImplementationGuide`** (1 nodes): `HunterImplementationGuide`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `PreflightGates`** (1 nodes): `PreflightGates`
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
- **Thin community `Player Data`** (1 nodes): `HunterXPBarClient`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Audio`** (1 nodes): `RbxCharacterSounds`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `SlowVignetteClient`** (1 nodes): `SlowVignetteClient`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Main` connect `Server Bootstrap` to `Server Bootstrap`, `Server Bootstrap`, `Combat`?**
  _High betweenness centrality (0.126) - this node is a cross-community bridge._
- **Why does `FPSRevolverClient` connect `Combat` to `Server Bootstrap`, `Server Bootstrap`, `Combat`?**
  _High betweenness centrality (0.123) - this node is a cross-community bridge._
- **Why does `RoundController` connect `Server Bootstrap` to `Server Bootstrap`, `Combat`, `Server Bootstrap`, `Combat`?**
  _High betweenness centrality (0.092) - this node is a cross-community bridge._
- **What connects `BountyPlusConfig`, `FriendBonusConfig`, `QuestConfig` to the rest of the system?**
  _49 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Server Bootstrap` be split into smaller, more focused modules?**
  _Cohesion score 0.1 - nodes in this community are weakly interconnected._
- **Should `Server Bootstrap` be split into smaller, more focused modules?**
  _Cohesion score 0.1 - nodes in this community are weakly interconnected._
- **Should `Combat` be split into smaller, more focused modules?**
  _Cohesion score 0.12 - nodes in this community are weakly interconnected._