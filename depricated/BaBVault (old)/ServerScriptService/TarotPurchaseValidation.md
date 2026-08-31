# TarotPurchaseValidation

Server-side validation for tarot card purchases. Checks player funds, enforces a per-session buy limit, and deducts cost from Cash.

**Path:** `game.ServerScriptService.Economy.TarotPurchaseValidation`
**Type:** Script (40 lines)
**Runs on:** Server

## How It Works

### Constants

| Constant | Value | Description |
|----------|-------|-------------|
| COST | 9.99 | Cash deducted per purchase |
| MAX_BUYS | 50 | Maximum purchases per session |

### Purchase Flow

1. Listens on `ReplicatedStorage.BuyCardsEvent` (same RemoteEvent as [[BuyCardsServer]])
2. On request:
   - Validates `leaderstats` and `Cash` exist
   - Checks `purchaseCounts[player] < MAX_BUYS` (stock limit)
   - Checks `cash.Value >= COST` (funds check)
   - Deducts `COST` from Cash, increments purchase count
   - Card logic placeholder after deduction

### Cleanup

PlayerRemoving clears `purchaseCounts[player]` (per-session tracking, resets on rejoin).

## Dependencies

- ReplicatedStorage.BuyCardsEvent — RemoteEvent
- Player's leaderstats.Cash — NumberValue (created by [[LeaderstatService]])

## Used By

- [[TarotCardMenu]] (client) — fires BuyCardsEvent to purchase cards
