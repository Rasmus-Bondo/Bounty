---
tags: [client, modulescript, ui, shop, trading-post, hunters, skins]
path: game.StarterGui.Shop.Modules.ShopHuntersTab
type: ModuleScript
lines: 896
---

# ShopHuntersTab

The HUNTERS tab of the Trading Post — hunter cards, the hunter purchase panel, and the per-hunter skin grid with its token purchase panel.

## What it does
1. API for ShopController: `show / transitionOut / hideRoot / isBusy / isVisible / requestDeepLink(hunter, skin)`
2. Hunter cards from `SkinCatalog.HunterOrder`; card status via ShopState (`OWNED` / price / `FREE`); accent colour read off each card's `CharacterName.TextColor3`
3. Unowned hunter → `HunterPurchaseFrame`: Robux button prompts `StoreConfig.DeveloperProducts[ProductKey]` (standalone `FortunaHunter` product, price via `Core.getProductPrice`) and plays `UIPurchaseButtonPrompt`; Cash button fires `PurchaseHunterEvent(hunter)` and locks the button as `PURCHASING…` for 5 s. The `hunters` signal (attribute flip) runs the own-hunter transition into the skin grid
4. Skin grid cloned from `Templates.HunterSkinDefault / HunterSkin` with unlock kinds `default / group / pass / bundle / tokens` (GroupPerkConfig.isGroupSkin, BattlePassConfig.isExclusiveSkin, StoreConfig.isBundleExclusive, SkinCatalog TokenPrice). Rarity words on the cards (DEFAULT / GROUP PERK / BOUNTY PASS / BUNDLE / LIMITED / RARE / EPIC / LEGENDARY by token price) were invented for the migration — flag to the owner
5. Skin panel buttons: `JOIN GROUP` → `GroupService:PromptJoinAsync(GroupPerkConfig.GroupId)`; `BOUNTY PASS` → `MenuNavigateRequested("4BattlePassFrame")`; `BUNDLE ONLY` disabled; `PURCHASE` → `PurchaseSkinWithTokensEvent(hunter, skin)`. Buy-only: no EQUIP anywhere in the shop (owner decision — equipping is the Collection's job)
6. **Stand preview** (ShopStandDisplay): the hunter list shows the equipped hunter in the equipped skin on the lobby stand; `selectSkinCard` (the one selection path — click, deep link, default) also puts that skin on the stand. The Robux hunter price is an icon + number row (`Core.attachRobuxPrice`); the skin grid's canvas is fitted to its rows (`Core.fitGridCanvas`)

## Dependencies
- **Requires:** [[ShopCore]], [[ShopState]], [[ShopStandDisplay]], [[SkinCatalog]], [[StoreConfig]], [[GroupPerkConfig]], [[BattlePassConfig]]
- **Required by:** ShopController

## Connections
### RemoteEvents
| Remote | Direction | Other script |
|--------|-----------|-------------|
| `PurchaseHunterEvent` | → Server | [[DataService]] buy a hunter with Cash |
| `PurchaseSkinWithTokensEvent` | → Server | [[DataService]] buy a hunter skin with Tokens |

### BindableEvents
| Bindable | Direction | Other script |
|----------|-----------|-------------|
| `MenuNavigateRequested` | → | [[MenuHandlerScript]] BOUNTY PASS button on a pass-exclusive skin |

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[ShopCore]] | `bindCard / bindPurchaseHover / setCardStatus / tweenFade` | presentation |
| [[ShopState]] | `ownsHunter / isSkinOwned / equippedHunterSkin / on("skins") / on("hunters") / fire` | state + remotes |
| [[ShopStandDisplay]] | `showHunter / hasHunterTemplate` | the selected / equipped skin on the lobby stand |
| [[SkinCatalog]] | `HunterOrder / Hunters / Skins / getSkin` | card data |
| [[StoreConfig]] | `DeveloperProducts / HunterCashPrices / isBundleExclusive` | prices |
| [[GroupPerkConfig]] | `isGroupSkin / GroupId` | group-perk skins |
| [[BattlePassConfig]] | `isExclusiveSkin` | pass-exclusive skins |
