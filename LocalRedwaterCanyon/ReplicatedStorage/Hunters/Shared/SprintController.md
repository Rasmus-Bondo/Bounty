---
tags: [shared, modulescript, client, input, movement]
path: game.ReplicatedStorage.Hunters.Shared.SprintController
type: ModuleScript
lines: 246
---

# SprintController

Shared per-player sprint state machine used by every hunter. Instantiated once per client entry script by HunterClientRuntime and exposed as `runtime.SprintController`. The hunter's **combat** client (Dust FPSRevolverClient, Fortuna CardsClient, Vesper SunspikeClient, Bram GrudgekeeperClient) is the one that actually drives it — it calls `:Update(dt)` every frame, reads `:GetSprintAlpha()` for the sprint FOV widen, and `:Cancel()`s it when the trigger is pulled (the trigger pull drops you out of sprint).

Sprint is published as a proportional **buff** on [[HunterMovement]] rather than written to `Humanoid.WalkSpeed`. This controller never reads or writes WalkSpeed; it owns one number, the ramp alpha.

## What it does
1. `.new(config)` — `{Player, SprintKey?, SpeedMultiplier?, AccelTime?, DecelTime?}`. Defaults: LeftShift, 1.25× speed, 0.25s accel / 0.15s decel
2. **PC input**: hold `SprintKey` (LeftShift) → sprint while held. Bound only on non-touch-only devices
3. **Mobile input**: driven by the on-screen SPRINT toggle button (HunterMobileSprintButton) via `SetMobileSprinting` / `ToggleMobileSprint` — replaces the old left-screen-half double-tap gesture that used to live here
4. `:Update(dt)` — ramps `_sprintAlpha` toward 1 while sprint is wanted (shift held OR mobile toggle on) AND `_checkCanSprint()` passes, else decays toward 0, then publishes `1 + (mult-1)*alpha` as the `Sprint` buff (or clears it at alpha 0)
5. **No base capture and no re-basing.** The two heuristics this controller used to need are gone. `_captureBaseSpeed` snapshotted the live WalkSpeed when the ramp started, so starting a sprint during someone else's effect captured THEIR value; `_rebaseIfExternallyChanged` diffed the live WalkSpeed against the last value written to guess when a server ability had changed the resting speed underneath. [[HunterMovement]] layers the buff over the server's published `MoveSpeed` every time either changes, so a server ability raising or lowering the base mid-sprint composes automatically, and releasing sprint restores whatever is live at that moment rather than a stale capture
6. **Slow suspend preserves sprint INTENT**: `_suspendForServerSlow` drops the ramp and the buff for the slow's lifetime (you cannot sprint out of a slow) but deliberately leaves `_shiftHeld` and the mobile toggle set. `_shiftHeld` only flips true on the keydown *edge*, so clearing it there ate a key the player was still holding: the slow expired, the base restored correctly, and the player walked instead of sprinting until they released and re-pressed Shift — pressing during the slow didn't help either, since the next frame wiped it. That was the "Vesper's Pinning Round slows me permanently" report. Holding the intent is inert (Update returns before publishing anything) and lets sprint resume by itself the frame the slow lifts. `:Cancel()` still clears intent — the trigger pull is *meant* to end sprint, an enemy slow is not
7. `SetCanSprintCheck(fn)` — hunters supply a gate (alive + round active + not-scoped, etc.); default is alive-only
8. `SetMobileSprinting(bool)` / `ToggleMobileSprint()` / `IsMobileSprinting()` — mobile toggle state, with change notification (no-op if unchanged)
9. `OnMobileSprintChanged(fn)` — subscribe to mobile-intent flips (tap, shoot-cancel, death, round end); returns a disconnect. The SPRINT button uses this to keep its highlight in sync
10. `GetIsSprinting()` / `GetSprintAlpha()` — state for the sprint FOV widen + viewmodel motion
11. `:Cancel()` — clears shift + mobile intent (notifying listeners), snaps alpha to 0 and clears the buff
12. `:Destroy()` — cancels, disconnects input, clears listeners

## Dependencies
- **Requires:** [[HunterMovement]]
- **Required by:** HunterClientRuntime (instantiates it as `runtime.SprintController`)

## Connections
### RemoteEvents
None

### BindableEvents
None

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[HunterMovement]] | `SetBuff` / `ClearBuff` | Publish the sprint ramp as a proportional modifier instead of writing WalkSpeed |
