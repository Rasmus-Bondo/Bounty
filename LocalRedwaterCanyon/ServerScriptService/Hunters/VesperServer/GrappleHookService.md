---
tags: [server, modulescript, movement, vesper]
path: game.ServerScriptService.Hunters.VesperServer.GrappleHookService
type: ModuleScript
lines: 244
---

# GrappleHookService

OOP server-side validation for Vesper's Grapple Hook. The server raycasts the hook, decides hit vs whiff, owns the cooldown (a whiff consumes half), and holds an anti-cheat grace window open until the caster lands. The pull movement itself is client-owned — the caster's client receives the validated anchor via `GrappleFX` and applies the velocity (same lesson as RevolverDashService: server-driven velocity on a client-owned character causes mid-move corrections).

## What it does
1. `TryGrapple(player, aimDirection)` — validates the aim Vector3, alive character, and 8s cooldown, then raycasts up to 125 studs from the head along the aim direction
2. The hook raycast excludes: the caster's character, `workspace.WallMap` (the invisible arena boundary — filtered by folder ancestry since its parts carry no tags or collision groups), the lag-compensation rewind hitbox folder, every alive humanoid model (the hook anchors to world geometry only, never characters), and each HealthPack's green `Pickup` + invisible `TouchHitbox` (the solid `Base` stand is still grappleable)
3. Fires `GrappleFX("Launch", ...)` to all clients before resolving the ray, so observers hear the launch rather than only a resolved hit
4. No hit → whiff: consumes `Cooldown * MissCooldownMultiplier` (half); fires `GrappleFX("Miss", player, origin, missEnd, missCooldown)` so clients draw a brief rope flash and start the shortened cooldown UI
5. Valid hit → consumes the full cooldown, calls `_beginGrappleGrace`, then fires `GrappleFX("Hit", player, origin, anchorPos, cooldown)` to all clients
6. `_beginGrappleGrace` sets `GrappleGraceUntil` (tick-based, matching MovementChecker's clock) and `IsGrappling`, then spawns a watcher that **holds the window open until the character lands** rather than expiring on a fixed timer. It polls every `GracePollInterval`, extends the grace past MovementChecker's 0.5s sample while `Humanoid.FloorMaterial` is `Air`, and on touchdown sets a final `LandingSettle` window so the arrival velocity bleeds off before checks resume. `MaxGraceTime` is a hard ceiling the window can never outlive, bounding how much immunity one validated hook can buy
7. Why landing-based: the old fixed `TravelTime + GraceBuffer` window started when the *server* validated the hook, but the client's pull only begins a round-trip later and itself runs up to `TravelTime * 2`, the landing `HopVelocity` adds ~0.6s of flight, and the character's position replicates back a further latency late — so a clean grapple needed ~1.5s of cover against a 1.35s window, and overshooting a platform (striking it at `distance / TravelTime` studs/s, so the pull never reaches the anchor and grinds out its full deadline) ran seconds longer. MovementChecker then charged weight 3 for the residual velocity, and its threshold of 5 kicks on two samples
8. A per-character token retires the previous watcher when a second grapple starts, so two loops never fight over the same attributes
9. `CleanupPlayer` clears the cooldown entry and retires any in-flight grace watcher on disconnect

**`ResetAll()` clears every grapple cooldown at round start** (2026-08-06), called by SunspikeModule on `ReplicatedStorage.RoundActive`. Absolute `os.clock()` deadlines against a server that now loops rounds; see RevolverDashService's note for the full reasoning. Grace tokens are keyed by **character** and a round start rebuilds every character, so they retire on their own and are deliberately not touched here.

## Dependencies
- **Requires:** Nothing directly (CharacterUtil, remote, and rewind folder injected via constructor config by [[SunspikeModule]])
- **Required by:** SunspikeModule

## Connections
### RemoteEvents
| Remote | Direction | Other script |
|--------|-----------|-------------|
| `GrappleFX` | → All Clients | [[SunspikeClient]] draws the rope; the caster's instance also executes the pull and starts its cooldown UI |

### BindableEvents
None

### Direct require()
None (all dependencies injected via constructor config)

### CollectionService Tags
| Tag | Usage | Defined by |
|-----|-------|-----------|
| `HealthPack` | Each pack's green `Pickup` + invisible `TouchHitbox` added to the hook raycast Exclude list (the solid `Base` stand stays grappleable) | [[HealthPackSystem]] |
