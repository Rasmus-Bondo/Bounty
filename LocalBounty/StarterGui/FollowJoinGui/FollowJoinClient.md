---
tags: [client, localscript, ui, teleport, social]
path: game.StarterGui.FollowJoinGui.FollowJoinClient
type: LocalScript
lines: 303
---

# FollowJoinClient

The "Joining <friend>…" overlay shown while [[FollowJoinService]] forwards a friends-list joiner into their friend's server.

## What it does
1. Reads `Players.LocalPlayer.FollowUserId` **directly** instead of waiting for a server message — that property has read security `None` and is populated before any script runs, so the overlay is up on the first frame rather than a round-trip later. A zero value `return`s immediately and the overlay is never built at all, so an ordinary join costs nothing
2. Builds the card in code, matching GiftPopupClient's western palette: leather `43,30,22` body, gold `214,170,96` stroke, `LuckiestGuy` title, `Gotham`/`GothamBold` body, 16px `UICorner`, `UISizeConstraint` capped at 380px wide. Its backdrop is `ZIndex = 50` so it covers the authored `Canvas` (the friends-in-match panel, which shares this ScreenGui at `ZIndex = 3`) — there is no code-level link between the two, only draw order
3. Dims the lobby behind a full-screen backdrop and absorbs taps with a transparent `TextButton`, so nothing behind the overlay can be clicked mid-hop
4. Animates an ellipsis on a 0.35s cycle so a slow hop still looks alive, and pops the card in with a Back ease
5. Shows "your friend" as a neutral placeholder, then swaps in the real name once `GetNameFromUserIdAsync` returns (it's a web call, so the overlay never blocks on it)
6. On `FollowJoinStatus` `"Failed"`, turns the card into "COULDN'T JOIN / … / Staying in the lobby." in the failure red, then fades after `FAILURE_HOLD` (5s). On `"Arrived"` it just dismisses
6b. **The middle line prefers the server's own `payload.message`** (2026-08-13) and only falls back to "<friend>'s match is full or already finished." when there is none. The server knows which refusal it hit — "still in the training run", "wrapping up", "full" — and that line was previously computed and thrown away. It is deliberately absent for outcomes with nothing worth showing a player, such as a teleport ladder that ran out, and then the generic wording stands in
6c. **`"Dismiss"` clears the overlay showing no card at all.** Sent when the server hands the player to another flow — today, the onboarding tutorial claiming someone whose forward failed — because spending five seconds on "staying in the lobby" immediately before teleporting them out of it reads as two bugs rather than one hand-off. It sets a `cancelled` flag *distinct from* `finished`, because `showFailure` sets `finished` **before** its intro wait, so that flag cannot be what suppresses a card already queued behind the loading screen
6a. **The failure card waits for `BountyIntroComplete`; the "JOINING" overlay does not** (2026-08-11). ReplicatedFirst.LoadingScreen builds its ScreenGui at `DisplayOrder = 1000` against this one's 100, so anything drawn while the veil is up is drawn *underneath* it — and the failure card's dismiss timer was running the whole time it was covered, so by the time the loading screen handed off there was nothing left to read. Reported live by a player who tried to join a friend who was in the training run: a tutorial server publishes no match-directory entry, so the follow-join fails at the lookup almost immediately, which is exactly the case where the message lands earliest and is covered longest. The overlay itself still goes up on frame one — covering the lobby during a *successful* hop is the whole reason it exists, and it is invisible behind the loading screen either way. The hold went 3s → 5s in the same pass, having been tuned when nobody could read it
7. A successful hop needs no message — the teleport itself tears the client down
8. `SAFETY_TIMEOUT` (20s) fades the overlay regardless, so a server-side failure can never strand the player behind an opaque screen. It keys on a `presented` flag rather than `finished`: a hop still in flight and a failure still queued behind the loading screen are the same thing from the player's side — an overlay with nothing readable on it — and without the distinction a failure at t=1s with an intro attribute that never arrived would stack the 25s wait on top of the 20s backstop and hold a near-opaque overlay for half a minute
9. The ScreenGui is authored `DisplayOrder = 100`, `ScreenInsets = None` / `IgnoreGuiInset = true`, `ResetOnSpawn = false` so it sits above the lobby UI and survives the lobby's character lock/respawn. `None` (matching MainMenuGui) also means the backdrop covers the raw screen — notch and safe-area gaps included — rather than stopping at the safe area

## Dependencies
- **Requires:** Nothing
- **Required by:** Nobody

## Connections
### RemoteEvents
| Remote | Direction | Other script |
|--------|-----------|-------------|
| `FollowJoinStatus` | ← Server | [[FollowJoinService]] reports `"Failed"` (with an optional player-facing `message`) / `"Arrived"` / `"Dismiss"`; a successful hop ends in the teleport instead |

### BindableEvents
None

### Direct require()
None
