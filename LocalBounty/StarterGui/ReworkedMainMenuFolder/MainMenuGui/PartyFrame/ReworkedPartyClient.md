---
tags: [client, localscript, ui, party, invite]
path: game.StarterGui.ReworkedMainMenuFolder.MainMenuGui.PartyFrame.ReworkedPartyClient
type: LocalScript
lines: 893
---

# ReworkedPartyClient

Client-side party UI managing the party panel, server player list, invite popups, and 3D invite button hover effects. Displays toast notifications for all party events via NotificationModule.

## What it does
1. Manages an open/close sliding party frame with owner display and member list
2. Builds a scrollable list of other players on the server for sending invites, sorted with friends at the top (uses `LocalPlayer:IsFriendsWith`, parallel-fetched with a per-session cache; alphabetical within each group)
3. Creates and animates a party invite popup (Accept/Decline) when receiving invites
4. Manages 3D InviteParts in workspace with hover scaling and click-pop animations via raycasts. The three parts are resolved by a no-timeout `WaitForChild` chain at the top of the script, so they gate every later line — `workspace.InviteButtons` is a `Model` with `ModelStreamingMode = Persistent` to guarantee they replicate on join regardless of the player's streaming position
5. Handles party state sync: updates owner, members, leave/kick buttons based on server data
6. Supports both PC mouse hover and mobile touch for 3D invite part interaction
7. Fires PartyInviteEvent for all party actions: SendInvite, AcceptInvite, DeclineInvite, LeaveParty, KickPlayer, RequestPartyState
8. Shows toast notifications for all party events: joined/left/kicked/disbanded/invite-sent/declined (success/info/error colors)
9. **SFX volume routing:** its hover/click sound helper clones sounds from `ReplicatedStorage.SFX.ShopMenuSFX` and assigns `SoundGroup = SoundService.SFX` before playing, so they obey the player's SFX + Master volume settings (SettingsController drives `SoundService.SFX.Volume`)

## Dependencies
- **Requires:** [[NotificationModule]], [[WaitForRequired]]
- **Required by:** Nobody

## Connections
### RemoteEvents
| Remote | Direction | Other script |
|--------|-----------|-------------|
| `PartyInviteEvent` | -> Server | [[PartyService]] party actions |
| `PartyInviteEvent` | <- Server | [[PartyService]] party state, invites, messages |

### BindableEvents
None

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[NotificationModule]] | `Notify()` | Toast notifications for party events |
| [[WaitForRequired]] | `waitForRequired(workspace, "InviteButtons")` | Resolve the 3D invite-part model without the engine's 5s "Infinite yield possible" warning; the `InvitePartyPart*` lookups beneath it need no helper |
