---
tags:
  - client
  - localscript
path: game.StarterGui.TutorialCompleteGui.TutorialCompleteController
type: LocalScript
lines: 153
---

# TutorialCompleteController

The tutorial's return leg: shows "TRAINING COMPLETE / REWARD [cash icon] N [token icon] N [chest icon] 1" to a player arriving back from the tutorial and pulses the PLAY button once.

## What it does

1. Reads its own arrival TeleportData via `TeleportService:GetLocalPlayerTeleportData()`; does nothing unless `tutorialComplete` is set.
2. Waits for the `BountyIntroComplete` attribute (25s cap) so the card lands after the intro camera, then shows it for `SHOW_SECONDS` (6s) and fades it out.
3. **The reward line is an authored row, not a formatted string** (2026-08-11). `Toast.RewardRow` is a Frame with a horizontal `UIListLayout` holding `RewardLabel` ("REWARD"), `CashIcon`, `CashAmount`, `TokenIcon` and `TokenAmount` (2026-08-17) and `ChestIcon` / `ChestAmount` (2026-09-07); the script only writes the two currency amounts and toggles the chest pair. It replaced a single `CashLine` TextLabel that read `+N CASH`, which is deleted. Both icons are the **same assets** `CurrencyHudGui`'s `CashFrame` (`rbxassetid://73057941480631`) and `TokenFrame` (`rbxassetid://138855504574427`) use, so the card names the two currencies the player then watches go up in the HUD chips. The chest is the LOOT tab's own art (`rbxassetid://121242329495518`), for the same reason — it names the tab the chest is waiting in. The award is Cash **and** Tokens (`Wallet` reason `tutorial_complete` for both, paid a step at a time in Redwater) **and** one super chest; if any of the three moves, the invite card in `TutorialWelcomeGui` advertises it and has to move too.
3b. **The chest rides a stamped flag, never an inference from `tutorialComplete`** (2026-09-07). TutorialDirector's `bankTutorialChest` sets `s.paidChest` only on the run that actually banked — the grant is once per account, guarded by `Lootboxes.TutorialChestPaid` — and both return paths stamp `tutorialChest` from it. A replay therefore arrives with it false and shows the two currency chips alone. Inferring the chest from `tutorialComplete` would have claimed one on every re-run.
3a. **The amount reaches this card through four hops and two of them were missing on the day Tokens landed.** `TutorialDirector` tracks `s.paidTokens`, then it has to ride *both* `stampReturnTeleportData` (the EXIT TRAINING path) **and** `sendHome`'s own `SetTeleportData` (the ordinary return), and `RoundController`'s solo drain-retry has to forward it as well. `tutorialChest` was added to all three in the same pass, for the same reason. It was on the stamp and off the teleport for part of 2026-08-17, which showed a cash-only reward on every normal run — the card was right and the payload was short.
4. **Each chip is driven by its own reward, not by the set.** A run that paid one currency shows one chip; a payout of nothing at all (an exited run, or a replay on an account whose `BonusPaid` is already burned) hides the whole row rather than claiming a reward that was not paid. Hidden children drop out of the row's `UIListLayout`, so it re-centres on whatever is left with nothing to reposition.
5. **Dismissible by clicking outside the card.** `Dismisser` is a full-screen transparent `TextButton` authored under the ScreenGui at `ZIndex = 0`, beneath the Toast; `Toast.Active = true` is what makes a click *on* the card not count as outside it, since a Frame with `Active = false` passes input straight through to the catcher underneath. Deliberately a catcher rather than hit-testing the pointer against the card's rect: this ScreenGui is `ScreenInsets = None`, and pointer coordinates and `AbsolutePosition` do not agree about the top inset. The cost is that the first click anywhere in the ≤6s window is consumed.
6. `dismiss()` is idempotent — the auto-hide timer and a click outside race by design and whichever lands first owns the fade. The fade now also tweens `ImageTransparency`, which the old TextLabel/UIStroke-only pass would have missed, leaving the reward icon hanging over the menu after the card faded.
7. Pulses the PLAY button once — resolved by its visible "PLAY" label under the main menu so a frame rename cannot break it; a miss is silently fine. The player is never auto-queued.

## Layout notes

Every label in the row is `TextScaled` with **no** size constraint, so each scales to fit its own box — which means they only render at the same size if height binds on all of them. `RewardLabel` at 0.40 of the row was width-bound and visibly smaller than the amount; it went to **0.32** (natural text width + 6%) against `CashAmount`'s 0.24, which put both on the row height.

**And the chest chip re-cut it again** (2026-09-07). Two more children plus two more gaps do not fit a row the token chip had already taken to 0.92 of its width, so the `Toast` widened at its aspect constraint — `UIAspectRatioConstraint` **2.6 → 3.15** — rather than by squeezing the labels; the `UIListLayout` padding came in `0.02 → 0.018` and the fractions re-cut to `RewardLabel` 0.25 / `CashAmount` 0.16 / `TokenAmount` 0.095 / `ChestAmount` 0.05. Every one is *wider in pixels* than before despite the smaller fraction, because the row itself grew: 0.29 of a 2.6-aspect toast is 32.5px on a phone, 0.25 of a 3.15 one is 33.8px. Content sits at 97% of the row — tight, and safe, because the icons are height-driven and the labels are `TextScaled` inside fixed boxes, so nothing in the row can grow to spill it. Verified numerically (every label height-bound at one `TextBounds.Y`) and by screenshot at 800x360, 640x480 and 1024x768.

**Making room for the token chip re-cut all of it** (2026-08-17). Two more children plus two more gaps do not fit a row that was already at 0.75 of its width, so the row widened `0.86 → 0.92` of the Toast, the `UIListLayout` padding came in `0.03 → 0.02`, and the fractions are now `RewardLabel` 0.29 / `CashAmount` 0.185 / `TokenAmount` 0.11 with the two icons square on the row height. Each is its measured natural width plus enough slack to stay height-bound — verified at 26px on all five. `CashAmount` deliberately keeps the most slack and stays `TextXAlignment = Left`, so the extra space falls on its right and the two icon+amount pairs read as two groups rather than one run of four glyphs. Safe to hardcode: `Toast` carries a `UIAspectRatioConstraint` of 2.6 (`ScaleWithParentSize`, `DominantAxis` Height), so the row's shape is identical on every viewport and these are not resolution-dependent numbers. Nothing reads one label's `TextBounds` to size the other — that is the thing that lies on real phones. Verified by screenshot on a 800x360 phone, a 1080x810 tablet and a 640x480 desktop.

## Dependencies

- **Requires:** Nothing
- **Required by:** Nobody

## Connections

None — no remotes, no requires. Reads TeleportData, the `BountyIntroComplete` ReplicatedStorage attribute, and the main menu's instances (all plain reads, not code-level connections).
