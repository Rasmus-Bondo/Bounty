---
tags: [client, localscript, ui, notifications]
path: game.StarterGui.GiftGui.GiftPopupClient
type: LocalScript
lines: 274
---

# GiftPopupClient

Shows a reward card popup when the server fires `GiftNotice` — the developer gift, and the ranked season payout.

## What it does
1. Waits for `ReplicatedStorage.Events.GiftNotice`.
2. **Defers display until the frontier is fully "in"** (`waitForReady`): waits for the `ReplicatedStorage.BountyIntroComplete` attribute (loading screen + intro camera pan finishing, set by the `ReplicatedFirst.LoadingScreen` script), then settles 0.35s. This keeps the gift from opening over the loading screen or mid-pan. The wait is capped at 25s so the gift still shows if the attribute never lands. The ScreenGui sits at `DisplayOrder = 60`, above every lobby panel, as belt-and-suspenders.
3. Then, on the deferred thread, builds a western leather-and-gold modal entirely via `Instance.new`: a dimmed full-screen backdrop plus a centered card with title "THANK YOU!", the gift `message`, a gold `＋ <amount> <currency>` badge, and a Close button. Falls back to sensible defaults (500 Tokens) if the payload is missing fields.
4. Animates in — backdrop fades to 45% and the card pops via a Back-eased `UIScale`.
5. Dismisses **only** via the Close button. The full-screen backdrop is a `TextButton` that absorbs taps (so the lobby behind can't be clicked) but does **not** close the popup — a stray tap on the dim must not throw the gift away. Mobile-friendly: `Scale` width + `UISizeConstraint` (max 380px), a 46px-tall button, and a `UIListLayout` with `AutomaticSize` so the card grows to fit the message.
6. Shows at most once per gift — the underlying ProfileService GlobalUpdate that triggers it is consumed exactly once server-side (see [[DataService]] `QueueCurrencyGrant` + the on-join handler).
7. **Two senders, one card** (2026-08-27). The payload gained optional `heading` (replaces "THANK YOU!") and `detail` (an extra gold line under the badge, `LayoutOrder = 5`, pushing Close to 6). Both are created only when supplied, so [[DataService]]'s gift keeps exactly the card it always had. RankSeasonRewardService uses them for the ranked payout: heading `SEASON <n>`, message `You finished #<rank> on the ranked leaderboard.`, and `detail` naming the podium title — which has no amount and so cannot ride the `＋ <amount> <currency>` badge. A second popup would have reimplemented this card's intro gate, its modality and its close-button-only rule for no gain
8. Card height with the `detail` line is **281px**, verified against desktop 1080 plus iPhone 7 and Galaxy A06 in landscape (375px and 360px tall) — `AutomaticSize.Y` plus the 380px `UISizeConstraint` keep it clear of the shortest viewport the lobby has to survive

## Dependencies
- **Requires:** Nothing
- **Required by:** Nobody

## Connections
### RemoteEvents
| Remote | Direction | Other script |
|--------|-----------|-------------|
| `GiftNotice` | ← Server | [[DataService]] fires it when an offline currency gift is applied on join |
| `GiftNotice` | ← Server | [[RankSeasonRewardService]] fires it when a ranked season payout is granted, with `heading` + `detail` set |

### BindableEvents
None

### Direct require()
Nothing
