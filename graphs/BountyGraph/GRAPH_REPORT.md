# Graph Report - LocalBounty  (2026-09-03)

## Corpus Check
- 129 files · ~157,032 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 129 nodes · 427 edges · 17 communities detected
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- [[_COMMUNITY_Main Menu|Main Menu]]
- [[_COMMUNITY_Server Bootstrap|Server Bootstrap]]
- [[_COMMUNITY_UI & HUD|UI & HUD]]
- [[_COMMUNITY_Server Bootstrap|Server Bootstrap]]
- [[_COMMUNITY_Server Bootstrap|Server Bootstrap]]
- [[_COMMUNITY_Server Bootstrap|Server Bootstrap]]
- [[_COMMUNITY_Server Bootstrap|Server Bootstrap]]
- [[_COMMUNITY_Server Bootstrap|Server Bootstrap]]
- [[_COMMUNITY_Server Bootstrap|Server Bootstrap]]
- [[_COMMUNITY_BattlePassRigAnimationClient|BattlePassRigAnimationClient]]
- [[_COMMUNITY_AbilitiesPanelClient|AbilitiesPanelClient]]
- [[_COMMUNITY_CollectionSoundClient|CollectionSoundClient]]
- [[_COMMUNITY_ViewportRigAnimationClient|ViewportRigAnimationClient]]
- [[_COMMUNITY_TutorialCompleteController|TutorialCompleteController]]
- [[_COMMUNITY_UnusedLegacy|Unused/Legacy]]
- [[_COMMUNITY_Character Select|Character Select]]
- [[_COMMUNITY_Lobby|Lobby]]

## God Nodes (most connected - your core abstractions)
1. `DataService` - 39 edges
2. `Main` - 22 edges
3. `TitlesConfig` - 17 edges
4. `CollectionService` - 17 edges
5. `Panels` - 17 edges
6. `State` - 17 edges
7. `CollectionGuiController` - 17 edges
8. `PartyService` - 16 edges
9. `LootboxService` - 16 edges
10. `Preview` - 16 edges

## Surprising Connections (you probably didn't know these)
- `LoadingScreen` --calls--> `WaitForRequired`  [EXTRACTED]
  LocalBounty/ReplicatedFirst/LoadingScreen.md → LocalBounty/ReplicatedStorage/Modules/WaitForRequired.md
- `GiftPopupClient` --calls--> `DataService`  [EXTRACTED]
  LocalBounty/StarterGui/GiftGui/GiftPopupClient.md → LocalBounty/ServerScriptService/PlayerServices/DataService.md
- `BattlePassConfig` --calls--> `GameEnvironment`  [EXTRACTED]
  LocalBounty/ReplicatedStorage/Config/BattlePassConfig.md → LocalBounty/ReplicatedStorage/Config/GameEnvironment.md
- `DataService` --calls--> `BattlePassConfig`  [EXTRACTED]
  LocalBounty/ServerScriptService/PlayerServices/DataService.md → LocalBounty/ReplicatedStorage/Config/BattlePassConfig.md
- `Shop` --calls--> `BattlePassConfig`  [EXTRACTED]
  LocalBounty/StarterGui/CollectionGui/CollectionGuiController/Shop.md → LocalBounty/ReplicatedStorage/Config/BattlePassConfig.md

## Communities

### Community 0 - "Main Menu"
Cohesion: 0.24
Nodes (26): AnimationLoader, BundleConfig, BundleHomeController, CurrencyHudController, FeaturedSequence, HuntersBuyController, LimitedStockConfig, LimitedStockService (+18 more)

### Community 1 - "Server Bootstrap"
Cohesion: 0.2
Nodes (21): AccessoryBuyPanel, BattlePassClient, BattlePassConfig, BattlePassService, BoostConfig, BoostService, BundleService, ChestController (+13 more)

### Community 2 - "UI & HUD"
Cohesion: 0.62
Nodes (17): BoostsTab, Catalog, CollectionGuiController, EmotesTab, EquipButton, HuntersTab, Panels, Preview (+9 more)

### Community 3 - "Server Bootstrap"
Cohesion: 0.29
Nodes (12): CodeRedemptionService, CollisionService, DataService, LoadingScreen, LobbyService, Main, MouseSensitivityService, NewItemClient (+4 more)

