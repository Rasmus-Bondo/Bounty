# State

Shared mutable state table for the round system. All modules read and write from this single table to coordinate round lifecycle.

**Path:** `game.ServerScriptService.Shared.State`
**Type:** ModuleScript (19 lines)
**Runs on:** Server

## Fields

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| roundActive | boolean | false | Whether a round is currently in progress |
| roundStarting | boolean | false | True during the brief setup phase before fight begins |
| currentPhase | string | "Waiting" | Current phase: "Waiting", "Intermission", "Fight", "Ended" |
| roundCancelled | boolean | false | Set true to abort the current round |
| playerKills | table | {} | Map of Player → kill count for current round |
| playerDeaths | table | {} | Map of Player → death count for current round |
| optedInPlayers | table | {} | Tracks which players have opted into the round |

## Methods

### State:reset()
Resets `roundActive`, `roundStarting`, `currentPhase`, `roundCancelled`, and `playerKills` to defaults. Note: `playerDeaths` and `optedInPlayers` are NOT reset by this method — `playerDeaths` is reset separately in [[RoundController]].

## Dependencies

- None — pure data table

## Used By

- [[RoundController]] — primary consumer, drives all state transitions
- [[RagdollService]], [[SpawnService]] — read `roundActive` to gate behavior
