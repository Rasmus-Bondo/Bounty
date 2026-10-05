---
tags: [client, localscript, enemies, animation, performance]
path: game.StarterPlayer.StarterPlayerScripts.Enemies.EnemyRenderer
type: LocalScript
lines: 327
---

# EnemyRenderer

Renders smooth client-side skeleton rigs over the server's lightweight hitbox proxies in `workspace.PVE_Enemies`, with distance/view culling and all enemy combat FX.

## What it does
1. Starts the chrono replication package with the ChronoConfig module, then watches `workspace.PVE_Enemies` proxies.
2. Clones `PVE.EnemyVisuals.SkeletonVisual` into `workspace.PVE_ClientEnemies` per proxy (tagged `PVEProxyId`, scaled by `PVEVisualScale`), strips scripts, makes parts non-colliding and the root anchored, and loads Idle / directional walk / Attack (and Aim for Gunslingers) tracks. Walk ids are read from the StringValue children of `ReplicatedStorage.BotAnimate.Animate` (stock Roblox Animate, used as data only), with hard-coded fallbacks.
3. Styles by `PVEArchetype` / `PVEElite`: coloured Highlights for Brute, Bomber, Gunslinger and elite, plus an `ArchetypeTag` billboard (`GRAVE WARDEN`, `UNDEAD BRUTE`, `DYNAMITE CARRIER`); Gunslingers get a revolver on a `GunslingerGrip` Motor6D.
4. Culling: always render within 135 studs, never beyond 520, otherwise only when on screen with clear line of sight; unload after 2.5 s unseen; at most 2 builds per frame. Hostile-to-all proxies are hidden while the player is in the boss arena.
5. RenderStepped lerps each visual to its proxy (snaps when `PVEChrono` is set), re-seats the gun grip, and picks the movement track from the proxy's `AIState`.
6. Plays `EnemyFX` actions: `Shot` (tracer + fire sound + attack anim), `Melee`, `Telegraph` muzzle glow, `DynamiteTelegraph` warning ring + thrown stick, `Explosion` fireball, Brute `ChargeTelegraph` / `ChargeImpact` rings, Warden telegraph anim and `WardenPhase` burst.
7. On `Died` (or `AIState == "Dead"`) ragdolls the rig with limited BallSocketConstraints in the `PVECorpses` collision group and fades it after 6 s.

## Dependencies
- **Requires:** [[chrono]]
- **Required by:** Nobody

## Connections
### RemoteEvents
| Remote | Direction | Other script |
|--------|-----------|-------------|
| `Remotes.EnemyFX` | ← Server | [[EnemyService]] shot / melee / telegraph / explosion / Warden / death FX |

### BindableEvents
None

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[chrono]] | `Chrono.Start(ChronoConfig)` | Client side of the smoothed enemy-proxy replication |
