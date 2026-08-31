---
tags:
  - client
  - localscript
path: game.StarterGui.TutorialWelcomeGui.TutorialWelcomeController
type: LocalScript
lines: 142
---

# TutorialWelcomeController

The onboarding OFFER: shows a first-time player what the training run pays and takes their answer — START TRAINING or "skip for now".

## What it does

1. **It is a choice again as of 2026-08-17.** The card offered START TRAINING / "skip for now" with a 4s auto-advance sliver until 2026-08-11, was reduced to a non-interactive "Teleporting to tutorial match..." hold between then and now, and is an offer once more — this time with no timer and no auto-advance at all. The tutorial is not mandatory: the only two things that close this card are its own two buttons.
2. On `TutorialInvite` with a reward payload, fills the reward row, waits out the lobby intro, then shows the buttons and enables the ScreenGui. On `TutorialInvite("failed")` (reserve or teleport ladder gave up) it closes to the normal lobby.
3. **The reward numbers come from the server, never from here.** The payload is `{ cash, tokens }`; the script writes `CashAmount.Text` / `TokenAmount.Text` and nothing else. The figures are paid in Redwater from `RoundSystem.Config`, so a payout change there cannot leave this card advertising a stale one — the only copy to keep in step is TutorialDispatchService's `REWARD_CASH` / `REWARD_TOKENS`, which is where the payload is built. A payload carrying nothing drops the row **and** swaps the sentence that introduces it, rather than promising a reward of zero.
4. **The dropped-push race is answered with a PULL, which is what let the choice come back.** A `FireClient` at a client whose listener has not connected yet is dropped silently, and that is the whole reason the dispatch was made server-driven in the first place — a teleport waiting on the client could simply never happen with nothing reporting it. This script connects `OnClientEvent` first and *then* fires `TutorialInviteResponse("__request")`; the server re-sends the invite if the offer is still open. Either arrival raises the card and `showCard` runs once, so the ordering of the two no longer matters.
5. **The `BountyIntroComplete` wait is back** (25s cap). It went with the choice in August and had to return with it: this ScreenGui is `DisplayOrder` 80 and the loading screen is 1000, so a card raised during the cinematic offers a decision the player can neither see nor press. Waited out rather than raced; the cap is so a cinematic that never reports still gets the offer on screen. A hold card could skip this wait because it delayed nothing but the news — an offer cannot.
6. **One answer per session**, guarded by a flag rather than by disabling the buttons, so a double-tap cannot fire `"start"` twice and have the server reserve two private Redwater servers.
7. On START the card **holds** rather than closing: buttons and reward row go, the body swaps to "Teleporting to tutorial match..." and re-centres in the space they left, and only then does a 30s stuck-card watchdog arm. `ReserveServer` is a web call, and revealing the menu here would hand the player a lobby they are about to be pulled out of.
8. **The watchdog is armed only after START, never while the choice is up** — a timer that closes an offer is an auto-skip, which is the exact thing the 4s sliver was removed for. After START the card has no way out, so the backstop covers the one failure neither the teleport nor a `"failed"` message reports: a dispatch that returns early server-side and says nothing.
9. On SKIP it fires `"skip"` and closes to the lobby. The decline is recorded server-side (see TutorialDispatchService item 3b); nothing about the ladder lives here.

## Layout notes

`ProgressSliver` is **deleted** (instance and code) — it drew the 4s auto-advance, and there is no timer left for it to draw.

The `Dialog` was reshaped for the taller content on 2026-08-17: `Size` height `0.195 → 0.34` of the viewport, `UIAspectRatioConstraint` `2.8 → 1.6`, `UISizeConstraint.MinSize` height `100 → 210`. Phones are unaffected by the height fraction (the 210px floor already wins on a 360px-tall screen); it buys presence back on tablets and desktops, where a card sized for a phone reads as a notification rather than a decision. Floored on the **container**, so `StartButton`'s authored `0.21` already clears the 44px touch target and needs no constraint of its own.

`Header` is **"WELCOME TO BOUNTY"**, shortened from "WELCOME TO BULLETS AND BOUNTY" in the same pass and matching the in-lesson welcome card's copy. Not a style preference: the long version wraps to two lines inside its plaque and then renders *smaller than the body copy underneath it*, which is the type-hierarchy inversion `UI_STYLE_GUIDE.md` §3.3 warns about. The short line is height-bound at 34px on a phone against the body's 17.

`RewardRow` is an authored horizontal `UIListLayout` reading `250 [cash] and 50 [token]` — amount before icon, so the row reads as the end of the sentence above it. Icons are `UIAspectRatioConstraint` 1 / `ScaleWithParentSize` / `DominantAxis` Height, so each is square at the row height whatever the viewport. The three labels' width fractions (`0.115` / `0.09` / `0.085`) are their measured natural widths plus ~12%: that keeps every one **height-bound**, which is the only way `TextScaled` renders them at the same size, without leaving dead slack that would push the centred group off-centre. Safe to hardcode because the `Dialog`'s aspect constraint makes the row's shape viewport-independent.

**`TextScaled` requires `TextWrapped`.** Assigning `TextWrapped = false` after `TextScaled = true` silently clears `TextScaled`, which left every amount rendering at the authored `TextSize` of 8 — a row of 8px digits beside 28px icons. Both amounts and the "and" carry `TextWrapped = true` for that reason alone, not because a one-word label wants to wrap.

Screenshot-verified on desktop 1658x678, Samsung Galaxy A06 800x360 and iPad 9th gen 1080x810. The `Backdrop` scrim (black @ 0.45, `Active = true`) was A/B captured against the same viewport with the card off — it dims and it swallows input, so the menu behind cannot be reached while the offer stands.

## Dependencies

- **Requires:** Nothing
- **Required by:** Nobody

## Connections

### RemoteEvents

| Remote | Direction | Other script |
|--------|-----------|-------------|
| `TutorialInvite` | ← Server | [[TutorialDispatchService]] sends `{ cash, tokens }` to open the offer, or `"failed"` to close it |
| `TutorialInviteResponse` | → Server | [[TutorialDispatchService]] receives `"start"`, `"skip"` and the `"__request"` pull |

### BindableEvents

None

### Direct require()

None. Reads the `BountyIntroComplete` attribute on ReplicatedStorage (a plain attribute read, not a code-level connection).
