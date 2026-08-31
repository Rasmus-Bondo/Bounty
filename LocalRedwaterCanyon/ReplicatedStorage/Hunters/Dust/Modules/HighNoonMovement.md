---
tags: [shared, modulescript, movement, ultimate]
path: game.ReplicatedStorage.Hunters.Dust.Modules.HighNoonMovement
type: ModuleScript
lines: 65
---

# HighNoonMovement

Dust's High Noon root. Registers the ultimate's crawl speed as a movement **base** on [[HunterMovement]] and drops it when the ult ends.

## What it does
1. `Capture` is now a no-op marker, kept only so HighNoonModule's call sites and its `endHighNoon(oldMovement)` signature stay put. There is deliberately nothing to capture: the absence of a snapshot is the fix. The old version saved the speed to restore after the ult, and capturing a live value while slowed used to strand Dust below passive after it ended
2. `Lock` registers `HighNoon` as an Ultimate-priority base with `LockJump = true`. Ultimate priority outranks the hunter's passive and any ability base, so an enemy slow landing mid-ultimate composes with the crawl (`6 * 0.75 = 4.5`) instead of measuring against Dust's passive — which would let a "slow" move him faster than the ult does. `LockJump` hands the `JumpPower` / `JumpHeight` / `AutoJumpEnabled` save-restore to [[HunterMovement]], which releases it when the base clears, including by TTL or on death
3. `Restore` clears the base. The speed Dust returns to is recomputed from whatever is still live at that moment, not replayed from a snapshot

## Dependencies
- **Requires:** [[HunterMovement]]
- **Required by:** HighNoonModule

## Connections
### RemoteEvents
None

### BindableEvents
None

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[HunterMovement]] | `SetBase` / `ClearBase` | Register High Noon's crawl speed + jump lock as a keyed Ultimate-priority modifier |
