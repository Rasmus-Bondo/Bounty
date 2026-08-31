---
tags: [client, localscript, ui, social, teleport]
path: game.StarterGui.FollowJoinGui.Canvas.FriendsInMatchClient
type: LocalScript
lines: 440
---

# FriendsInMatchClient

The "your friends are in a match" slide-out panel, with a JOIN per friend.

## What it does
1. Renders the friend rows streamed by [[FriendJoinService]] (`FriendsInMatch`) into clones of the authored `ScrollingFrame.Template`: time left in their match, display name, and a JOIN button. The template is reparented into the script at startup so it cannot render as a ghost row
2. Drives the authored `Canvas` — `TopFrame` header, `BottomFrame.ScrollingFrame` rows, `Notice` overlay, and the `OpenCloseParty` handle rotated -90 on the left edge. The panel slides between its authored open position and a closed position **one panel-width to the right** (computed from `Canvas.Size`, not hardcoded), so only the handle is left on screen — always reachable, exactly like PartyFrame, and never hidden when the friend list is empty
3. Sits in the band between PartyFrame's bottom edge (`0.674`) and InviteFriendsGui's top edge (`0.889`) at `Position.Y = 0.7819`, centred with equal clearance. That arithmetic only holds because `FollowJoinGui`, `MainMenuGui`, `InviteFriendsGui` and `ReworkedSettingsGui` all use `ScreenInsets = None` — panels in different inset spaces cannot be positioned against each other, since a safe-area space is 62px narrower per side on a notched phone in landscape. `None` is also what puts the closed handle flush against the physical screen edge
4. Shows a red count dot (`OpenCloseParty.NotiFrame`) while closed and at least one friend is in a match. Its number label carries `Rotation = 90` to cancel the handle's `-90` and read upright
5. Auto-opens for a userId not in the pruned-to-present `seen` set, so a dismissal sticks but a friend who *starts* a match re-opens it. Gated on `ReplicatedStorage.BountyIntroComplete` (12s fallback) so it cannot pop during the opening camera pan
6. Deliberately **not** gated on the main-menu tab — inferring the active page left the panel hidden for the rest of the session after any hand-off that did not start on the bottom bar. It follows `MainMenuGui.Enabled` instead, so it disappears with the menu (loading screen, Trading Post, buy menu) without knowing which tab is up. MainMenuGui is `ResetOnSpawn`, so that reference is re-resolved on `ReworkedMainMenuFolder.ChildAdded` rather than cached once
7. Sizes rows and `CanvasSize` in **offset**, derived from the scroll window's own `AbsoluteSize` — a ScrollingFrame resolves `CanvasSize`'s scale against its *parent* and its children's scale against the *canvas*, so scale rows under a scale canvas feed back on themselves. Re-derived on `AbsoluteSize` change and on becoming visible
8. Server refusal notices ("Your friend's match is full.") take the list's box for 4.5s via the `Notice` label; the same label carries the empty state when no friend is in a match
9. Polls `"Refresh"` every 12s unconditionally rather than only while open — the panel has to learn that a friend started a match in order to open itself, and the count dot has to stay honest while closed. The server throttles to one refresh per 3s per player
10. Counts down `secondsLeft` locally between refreshes and writes the clocks **in place**, because a full re-render every second would rebuild the rows under the player's finger and lose presses
11. A JOIN press locks every button for 6s (`JOIN_LOCKOUT`) so a double-tap cannot queue two teleports; the server answers with either a teleport or a notice

## Dependencies
- **Requires:** Nothing
- **Required by:** Nobody

## Connections
### RemoteEvents
| Remote | Direction | Other script |
|--------|-----------|-------------|
| `FriendJoinRequest` | → Server | [[FriendJoinService]] `"Refresh"` poll and `"Join"` press |
| `FriendsInMatch` | ← Server | [[FriendJoinService]] friend rows, refusal notices, and the joining flag |

### BindableEvents
None

### Direct require()
None
