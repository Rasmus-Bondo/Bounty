# ZoneService

Shrinking safe zone system with 4 phases. Creates fire wall visuals that close in along the Z axis, dealing damage to players outside the safe area. Similar to a battle royale zone mechanic.

**Path:** `game.ServerScriptService.RoundSystem.ZoneService`
**Type:** ModuleScript (287 lines)
**Runs on:** Server

## How It Works

### Phases

| Phase | Name | Zone Size | Damage | Fire Walls |
|-------|------|-----------|--------|------------|
| 1 | Exploration | 100% of map | None | None |
| 2 | Pressure | 100% → 75% | Yes | Created at phase start |
| 3 | Event | 75% → 50% | Yes | Moving inward |
| 4 | Final | 50% → 25% | Yes | Moving inward |

Each phase lasts `ZONE_PHASE_DURATION` (150s). Phase transitions are detected per-frame in the Heartbeat loop.

### Zone Bounds Calculation

- **Full range**: `ZONE_END_Z - ZONE_START_Z` (200 - (-700) = 900 studs)
- **Center**: midpoint + `randomCenterOffset` (randomized per round within `ZONE_CENTER_RANDOM_RANGE`)
- **Shrinking**: during each phase, zone fraction lerps from previous to target over the first half of the phase, then holds for the second half
  - Phase 2: 100% → 75%
  - Phase 3: 75% → 50%
  - Phase 4: 50% → 25%

### Zone Damage

- Runs when `currentPhase >= 2` via an accumulator pattern
- Every `ZONE_DAMAGE_INTERVAL` seconds, calls `_applyZoneDamage()`
- Only damages opted-in players with health > 0 who are outside the safe zone
- Damage per tick: `ZONE_DAMAGE_PER_SEC * ZONE_DAMAGE_INTERVAL`
- If damage would kill, sets `ShouldRagdoll = true` before applying (enables ragdoll death)

### Fire Wall Visuals (`_createFireEffects`)

Created at Phase 2 start. Two Parts (800x50x20 studs) named `ZoneFire_South` and `ZoneFire_North`:
- Anchored, non-collidable, non-queryable
- Transparency 0.6, Neon material, brown-orange color
- **Fire ParticleEmitter**: yellow → orange → red → dark red gradient, rate 200
- **Dust/Smoke ParticleEmitter**: brown gradient, rate 150, adds density
- **PointLight**: orange, brightness 4, range 60

Walls are initially spawned at map edges (±50 beyond zone bounds) and moved inward each frame by `_updateFirePositions()`.

### Safe Zone Checks

| Method | Input | Description |
|--------|-------|-------------|
| `isPlayerInSafeZone(player)` | Player | Checks player's HumanoidRootPart Z against fire wall positions (or zone bounds if no walls) |
| `isPositionInSafeZone(zPos)` | number | Checks a Z coordinate against calculated bounds |

Both return `true` if zone is inactive or phase ≤ 1.

### Workspace Attributes (client-readable)

| Attribute | Type | Updated |
|-----------|------|---------|
| ZonePhase | number | On phase change |
| ZonePhaseName | string | On phase change |
| ZonePhaseTimeLeft | number | Every frame |

### Reset (`resetZone`)

Disconnects Heartbeat, destroys fire effects, clears all workspace attributes.

## Dependencies

- [[Config]] — ZONE_START_Z, ZONE_END_Z, ZONE_PHASE_DURATION, ZONE_DAMAGE_PER_SEC, ZONE_DAMAGE_INTERVAL, ZONE_CENTER_RANDOM_RANGE, ROUND_TIME
- [[State]] — roundActive (gate for damage)
- [[LobbyService]] — isOptedIn (only damage opted-in players)

## Used By

- [[MainServer]] — Initialize() called at boot
- [[RoundController]] — startZone() in Fight phase, resetZone() in Reset phase
- [[SpawnService]] — isPositionInSafeZone() to filter spawn points
- [[ZoneIndicator]] (client) — reads workspace zone attributes for UI display