### Community 4 - "Server Bootstrap"
Cohesion: 0.38
Nodes (11): CarouselMath, CollectionClient, Config, GroupPerkConfig, HunterList, NameGui, PreviewModel, Reel (+3 more)

### Community 5 - "Server Bootstrap"
Cohesion: 0.29
Nodes (10): FollowJoinClient, FollowJoinService, FriendJoinService, FriendsInMatchClient, MapCatalog, MatchmakingService, Telemetry, TelemetryClient (+2 more)

### Community 6 - "Server Bootstrap"
Cohesion: 0.31
Nodes (9): GameModeClient, GamemodeConfig, Mobile3DClickHandler, NotificationModule, PartyService, RegionService, ReworkedPartyClient, ReworkedUIPlay (+1 more)

### Community 7 - "Server Bootstrap"
Cohesion: 0.28
Nodes (9): GameEnvironment, GiftPopupClient, RankLeaderboardClient, RankLeaderboardService, RankRewardsConfig, RankSeasonRewardService, SoftShutdown, TesterGrantService (+1 more)

### Community 8 - "Server Bootstrap"
Cohesion: 0.4
Nodes (6): DailyLoginController, DailyRewardConfig, DailyRewardService, FriendBonusConfig, FriendBonusService, MultiplierDisplayClient

### Community 9 - "BattlePassRigAnimationClient"
Cohesion: 1.0
Nodes (1): BattlePassRigAnimationClient

### Community 10 - "AbilitiesPanelClient"
Cohesion: 1.0
Nodes (1): AbilitiesPanelClient

### Community 11 - "CollectionSoundClient"
Cohesion: 1.0
Nodes (1): CollectionSoundClient

### Community 12 - "ViewportRigAnimationClient"
Cohesion: 1.0
Nodes (1): ViewportRigAnimationClient

### Community 13 - "TutorialCompleteController"
Cohesion: 1.0
Nodes (1): TutorialCompleteController

### Community 14 - "Unused/Legacy"
Cohesion: 1.0
Nodes (1): DisableDefaultLeaderboard

### Community 15 - "Character Select"
Cohesion: 1.0
Nodes (1): DisableResetCharacter

### Community 16 - "Lobby"
Cohesion: 1.0
Nodes (1): TumbleweedSpawner

## Knowledge Gaps
- **24 isolated node(s):** `FriendBonusConfig`, `TitleStyles`, `CollisionService`, `RegionService`, `ProfileService` (+19 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **Thin community `BattlePassRigAnimationClient`** (1 nodes): `BattlePassRigAnimationClient`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `AbilitiesPanelClient`** (1 nodes): `AbilitiesPanelClient`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `CollectionSoundClient`** (1 nodes): `CollectionSoundClient`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `ViewportRigAnimationClient`** (1 nodes): `ViewportRigAnimationClient`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `TutorialCompleteController`** (1 nodes): `TutorialCompleteController`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Unused/Legacy`** (1 nodes): `DisableDefaultLeaderboard`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Character Select`** (1 nodes): `DisableResetCharacter`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Lobby`** (1 nodes): `TumbleweedSpawner`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `DataService` connect `Server Bootstrap` to `Main Menu`, `Server Bootstrap`, `UI & HUD`, `Server Bootstrap`, `Server Bootstrap`, `Server Bootstrap`, `Server Bootstrap`, `Server Bootstrap`?**
  _High betweenness centrality (0.314) - this node is a cross-community bridge._
- **Why does `PartyService` connect `Server Bootstrap` to `Main Menu`, `Server Bootstrap`, `UI & HUD`, `Server Bootstrap`, `Server Bootstrap`, `Server Bootstrap`?**
  _High betweenness centrality (0.114) - this node is a cross-community bridge._
- **Why does `CollectionClient` connect `Server Bootstrap` to `Main Menu`, `Server Bootstrap`, `Server Bootstrap`?**
  _High betweenness centrality (0.114) - this node is a cross-community bridge._
- **What connects `FriendBonusConfig`, `TitleStyles`, `CollisionService` to the rest of the system?**
  _24 weakly-connected nodes found - possible documentation gaps or missing edges._