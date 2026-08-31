---
tags:
  - server
  - modulescript
  - vfx
path: game.ServerScriptService.VFX.DashDustVFXServer
type: ModuleScript
lines: 69
---

# DashDustVFXServer

Server-side dash dust trail effect that spawns ground-level dust stamps behind dashing characters.

## What it does

1. Creates a DashDustVFX instance with configurable trail timing, spread, color, size, opacity, and rise velocity
2. Listens to the `DashRequest` RemoteEvent for incoming dash directions from clients
3. Validates the move direction (must be Vector3 with magnitude > 0.05) and checks that the player has a living character
4. Calls `dashDust:StartTrail()` to spawn a sequence of dust stamps behind the character using raycasts to find ground position
5. Cleans up per-player trail state on PlayerRemoving

## Dependencies

- **Requires:** RevolverRemoteSetup, DashDustVFX (from `ReplicatedStorage.Hunters.Dust.Modules.RevolverServer`), [[HunterSelectionService]] (gates Dust-only behavior), [[DashDustVFX]], [[RevolverRemoteSetup]]
- **Required by:** Main

## Connections

### RemoteEvents

| Remote | Direction | Other script |
|--------|-----------|--------------|
| `DashRequest` | ← Client | Client sends dash direction; also handled by [[RevolverModule]] for movement |

### BindableEvents

None

### Direct require()

| Target | Function | Purpose |
|--------|----------|---------|
| RevolverRemoteSetup | `.EnsureAll()` | Gets reference to DashRequest remote |
| DashDustVFX | `.new()`, `:StartTrail()`, `:CleanupPlayer()` | Dust stamp trail generation and cleanup |
