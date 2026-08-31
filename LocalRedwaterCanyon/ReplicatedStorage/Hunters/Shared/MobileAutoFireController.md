---
tags: [client, modulescript, combat, shared, mobile]
path: game.ReplicatedStorage.Hunters.Shared.MobileAutoFireController
type: ModuleScript
lines: 219
---

# MobileAutoFireController

OOP auto-fire ticker for touch devices: fires a hunter's existing fire entry on its own cadence while the aim assist's lock report says the crosshair is holding an enemy. One shared implementation covers all four hunters; everything (lock source, fire entry, per-hunter gate) is injected via the constructor, and the module `require()`s nothing.

## What it does

1. `Update(dt)` runs once per frame, called by each hunter client **after** the AimAssistController's own `Update` in the same render step, so the lock it reads was measured against the camera the shot ray will actually use
2. Hard-gates on the same touch-only fairness boundary as the aim assist (`TouchEnabled and not KeyboardEnabled and not GamepadEnabled`), re-checked every frame so Studio's late-flipping device emulator is harmless. Also gates on the `AutoFireEnabled` player attribute — `== false` disables; an **absent** attribute means ON, because the attribute only exists once the settings payload lands and the default is on
3. Reads the lock from the injected AimAssistController instance via its `GetLock()` report. **How often that report is non-nil changed materially on 2026-08-07**: the lock tolerance is now sized to match each hunter's server-side hit registration instead of a shared 1.6-stud guess, so this ticker fires in the whole band where a shot would have scored but the gun previously stayed silent — see AimAssistController's "What it does" for the per-hunter radii. The report is still never re-derived here with a raycast (a raycast lock — a raycast lock would resolve against the oversized `BotAssistHitbox` volumes and the `RewindHitboxes` lag-comp snapshots). An optional `MaxLockDistance` (studs, added 2026-08-07) treats a lock farther away as no lock at all — for close-range hunters whose falloff makes a long shot a waste of ammo. Bram passes `GrudgekeeperConfig.Basic.AutoFireMaxDistance` (60 — equal to his blast's `MaxRange`, past which a shell deals literally zero), Fortuna passes `CardsConfig.Basic.Range` (150 since 2026-08-07's range raise, her card raycast's hard cap); Dust and Vesper leave it unset (no cap). **A stealthed target no longer produces a lock at all** (2026-08-08): a Fortuna inside her ultimate used to be an ordinary acquire candidate, so this ticker tracked and shot her for the whole invisibility window. The gate lives in AimAssistController's `_evaluateCharacter`, not here, so it removes the target from magnetism as well as from auto-fire and covers all four hunters at once
4. Dwell / grace state machine: the lock must hold for `AcquireDelay` (default 0.08s) before the first shot — sweeping the camera across three enemies to reach a fourth fires nothing — and survives dropouts up to `LossGrace` (default 0.12s), so strafing behind a thin post doesn't reset the burst. **`LossGrace` preserves the dwell, it does not authorise a blind shot** (fixed 2026-08-07): the grace branch used to fall through to the fire call with `lock == nil`, so a cooldown maturing anywhere inside the window fired at whatever the crosshair happened to be on. Reported from a mobile playtest as auto-fire "firing for no reason and then missing", and it hit the slow hunters hardest — Vesper's 1.8s `FireInterval` means her cooldown almost never matures on the frame she acquires, so it was far likelier to mature during a dropout than Dust's 0.4s, and at her ranges the sub-degree tolerance flickers constantly
5. **`FireQuality`** (0–1, default 1): the fraction of the lock tolerance the crosshair must be *inside* before the shot is taken. The tolerance is sized to the server's hit radius, so a shot at the very edge only lands if the client's view of the target agrees with the server's — and those diverge by roughly (ping × target speed) studs, which eats the whole margin against a strafing target. Only Vesper sets it (**0.55**): four rounds, a 3s reload and 1.8s between shots make a marginal miss cost far more than waiting a few frames for a better frame. The other three fire often enough that taking every chance is correct and stay at 1.0
5. Fires `OnFire()` (the hunter's own fire entry: Dust `shoot()`, Vesper/Bram `tryFire()`, Fortuna `useBasic()`) at most once per `FireInterval`. The interval is a **floor**, not the cadence — every fire entry re-checks its own cooldown/ammo/reload state, which is what makes the ticker safe. Fortuna polls at 0.05s and lets `S.NextBasicTime` gate her combo timing
6. `OnLockChanged(isLocked)` fires when the dwell completes (not on raw acquisition) and on release/reset; the four hunter clients use it to publish the `AutoFireLocked` player attribute. Nothing currently consumes that attribute — the crosshair lock ring built alongside this module was removed the same day (2026-08-07) at the user's request — but it remains the intended hook for any future lock feedback
7. A `CanAutoFire` callback lets each hunter veto firing: Dust during High Noon, Vesper while scoped until the Deadeye Focus ramp completes, Bram during Breach Charge, Fortuna during ultimate/ability casts — each combined with the hunter's own combat-allowed check so death or round-end resets the lock state (and the ring) immediately
8. `Destroy()` resets state (releasing the lock visual via one final `OnLockChanged(false)`) and drops all injected references; each hunter client destroys its controller in its `HunterClientState.registerCleanup` teardown so a mid-match hunter switch can never leak a firing ticker

## Dependencies

- **Requires:** Nothing (lock source, fire entry and gates all injected via constructor config)
- **Required by:** FPSRevolverClient, SunspikeClient, GrudgekeeperClient, CardsClient (plain text — each caller declares the `require()` in its own file, and wikilinking them here points the edge dependency → dependent, which is backwards)

## Connections

### RemoteEvents
None

### BindableEvents
None (deliberately: Dust's auto-fire calls `shoot()` directly rather than firing the `FireRequested` bindable, which HighNoonClient also connects for the ultimate shot)

### Direct require()
None
