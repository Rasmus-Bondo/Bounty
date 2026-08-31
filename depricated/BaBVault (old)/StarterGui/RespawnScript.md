# RespawnScript

Simple respawn countdown overlay. Shows "Respawning in X..." and counts down to 1 before hiding.

**Path:** `game.StarterGui.RespawnGui.RespawnScript`
**Type:** LocalScript (17 lines)
**Runs on:** Client

## How It Works

1. Listens for `RespawnCountdown` RemoteEvent
2. Receives `delay` (number of seconds)
3. Shows CountdownFrame, updates label each second: `"Respawning in 3..."`, `"2..."`, `"1..."`
4. Hides frame after countdown completes

## GUI Elements

| Element | Type | Description |
|---------|------|-------------|
| CountdownFrame | Frame | Container for countdown display |
| CountdownLabel | TextLabel | "Respawning in X..." text |

## Dependencies

- [[RespawnCountdown]] RemoteEvent — in Events folder, fired by [[SpawnService]] on player death

## Used By

- Runs automatically in PlayerGui when the player joins
