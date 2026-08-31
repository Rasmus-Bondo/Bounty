---
tags:
  - client
  - localscript
  - camera
  - input
  - vesper
path: game.StarterPlayer.StarterPlayerScripts.Vesper.VesperScopeController
type: LocalScript
lines: 682
---

# VesperScopeController

Owns Vesper's ADS state — the first scope/ADS system in the game: reduced mouse look sensitivity while scoped, local walk-speed feel, the `ScopeStateChanged` remote (server enforces the authoritative walk speed + Deadeye Focus timer from it), the `ScopeChanged` client bindable, and the dedicated mobile Scope toggle button. It broadcasts scope state but **no longer writes `camera.FieldOfView`** — [[SunspikeClient]]'s FOV compositor owns the camera FOV and folds in the ADS zoom from the `ScopeChanged` bindable, so scope and sprint never fight over FieldOfView.

PC: hold Right Mouse Button to scope. Mobile: tap the round SCOPE button to toggle — ADS is not a natural touch gesture, same lesson that forced Dust's visible Fire button. It only exists for Vesper.

**SCOPE holds the touch cluster's outer column** — it is the only button at `OUTER_RIGHT` (0.965W), with JUMP one notch inboard of it. Authored at `(0.965, 0.5432)`, sized `0.184` of viewport height and squared by a 1:1 `UIAspectRatioConstraint`, clamped 55–124px, in a ScreenGui using `ScreenInsets = None` so it reaches the physical edge. Its `MaxSize` is proportional to the jump button's 135 ceiling (0.184 / 0.200); all five maxima have to move together or the cluster comes apart on tablets. It is bounded above by the pixel-pinned settings gear — on the smallest phone tested that leaves ~12pt, so it cannot rise further without re-measuring.

**The authored button carries an icon, not text** (2026-07-30): `Text` is `""` and a centred `ImageLabel` named `Icon` sits at `0.58` of the button, `ScaleType = Fit`, cropped to the art's tight opaque bounds (`719×727` at `(152,134)`; the 1024×1024 source is ~30% transparent margin). Only this controller's **runtime fallback** path assigns the button's text, so the cleared text survives; the fallback still builds a worded button. Unlike FIRE and SPRINT this button never had a `UIPadding` to remove, which is why one `0.58` icon scale now reads identically on all three.

**This controller does not resolve the button's position.** It used to mirror whatever horizontal inset FIRE settled on, back when FIRE hugged the screen edge and re-derived its own; the 2026-08-08 cluster rebuild gave both static slots, and `HunterMobileClusterLayout.apply` now owns every cluster button's position on both axes. The authored `Position` above is the fallback and the shape reference, nothing more. That module is invoked from HunterMobileSprintButton's ordered layout pass, so nothing here calls it — and reading another ScreenGui's button was never a code-level dependency (no require, no remote), which is why nothing in this area is a wikilink.

It **prefers the editor-authored `StarterGui.VesperScopeGui > MobileScopeButton`** (shipped `Enabled=false` so it stays hidden for non-Vesper / PC players) and just sets `ScreenGui.Enabled = true` when it runs (Vesper + touch); it falls back to building the button at runtime only if that instance is missing. The touch gate waits (bounded poll, ~12s) for `TouchEnabled` rather than sampling it once, so the button still appears in Studio's device emulator, which flips `TouchEnabled` true a beat after client scripts start. When it enables the gui it tags it with a `MobileCombatButton` attribute (read by `RoundClientController`) so the round HUD manager re-enables it after intermission instead of restoring the authored `Enabled=false`; because the tag is only set here, it never appears for non-Vesper players or on PC.

