---
tags: [server, modulescript, combat, ultimate, damage]
path: game.ReplicatedStorage.Hunters.Dust.Modules.HighNoonDamage
type: ModuleScript
lines: 358
---

# HighNoonDamage

OOP server-side damage handler for HighNoon ultimate shots with execute threshold and visual feedback.

## What it does
1. Applies damage to targets. A **locked** shot (`isHeadshot`) is a guaranteed one-shot: damage comes from the injected `GetLockedShotDamage` (HighNoonServerConfig's `MaxHealth * LockedHealthPercent`, 100% by default) and falls back to the flat `HeadshotDamage` only when that isn't injected. A **body** shot (in-cone, not yet locked) is the flat quick damage (45) and still executes anyone already under the threshold (35 HP = damage equal to remaining health). Each `targetData` may carry a per-target `isHeadshot` override so one `ShootTargets` list can mix executes and body shots; when unset it falls back to the list-level flag
2. A locked shot is a **true execute** and skips the victim's `DamageReductionPercent` when `LockedIgnoresDamageReduction` is set (the default) — otherwise Bram's Last Call 50% cut would carry a full-HP Bram through the kill. Body shots still respect the reduction, so mitigation can carry a low-health target through an unlocked finisher
3. Creates a brief orange Highlight flash (0.16s) on hit characters for visual feedback (gold `HighNoonHitHighlight` — distinct from HunterHitPipeline's pink basic-hit flash)
4. Fires `HitConfirm` RemoteEvent to the attacker with headshot and kill info
5. Plays the victim's bullet impact via [[BulletHitAudioService]]`.Play(character, isHeadshot)` in `:Apply`. Because this module runs its own post-hit chain instead of HunterHitPipeline, it has to make this call by hand — omitting it is what left a High Noon victim with **no sound at all** (launch issue #3), while the bot path in `BotCombat._applyUltimateHit` had always played it. Unconditional, matching the pipeline rather than BotCombat's player-only guard, so a bot body cracks the same way it does under the basic revolver. The dependency is `require`d rather than injected like the rest of the config, deliberately: an optional dependency can go missing without erroring, which is precisely how this went silent
6. `ShootTargets` iterates through the resolved target list with 0.12s delay between shots, honoring each target's `isHeadshot` (execute vs body)
7. Fires `HighNoonShot` RemoteEvent to all clients with muzzle and hit positions for visual replication
8. Gets server-side muzzle position from the attacker's head
9. `SendKillFeed` is gated on [[KillFeedGate]]`.Claim(victimCharacter, ...)` before it fires, so a death already announced by another emitter cannot get a second row (launch issue #10). Because this module runs a post-hit chain **parallel** to HunterHitPipeline's rather than through it, it needs the gate wired by hand for the same reason it needs [[BulletHitAudioService]] by hand — and for the same reason it is `require`d outright rather than injected. Without it, High Noon would be the one path able to re-announce a kill some other path had already posted.
10. Stats wiring (matches HunterHitPipeline for parity): after `humanoid:TakeDamage` in `:Apply`, sets `LastDamager` attribute on the victim character (so the universal death handler can credit the kill **and resolve assists**), and if the `RoundStats` config field is supplied calls `RoundStats.RegisterDamage(attacker, character, math.min(oldHealth, damageToDeal), isHeadshot)`. **Kill-stat + assist crediting is NOT done here** — it moved to `RoundStatsService.ResolveDeath` on the `Humanoid.Died` handlers (RoundController/BotService); High Noon previously called `RegisterKill` inline, which dropped assists (and stat kills) for pipeline-bypassing finishers (zone, fall, bot blows). [[HighNoonModule]] still wires `RoundStats` and `ProgressionService` via constructor, though `ProgressionService` is no longer invoked here.

## Team modes

`Apply` refuses a hit the gamemode disallows, before any damage or feedback. The kill feed
broadcast also carries the killer's and the victim's team, so the feed can colour the two names
by side.

## Dependencies
- **Requires:** [[BulletHitAudioService]] and [[KillFeedGate]] (the two hard requires; everything else is configured externally — `RoundStats` is an optional config field; when absent, kills/damage are silently dropped from round stats. `GetLockedShotDamage` is likewise injected, not required: without it locked shots quietly fall back to the flat `HeadshotDamage` and stop one-shotting high-HP hunters. Both wired by [[HighNoonModule]].), [[TeamAffinity]], [[DamageGate]]
- **Required by:** HighNoonModule

## Connections
### RemoteEvents
| Remote | Direction | Other script |
|--------|-----------|-------------|
| `HitConfirm` | → Client | [[HitMarkScript]] displays hit/kill feedback (cross-hero remote from `Hunters.Shared.Remotes`) |
| `HighNoonShot` | → All Clients | [[HighNoonClient]] plays shot VFX and laser beams |
| `HealthBarReveal` | → Client | Fired to the attacker (only) on every landed shot; [[HealthBarSpawnerClient]] spawns a local-only overhead health bar on the victim (cross-hero remote from `Hunters.Shared.Remotes`) |
| `DamageDirection` | → Client | Fired to the victim on every landed shot; [[DamageDirectionClient]] shows directional damage indicator (cross-hero remote from `Hunters.Shared.Remotes`). Carries the same trailing `isHeadshot, isBulletImpact` flags as HunterHitPipeline, the second always true here, so `BulletImpactAudioClient` can suppress a near-miss whiz from the same shot |
| `KillFeed` | → All Clients | Fired on kill; [[KillFeedClient]] adds a kill feed row (cross-hero remote from `Hunters.Shared.Remotes`) |
| `KillCam` | → Client | Fired to the victim on kill; [[KillCamClient]] starts kill cam (cross-hero remote from `Hunters.Shared.Remotes`) |

### BindableEvents
None

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[BulletHitAudioService]] | `.Play(character, isHeadshot)` | The victim's bullet impact sound. Everything else this module needs is injected via constructor config; this one is required outright so it cannot go missing silently |
| [[KillFeedGate]] | `.Claim(victimCharacter, killerName, victimName, "Revolver", "HighNoonDamage")` | Refuses a second kill-feed row for an already-announced death. Required outright for the same reason as above — a gate that can go missing is a gate that stops gating |
