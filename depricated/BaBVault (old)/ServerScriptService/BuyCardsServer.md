# BuyCardsServer

Simple relay script for the card purchase UI. When a client fires BuyCardsEvent, it echoes the event back to that same client to trigger the card display.

**Path:** `game.ServerScriptService.Economy.BuyCardsServer`
**Type:** Script (10 lines)
**Runs on:** Server

## How It Works

1. Listens on `ReplicatedStorage.BuyCardsEvent` (RemoteEvent)
2. On server event: fires the same event back to the requesting player
3. No validation logic — just a relay (comment says "put your money/check logic here if needed")

**Note:** [[TarotPurchaseValidation]] handles the actual cost/stock validation for the same event. These two scripts both listen on the same RemoteEvent.

## Dependencies

- ReplicatedStorage.BuyCardsEvent — RemoteEvent

## Used By

- [[TarotCardMenu]] (client) — fires BuyCardsEvent, receives echo to show cards
