---
tags: [server, script, combat]
path: game.ServerScriptService.Combat.CombatServer
type: Script
lines: 309
---

# CombatServer

Server-authoritative PVE gunplay: ammo, cadence, reload, sprint, equip and FastCast projectile damage.

## What it does
1. Keeps per-player weapon state (Revolver/Shotgun ammo, reload generation, sprint, equip delay) and pushes it to the owner via `State`; a token bucket (35 burst, 25/s) rate-limits the `Action` remote (`Fire` / `Reload` / `Equip` / `Sync` / `Sprint`).
2. Validates every shot: alive, not downed/eliminated/mounted, not outside the expedition during an encounter phase, cooldown, finite unit direction, origin within 4 studs of the head and not behind cover. Rejections set `PVEFireBlockedReason` and resync predicted ammo.
3. Fires one FastCast projectile per pellet with spread; thin wood (<=3 studs) pierces up to 2 layers and damage is scaled by `Ballistics.GetDamageMultiplier(layers)`, range falloff, headshot, Deadeye (x1.25), weapon upgrade level (+6%/level) and `PVERunDamageScale`.
4. Nudges each pellet toward a live enemy Head/UpperTorso within a 2.1/2.5-stud miss allowance when line of sight is clear (server-side moving-target compensation).
5. Batches ray hits on Heartbeat: damages enemies (Humanoid) or practice targets (`Health` attribute, auto-reset after 2 s), tallies `PVERunDamage` / `PVERunHeadshots` / `PVERunKills` while in an encounter, and confirms hits to the shooter via `Hit`.
6. Broadcasts `ShotFX`, `CastImpact` and `ReloadFX` to all clients, welds a cosmetic `PVEWorldWeapon` to the character, and forwards train-bell hits (within 300 studs) to `PVETrainBellHit`.
7. On spawn sets MaxHealth from config + `PVEGritLevel`*10 + `PVERunBonusHealth`, and cancels reload/sprint when the player is downed, eliminated or given a revive deadline.

## Dependencies
- **Requires:** [[CombatConfig]], [[Ballistics]], [[FastCastRedux]]
- **Required by:** Nobody

## Connections
### RemoteEvents
| Remote | Direction | Other script |
|--------|-----------|-------------|
| `Remotes.Action` | ← Client | [[CombatClient]] fire/reload/equip/sync/sprint requests |
| `Remotes.State` | → Client | [[CombatClient]] authoritative weapon state |
| `Remotes.ShotFX` | → All clients | [[CombatClient]] tracer/muzzle replication |
| `Remotes.CastImpact` | → All clients | [[CombatClient]] impact decals/FX |
| `Remotes.ReloadFX` | → All clients | [[CombatClient]] reload start/cancel/finish |
| `Remotes.Hit` | → Client | [[CombatClient]], [[HitFeedbackClient]], [[DamageNumbersClient]] hit confirm |

### BindableEvents
| Bindable | Direction | Other script |
|----------|-----------|-------------|
| `ServerStorage.PVETrainBellHit` | → (creates + fires) | [[MissionServer]] train-bell shot trigger |

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[CombatConfig]] | `Config.Weapons`, `MaxHealth`, `WalkSpeed`, `EquipDelay` | Weapon and player tuning |
| [[Ballistics]] | `Ballistics.GetDamageMultiplier(layers)` | Penetration damage falloff |
| [[FastCastRedux]] | `FastCast.new()`, `newBehavior()` | Projectile simulation |
