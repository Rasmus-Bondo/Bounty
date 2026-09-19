---
tags: [client, localscript, ui, friendbonus, invite, events]
path: game.StarterGui.InviteFriendsGui.MultiplierDisplayClient
type: LocalScript
lines: 300
---

# MultiplierDisplayClient

Drives the bottom-right "active multiplier" panel, the Invite Friends button, and the top-centre limited-time event banner.

## What it does
1. Renders the Cash / XP multipliers streamed by [[FriendBonusService]] (`MultiplierStateEvent`) — the combined friend-group bonus + active boost potions + daily-streak passive + BOUNTY+ game pass — with a small scale-pop when a value changes
2. Fires `RequestMultiplierState` on startup (with retry) to get an initial state
3. **Event banner** (2026-09-19) — renders `eventLabel` and a live countdown to `eventEndsAt` in the `EventBanner` frame, top-centre, text-only with no plate. The server sends the event's END as a UTC epoch second, never a remaining duration, so the countdown is recomputed each tick and cannot drift across a long lobby session; it reads `workspace:GetServerTimeNow()`, not `os.time()`, which would be the player's own device clock. A 1s loop drives the countdown and also retires the banner ON ITS OWN at `endsAt`, because the server's boundary re-push can be up to five seconds behind and a banner still promising a bonus that has stopped paying is the one state worth never showing. Both event fields nil (no event running) hides it
3a. The three countdown formats (`ENDS IN 2d 00h` / `ENDS IN 04h 11m` / `ENDS IN 00m 32s`) are all 14-15 characters **on purpose** — `TextScaled` sizes type to the string it is given, so a format that shed a unit as the clock ran down would make the line visibly grow. Measured identical at 26px across all three
3b. The banner lives in this same ScreenGui rather than one of its own so it inherits the visibility gate below verbatim; a second copy of that gate beside this one is a copy that drifts
4. Invite Friends button opens the native Roblox game-invite prompt (`SocialService:PromptGameInvite`), guarded by `CanSendGameInviteAsync`; shows brief inline feedback if invites are unavailable
5. **Visibility gate:** the `InviteFriendsGui` ScreenGui starts `Enabled = false` and is only shown when BOTH the intro/loading screen has finished (the `BountyIntroComplete` attribute on ReplicatedStorage set by LoadingScreen) AND the player is on the **Home** tab. A 12s fallback reveals it if the intro flag is ever missed
5a. **The active tab is read from the `SelectedMenuFrame` attribute** on `MainMenuGui`, which MenuHandlerScript publishes from `selectMenuFrame` — the one function every navigation route passes through (tab press, black-bar transition, trading-post cinematic, and the `MenuNavigateRequested` bindable other panels fire). It previously hooked the bottom-tab buttons' `Activated`, which only sees navigation that *starts* on the bottom bar and misses every hand-off (the Bounty Pass X button returning Home, the currency vault going back to its origin page). `ResetOnSpawn` is false, so a single missed return to Home hid the multiplier panel for the **rest of the session**

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
