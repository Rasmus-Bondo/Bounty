---
tags: [server, modulescript, combat, networking]
path: game.ReplicatedStorage.Hunters.Dust.Modules.RevolverServer.RevolverLagCompensation
type: ModuleScript
lines: 306
---

# RevolverLagCompensation

OOP server-side lag compensation system that rewinds hitboxes to validate shots against past positions.

## What it does
1. Delegates snapshot recording + rewind time + closest-snapshot lookup to a shared [[HunterPositionHistory]] instance: records CFrame/Size snapshots of tracked body parts (Head, HumanoidRootPart, torsos — any part in `TrackedBodyParts` or with a `HitboxType` attribute) at 30Hz via Heartbeat, with rolling history pruned by `MaxHistoryTime` (default 0.65s)
2. Estimates rewind time via `HunterPositionHistory:GetRewindTime` (ping + `ExtraRewindOffset` clamped to `MaxRewindTime`)
3. `Raycast` acquires temporary Part hitboxes from a pool (`AcquireHitbox`/`ReleaseHitboxes`), parents them under `workspace.RewindHitboxes` at historical CFrames/Sizes (from the position history's snapshots), raycasts with `FilterType.Include`, then releases the parts back to the pool
4. `GetObstruction` verifies the hit isn't blocked by world geometry, walking from origin to historical hit position via [[BulletPenetration]].Pierce and ignoring all character models, the rewind hitbox folder, and every `HealthPack`'s green `Pickup` + invisible `TouchHitbox` (so the floating pickup never blocks lag-compensated hits; the solid `Base` stand still can). Returns `(blocked, penetrationLayers)` — penetrable cover no longer blocks the shot outright, it just costs damage; a wall the bullet can't punch through still blocks
5. Returns hit character, humanoid, position, headshot flag (`isHeadshot` from `IsHeadshotSnapshotPart`), and `penetrationLayers` so the caller can scale damage
6. Supports `HitboxType` attribute for custom hitbox parts (a part is tracked if it's in `TrackedBodyParts` OR has any `HitboxType` attribute; it counts as a headshot if name is "Head" or `HitboxType == "Head"`)
7. `Cleanup` disconnects the position history's heartbeat and destroys pooled hitboxes

## Team modes

Allies are dropped from the rewind candidate set, so a teammate standing where the shooter aimed
cannot absorb a rewound hit.

## Dependencies
- **Requires:** [[HunterPositionHistory]], [[BulletPenetration]] (both from `ReplicatedStorage.Hunters.Shared`), [[TeamAffinity]]
- **Required by:** RevolverModule, SunspikeModule (Vesper instantiates its own instance from VesperConfig.LagCompensation), GrudgekeeperModule (Bram instance from GrudgekeeperConfig.LagCompensation; rewinds every pellet)

## Connections
### RemoteEvents
None

### BindableEvents
None

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[HunterPositionHistory]] | `.new()`, `:Start()`, `:Cleanup()`, `:GetClosestSnapshot()`, `:GetRewindTime()` | Shared snapshot loop + ping-based rewind time + closest-snapshot lookup (replaces former inline `HitboxHistory`, `RecordHitboxHistory`, `GetClosestSnapshot`, `GetEstimatedRewindTime`) |
| [[BulletPenetration]] | `.Pierce()` | Walks the obstruction segment through penetrable cover in `GetObstruction`, returning the wall count instead of a blocked/not-blocked bool |

### CollectionService Tags
| Tag | Usage | Defined by |
|-----|-------|-----------|
| `HealthPack` | Read via `GetTagged` in `GetWorldObstructionIgnoreList`; each pack's green `Pickup` + invisible `TouchHitbox` added to the obstruction-check Exclude list (the solid `Base` stand still obstructs) | [[HealthPackSystem]] |
