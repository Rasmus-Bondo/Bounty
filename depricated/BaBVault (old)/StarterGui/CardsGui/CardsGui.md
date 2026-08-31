# CardsGui

The card shop ScreenGui. Contains a camera-switching store view with parallax, open/close menu handling, and a purchase button for buying tarot card packs.

**Path:** `game.StarterGui.CardsGui`
**Type:** ScreenGui

## Structure

### Scripts
| Script | Type | Purpose |
|--------|------|---------|
| [[OpenStoreScript]] | LocalScript | Camera switch to shop view with parallax mouse tracking |
| [[MenuHandler]] | LocalScript | Open/close Canvas visibility, hides during rounds |
| [[BuyButtonScript]] | LocalScript | Buy card pack button with validation and state text |

### Key Children
| Child | Type | Description |
|-------|------|-------------|
| OpenButton | TextButton | Opens the card shop Canvas |
| CloseButton | TextButton | Closes the shop and restores camera |
| PreviewingCard | BoolValue | Flag used by [[OpenStoreScript]] to pause parallax during card preview |
| CanBuyPack | BoolValue | Flag set by [[CardController]] — false while cards are being flipped |
| Canvas | Frame | Main shop content area containing BuyButton and card display |

## Visibility Rules

- Hidden entirely when player is opted into a round (`OptedIn` attribute)
- [[MenuHandler]] controls OpenButton/CloseButton/Canvas visibility
- Canvas starts hidden, toggled by open/close buttons

## Dependencies

- `workspace.ShopCameraPoint` — Part used as camera anchor for shop view
- [[BuyCardsEvent]] RemoteEvent — fires purchase request to [[BuyCardsServer]]
- [[CardController]] — sets `CanBuyPack` BoolValue
- `leaderstats.Cash` — for purchase validation

## Used By

- Runs automatically in PlayerGui when the player joins
