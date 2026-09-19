# Graph Report - LocalBounty  (2026-09-19)

## Corpus Check
- 134 files · ~165,330 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 134 nodes · 452 edges · 15 communities detected
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- [[_COMMUNITY_Server Bootstrap|Server Bootstrap]]
- [[_COMMUNITY_Server Bootstrap|Server Bootstrap]]
- [[_COMMUNITY_Main Menu|Main Menu]]
- [[_COMMUNITY_UI & HUD|UI & HUD]]
- [[_COMMUNITY_Server Bootstrap|Server Bootstrap]]
- [[_COMMUNITY_Server Bootstrap|Server Bootstrap]]
- [[_COMMUNITY_PreflightGates|PreflightGates]]
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
3. `LootboxService` - 22 edges
4. `TitlesConfig` - 20 edges
5. `CollectionService` - 18 edges
6. `Panels` - 17 edges
7. `State` - 17 edges
8. `CollectionGuiController` - 17 edges
9. `PartyService` - 16 edges
10. `Preview` - 16 edges

## Surprising Connections (you probably didn't know these)
- `GiftPopupClient` --calls--> `DataService`  [EXTRACTED]
  LocalBounty/StarterGui/GiftGui/GiftPopupClient.md → LocalBounty/ServerScriptService/PlayerServices/DataService.md
- `LoadingScreen` --calls--> `WaitForRequired`  [EXTRACTED]
  LocalBounty/ReplicatedFirst/LoadingScreen.md → LocalBounty/ReplicatedStorage/Modules/WaitForRequired.md
- `PlayerSettingsService` --calls--> `LoadingScreen`  [EXTRACTED]
  LocalBounty/ServerScriptService/PlayerServices/PlayerSettingsService.md → LocalBounty/ReplicatedFirst/LoadingScreen.md
- `BattlePassConfig` --calls--> `GameEnvironment`  [EXTRACTED]
  LocalBounty/ReplicatedStorage/Config/BattlePassConfig.md → LocalBounty/ReplicatedStorage/Config/GameEnvironment.md
- `TitlesConfig` --calls--> `BattlePassConfig`  [EXTRACTED]
  LocalBounty/ReplicatedStorage/Config/TitlesConfig.md → LocalBounty/ReplicatedStorage/Config/BattlePassConfig.md

## Communities

### Community 0 - "Server Bootstrap"
Cohesion: 0.17
Nodes (29): BattlePassClient, BattlePassConfig, BattlePassService, BoostConfig, BoostService, BountyPlusConfig, BountyPlusService, BundleHomeController (+21 more)

### Community 1 - "Server Bootstrap"
Cohesion: 0.14
Nodes (27): CollisionService, FollowJoinClient, FollowJoinService, FriendJoinService, FriendsInMatchClient, GameEnvironment, GameModeClient, GamemodeConfig (+19 more)

### Community 2 - "Main Menu"
Cohesion: 0.23
Nodes (26): BundleConfig, CurrencyHudController, FeaturedSequence, GroupPerkConfig, HuntersBuyController, LimitedStockConfig, LimitedStockService, LoadingScreen (+18 more)

### Community 3 - "UI & HUD"
Cohesion: 0.56
Nodes (18): BoostsTab, Catalog, CollectionGuiController, EmoteConfig, EmotesTab, EquipButton, HuntersTab, Panels (+10 more)

### Community 4 - "Server Bootstrap"
Cohesion: 0.23
Nodes (13): AccessoryBuyPanel, CollectionService, EmoteBuyController, GiftPopupClient, LobbySpawn, NewItemClient, NewItemService, RankRewardsConfig (+5 more)

### Community 5 - "Server Bootstrap"
Cohesion: 0.35
Nodes (12): AnimationLoader, CarouselMath, CollectionClient, Config, DisplayCharacterAnimator, HunterList, NameGui, PreviewModel (+4 more)

### Community 6 - "PreflightGates"
Cohesion: 1.0
Nodes (1): PreflightGates

### Community 7 - "BattlePassRigAnimationClient"
Cohesion: 1.0
Nodes (1): BattlePassRigAnimationClient

### Community 8 - "AbilitiesPanelClient"
Cohesion: 1.0
Nodes (1): AbilitiesPanelClient

### Community 9 - "CollectionSoundClient"
Cohesion: 1.0
Nodes (1): CollectionSoundClient

### Community 10 - "ViewportRigAnimationClient"
Cohesion: 1.0
Nodes (1): ViewportRigAnimationClient

### Community 11 - "TutorialCompleteController"
Cohesion: 1.0
Nodes (1): TutorialCompleteController

### Community 12 - "Unused/Legacy"
Cohesion: 1.0
Nodes (1): DisableDefaultLeaderboard

### Community 13 - "Character Select"
Cohesion: 1.0
Nodes (1): DisableResetCharacter

### Community 14 - "Lobby"
Cohesion: 1.0
Nodes (1): TumbleweedSpawner

## Knowledge Gaps
- **27 isolated node(s):** `FriendBonusConfig`, `TitleStyles`, `CollisionService`, `RegionService`, `ProfileService` (+22 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **Thin community `PreflightGates`** (1 nodes): `PreflightGates`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
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

- **Why does `DataService` connect `Server Bootstrap` to `Server Bootstrap`, `Main Menu`, `UI & HUD`, `Server Bootstrap`, `Server Bootstrap`?**
  _High betweenness centrality (0.292) - this node is a cross-community bridge._
- **Why does `PartyService` connect `Server Bootstrap` to `Server Bootstrap`, `Main Menu`, `UI & HUD`, `Server Bootstrap`, `Server Bootstrap`?**
  _High betweenness centrality (0.108) - this node is a cross-community bridge._
- **Why does `CollectionClient` connect `Server Bootstrap` to `Server Bootstrap`, `Server Bootstrap`, `Main Menu`?**
  _High betweenness centrality (0.108) - this node is a cross-community bridge._
- **What connects `FriendBonusConfig`, `TitleStyles`, `CollisionService` to the rest of the system?**
  _27 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Server Bootstrap` be split into smaller, more focused modules?**
  _Cohesion score 0.14 - nodes in this community are weakly interconnected._