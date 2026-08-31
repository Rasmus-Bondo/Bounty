---
tags: [client, modulescript, ui, collection, navigation, shop-handoff]
path: game.StarterGui.CollectionGui.CollectionGuiController.Shop
type: ModuleScript
lines: 260
---

# Shop

The hand-off OUT of the wardrobe.

## What it does
This menu is a **WARDROBE, NOT A SHOP**: it shows locked hunters, skins, guns, titles and emotes, and previews them, but never sells one. So a locked selection used to dead-end on the word LOCKED with no hint of where the item comes from. Instead the shared EQUIP button becomes the hand-off: it **names** the destination and takes the player there.

1. `skinUnlock(hunter, skin, kind)` and `titleUnlock(titleId)` return the button wording followed by `navigate`'s own arguments, in `navigate`'s order so a caller hands them straight back: `(buttonText, bottomTabFrame, accessoryMode, tradingPostTab, deepLink, action)`. **Both the label path and the click path call the same helper**, which is what makes it impossible for the label and the destination to disagree
1b. `activateSkinUnlock(hunter, skin, kind)` is the **click** half — call this rather than `navigate` directly. `action` names the rows that are not a navigation at all, and a caller that ignores it navigates nowhere
1c. `promptGroupJoin()` opens `GroupService:PromptJoinAsync` in place. ⚠ Never `GuiService:OpenBrowserWindow` — it is RobloxScriptSecurity, silently rejected in a shipped client while resolving fine under edit-mode security, which is how the Trading Post's copy of this button shipped doing nothing
2. `navigate(frameName, accessoryMode, shopTab, deepLink)` — **announces a destination** rather than reaching into the shop's internals. Sets `TradingPostRequestedTab` and, for an accessory, `AccessoryModeRequest` — both on the `StarterGui.Shop` ScreenGui itself since 2026-08-23 (the old per-frame `EmoteBuyFrame` attribute went with the old GUI); ShopController reads and **clears** every request attribute on open, so none can hijack a later visit. Then fires `MenuNavigateRequested`, which runs the same camera-flight + tab-highlight path a real tab click takes
3. `deepLink` names **the item, one level below the tab** — `{ hunter, skin }`, `{ weaponHunter, weaponSkin }`, `{ title }` or `{ emote }` — published as six `Requested*` attributes on the `Shop` ScreenGui. Landing the player on the right tab and leaving them to find the thing they just clicked is most of the way to a dead end, so the shop drills in the rest of the way itself. ShopController consumes all six and forwards them to ShopHuntersTab / ShopWeaponsTab / ShopExtrasTab `requestDeepLink`. **All six are cleared on every `navigate`** — a navigation the player backed out of before the shop consumed it would otherwise steer an unrelated later visit
3. `CURRENCY_ICON` — the same Cash/Tokens art the Trading Post cards and the lobby currency bar use, so the currency is answered by the icon rather than by reading a word
4. `Shop.closeMenu` is **injected by the controller** (Panels owns `setOpen`). Firing the navigate bindable bypasses the bottom-bar buttons, and it is those buttons' handlers that normally close this menu — without closing it here the Collection panels stay on screen **over** the shop. Injected rather than required so Shop has no dependency on the panel layer

| Locked selection | Button | Destination | Lands on |
|---|---|---|---|
| Hunter not owned (any of its skins/guns) | `UNLOCK <HUNTER>` | Trading Post `2Hunters` | that hunter's own page |
| Pass-exclusive skin or gun | `VIEW IN BOUNTY PASS` | `4BattlePassFrame` | the pass (no item page) |
| Group-perk hunter skin (Wraith) | `JOIN GROUP TO UNLOCK` | **none** — `action = "groupJoin"` | stays in the wardrobe; join prompt opens over it |
| Any other hunter skin | `PURCHASE` | Trading Post `2Hunters` | that hunter, then that skin |
| Any other gun skin | `PURCHASE` | Trading Post `3Skins` | that hunter, then that gun |
| Purchasable title | `PURCHASE` | Trading Post ACCESSORIES, TITLES half | that title's card, scrolled to |
| Pass-granted title | `VIEW IN BOUNTY PASS` | `4BattlePassFrame` | the pass (no item page) |
| Ranked season title | `TOP 3 IN A RANKED SEASON` | **none** | normally unreachable — TitlesTab hides an unowned one |
| Locked emote | `LOCKED` + its own shop button | Trading Post ACCESSORIES, EMOTES half | that emote's card, scrolled to |

