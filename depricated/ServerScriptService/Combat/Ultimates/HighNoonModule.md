---
tags: [server, module, combat, ultimate]
path: game.ServerScriptService.Combat.Ultimates.HighNoonModule
type: ModuleScript
lines: 769
---

# HighNoonModule

The ultimate ability system. Players build charge from combat hits and passive gain, then activate a multi-target lock-on shot.

## What it does

### Charge System
- Each player accumulates ultimate charge (0–100)
- **Passive charge:** 0.125 per second, ticked every 0.25s via Heartbeat
- **Hit charge:** 1.25 per body hit, 3 per headshot (called by [[RevolverModule]])
- Sends `HighNoonChargeUpdate` to the owning client when charge changes

### Activation Flow
1. Player sends `HighNoonRequest` with aim direction
2. If charge is full (100), the ability starts:
   - Sets `IsUsingHighNoon` attribute on character (checked by RevolverModule to block shooting/dashing)
   - Slows walk speed to 6, disables jumping
   - Finds targets in a 45-degree cone, 180 stud range, with line-of-sight checks
   - Broadcasts `HighNoonVisual` to all clients for the casting animation
3. **Lock-in phase** (2 seconds): player can still look around. If they shoot early → quick shot (body damage 45)
4. **Locked phase**: targets are finalized. If they shoot now → headshot damage (125) on locked targets
5. **Max hold** (5 seconds): auto-ends if the player doesn't fire
6. On end: restores movement, clears state, broadcasts visual end

### Target Finding
- Uses its own tracked humanoid set (independent from RevolverModule's)
- Filters by: enemy check, cone angle, range, line-of-sight raycast
- Max 6 targets, sorted by distance

## Dependencies

- **Requires:** Nothing (no module imports)
- **Required by:** [[RevolverModule]] (for `addCharge`), [[Main]] (`.init()` at boot)

## Connections

### RemoteEvents

| Remote | Direction | Other script |
|--------|-----------|-------------|
| `HighNoonRequest` | ← Client | [[HighNoonClient]] sends aim direction to activate |
| `HighNoonShootRequest` | ← Client | [[HighNoonClient]] sends aim direction to fire |
| `HighNoonAimUpdate` | ← Client | [[HighNoonClient]] sends aim every 80ms during ult |
| `HighNoonVisual` | → Client | Received by [[HighNoonClient]] (Start/Locked/End + targets) and [[FPSRevolverClient]] (blocks shooting) |
| `HighNoonShot` | → All Clients | Received by [[HighNoonClient]] (local muzzle flash + tracer) |
| `HighNoonChargeUpdate` | → Client | Received by [[HighNoonClient]] (charge UI percentage) |
| `HitConfirm` | → Client | Received by [[HitMarkScript]] (hitmarker on ult kills) |

### Called by other modules

| Caller | Function | Purpose |
|--------|----------|---------|
| [[RevolverModule]] | `HighNoon.addCharge(player, isHeadshot)` | Grants charge from revolver hits |

## Public API

| Function | Called by | Purpose |
|----------|----------|---------|
| `HighNoon.init()` | [[Main]] | Sets up event listeners and passive charge loop |
| `HighNoon.addCharge(player, isHeadshot)` | [[RevolverModule]] | Grants ultimate charge on hit |
| `HighNoon.getCharge(player)` | (unused currently) | Returns current charge |
| `HighNoon.isActive(player)` | (unused currently) | Returns whether player is in High Noon |

## Key Constants

| Constant | Value | Purpose |
|----------|-------|---------|
| ULTIMATE_MAX_CHARGE | 100 | Full charge threshold |
| HIGH_NOON_LOCK_IN_TIME | 2s | Time before targets lock |
| HIGH_NOON_SHOOT_TIME | 3s | (unused, see MAX_HOLD_TIME) |
| HIGH_NOON_MAX_HOLD_TIME | 5s | Auto-end timer |
| HIGH_NOON_RANGE | 180 | Target detection range |
| HIGH_NOON_CONE_ANGLE | 45 degrees | Targeting cone half-angle |
| HIGH_NOON_QUICK_DAMAGE | 45 | Early-fire body damage |
| HIGH_NOON_HEADSHOT_DAMAGE | 125 | Locked headshot damage |
