---
tags: [shared, modulescript, config, combat]
path: game.ReplicatedStorage.Hunters.Dust.Modules.RevolverConfig
type: ModuleScript
lines: 146
---

# RevolverConfig

Central configuration table for all revolver weapon parameters.

## What it does
1. Defines Combat settings: range (**250** — this is the CLIENT TRACER length and must equal `RevolverServerConfig.Combat.Range`, or the tracer draws visibly past the point the server stops scoring damage; cut from 500 on 2026-08-29), fire cooldown (0.4s), max ammo (6), reload time (1.5s)
2. Defines Skill2 settings: E key, 8s cooldown, camera kick values, and **`ShotInterval` (0.0833s), the burst's authored fire rate** — RevolverAnimations stretches the Fanning clip to land on this interval, so swapping the animation no longer moves the pace. It replaced `AnimationSpeed`/`FallbackAnimationLength` on 2026-08-24: the old pair derived the interval *from* the clip (`FanningLength / AnimationSpeed`), which meant whatever rig was equipped set the ability's fire rate. The rig that exposed it was Icefang, carrying a 0.167s Fanning against the default's 0.233s, so its burst ran at 0.060s — under the server's 0.07s `Skill2FireCooldown` — and RevolverModule silently dropped about half the shots. That clip was not skin art: Icefang had been forked off the July default set and missed the August re-author, corrected 2026-08-27, so every Dust rig now shares one clip set
3. Defines Dash settings: Q key, 4s cooldown, 0.5s duration, air dash caps
4. Defines Reload settings: R key, left arm show/hide delays, sound timings
5. Defines ViewModel settings: base offset, sway, strafe tilt, bob, idle motion
6. Defines Recoil settings: pitch/yaw impulse, camera kick, spring strength, FOV kick
7. Defines AirHang settings: strength (0.32), max fall speed (-90)
8. Defines Sprint settings: LeftShift key, 1.25x speed multiplier, FOV increase
9. Defines AimAssist settings (consumed by AimAssistController — plain text: this module is a data table that requires nothing, so it never names the controller in code): **`Enabled = false` as of 2026-08-07 — camera magnetism is disabled for now.** The flag only gates the rotation: target acquisition and the auto-fire `GetLock()` report still run (the `_canAcquire`/`_canRotate` split), so mobile auto-fire keeps working with the drag off. The rest of the table stays tuned for a future re-enable: **350 stud max range** (raised from 200 on 2026-08-07 — this is an *acquisition* cut-off, so 200 meant auto-fire could not lock at any range past it however well aimed, and Vesper's `Basic.Range` is 500 with falloff only ending at 300; mobile Vespers had no auto-fire at all in the band she is built to fight in. 350 was chosen as the server's `HitForgiveness.MaxDistance`, the furthest a forgiven hit scored — **that equality broke on 2026-08-29** when Dust's forgiveness dropped to 250 with his range; 350 is kept because this table is shared and Vesper still needs it. Per-hunter caps apply on top via MobileAutoFireController's `MaxLockDistance`, and **Dust now sets one** (`CombatConfig.Range`, 250) so a mobile Dust cannot lock past his own damage range), 4° acquire cone, **1.0° max yaw offset** (softened from 1.5 in the auto-fire rework — the lock tolerance carries mobile aim now), 0° max pitch offset (deliberately: vertical pull was tested and steals headshots), 3/sec closure speed, 8/sec decay speed, upper-chest targeting, LOS-required, plus the auto-fire lock keys **`LockRadiusStuds = 3.5`**, **`MinLockAngleDeg = 0`**, **`MaxLockAngleDeg = 20`** (point-blank ceiling, now binds inside ~9.6 studs) and **`LockStickyScale = 1.25`** (hysteresis for an already-locked target).

    **The sizing rule was inverted on 2026-08-07.** It used to be "`LockRadiusStuds` must stay *below* every hunter's server hit-forgiveness radius so a lock reliably becomes a hit rather than firing at empty air", which forced one shared value at the smallest common denominator (1.6). The effect was the opposite of the intent: the lock ended up less than half the revolver's own 3.5-stud forgiveness, so auto-fire **declined** shots the server would have scored — mobile players hovered on an enemy and the gun stayed silent. The rule is now **match, per hunter**: set the radius to the radius that hunter's own server code already treats as a hit, so the trigger pulls exactly when the shot would land. This shared value is Dust's and Vesper's (both `HitForgiveness.Radius = 3.5`); Fortuna and Bram override it at their construction sites from their own configs. Do not restore a single global value — see AimAssistController's per-hunter table

## Dependencies
- **Requires:** Nothing
- **Required by:** FPSRevolverClient, SunspikeClient (AimAssist table for the auto-fire lock source), GrudgekeeperClient, CardsClient, HunterFirstPersonClient (plain text — each caller declares the `require()` in its own file, and wikilinking them here points the edge dependency → dependent, which is backwards)

## Connections
### RemoteEvents
None

### BindableEvents
None

### Direct require()
None
