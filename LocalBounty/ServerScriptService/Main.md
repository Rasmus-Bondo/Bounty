---
tags: [server, script, entrypoint]
path: game.ServerScriptService.Main
type: Script
lines: 64
---

# Main

Server entry point that initializes all server-side services.

## What it does
1. Requires DataService, TesterGrantService, Telemetry, CollisionService, LobbyService, FriendJoinService, FollowJoinService, PartyService, QuestService, PlayerSettingsService, MouseSensitivityService, CodeRedemptionService, BattlePassService, BoostService, DailyRewardService, FriendBonusService, CollectionService, BundleService, LootboxService, TutorialDispatchService, and TutorialReplayService modules
2. Calls `.Start()` on each service in sequence to boot the server
3. **Start order is load-bearing for BoostService, CollectionService, BundleService and LootboxService** (2026-09-03), which run 2nd to 5th — immediately after DataService and ahead of everything else. The Collection menu's client-side `Refs` module blocks on the remotes those two create (`ActivateBoost` / `RequestBoostState` / `BoostStateEvent`, plus the emote and title remotes) *before* the menu's skin-ownership listener can connect. While they started at the bottom of this list, that listener stayed deaf for the entire span between `DataService.Start()` — which already loads profiles and pushes skin ownership — and the end of boot, so the join push was routinely dropped and owned skins/gun skins rendered as PURCHASE. Any service added later that creates a remote a client `WaitForChild`s on belongs in the same early group — LootboxService creates the five lootbox remotes the chest menu's ChestController waits on, and its join-state listener must exist before the profile-load push
4. BountyPlusService joins that same early group (2026-09-06), for both reasons at once: ChestController waits on the two BOUNTY+ remotes it creates, and its one-time grant pays five chests through `LootboxService.grantChests`, so it must start after LootboxService as well

## Dependencies
- **Requires:** [[DataService]], [[TesterGrantService]], [[Telemetry]], [[CollisionService]], [[LobbyService]], [[FriendJoinService]], [[FollowJoinService]], [[PartyService]], [[QuestService]], [[PlayerSettingsService]], [[BattlePassService]], [[BoostService]], [[DailyRewardService]], [[FriendBonusService]], [[CollectionService]], [[BundleService]], [[LootboxService]], [[CodeRedemptionService]], [[MouseSensitivityService]], [[TutorialDispatchService]], [[TutorialReplayService]], [[NewItemService]], [[BountyPlusService]]
- **Required by:** Nobody

## Connections
### RemoteEvents
None

### BindableEvents
None

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[DataService]] | `DataService.Start()` | Initialize player data persistence |
| [[TesterGrantService]] | `TesterGrantService.Start()` | Hold the external playtester accounts at 999,999 Cash/Tokens. Started right after DataService because that is what it reads; a no-op on every live server, since it gates on `GameEnvironment.env == "Dev"` |
| [[Telemetry]] | `Telemetry.Start()` | Wire the `ReportPlatform` remote, start session-length timing, and fire `SessionEnd` on leave. Started right after DataService so profiles are loading before any event can reference one |
| [[CollisionService]] | `CollisionService.Start()` | Set up character collision groups |
| [[LobbyService]] | `LobbyService.Start()` | Lock characters at lobby spawn |
| [[FriendJoinService]] | `FriendJoinService.Start()` | Initialize the friend-slot rules, the Home-tab "friends in a match" banner remotes, and its own teleport retries. Started before FollowJoinService, which depends on it |
| [[FollowJoinService]] | `FollowJoinService.Start()` | Forward a Roblox friends-list joiner into their friend's actual server (Roblox only ever drops them here in Bounty) |
| [[PartyService]] | `PartyService.Start()` | Initialize party and teleport system |
| [[QuestService]] | `QuestService.Start()` | Initialize quest assignment and claim handling |
| [[PlayerSettingsService]] | `PlayerSettingsService.Start()` | Persist crosshair, audio, HUD, graphics settings |
| [[BattlePassService]] | `BattlePassService.Start()` | Initialize battle-pass state streaming and reward-track claiming |
| [[BoostService]] | `BoostService.Start()` | Initialize XP/Cash boost activation + state streaming (lobby-side; the timer ticks in Redwater) |
| [[DailyRewardService]] | `DailyRewardService.Start()` | Initialize daily play-streak claiming (grants Cash/Tokens/XP/boosts) + its RemoteEvents |
| [[FriendBonusService]] | `FriendBonusService.Start()` | Initialize friend-group bonus counting + the center-top total-multiplier display stream |
| [[CollectionService]] | `CollectionService.Start()` | Initialize title state streaming + equip validation for the Collection panel |
| [[BundleService]] | `BundleService.Start()` | Validate the bundle catalog and create PurchaseBundleEvent for the Trading Post's BUNDLES tab |
| [[LootboxService]] | `LootboxService.Start()` | Create the five lootbox remotes, wire the chest purchase / open / state handshake and the free per-level chest accrual. In the early group because ChestController blocks on those remotes |
| [[TutorialReplayService]] | `TutorialReplayService.Start()` | Wire the `TutorialReplayRequest` remote so the CHANGE MODE picker can send a player back through the lesson. Started after TutorialDispatchService, though nothing orders the two — they share no state and each owns its own remote |
