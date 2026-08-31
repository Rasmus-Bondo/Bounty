# CombatEvents

Tiny convenience module that caches references to the two main combat events, so other scripts can `require()` it instead of doing `WaitForChild` chains.

**Path:** `game.ReplicatedStorage.Events.CombatEvents`
**Type:** ModuleScript
**Runs on:** Both (required by server and client scripts)

## Cached References

| Field | Points To | Used For |
|-------|-----------|----------|
| `GunRemote` | `Events.GunRemote` (RemoteEvent) | Client→Server shoot requests |
| `EliminatePlayer` | `Events.EliminatePlayer` (BindableEvent) | Server-side kill notifications |

## Used By

- [[GunServer]] — listens for GunRemote, fires EliminatePlayer
- [[GunClient]] — fires GunRemote on shoot
