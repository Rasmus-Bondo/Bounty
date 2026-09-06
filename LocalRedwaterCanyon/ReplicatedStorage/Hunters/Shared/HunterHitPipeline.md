---
tags: [shared, modulescript, combat, hit-pipeline]
path: game.ReplicatedStorage.Hunters.Shared.HunterHitPipeline
type: ModuleScript
lines: 255
---

# HunterHitPipeline

OOP service that encapsulates the standard post-hit bookkeeping + UI feedback chain used by every hunter after a confirmed enemy hit. Replaces the four near-identical inline copies that used to live in `RevolverModule` (3 hit-resolution branches) and `CardsServer.damageHumanoid` (Fortuna's basic + ability1 + recall + ultimate damage). Also owns the universal red hit-flash highlight (Phase 2 gave Fortuna parity with Dust — previously only Dust flashed).

## What it does
1. `.new(config)` — accepts RoundStatsService (used only for `RegisterDamage` now — kill/assist resolution moved to the death handlers), ProgressionService (still injected but no longer invoked here since assist crediting moved out), the 5 cross-hero remotes (`HitConfirmRemote`, `DamageDirectionRemote`, `HealthBarRevealRemote`, `KillFeedRemote`, `KillCamRemote`), one of `ChargeAwardEvent` (legacy BindableEvent path, kept for any caller that still supplies one) or `ChargeService` (current path — calls `:AwardHit` directly; this is what HunterServerRuntime always supplies), `DefaultWeaponName`, `DefaultSourceType`
2. `:Register({ Attacker, TargetCharacter, Humanoid, Damage, OldHealth, DidKill, IsHeadshot, SourceType?, WeaponName? })` runs the full post-hit sequence in this order:
   1. `RoundStatsService.RegisterDamage(attacker, target, actualDamage, isHeadshot)` — `actualDamage = math.min(OldHealth or Humanoid.Health, Damage)` so pre-existing stats clamping is preserved
   2. `target:SetAttribute("LastDamager", attacker.UserId)` — load-bearing for kill attribution
   3. `_flashHit(target, isHeadshot)` — destroys any existing `HitFlashHighlight` then creates a fresh one tweened to full transparency over 0.14s (`HIT_FLASH_TIME`). Headshots get a brighter red fill+outline; body shots get a softer pink. Both hunters now flash on every hit.
   4. `DamageDirectionRemote:FireClient(victim, sourcePosition, isHeadshot, isBulletImpact)` — only if victim is a different player; source position resolves from attacker's `Head → HumanoidRootPart → PrimaryPart`. The trailing `isBulletImpact` flag carries `opts.PlayBulletHitSound` so `BulletImpactAudioClient` can suppress a near-miss whiz from the same shot
   5. `_playBulletHitSound(target, isHeadshot)` → [[BulletHitAudioService]]`.Play` — **only when the caller passes `opts.PlayBulletHitSound == true`**. Every basic weapon in the game passes it (`RevolverModule`, `SunspikeModule`, `StarfallSightModule`, `GrudgekeeperModule`); a caller that omits it leaves the victim with no impact sound and nothing errors
   6. `HealthBarRevealRemote:FireClient(attacker, target)` — visible only to the attacker
   7. `HitConfirmRemote:FireClient(attacker, isHeadshot, didKill, actualDamage, victimName, victimCharacter)` — the trailing three were added for the combat-feedback pass. It is the only event that reaches the attacker and nobody else while the emitter still holds the victim, so it carries both the floating damage number and the name for the centre-screen elimination line. `victimName` resolves the same way `_sendKillFeed` does (DisplayName for players, model name for bots), and the damage reported is `actualDamage`, already clamped to remaining health. Purely additive: `HitMarkScript` binds `function(isHeadshot, didKill)` and ignores the rest
   8. Award ultimate charge via the configured channel (`ChargeAwardEvent` or `ChargeService:AwardHit`)
   9. (if killed) `KillFeedRemote:FireAllClients(killerName, victimName, weaponName, isHeadshot)` and `KillCamRemote:FireClient(victim, attacker)`. The kill-feed fire is gated on [[KillFeedGate]]`.Claim(victimCharacter, ...)` so a death announced by any emitter cannot be announced a second time (launch issue #10); the claim sits **after** the `KillFeedRemote`/`killerPlayer`/`victimCharacter` nil-guard, so a suppressed row never consumes the claim. The kill cam is deliberately left ungated — it is fired to the victim only and a second one would land on a client already in the cam.

   **Kill-stat + assist crediting is deliberately NOT done here.** It is resolved once per death on the universal `Humanoid.Died` handlers (RoundController for players, BotService for bots) via `RoundStatsService.ResolveDeath`, keyed off the `LastDamager` attribute set in step 2. This is what lets finishers that never reach this pipeline — zone/firewall, fall damage, a bot's killing blow — still credit the kill and every recent contributor's assist. (Previously this pipeline called `RegisterKill` inline, so those bypass-finishers dropped all assists.)
3. The caller is still responsible for **applying damage** (Dust via RevolverDamageService:ApplyDamage, Fortuna via `humanoid:TakeDamage`). The pipeline reads `OldHealth` from the caller so damage stats stay accurate even though damage is applied before the pipeline runs.

## Team modes

The kill feed broadcast carries the killer's and the victim's team alongside the names, so the
feed can colour each side.

## Dependencies
- **Requires:** [[BulletHitAudioService]] (victim-side impact sound), [[KillFeedGate]] (one kill-feed row per death), [[TeamAffinity]]
- **Required by:** HunterServerRuntime (constructs one for every hunter), and indirectly via that runtime by RevolverModule + CardsServer + SunspikeModule/StarfallSightModule

## Connections
### RemoteEvents
None directly — fires the 5 cross-hero remotes supplied at construction (from `Hunters.Shared.Remotes`, created by [[HunterSharedRemoteSetup]])

`HitConfirm`'s attacker-side listeners are HitMarkScript (crosshair + hitmarker), DamageNumberClient (floating damage numbers) and AnnouncementController (the elimination line).

### BindableEvents
None directly — fires `ChargeAwardEvent` if a caller still supplies one (no caller does after Phase 2)

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[BulletHitAudioService]] | `.Play(character, isHeadshot)` | The victim's bullet impact sound, gated on `opts.PlayBulletHitSound` |
| [[KillFeedGate]] | `.Claim(victimCharacter, killerName, victimName, weaponName, "HunterHitPipeline")` | Refuses a second kill-feed row for a death already announced, and warns with a traceback when it does |
