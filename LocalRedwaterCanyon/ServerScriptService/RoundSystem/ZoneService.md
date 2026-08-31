---
tags:
  - server
  - modulescript
path: game.ServerScriptService.RoundSystem.ZoneService
type: ModuleScript
lines: 1231
---

# ZoneService

Shrinking zone system that forces players into a smaller area over time with scaling damage.

## What it does

1. Runs a 4-phase zone shrink: Exploration, Pressure, Event, Final
2. Each phase lasts `ZONE_PHASE_DURATION` seconds and shrinks the safe **area** by 25%
2a. **The shape of that shrink is per-map data, not code** (2026-08-13). `_getZoneFraction()` owns the schedule and is shape-free — it returns the fraction `f` of the map's original playable area still safe, walking `ZONE_FIRE_SPAWN_FRACTION` → 0.75 → 0.50 → 0.25 exactly as before. Only the mapping from `f` to geometry branches on `MapConfig.Zone.Shape`: `_getZoneBounds()` gives `halfSpan = fullSpan * f / 2` for `"linear"` (Redwater, two walls closing on Z), `_getZoneCircle()` gives `radius = StartRadius * sqrt(f)` for `"radial"` (a closing ring). The square root is the point — a span shrinks area linearly while a radius shrinks it quadratically, so applying `f` straight to a radius would end the round in a circle 4.7x smaller than Redwater's final strip on the same timer. Every phase constant is shared, unchanged, by both shapes
3. Zone centre has a random offset each round for variety. `randomCenterOffset` is a `Vector2` on the XZ plane; linear reads only its `.Y` (Z is its one axis) and draws one number, radial jitters both. Published once per round as the `ZoneCenter` workspace attribute, which is how the client's ZoneAtmosphere locates a ring it cannot ask a server module about
4. Creates fire wall visual effects (Part + ParticleEmitter + PointLight) at zone boundaries starting in Phase 2. Linear builds two 800-stud slabs; radial builds 12 tangent chord segments in a `workspace.ZoneFireRing` folder, each resized as the ring closes — a fixed-width chord would leave the ring a twelve-pointed star with flames tens of studs outside the boundary the damage tick uses. Emitter columns, ground trail and burned-smoke volumes are shared between the shapes and budgeted to the same totals
5. Tracks per-player fire time and applies linearly scaling damage (starts at `ZONE_DAMAGE_BASE`, ramps by `ZONE_DAMAGE_RAMP_PER_SEC` per second, capped at `ZONE_DAMAGE_MAX`). Damages bots in `workspace.ArenaBots` through the same ramp.
5a. When a tick will be lethal, sets the victim character's `KilledByZone` attribute **before** applying the damage (so it is present even if `Humanoid.Died` fires synchronously), and clears it again if immunity (spawn protection / victory `ForceField`) actually blocked the hit. The death handlers (RoundController for players, BotService for bots) read this attribute and, when set, credit **no kill to anyone** while still resolving assists for recent contributors — so a firewall finish never hands a kill to whoever last shot the victim.
6. Resets accumulated fire time when a player re-enters the safe zone
7. Sets `ZoneFireTime` attribute on each player for client-side visual feedback
8. Sets workspace attributes (`ZonePhase`, `ZonePhaseName`, `ZonePhaseTimeLeft`) for client UI
9. Fire walls move inward during the first half of each phase, then hold
10. Cleans up per-player state on PlayerRemoving and round reset
11. **`getSafeClearance(position)` is the one safe-zone primitive** — studs the position sits inside the fire's inner **face** (boundary minus the 10-stud half-thickness), negative in the flames, `math.huge` while the zone is idle or in Phase 1. It replaced `getSafeZBounds`, whose `(minZ, maxZ)` return has no radial meaning, on 2026-08-13: three of that function's four callers were deriving exactly this number from the pair, so a shape-tagged return would have put the shape branch in all four. It reads the live fire parts rather than recomputing from `f`, because the flames are what a player burns against. `isPositionInSafeZone(position, extraMargin)` is a thin wrapper applying **no margin of its own** — `extraMargin` defaults to 0, so a bare call accepts a position standing directly on the flames. Callers that place something must pass a margin: BotPathing uses `BotConfig.FirewallAvoidanceMargin` (26), and SpawnService `getSafeSpawnPool` its derived 27-stud `SPAWN_ZONE_MARGIN`
11a. Both take a **`Vector3`, not a Z coordinate**, and raise on anything else rather than coercing — a radial zone needs both ground axes, and the quiet version of that mistake is a bot pathing confidently into the fire. `clampPositionToSafeZone(position, extraMargin)` returns the nearest position with that much clearance, preserving Y: it slides along Z on a linear map and along the radius on a radial one, and collapses to the centre when the margin exceeds what is left of the zone
12. `resetPlayerFireTime(player)` zeroes the burn ramp and the `ZoneFireTime` attribute. Called by SpawnService on every validated placement — the ramp is otherwise only cleared by a live tick that finds the player back inside the safe area, so it survived death and carried cap damage into the next life
13. **The tutorial zone is gone** (2026-08-16). `startTutorialZone` and every `tutorialZone` branch (the compressed 0.75 → 0.25 interpolation, the pinned centre offset, the spawn-fraction override, the `resetZone` clear) were deleted with the lesson's relocation to the walled bowl: on a linear map `getSafeClearance` tests Z only, so at the bowl's X (~−1600) the fire was invisible and the damage still applied — the lesson runs zoneless now, and nothing on a tutorial server starts any zone. One tutorial guard survives: the bot half of `_applyZoneDamage` still early-returns on `State.tutorialMode`, dead in practice with no zone running but harmless

## Dependencies

- **Requires:** [[Config]], [[State]], [[MapConfig]]
- **Required by:** RoundController, SpawnService, BotPathing

## Connections

### Direct require()

| Target | Function | Purpose |
|--------|----------|---------|
| [[Config]] | Constants | Damage rates, phase duration, closing fractions |
| [[MapConfig]] | `Zone.Shape`, `Zone.Start` / `End` / `Axis` (linear), `Zone.Center` / `StartRadius` (radial) | This map's zone shape and geometry. A linear map declaring a non-Z `Axis` asserts at require time rather than rendering its zone 90 degrees out |
| [[State]] | `State.roundActive` | Gate zone damage application |