## What it does
1. Requires [[HunterClientRuntime]] + the [[Manifest|Vesper Manifest]]; exits silently when not on Vesper
2. `setScoped(bool)` — idempotent state switch. Scope-in requires alive + round active. The ADS FOV zoom itself is applied by [[SunspikeClient]]'s FOV compositor (which reads `S.IsScoped` from the `ScopeChanged` bindable and smoothDamps toward `ADSFOV` 35); this controller no longer tweens `Camera.FieldOfView`
3. Reduces look sensitivity while scoped by `ScopedSensitivityMultiplier` (0.4), on **one path per device** — `UserInputService.TouchEnabled` is sampled at scope time (not at load, since Studio's emulator flips it late). PC captures the player's current `UserInputService.MouseDeltaSensitivity` on scope-in (the settings menu owns this value) and restores it on scope-out. Touch look never passes through the mouse delta, so it instead binds a render step at `Enum.RenderPriority.Camera.Value - 1` that scales the default camera controller's `rotateInput` accumulator (via `PlayerScripts.PlayerModule:GetCameras().activeCameraController`) before the camera consumes it. Damping the pending *input* rather than the camera CFrame leaves the PlayerModule's own state authoritative — no drift, no snap on scope-out — and running one step *ahead* of the camera keeps the aim assist (which rotates the camera at `Camera + 1`, inside HunterFirstPersonClient) at full tuned strength. The two paths are mutually exclusive because `rotateInput` carries mouse input too, so a touchscreen PC would otherwise stack the multiplier to 0.16x. Frames where `rotateInput` is missing are skipped silently. The PlayerModule swaps `activeCameraController` on state changes, so it is legitimately absent for a frame or two around scope-in and recovers on the next frame; the warning that used to fire here only ever reported those transients (22 across the launch window, no broken sessions among them), so it was removed rather than re-tuned
4. Draws the scope overlay: a square `ScreenGui` (`ScreenInsets.None`, so it spans the whole physical screen) holding the scope artwork centered at the largest square that fits, with four black panels covering the leftover side/top bars. All of it is laid out from the **ScreenGui's own `AbsoluteSize`**, never `Camera.ViewportSize` — on phones with notch/home-indicator insets the camera viewport reports the smaller device-safe area, and sizing the mask to it while anchoring at the full-screen top-left left the world visible in a strip down the right and bottom edges and pushed the scope circle up-left off the crosshair. Re-lays out on both `Camera.ViewportSize` and gui `AbsoluteSize` changes
5. Predicts the scoped walk speed (6) locally for instant feel via [[HunterMovement]]`.PredictBase` — the server applies the same value authoritatively from `ScopeStateChanged`, and [[SunspikeModule]] uses the same remote to drive the Deadeye Focus ramp timer. The prediction only stands in for the server's published `MoveSpeed` until that acknowledgement lands, and expires by itself if the server rejects the request. Because it is REPLACED by the server value rather than multiplied with it, the old "fire the remote AFTER the local write" ordering rule is gone — firing either way round can no longer fold the change in twice
6. Fires the `ScopeChanged` bindable on every transition — [[SunspikeClient]] blocks sprint on it and drives its FOV compositor (the ADS zoom) from it, [[VesperHunterGuiClient]] shows/hides the Deadeye ramp bar
7. Never stays scoped through death, respawn, round end, or reload (auto-unscope on all four — reload arrives via the `ReloadStarted` bindable [[SunspikeClient]] fires when a reload begins)
8. Hides the local first-person arms + sniper viewmodel while scoped (you look *through* the scope, so the gun model would only clip into the overlay). HunterFirstPersonClient owns Vesper's viewmodel render and re-asserts visibility every render step, so this sets a `HideViewModel` attribute on the local player that its `setViewModelEnabled` honours rather than writing part transparency here. Instant on scope-in, restored on the next render step after scope-out; covers PC (RMB) and mobile (Scope button) alike since both route through `setScoped`. The teardown clears the attribute unconditionally so a hunter swap can't strand the next hunter with an invisible viewmodel
9. Blocks scoping back in for the full reload duration: `ReloadStarted` sets a local `isReloading` flag that `setScoped(true)` checks and bails on; `ReloadEnded` (fired by [[SunspikeClient]] on both natural completion and early cancellation) clears the flag
10. Blocks scoping back in until the shot animation has finished playing: `ShotFired` (fired by [[SunspikeClient]] on every accepted trigger pull, basic and Starfall alike) drops the scope immediately and arms a `scopeBlockedUntil` deadline `Basic.Cooldown` (1.8s) ahead. That constant is the clip's real on-screen duration — VesperViewModelAnimationClient time-scales the Shoot track to fill it (`speed = length / cooldown`) — and it is also the fire cooldown, so scope returns at the same moment the next shot does rather than letting the player re-ADS over a rifle still cycling its bolt. A scope request arriving inside the window is **queued rather than swallowed**: the shot drops the scope while RMB is still held, so the player re-presses at once, and discarding that press reads as a dead scope button until they press a third time. On expiry a held PC request only stands if RMB is still down (`IsMouseButtonPressed`), so a tap-and-release during the block does nothing; a queued mobile tap is honoured as-is, and a second tap on the button cancels it so the toggle still behaves as a toggle. Death, respawn, round end, reload and the hunter-switch teardown all clear the queue, because `setScoped(false)` drops it ahead of its own no-op early return

## Dependencies
- **Requires:** [[HunterClientRuntime]], [[HunterMovement]] (from `ReplicatedStorage.Hunters.Shared`); [[Manifest|Vesper Manifest]] + [[VesperConfig]] (from `ReplicatedStorage.Hunters.Vesper.Config`), [[HunterClientState]]
- **Required by:** Nobody

## Connections
### RemoteEvents
| Remote | Direction | Other script |
|--------|-----------|-------------|
| `ScopeStateChanged` | → Server | [[SunspikeModule]] Deadeye timer + authoritative scoped walk speed |
| `ForceScopeExit` | ← Client | [[SunspikeModule]] echoes it after authoritatively accepting a shot → local unscope, then a confirming `ScopeStateChanged(false)` so world/public ADS pose listeners also leave the held pose |

### BindableEvents
| Bindable | Direction | Other script |
|----------|-----------|-------------|
| `ScopeChanged` | → | [[SunspikeClient]] (sprint block + ADS FOV compositor), [[VesperHunterGuiClient]] (Deadeye ramp bar) |
| `ReloadStarted` | ← | [[SunspikeClient]] fires it when a reload begins → auto-unscope + blocks re-scoping |
| `ReloadEnded` | ← | [[SunspikeClient]] fires it on reload completion or early cancellation → lifts the scope block |
| `ShotFired` | ← | [[SunspikeClient]] fires it on every accepted trigger pull → auto-unscope + arms the shot-animation scope block |

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[HunterClientRuntime]] | `.Start(manifest)` | Hero gate + remote/event resolution |
| [[Manifest|Vesper Manifest]] | (table return) | Declarative description of Vesper |
| [[VesperConfig]] | `.Scope`, `.Passive`, `.Basic` | walk speeds, scoped sensitivity multiplier, and `Basic.Cooldown` as the shot-animation lockout length — one value shared by the PC mouse-delta path and the touch `rotateInput` path (ADSFOV is now read by [[SunspikeClient]]'s FOV compositor; TransitionTime no longer used here) |
