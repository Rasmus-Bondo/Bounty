---
tags: [client, localscript, ui, friendbonus, invite]
path: game.StarterGui.InviteFriendsGui.MultiplierDisplayClient
type: LocalScript
lines: 230
---

# MultiplierDisplayClient

Drives the bottom-right "active multiplier" panel and the Invite Friends button.

## What it does
1. Renders the Cash / XP multipliers streamed by [[FriendBonusService]] (`MultiplierStateEvent`) — the combined friend-group bonus + active boost potions + daily-streak passive + BOUNTY+ game pass — with a small scale-pop when a value changes
2. Fires `RequestMultiplierState` on startup (with retry) to get an initial state
3. Invite Friends button opens the native Roblox game-invite prompt (`SocialService:PromptGameInvite`), guarded by `CanSendGameInviteAsync`; shows brief inline feedback if invites are unavailable
4. **Visibility gate:** the `InviteFriendsGui` ScreenGui starts `Enabled = false` and is only shown when BOTH the intro/loading screen has finished (the `BountyIntroComplete` attribute on ReplicatedStorage set by LoadingScreen) AND the player is on the **Home** tab. A 12s fallback reveals it if the intro flag is ever missed
4a. **The active tab is read from the `SelectedMenuFrame` attribute** on `MainMenuGui`, which MenuHandlerScript publishes from `selectMenuFrame` — the one function every navigation route passes through (tab press, black-bar transition, trading-post cinematic, and the `MenuNavigateRequested` bindable other panels fire). It previously hooked the bottom-tab buttons' `Activated`, which only sees navigation that *starts* on the bottom bar and misses every hand-off (the Bounty Pass X button returning Home, the currency vault going back to its origin page). `ResetOnSpawn` is false, so a single missed return to Home hid the multiplier panel for the **rest of the session**

## Dependencies
- **Requires:** Nothing
- **Required by:** Nobody

## Connections
### RemoteEvents
| Remote | Direction | Other script |
|--------|-----------|-------------|
| `MultiplierStateEvent` | ← Server | [[FriendBonusService]] multiplier state |
| `RequestMultiplierState` | → Server | [[FriendBonusService]] request fresh state |

### BindableEvents
None

### Direct require()
None
