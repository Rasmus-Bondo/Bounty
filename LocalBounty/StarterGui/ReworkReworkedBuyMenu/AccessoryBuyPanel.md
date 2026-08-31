---
tags: [client, modulescript, ui, shop, trading-post, emotes, titles, cosmetics]
path: game.StarterGui.ReworkReworkedBuyMenu.AccessoryBuyPanel
type: ModuleScript
lines: 301
---

# AccessoryBuyPanel

> **SUPERSEDED 2026-08-23.** The Trading Post is now `StarterGui.Shop` (ShopController + Shop.Modules.*). This ScreenGui is kept `Enabled = false` for one release as the rollback, and its LocalScripts are `Disabled = true` (they played purchase SFX and pulled state even while hidden). Nothing enables it; MenuHandlerScript, CurrencyHudController, BattlePassClient, ReworkedUIPlay and the Collection Shop module all point at `Shop` now. The text below describes the retired script as it still exists in Studio.

The shared right-hand info panel and BUY button of the Trading Post **ACCESSORIES** tab.

## What it does
1. **One owner for one panel.** The ACCESSORIES tab has TWO card grids owned by two different scripts — EmoteBuyController and TitleBuyController — but a single info panel (`EmoteBuyFrame.BuyHunterFrame`) between them. Both require this module and get the **same object back** (`AccessoryBuyPanel.get(infoFrame)` memoises per frame), so whichever half is showing drives the widgets and the two can never fight over them
2. **Selecting a card fills the panel and arms a real BUY button**, replacing the old flow where the card's own price strip was the purchase. That matches how the HUNTERS and SKINS tabs already read, and a shop whose price tag doubles as the buy button is a mis-click waiting to happen
3. **The widgets are AUTHORED, not built here.** `PriceLabel` and `PurchaseFrameCash` already sat in the panel, both `Visible = false` and unused, and are the same components the other tabs buy through — so the button matches the rest of the shop without a hand-rolled corner or stroke. ⚠️ That matters twice over in this GUI: authored `UIStroke.Thickness` here is a **scale** (the designer's value is `0.03`), so assigning a plain pixel `1` renders a ring hundreds of pixels thick and swallows the panel. Clone the authored art; never restyle it by hand
4. `setCopy(title, class, description)` writes the panel's three text lines; passing `nil` for a line leaves it alone, so a caller can set the item's name and kind while TitleBuyController's mode blurb stays in the Description
5. `setOffer(offer)` drives the price line and the button: `priceAmount` + `priceCurrency` (`"Cash"` / `"Tokens"`) for a real price, or `priceText` for a state that is not one; then `actionText`, `enabled`, `onActivate`. Neither price field means no price line at all, and passing `nil` clears the panel back to "nothing selected". An **armed** button keeps its glow lit so it reads as the call to action before the pointer reaches it; an inert one (OWNED) stays dark
5a. **The price reads as a COIN and a number — `600`, never "600 CASH".** This panel was the one place in the shop that spelled the currency out: the lobby currency bar, the emote and title cards behind it, and the HUNTERS and SKINS panels all show the icon, so the word was both redundant and inconsistent. `CurrencyLabel` is an authored **child** of `PriceLabel` — cloned from the skin panel's, so it carries the same art and the same `UIShadow` — which is what makes the two travel together
5b. **Both pieces move when a price gains a digit.** The number is centre-aligned in a full-width label, so its left edge — exactly where the coin has to sit — travels with its width, and the label itself slides right by half of (coin + gap) to re-centre the **pair** on the panel (that shift is constant; only the coin's x depends on the number). ⚠️ Oswald is **not** tabular here — `1` is 27/100 of the text size against `0`'s 35, and the thousands separator is 13 — so the width is *measured* per string with `TextService:GetTextSize` at a reference size, not counted in digits. Nothing reads `AbsoluteSize`: the shop canvas is aspect-locked 16:9 and every frame between it and this label is sized in pure scale, so the label's own aspect is a constant at any resolution — which also keeps the maths off the pre-layout path where `AbsoluteSize` reads 0 and off `TextBounds`, which over-reports on a real phone. Verified at 600 / 1.500 / 250 Tokens: the pair lands within half a pixel of the panel's centre in each
5c. A **word** state (`priceText` — a pass-exclusive emote's "BOUNTY PASS") hides the coin and puts the label back on its authored centre, since an unlock route is a sentence rather than an amount. The authored position is captured once in the constructor for exactly this reason: re-reading it after a price had moved the label would compound the shift on every selection. The panel **formats the number itself**, with the same thousands separator the cards use, so the text and the coin's position can never disagree
6. **`Activated` is connected ONCE, in the constructor**, and dispatches to whatever `onActivate` the current offer set. Re-connecting per selection instead would stack a handler for every card ever clicked and fire one purchase per stacked handler
7. Hover / press feedback (scale + glow) matches HuntersBuyController's `setupPurchaseHover`, so an armed buy button on this tab lights the same way it does on HUNTERS and SKINS
8. `AccessoryBuyPanel.setGlow(frame, shown)` is exported as a static for callers that clone one of these authored purchase frames for another job — TitleBuyController's EMOTES | TITLES toggle borrows the styling and lights the selected half with it
9. **Purchases stay server-authoritative.** This module never resolves a price or charges anything, and it fires no remote of its own; it calls back into the controller that set the offer, which sends an id-only remote and lets CollectionService resolve cost and currency through Wallet (plain text, not links — this module has no code-level connection to either)

## Dependencies
- **Requires:** Nothing
- **Required by:** EmoteBuyController, TitleBuyController

## Connections
### RemoteEvents
None

### BindableEvents
None

### Direct require()
None
