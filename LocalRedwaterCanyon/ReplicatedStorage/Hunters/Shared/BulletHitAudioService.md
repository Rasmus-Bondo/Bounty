---
tags: [shared, modulescript, combat, audio]
path: game.ReplicatedStorage.Hunters.Shared.BulletHitAudioService
type: ModuleScript
lines: 48
---

# BulletHitAudioService

The victim-side bullet impact sound. One entry point, `Play(targetCharacter, isHeadshot)`, which clones an authored template onto the victim's body so the hit is audible to the victim and everyone near them.

## What it does
1. `Play(targetCharacter, isHeadshot)` — resolves the template from `ReplicatedStorage.SFX.BulletHitSFX` (`HeadShotHit` for a headshot, `BulletBodyHit` otherwise) and bails silently if the folder, the template, or the target's body part is missing
2. Parents the clone to the victim's `Head` on a headshot and `HumanoidRootPart` on a body shot, falling back to `Head` — so the sound is positional at the point of impact
3. Overrides the clone's mix for combat range: volume at 1.4x the authored value (clamped to 10), `InverseTapered` rolloff, 8–90 stud range. The clone inherits the template's SoundGroup, so the authored template is what keeps it under the `HitSound` settings slider
4. Rapid-hit pitch variation — a per-character rotation through `{1, 1.035, 0.975, 1.06, 0.95, 1.02}` scaling the authored `PlaybackSpeed`, so a burst into one target does not machine-gun the identical sample. The index resets when that character has gone 0.55s without a hit; state is held in a weak-keyed table so a dead character's entry is collectable
5. Hands the clone to `Debris` for cleanup after its own length + 0.5s, and returns it

## Dependencies
- **Requires:** Nothing
- **Required by:** HunterHitPipeline (via `opts.PlayBulletHitSound`), BotCombat (basic shots and `_applyUltimateHit`), HighNoonDamage (Dust's ultimate, which runs its own post-hit chain rather than the pipeline)

## Connections
### RemoteEvents
None

### BindableEvents
None

### Direct require()
None
