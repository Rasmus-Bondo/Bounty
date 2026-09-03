# Graph Report - LocalBounty  (2026-09-03)

## Corpus Check
- 127 files · ~154,145 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 127 nodes · 415 edges · 17 communities detected
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
1. `DataService` - 36 edges
2. `Main` - 21 edges
3. `Panels` - 17 edges
4. `State` - 17 edges
5. `CollectionGuiController` - 17 edges
6. `TitlesConfig` - 16 edges
7. `PartyService` - 16 edges
8. `CollectionService` - 16 edges
9. `LootboxService` - 16 edges
10. `Preview` - 16 edges

## Surprising Connections (you probably didn't know these)
- `LoadingScreen` --calls--> `WaitForRequired`  [EXTRACTED]
  LocalBounty/ReplicatedFirst/LoadingScreen.md → LocalBounty/ReplicatedStorage/Modules/WaitForRequired.md
- `BattlePassConfig` --calls--> `GameEnvironment`  [EXTRACTED]
  LocalBounty/ReplicatedStorage/Config/BattlePassConfig.md → LocalBounty/ReplicatedStorage/Config/GameEnvironment.md
- `DataService` --calls--> `BattlePassConfig`  [EXTRACTED]
  LocalBounty/ServerScriptService/PlayerServices/DataService.md → LocalBounty/ReplicatedStorage/Config/BattlePassConfig.md
- `Shop` --calls--> `BattlePassConfig`  [EXTRACTED]
  LocalBounty/StarterGui/CollectionGui/CollectionGuiController/Shop.md → LocalBounty/ReplicatedStorage/Config/BattlePassConfig.md
- `HuntersBuyController` --calls--> `BattlePassConfig`  [EXTRACTED]
  LocalBounty/StarterGui/ReworkReworkedBuyMenu/HuntersBuyController.md → LocalBounty/ReplicatedStorage/Config/BattlePassConfig.md

## Communities

### Community 0 - "Main Menu"
Cohesion: 0.26
Nodes (24): BundleConfig, BundleService, CurrencyHudController, FeaturedSequence, HuntersBuyController, LimitedStockConfig, LimitedStockService, MenuHandlerScript (+16 more)

### Community 1 - "Server Bootstrap"
Cohesion: 0.18
Nodes (19): AccessoryBuyPanel, BattlePassClient, BattlePassConfig, BattlePassService, BoostConfig, ChestController, CollectionService, EmoteBuyController (+11 more)

### Community 2 - "UI & HUD"
Cohesion: 0.57
Nodes (18): BoostsTab, Catalog, CollectionGuiController, EmotesTab, EquipButton, HuntersTab, Panels, Preview (+10 more)

### Community 3 - "Server Bootstrap"
Cohesion: 0.24
Nodes (15): BundleHomeController, CodeRedemptionService, CollisionService, DataService, GiftPopupClient, LoadingScreen, LobbyService, Main (+7 more)

### Community 4 - "Server Bootstrap"
Cohesion: 0.4
Nodes (11): AnimationLoader, CarouselMath, CollectionClient, Config, HunterList, NameGui, PreviewModel, Reel (+3 more)

### Community 5 - "Server Bootstrap"
Cohesion: 0.29
Nodes (10): FollowJoinClient, FollowJoinService, FriendJoinService, FriendsInMatchClient, MapCatalog, MatchmakingService, Telemetry, TelemetryClient (+2 more)

### Community 6 - "Server Bootstrap"
Cohesion: 0.31
Nodes (9): GameModeClient, GamemodeConfig, Mobile3DClickHandler, NotificationModule, PartyService, RegionService, ReworkedPartyClient, ReworkedUIPlay (+1 more)

### Community 7 - "Server Bootstrap"
Cohesion: 0.38
Nodes (7): BoostService, DailyLoginController, DailyRewardConfig, DailyRewardService, FriendBonusConfig, FriendBonusService, MultiplierDisplayClient

### Community 8 - "Server Bootstrap"
Cohesion: 0.4
Nodes (6): GameEnvironment, RankLeaderboardClient, RankLeaderboardService, RankRewardsConfig, SoftShutdown, VersionTagController

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

- **Why does `DataService` connect `Server Bootstrap` to `Main Menu`, `Server Bootstrap`, `UI & HUD`, `Server Bootstrap`, `Server Bootstrap`, `Server Bootstrap`, `Server Bootstrap`?**
  _High betweenness centrality (0.284) - this node is a cross-community bridge._
- **Why does `PartyService` connect `Server Bootstrap` to `Main Menu`, `Server Bootstrap`, `UI & HUD`, `Server Bootstrap`, `Server Bootstrap`, `Server Bootstrap`?**
  _High betweenness centrality (0.122) - this node is a cross-community bridge._
- **Why does `CollectionClient` connect `Server Bootstrap` to `Main Menu`, `Server Bootstrap`, `Server Bootstrap`, `Server Bootstrap`?**
  _High betweenness centrality (0.116) - this node is a cross-community bridge._
- **What connects `FriendBonusConfig`, `TitleStyles`, `CollisionService` to the rest of the system?**
  _24 weakly-connected nodes found - possible documentation gaps or missing edges._