An **unowned hunter deep-links to the hunter, never to the skin** — her page is where the blocking purchase is, and it lists her skins anyway. The Bounty Pass has no per-item page, so those two rows carry no deep link.

⚠ **WHICH TAB SELLS WHAT IS NOT WHAT THE INSTANCE NAMES SUGGEST, AND EVERY ROUTE STRING HERE IS AN INSTANCE NAME.** The tab named **`3Skins` is the WEAPON tab** — it reads **"WEAPONS"** on screen (renamed 2026-07-30) but the instance kept its old name, so `3Skins` in this module means *guns*. ShopController maps it onto its WEAPONS tab. **Hunter skins are a drill-down inside "HUNTERS" (`2Hunters`)**, one level below the hunter grid — route a hunter skin to `3Skins` and the player lands on guns. The ACCESSORIES route is the same trap: `4Emotes` is the new shop's EXTRAS tab, and it hosts titles too.

An unowned hunter routes to `2Hunters` before anything else because it is the blocking purchase: no Fortuna skin is usable without Fortuna.

**Dust's `Wraith` reads `JOIN GROUP`, not `PURCHASE` (fixed 2026-08-12).** It is an Outlaw Syndicate group perk that cannot be bought at any price in any currency, so `PURCHASE` was a lie — the same rule that gives pass skins `VIEW IN BOUNTY PASS`. The reason it read wrong for so long is that the group-skin list was **server-side only**, in DataService, where this panel could not reach it; it now lives in `ReplicatedStorage.GroupPerkConfig`, which the server and all three shop/wardrobe surfaces read. The branch sits **after** the pass lookup and is gated on `kind == "hunterSkin"`, because that config lists hunter skins only and a gun skin must never match a hunter skin sharing its name.

**It is the only row with no destination.** Every other unlock is somewhere the player must be taken; a group join is a prompt that opens on top of wherever they already are, so the branch returns no `frameName` and an `action` instead. It briefly routed to the Trading Post card for the explanation, which meant leaving the wardrobe and pressing a second `JOIN GROUP` to do one thing — changed 2026-08-12 to prompt in place. The Trading Post card keeps its own button and its own copy of the prompt.

`VIEW IN BOUNTY PASS` never shows a price, because a pass item cannot be bought at any price. `BattlePassConfig` is resolved inside the function and wrapped in `pcall`: if it cannot be loaded the routing falls through to `PURCHASE`, and the shop card there still reads BOUNTY PASS.

## Dependencies
- **Requires:** [[Refs]], [[State]], [[TitlesConfig]], [[BattlePassConfig]], [[GroupPerkConfig]]
- **Required by:** SkinsTab, TitlesTab, EmotesTab, Panels

## Connections
### RemoteEvents
None

### BindableEvents
| Bindable | Direction | Other script |
|----------|-----------|-------------|
| `MenuNavigateRequested` | → | [[MenuHandlerScript]] runs the same camera flight + tab highlight a real bottom-bar tab click takes |

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[Refs]] | `playerGui` | Reaching the buy menu to set its request attributes |
| [[State]] | `isHunterOwned()` | An unowned hunter is the blocking purchase |
| [[TitlesConfig]] | `UnlockOf()` | `purchase` routes to the shop; `source == "rank_season"` dead-ends; every other grant is the pass |
| [[BattlePassConfig]] | `isExclusiveSkin()` | Tells a pass skin from a shop one. Required **inside** `skinUnlock` and pcall-guarded |
| [[GroupPerkConfig]] | `isGroupSkin()`, `GroupId` | Tells a group perk from a sale, so Wraith reads `JOIN GROUP TO UNLOCK` rather than `PURCHASE`, and supplies the id `promptGroupJoin` passes to `PromptJoinAsync`. Required at the top like `TitlesConfig`, not lazily — it is plain data and the label path calls it on every selection change |

**`grant` no longer implies "pass level" (2026-08-27).** `titleUnlock`'s fallback used to send every non-purchasable title to the Bounty Pass, on the stated assumption that every `grant` in TitlesConfig was a pass level. Ranked season titles broke that: routing one to the pass sends a player hunting for something that was never on it. The fallback now checks `unlock.source == "rank_season"` first and returns a label with **no destination**, the shape the group-perk row already uses, because a placement in a season that has closed is not somewhere anyone can be sent. TitlesTab hides unowned season titles outright, so this is the belt to that braces.
