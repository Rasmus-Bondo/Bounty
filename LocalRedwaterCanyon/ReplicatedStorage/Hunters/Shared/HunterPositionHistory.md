---
tags: [shared, modulescript, combat, lag-compensation]
path: game.ReplicatedStorage.Hunters.Shared.HunterPositionHistory
type: ModuleScript
lines: 151
---

# HunterPositionHistory

OOP service that records per-entity position snapshots on a throttled Heartbeat loop and looks up the closest snapshot for a given target time. Used by every hunter's lag-compensation system to share the snapshot-recording and ping-rewind plumbing while keeping each hero's hit-resolution math independent.

## What it does
1. `.new(config)` — accepts `RunService`, `HistoryRecordRate` (default 1/30s), `MaxHistoryTime` (rolling window, default 0.65s), `MaxRewindTime` (clamp on ping-based rewind, default 0.25s), `ExtraRewindOffset` (default 0.03s), `Enabled` flag, and three callbacks: `GetTrackedEntities()` → array of `{key, character}` to snapshot each tick, `CaptureSnapshot(character)` → opaque table to store (service tags it with `.Time`), and optional `ShouldRetainKey(key)` → boolean for active cleanup of stale entries
2. `:Start()` — connects to `RunService.Heartbeat`, accumulates `deltaTime`, fires `_recordTick` every `HistoryRecordRate` seconds. Per tick: iterate `GetTrackedEntities()`, call `CaptureSnapshot(character)` for each, push to per-key history with `Time = now`, prune entries older than `MaxHistoryTime`. If `ShouldRetainKey` is provided, drop history for keys not seen this tick that fail the predicate
3. `:GetClosestSnapshot(key, targetTime)` — returns the snapshot from this key's history whose `Time` is closest to `targetTime`, or `nil` if no history
4. `:GetRewindTime(player)` — returns `math.clamp(player:GetNetworkPing() + ExtraRewindOffset, 0, MaxRewindTime)`; defaults to 0 on pcall failure
5. `:Forget(key)` — clears all history for a key (used on PlayerRemoving)
6. `:Cleanup()` — disconnects the Heartbeat connection and clears all history

## Dependencies
- **Requires:** Nothing
- **Required by:** RevolverLagCompensation (Dust), CardsServer (Fortuna)

## Connections
### RemoteEvents
None

### BindableEvents
None

### Direct require()
None
