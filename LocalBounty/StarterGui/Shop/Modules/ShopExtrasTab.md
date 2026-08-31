---
tags: [client, modulescript, ui, shop, trading-post, titles, emotes, redeem]
path: game.StarterGui.Shop.Modules.ShopExtrasTab
type: ModuleScript
lines: 1159
---

# ShopExtrasTab

The EXTRAS tab of the Trading Post — the TITLES and EMOTES tiles, their card grids and purchase panel, and the redeem-code box.

## What it does
1. API: `show / transitionOut / hideRoot / isBusy / isVisible / requestDeepLink(title, emote, mode) / onShopOpened / onShopClosed`
2. Title cards cloned from `Templates.TitleCardTokens / TitleCardCash` for `TitlesConfig.Purchasable()` (canvas fitted to the rows by `Core.fitGridCanvas` — the authored 2× canvas held 8 of the 17); each preview is rendered by `TitleRenderer.apply(label, text, titleId)` (explicit `TextSize`, `fitStyledLabel`); the selected title is rendered styled on the heading AND on the purchase panel's `CharacterName` — the latter stays in the panel's fade map, so its style is applied once the fade-in has landed (static presets do not self-correct mid-tween), token-cancelled on hide or a newer selection
3. The TITLES tile runs a sliding preview loop (2.6 s dwell, 0.35 s Quint slide) over the purchasable titles while the tab is open — stopped by `onShopClosed`; the EMOTES tile's authored rig plays random emotes back to back while the home is up (`startEmoteTileLoop`: one clip at a time via `AnimationLoader.load`, played once, capped at 6 s, the next blended in 0.25 s before the end, never the same emote twice running; stopped with the title loop)
4. Emote cards from `EmoteConfig.list()` (ids) cloned from `Templates.EmoteCard` (canvas fitted to the rows — 8 of 18 were reachable before); the template's rig is swapped for the **equipped hunter** (`equippedPreviewHunter` → `ShopStandDisplay.makePreviewRig`, same pivot; `frameRig` fits the body span into the card's clear band at 0.42 of the viewport height, centre 0.55) and the cards are rebuilt on the way into EMOTES when that pair changed (`ensureEmoteCardsForEquipped`); rigs animate via `AnimationLoader.prewarm / load`, gated by `cardLoadToken`; playback only while the card is on screen. The whole tab shows the equipped hunter on the lobby stand (`ExtrasTab.show` → `Stand.showHunter`, ShopController leaves tab 4's stand to this module) under the featured close-up; selecting an emote card plays it on the stand rig (`Stand.playEmote`), the EXTRAS back button stops it and keeps the hunter. The header's own emote preview viewport was removed (owner, round 2)
5. `CosmeticPurchaseFrame`: `BuyButtonCash` / `BuyButtonTokens` / `OwnedButton` → `PurchaseTitleEvent(id)` / `PurchaseEmoteEvent(id)`; the panel descriptions were written for the migration — flag to the owner
6. Redeem box (`BackgroundStart`): `bindActionHover` re-pressable, fires `RedeemCodeRequest(code)`; the `redeem` signal paints the feedback label `FEEDBACK_OK` green / `FEEDBACK_ERR` red and hides it after 4 s. Redeem stays in Settings too (owner decision)

## Dependencies
- **Requires:** [[ShopCore]], [[ShopState]], [[TitlesConfig]], [[EmoteConfig]], [[TitleRenderer]], [[AnimationLoader]], [[ShopStandDisplay]]
- **Required by:** ShopController

## Connections
### RemoteEvents
| Remote | Direction | Other script |
|--------|-----------|-------------|
| `PurchaseTitleEvent` | → Server | [[CollectionService]] buy a title |
| `PurchaseEmoteEvent` | → Server | [[CollectionService]] buy an emote |
| `RedeemCodeRequest` | → Server | [[CodeRedemptionService]] redeem a code |

### BindableEvents
| Bindable | Direction | Other script |
|----------|-----------|-------------|
| `MenuNavigateRequested` | → | [[MenuHandlerScript]] BOUNTY PASS button on a pass-exclusive emote |

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[ShopCore]] | `bindCard / bindPurchaseHover / bindActionHover / tweenFade` | presentation |
| [[ShopState]] | `isTitleOwned / isEmoteOwned / on / fire` | state + remotes |
| [[TitlesConfig]] | `Purchasable()` | sellable titles |
| [[EmoteConfig]] | `list() / get` | emote catalog |
| [[TitleRenderer]] | `apply` | styled title previews |
| [[AnimationLoader]] | `prewarm / load` | emote clips |
| [[ShopStandDisplay]] | `showHunter / playEmote / stopEmote / state / hasHunterTemplate / makePreviewRig` | the equipped hunter on the stand for the tab, the selected emote on it, and the card rigs |
