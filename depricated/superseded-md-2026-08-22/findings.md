# Findings — Team Deathmatch build

## Studio connections (2026-08-18)
| Place | instance_id | Role |
|---|---|---|
| Bounty | `place:131701626847012` | edit |
| Redwater Canyon | `place:98517073248449` | edit |
| Frostbite Claim | `place:134041618959520` | edit |

## Key paths (fill as discovered)
| Thing | Path |
|---|---|
| RoundController | game.ServerScriptService.RoundSystem.RoundController (2603 lines) |
| Config | game.ServerScriptService.RoundSystem.Config |
| MatchDirectoryService | game.ServerScriptService.RoundSystem.MatchDirectoryService |
| SpawnService | game.ServerScriptService.RoundSystem.SpawnService |
| BotService | game.ServerScriptService.Bots.BotService |
| Spawn pads | workspace.TeamDeathmatch.{RedTeamSpawn,BlueTeamSpawn} (both match places) |

## Damage sites (§8.1) — MUST re-grep before Phase 3; spec line numbers will drift
See spec §8.1 table for the 8 sites + ZoneService (out of scope in TDM).

## Frostbite invisible bullet-stopper (2026-08-18, marker part `prope`)

**Cause:** `Workspace.FinishSpawns.BoxPlayerSpawns.CameraPartAnimation` — Transparency 1,
CanCollide false, **CanQuery true**. 4 x 3.6 x 6.2 studs at (15.0, 49.7, -24.5), which is 5.5
studs above the Bridge deck. Players walk through it; raycasts do not. Exposure probe: 52 of 72
sightlines from 80 studs out terminate on it (68/72 from 20 studs).

It is the CFrame source for the end-of-match cinematic camera (`VictoryShowcaseClient` line 2008,
`camera.CFrame = scene.AnimationCamera.CFrame`) — geometry never used for anything. Ground-level
placement is deliberate in both maps; Redwater's twin sits at (-20.4, 43.8, -232.8), 33.8 studs
up in open air, 53/72 exposed at 80 studs. Same latent bug, less noticeable because it is above
head height.

**Fix:** `CanQuery = false` (+ `CanTouch = false`) on the part, both places. Workspace is not
mirrored, so this is two independent edits. Camera behaviour is untouched.

**Why not a raycast-side fix:** `BulletPenetration.cloneParams` copies `RespectCanCollide` from
the caller, and R15 limbs are CanCollide=false, so respecting collision would make bullets pass
through players.

**Same class, still live in Frostbite (invisible + query-able, inside playable space):**
| Part | n | Note |
|---|---|---|
| `SpawnPoints.Part` | 37 | 4 x 0.2 x 4 pads at floor level |
| `HealthPackStand.TouchHitbox` | 35 | 3^3 cube; ALREADY worked around in 13 shooter scripts' ignore lists |

**Health packs verified shoot-through in Frostbite (2026-08-18).** All 35 stands carry the
`HealthPack` tag and the `Base + Pickup + TouchHitbox` shape the `child.Name ~= "Base"` rule
expects; probe rays pass through 35/35 with the ignore list (bare rays stop on 27).
`RevolverHitForgiveness` is the only `Pierce` caller that builds no list of its own -- it takes
`rayParams` from its caller, so it inherits the exclusions. Do not re-open this: the hitboxes
are redundant, not broken.
| `FinishSpawns.Player1/2/3/PlayerLocal` | 4 | ground podium pads, superseded by BoxPlayerSpawns |
| `FinishSpawns.VictoryScreenRigSpawn` | 1 | 2.4 x 0.6 x 0.1 sliver at y 64.8 |
| `FinishSpawns.Pillars.Union` | 4 | invisible AND collidable; `RoundController.setFinishPillarsVisible(false)` clears all four flags at runtime, so authored state only matters pre-round |
