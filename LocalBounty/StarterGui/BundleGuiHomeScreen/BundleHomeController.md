---
tags: [client, localscript, store, monetization, ui]
path: game.StarterGui.BundleGuiHomeScreen.BundleHomeController
type: LocalScript
lines: 479
---

# BundleHomeController

Drives the LET THE HUNT BEGIN bundle card on the lobby home screen — visibility gates, live Robux price, the Vesper preview rig, and the purchase prompt.

## What it does
1. Reads the product id and its contents from [[StoreConfig]] `BundleProducts.LetTheHuntBegin`, the same table the receipt handler grants from, so the card cannot advertise something the purchase does not deliver. Bails early (card stays hidden) if the entry is missing
2. Gates visibility on four conditions, all of which must hold: the lobby intro has finished (`ReplicatedStorage.BountyIntroComplete` attribute, with a 12s fallback), the menu is on the Home page, ownership has actually been answered, and the answer was "not owned". The ownership-answered gate is capped at 10s so a lost payload shows the card rather than hiding it forever — without it `owned` starts false and every owner watches the card flash up and vanish as `SkinDataEvent` lands
3. Reveals by **fading**, matching the settings gear (`SettingsController`): 0.4s Quad Out once `LoadingScreen` hands off, plus a small `UIScale` pop. A ScreenGui has no transparency of its own and a `CanvasGroup` rasterises its subtree, which the `ViewportFrame` does not survive — so the authored transparency of all 18 painted properties is collected once and replayed. Collected, never hardcoded: the strokes sit at `0.37` and the shadows at `0.11` / `0.26`, and a fade returning everything to 0 would brighten the card on every re-show. The rig's parts are left alone; `ViewportFrame.ImageTransparency` fades the whole 3D render in one property
4. Tracks ownership from the `SkinDataEvent` payload's `ownedSkins` / `ownedWeaponSkins` tables. Counts as owned as soon as **any** grant has landed, so a half-owner stops seeing the card. A grant kind the script does not recognise is skipped rather than counted as owned
5. Fires `RequestSkinData` on start as the pull half of the join handshake: `SkinDataEvent` is a one-shot push at profile load, and one that arrives before this script connected would sell the bundle back to someone who already owns it
6. Fills `PurchaseButton.PriceLabel` from `MarketplaceService:GetProductInfoAsync`, so the displayed price follows regional pricing rather than the authored placeholder
7. Opens `PromptProductPurchase` from either the `PurchaseButton` or the full-card `CardHitbox`. The hitbox exists because on the smallest supported phone (800x360) the button renders 61x20 — under the 44x44 touch minimum — while the card is 160x52; it sits at `ZIndex` 0 so it only catches taps the button did not
8. Re-requests skin data on `PromptProductPurchaseFinished`, covering a grant push that races the prompt closing
9. Keeps the card clear of the pinned top-right row (settings gear; the build tag shares it). That row is pinned in **pixels** while the card is placed in **scale**, so it takes a growing share of a shrinking viewport and the card slid under the gear on a phone. Targets `rig top = gear bottom + 11px`, pushing the card down only by the overlap so wide viewports keep the authored position untouched (iPhone 7 +48px, desktop +15px). Re-runs on rotate/resize; the authored `Position` keeps a zero pixel offset, the push is runtime state.

    Both sides of the comparison are **measured**, and that is load-bearing. The ViewportFrame is `RelativeXX`, so the rig overhangs the card by half the card's *width* — a quantity that moves with the aspect ratio. And the gear is read from its own rect rather than the `44 at y 10` its ScreenGui authors: `AbsolutePosition` is reported with the topbar already removed, so the gear reads `y -48..-4` for an authored `10..54`. Comparing a measured `AbsolutePosition` against the authored constant mixes two coordinate spaces — that shipped once and pushed the card 58px too far down, which looks correct in the Studio preview (where the shift is 0) and wrong in the hand. The comparison is only legal because `ReworkedSettingsGui` and this ScreenGui are both `ScreenInsets = None`
9. Prepares the preview rig in the authored `ViewportFrame`: strips its scripts (the stock `Animate` would fight the clip from Idle priority), makes every part massless and non-colliding, and anchors **only** the root so the pose can still animate. Plays the clip named by the `ViewportFrame.AnimationID` NumberValue through [[AnimationLoader]] at Action priority, looped

## Dependencies
- **Requires:** [[StoreConfig]], [[AnimationLoader]]
- **Required by:** Nobody

## Connections
### RemoteEvents
| Remote | Direction | Other script |
|--------|-----------|-------------|
| `SkinDataEvent` | ← Server | Ownership payload; created and fired by [[DataService]] |
| `RequestSkinData` | → Server | Pull half of the join handshake; handled by [[DataService]] |

### BindableEvents
None

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[StoreConfig]] | `BundleProducts.LetTheHuntBegin` | Product id and the list of cosmetics the card advertises |
| [[AnimationLoader]] | `load()` | Play the preview clip only once its asset is confirmed fetched — a bare `LoadAnimation` returns a valid track for a clip that never downloads, which is how a preview ends up silently T-posed |

## Notes
Reads the `SelectedMenuFrame` attribute published on MainMenuGui by MenuHandlerScript to know which bottom-tab page the menu is on — the one function every navigation route passes through. Hooking the tab buttons instead would miss every hand-off, and `ResetOnSpawn` is false on this ScreenGui, so one missed return to Home would hide the card for the rest of the session.

The card is authored top-right at `ScreenInsets = None` so it reaches the physical right edge on touch devices; the currency HUD occupies the strip above it.
