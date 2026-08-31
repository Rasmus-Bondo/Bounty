---
tags: [client, modulescript, combat, camera, shared, mobile]
path: game.ReplicatedStorage.Hunters.Shared.AimAssistController
type: ModuleScript
lines: 702
---

# AimAssistController

OOP camera magnetism controller that pulls the camera toward enemy targets on touch devices via an accumulated yaw/pitch offset that lerps toward "point at target" each frame. Gated to touch-only inputs (no keyboard, no gamepad) so PC and console players are unaffected. Shares the same render-step update lifecycle as `RevolverCameraEffects` and `HunterViewModelMotion`.

## What it does

1. Each frame, gates on `UserInputService.TouchEnabled and not KeyboardEnabled and not GamepadEnabled` plus an optional `CanAimAssistCheck` callback (Dust uses this to disable assist during High Noon)
2. Builds a candidate list from two sources: alive enemy `Player.Character` rigs (filtered to different teams, mirroring the server-side `HunterCharacterUtil.IsEnemy` logic without requiring it), plus any character tagged `AimAssistTarget` via CollectionService ([[BotController]] arena bots). The local player's own character is excluded from the tagged set. Each candidate's torso position is projected into camera-local space
3. **Arena bots are acquired through their local visual copy, not their server rig.** `buildBotVisualMap` indexes `workspace.ClientBotVisuals` by `BotId` (the folder and its `IsBotVisual`/`BotId` attributes are authored by BotVisualClient). When a tagged rig has a matching visual, `_evaluateCharacter` reads liveness from the authoritative server rig but position from the visual — so a ragdolling bot stops being a target while a running one is aimed at where the player actually sees it. The server rig trails the rendered copy by roughly a stud at `smoothTime = 0.09`, which at 10 studs is ~5.7° — wider than the whole 4° acquire cone, so acquiring against the rig missed running bots entirely. Tagged characters with no visual (test bots, or a bot whose visual hasn't been built yet) are acquired as their own rig exactly as before
3a. **Skips characters that are currently stealthed** (2026-08-08). Fortuna's ultimate hides her by dropping every part to `Transparency = 1`, and invisibility is a fact about *pixels* — her rig stayed a perfectly ordinary target to this module, so the lock tracked her right through the window and MobileAutoFireController shot her the whole way, which is the one thing that ultimate exists to prevent. The check is `HunterCharacterUtil.IsStealthed`, the same rule the server-side AI has always obeyed (both BotBrain and BotCombat gate on it), so the auto-firing half of the game now agrees with the thinking half. Three things about where it sits: it is in `_evaluateCharacter` rather than `_acquireTarget` so it takes **camera magnetism** with it — a crosshair sliding toward an enemy nobody can see gives her away as loudly as the gunfire; it reads `character` (the authoritative rig) rather than `geometry`, so it covers a **Fortuna bot's** ultimate as well as a player's, since `BotFortunaInvisible` lives on the server rig even when the bot renders from its visual copy; and a stealthed Fortuna is deliberately **not** dropped from the line-of-sight ray in behavior 6, because she still eats a bullet aimed through her and so must still suppress a lock on whoever is standing behind her
4. Keeps the three candidates with smallest angular distance from camera forward, within `MaxRange` studs (default 150) and inside a **scan cone** of `max(AcquireConeDeg, MaxLockAngleDeg)`. The scan is deliberately wider than the magnetism cone: until 2026-08-07 the search started at `AcquireConeDeg`, which silently clipped the lock to 4° at every range where the lock sphere subtends more than that (inside ~50 studs), far tighter than the band the server scores as a hit. `AcquireConeDeg` now gates only the camera rotation. The top-N is an insertion into a pooled fixed-size array rather than a collect-and-sort, so the per-frame acquire allocates nothing. The model recorded is the *rendered* one (the visual for bots, the character itself for players), since that's what the raycast below can actually hit
5. **Line of sight is decided by [[BulletPenetration]], not by a bare raycast** (2026-08-07). Every hunter resolves its shot through `BulletPenetration.Pierce`, so wood, planks and fabric are cover the round *crosses* for reduced damage rather than cover that stops it — a plain raycast made auto-fire **stricter than the gun**, declining shots the server would have scored. The health pack stands were the clearest case (each `Base` is a Wood plate 0.7 studs thick, deliberately shoot-through), but it applied to every wooden building and fence in the arena. The cheap raycast still runs first and only escalates to `Pierce` when it has actually hit penetrable cover, so a target in the open costs one ray and allocates nothing; the guard is exact rather than approximate, because `Pierce`'s own first iteration is that same cast and continues on that same `IsPenetrable` test. A round that dies inside cover (`Stopped` — too many walls, or one part thicker than `MaxDepthPerLayerStuds`) still counts as blocked, so this is not a wallhack: solid geometry behind the wood blocks exactly as before. `Pierce` is called **without** per-hunter overrides, since Dust, Vesper and Bram override only `DamageMultiplierPerLayer`, which cannot change whether the round arrives — a hunter that ever overrides `MaxLayers` or `MaxDepthPerLayerStuds` must pass its table here or the lock will disagree with its gun again
6. Raycasts from camera to the target **testing three heights up the body — chest, head, then root — and passing on the first one that is clear** (2026-08-07). A target only has to be visible *somewhere* to be shootable: an enemy standing on a rooftop or platform, seen from below, has their legs and root behind the parapet while head and chest are in the open, and testing the root alone rejected them outright — which read as enemies becoming untargetable whenever the player had to look up at them. The server agrees with the permissive answer, since its primary hit path is a direct raycast that strikes whichever part the ray actually meets. Chest is tested first because it is the most representative point, so a target in the open passes on ray one and the extra rays are only cast for partly-hidden targets. The ray excludes the local character, the viewmodel (via `GetExtraExcludes`), every `HealthPack`'s green `Pickup` + invisible `TouchHitbox` (the `Base` stand stays in the ray, but its Wood plate is penetrable per behavior 5, so only its Metal pieces actually block), and every bot server rig that's hidden behind a visual copy. **It walks the candidates outward until one is visible** rather than testing only the nearest — testing just the single best meant an enemy behind a post suppressed the lock on a second enemy standing in the clear, a large part of why auto-fire fired "only sometimes" in a crowd. The exclude list is built once per acquire and reused across all three rays. The hidden-rig exclusion is what makes bots targetable at all: the invisible server rig stays `CanQuery` and carries the same generous `BotAssistHitbox` volumes as its visible copy, so a ray aimed at a bot used to land on the wrong one of the two overlapping hitboxes and fail the `IsDescendantOf` ownership test. Each bot's visible copy still blocks LOS normally, so bots occlude each other exactly as they appear to
7. Maintains accumulated `_yawOffset` and `_pitchOffset` (radians). When a target is acquired, lerps them toward the angular delta required to point straight at the target at `ClosureSpeed`/sec (exponential). When no target, lerps them back to zero at `DecaySpeed`/sec
8. Clamps the offsets to `MaxYawOffsetDeg` / `MaxPitchOffsetDeg` (default 5°/4°) so the assist can never steal more than a few degrees from the player's intent — the player keeps ultimate authority
9. Applies the accumulated offsets as a rotation of camera.CFrame around the camera position. The default camera scripts overwrite camera.CFrame each frame from their internal yaw/pitch state, so the offset is re-applied every frame on top of the player's input (the same pattern RevolverCameraEffects uses for its recoil offset)
10. With `TargetUpperChest = true` (default), **magnetism** aims at the midpoint of `HumanoidRootPart.Position` and `Head.Position` — keeps bodyshots reliable while leaving headshots reachable by a small flick-up from the assisted aim. The **lock** ignores this flag entirely and always measures from the root, so it stays anchored to the same point the server measures its hit forgiveness from
11. **Eligibility is split in two** (2026-08-07): `_canAcquire()` (touch-only + the hunter's `CanAimAssistCheck`) gates target acquisition, while `_canRotate()` (`_canAcquire` **and** `Enabled`) gates the camera rotation. `Enabled = false` therefore stops magnetism but not acquisition — which is what lets Vesper's SunspikeClient run a second, rotation-disabled instance purely as an auto-fire lock source without a second camera writer
12. **Publishes a lock report via `GetLock()`** for MobileAutoFireController (plain injection, not a require in either direction). Both `Update` and `_acquireTarget` clear the report first, so only a lock published by the current pass can survive it. The report carries `{ Model, Position, AngleRad, ToleranceRad, Distance }` — `Position` is the root — measured against the already-assisted camera (the same camera the shot ray uses)
13. **The lock tolerance is sized to match the server's hit registration** (reworked 2026-08-07). It is the apparent size of a `LockRadiusStuds` sphere around the target's root, `clamp(atan(LockRadiusStuds / distance), MinLockAngleDeg, MaxLockAngleDeg)`. Setting `LockRadiusStuds` to the radius that hunter's server code already scores as a hit makes auto-fire fire exactly when the shot would land — it never declines a hit the server would grant, and never spends a round on one it cannot. The previous 1.6 studs was less than half the revolver's 3.5-stud forgiveness, so mobile players hovered on an enemy and the gun stayed silent. Measured on a standard R15 rig a 3.5 sphere at the root spans the whole body (head top +2.19, feet −3.00), which is why hovering over a head or legs now locks with no separate body-shaped test; the old sphere sat on the upper chest and reached neither. Per hunter:

    | Hunter | `LockRadiusStuds` | Floor | Server rule it mirrors |
    |--------|------------------|-------|------------------------|
    | Dust | 3.5 | 0° | `RevolverServerConfig.HitForgiveness.Radius` |
    | Vesper | 3.5 | 0° | `VesperConfig.HitForgiveness.Radius` |
    | Fortuna | 2.4 | 0° | `CardsConfig.LagCompensation.PartRadii.HumanoidRootPart` — her lag-comp spheres are her only forgiveness, so the shared 3.5 would throw cards that cannot land |
    | Bram | 2.0 | 7.6° | `GrudgekeeperConfig.Basic.SpherecastRadius`, floored at `ConeHalfAngleDegrees` because his body damage is a fixed cone, not a sphere, so his tolerance must not shrink with distance. At his 60-stud `AutoFireMaxDistance` 7.6° is 8.0 studs, exactly the cone's own spread there |

14. **Lock hysteresis** (`LockStickyScale`, default 1.25): a target that is already the locked model keeps a proportionally wider tolerance, so one hovering exactly on the boundary stops chattering in and out and re-paying MobileAutoFireController's acquire dwell on every flicker. `_lockedModel` persists across frames and is cleared the moment a pass that ran acquisition fails to lock it even at the widened tolerance, or acquisition does not run at all
15. `SetCamera(camera)` swaps the camera reference at runtime (used by SunspikeClient's lock-source instance to track `workspace.CurrentCamera` each frame)

## Team modes

Allies are excluded twice over: from the player scan and from the tagged-rig gather, so neither
magnetism nor auto-fire acquisition can settle on a teammate. Line-of-sight walks cover with the
shooter passed in, matching the server's shot.

The LOS `RaycastParams` also carries the local player's shot collision group
(`TeamAffinity.shotGroup`), re-stamped each `Update` next to the exclude-list refresh, so an
enemy standing inside their own spawn house is not visible to the lock and touch auto-fire
never opens up on a shot the door would stop. Own-side doors stay transparent; FFA and an
unstamped player answer `Default`, which is the pre-team behaviour.

## Dependencies

- **Requires:** [[BulletPenetration]], [[HunterCharacterUtil]], [[TeamAffinity]]
- **Required by:** FPSRevolverClient, HunterFirstPersonClient, SunspikeClient, GrudgekeeperClient, CardsClient (plain text — each caller declares the `require()` in its own file, and wikilinking them here points the edge dependency → dependent, which is backwards)

## Connections

### RemoteEvents
None

### BindableEvents
None

### Direct require()

| Target | Function | Purpose |
|--------|----------|---------|
| [[BulletPenetration]] | `IsPenetrable()`, `Pierce()` | Decide line of sight by the rules the bullet obeys, so penetrable cover the round crosses does not hide a target from the lock. Sibling require via `script.Parent` |
| [[HunterCharacterUtil]] | `IsStealthed()` | Refuse to acquire — and therefore refuse to magnetise toward, and refuse to auto-fire at — a Fortuna inside her ultimate. Sibling require via `script.Parent`, and the only client-side caller of that module; safe because its workspace walk is behind a `RunService:IsServer()` gate |

Everything else (lock consumers, per-hunter gates, extra excludes) is still injected via constructor config.

### CollectionService Tags

| Tag | Usage | Defined by |
|-----|-------|-----------|
| `HealthPack` | Read via `GetTagged`; each pack's green `Pickup` + invisible `TouchHitbox` added to the LOS raycast Exclude list so the floating pickup doesn't break aim assist. The `Base` stand is deliberately left in the ray, but since 2026-08-07 its Wood plate is crossed via `BulletPenetration` rather than blocking — only its Metal pieces stop the lock, matching what the bullet does | [[HealthPackSystem]] |
| `AimAssistTarget` | Read via `GetTagged` to surface non-Player characters (arena bots) as valid acquire candidates alongside enemy players | [[BotController]] |
