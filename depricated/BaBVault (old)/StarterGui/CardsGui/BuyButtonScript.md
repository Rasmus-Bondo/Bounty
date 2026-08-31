# BuyButtonScript

Purchase button for buying tarot card packs. Validates cash balance, pack flip state, and stock limit before firing purchase to server.

**Path:** `game.StarterGui.CardsGui.Canvas.BuyButton.BuyButtonScript`
**Type:** LocalScript (55 lines)
**Runs on:** Client

## How It Works

1. On click: checks 3 conditions in order
2. If all pass: increments local purchase count, fires `BuyCardsEvent` to server
3. Updates button text reactively when cash or canBuyPack changes

## Validation & Button States

| Priority | Condition | Display Text |
|----------|-----------|-------------|
| 1 | `purchaseCount >= MAX_BUYS` | "OUT OF STOCK" |
| 2 | `canBuyPack.Value == false` | "FLIP ALL CARDS" |
| 3 | `cash.Value < COST` | "INSUFFICIENT FUNDS" |
| 4 | All clear | "BUY CARDS" |

## Constants

| Constant | Value | Purpose |
|----------|-------|---------|
| COST | 9.99 | Cash required per pack |
| MAX_BUYS | 50 | Per-session purchase limit |

## Dependencies

- `leaderstats.Cash` — NumberValue for balance check
- `CardsGui.CanBuyPack` — BoolValue set by [[CardController]] (false during card flip animations)
- [[BuyCardsEvent]] RemoteEvent — sends purchase request to [[BuyCardsServer]]

## Used By

- [[CardsGui]] — nested inside Canvas.BuyButton
