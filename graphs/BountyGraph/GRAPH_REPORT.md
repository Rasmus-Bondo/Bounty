# Graph Report - LocalBounty  (2026-09-03)

## Corpus Check
- 124 files · ~150,559 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 124 nodes · 396 edges · 14 communities detected
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- [[_COMMUNITY_Main Menu|Main Menu]]
- [[_COMMUNITY_Server Bootstrap|Server Bootstrap]]
- [[_COMMUNITY_Server Bootstrap|Server Bootstrap]]
- [[_COMMUNITY_UI & HUD|UI & HUD]]
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
1. `DataService` - 35 edges
2. `Main` - 20 edges
3. `Panels` - 17 edges
4. `State` - 17 edges
5. `CollectionGuiController` - 17 edges
6. `PartyService` - 16 edges
7. `Preview` - 16 edges
8. `Refs` - 16 edges
9. `ShopState` - 16 edges
10. `TitlesConfig` - 15 edges

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
Cohesion: 0.23
Nodes (26): BundleConfig, BundleService, CurrencyHudController, FeaturedSequence, GroupPerkConfig, HuntersBuyController, LimitedStockConfig, LimitedStockService (+18 more)

### Community 1 - "Server Bootstrap"
Cohesion: 0.14
Nodes (24): BoostService, CodeRedemptionService, DailyLoginController, DailyRewardConfig, DailyRewardService, DataService, FriendBonusConfig, FriendBonusService (+16 more)

### Community 2 - "Server Bootstrap"
Cohesion: 0.18
Nodes (21): CollisionService, FollowJoinClient, FollowJoinService, FriendJoinService, FriendsInMatchClient, GameModeClient, GamemodeConfig, Main (+13 more)

### Community 3 - "UI & HUD"
Cohesion: 0.57
Nodes (18): BoostsTab, Catalog, CollectionGuiController, EmotesTab, EquipButton, HuntersTab, Panels, Preview (+10 more)

### Community 4 - "Server Bootstrap"
Cohesion: 0.22
Nodes (15): AccessoryBuyPanel, BattlePassClient, BattlePassConfig, BattlePassService, BoostConfig, CollectionService, EmoteBuyController, EmoteConfig (+7 more)

### Community 5 - "Server Bootstrap"
Cohesion: 0.35
Nodes (12): AnimationLoader, BundleHomeController, CarouselMath, CollectionClient, Config, HunterList, NameGui, PreviewModel (+4 more)

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

- **Why does `DataService` connect `Server Bootstrap` to `Main Menu`, `Server Bootstrap`, `UI & HUD`, `Server Bootstrap`, `Server Bootstrap`?**
  _High betweenness centrality (0.301) - this node is a cross-community bridge._
- **Why does `PartyService` connect `Server Bootstrap` to `Main Menu`, `Server Bootstrap`, `UI & HUD`, `Server Bootstrap`, `Server Bootstrap`?**
  _High betweenness centrality (0.127) - this node is a cross-community bridge._
- **Why does `CollectionClient` connect `Server Bootstrap` to `Main Menu`, `Server Bootstrap`, `Server Bootstrap`?**
  _High betweenness centrality (0.118) - this node is a cross-community bridge._
- **What connects `FriendBonusConfig`, `TitleStyles`, `CollisionService` to the rest of the system?**
  _24 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Server Bootstrap` be split into smaller, more focused modules?**
  _Cohesion score 0.14 - nodes in this community are weakly interconnected._