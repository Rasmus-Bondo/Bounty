# Graph Report - LocalBounty  (2026-09-07)

## Corpus Check
- 132 files · ~162,763 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 132 nodes · 447 edges · 14 communities detected
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- [[_COMMUNITY_Server Bootstrap|Server Bootstrap]]
- [[_COMMUNITY_Server Bootstrap|Server Bootstrap]]
- [[_COMMUNITY_Main Menu|Main Menu]]
- [[_COMMUNITY_Server Bootstrap|Server Bootstrap]]
- [[_COMMUNITY_UI & HUD|UI & HUD]]
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
1. `DataService` - 40 edges
2. `Main` - 23 edges
3. `LootboxService` - 21 edges
4. `TitlesConfig` - 19 edges
5. `CollectionService` - 18 edges
6. `Panels` - 17 edges
7. `State` - 17 edges
8. `CollectionGuiController` - 17 edges
9. `PartyService` - 16 edges
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

### Community 0 - "Server Bootstrap"
Cohesion: 0.13
Nodes (28): CollisionService, FollowJoinClient, FollowJoinService, FriendJoinService, FriendsInMatchClient, GameEnvironment, GameModeClient, GamemodeConfig (+20 more)

### Community 1 - "Server Bootstrap"
Cohesion: 0.2
Nodes (25): AccessoryBuyPanel, BattlePassClient, BattlePassConfig, BattlePassService, BoostConfig, BountyPlusConfig, BountyPlusService, ChestArrivalClient (+17 more)

### Community 2 - "Main Menu"
Cohesion: 0.27
Nodes (23): BundleConfig, BundleService, CurrencyHudController, FeaturedSequence, HuntersBuyController, LimitedStockConfig, LimitedStockService, MenuHandlerScript (+15 more)

### Community 3 - "Server Bootstrap"
Cohesion: 0.16
Nodes (18): BoostService, CodeRedemptionService, DailyLoginController, DailyRewardConfig, DailyRewardService, DataService, FriendBonusConfig, FriendBonusService (+10 more)

### Community 4 - "UI & HUD"
Cohesion: 0.6
Nodes (17): BoostsTab, Catalog, CollectionGuiController, EmotesTab, EquipButton, HuntersTab, Panels, Preview (+9 more)

### Community 5 - "Server Bootstrap"
Cohesion: 0.31
Nodes (13): AnimationLoader, BundleHomeController, CarouselMath, CollectionClient, Config, HunterList, LobbySpawn, NameGui (+5 more)

### Community 6 - "BattlePassRigAnimationClient"
Cohesion: 1.0
Nodes (1): BattlePassRigAnimationClient

### Community 7 - "AbilitiesPanelClient"
Cohesion: 1.0
Nodes (1): AbilitiesPanelClient

### Community 8 - "CollectionSoundClient"
Cohesion: 1.0
Nodes (1): CollectionSoundClient

### Community 9 - "ViewportRigAnimationClient"
Cohesion: 1.0
Nodes (1): ViewportRigAnimationClient

### Community 10 - "TutorialCompleteController"
Cohesion: 1.0
Nodes (1): TutorialCompleteController

### Community 11 - "Unused/Legacy"
Cohesion: 1.0
Nodes (1): DisableDefaultLeaderboard

### Community 12 - "Character Select"
Cohesion: 1.0
Nodes (1): DisableResetCharacter

### Community 13 - "Lobby"
Cohesion: 1.0
Nodes (1): TumbleweedSpawner

## Knowledge Gaps
- **25 isolated node(s):** `FriendBonusConfig`, `TitleStyles`, `CollisionService`, `RegionService`, `ProfileService` (+20 more)
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

- **Why does `DataService` connect `Server Bootstrap` to `Server Bootstrap`, `Server Bootstrap`, `Main Menu`, `UI & HUD`, `Server Bootstrap`?**
  _High betweenness centrality (0.302) - this node is a cross-community bridge._
- **Why does `CollectionClient` connect `Server Bootstrap` to `Server Bootstrap`, `Main Menu`, `Server Bootstrap`?**
  _High betweenness centrality (0.111) - this node is a cross-community bridge._
- **Why does `PartyService` connect `Server Bootstrap` to `Main Menu`, `Server Bootstrap`, `UI & HUD`, `Server Bootstrap`?**
  _High betweenness centrality (0.110) - this node is a cross-community bridge._
- **What connects `FriendBonusConfig`, `TitleStyles`, `CollisionService` to the rest of the system?**
  _25 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Server Bootstrap` be split into smaller, more focused modules?**
  _Cohesion score 0.13 - nodes in this community are weakly interconnected._