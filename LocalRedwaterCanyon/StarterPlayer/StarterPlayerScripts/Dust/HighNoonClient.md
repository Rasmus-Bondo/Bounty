---
tags:
  - client
  - localscript
  - combat
  - ultimate
  - dust
path: game.StarterPlayer.StarterPlayerScripts.Dust.HighNoonClient
type: LocalScript
lines: 494
---

# HighNoonClient

Client-side High Noon ultimate controller for the Dust caster only — handles input, FOV effects, charge UI, target indicators, local sound effects, and gun VFX. The world-visible public FX (red caster highlight, eagle/mid sounds, dust ring) lives in the ungated `HighNoonPublicFXClient` so non-Dust players also see them.

## What it does

1. Top-of-script hunter gate via `HunterGate.IsHunter(player, "Dust")` — returns immediately if not Dust, so Fortuna players never `WaitForChild` on Dust-only remotes (replaces the former inline `waitForSelectedHunter` helper)
2. Manages ultimate activation: F key or mobile button, checks charge via HighNoonChargeUI, validates alive character
2. Sends `HighNoonRequest` to server with current camera aim direction
3. During ultimate: sends continuous aim updates to server every 0.08s via `HighNoonAimUpdate`
4. Handles shoot request: left-click, raw touch tap, or the [[HunterGuiClient]] mobile Fire button (via the `FireRequested` BindableEvent) fires `HighNoonShootRequest` (enforces min shoot time of 1.5s). The dedicated `FireRequested` path exists because the on-screen Fire button consumes the tap, so the raw `UserInputService.TouchTap` handler skips it with `gameProcessed = true`.
4a. **On a TUTORIAL server only, the trigger also needs a lock** (2026-08-16). `requestHighNoonShot` drops the request when nothing is marked and `workspace.TutorialMode` is true, tracked in a `hasLockedTarget` local set from the `TargetUpdate` branch's `locked` list and cleared on `Start`, `End` and `CharacterAdded`. The lesson's ult step teaches "hold your aim until the skull appears, **then** fire", and a player who pulled the trigger at empty air spent the ultimate on nothing. **Deliberately tutorial-scoped**: in a real match a lock that breaks in the instant the player fires is a legitimate miss, and gating it globally would leave them unable to fire for the rest of the hold. **Deliberately client-side too, which is the exception to the house server-authoritative rule** — `hasRequestedHighNoonShot` is one-shot per activation, so a server-side rejection would lock the player out of firing for the remainder of the window, and the worst a bypass can do is waste the player's own tutorial ultimate (which the director then refunds anyway — its `watchUltCharge` refill).
5. Processes `HighNoonVisual` states from server (only the Dust-caster-facing ones — public `CasterStart`/`CasterEnd` are handled by `HighNoonPublicFXClient`):
   - `Start`: FOV zoom intro, local SFX (start/mid/whistle), aim updates begin, "can shoot" gun cue after min time (target visuals are no longer set up here — they're driven live by `TargetUpdate`). Also prewarms the Shoot + Fanning tracks and calls `gunFX:PlayUltimateIntro()`, which plays Dust's ultimate draw once and freezes it on its last frame for the whole lock-on phase
   - `TargetUpdate`: forwards the server's live `{ targeting, locked }` lists to `HighNoonTargetUI:UpdateTargets`, so lock-on indicators track the cone as enemies enter/leave
   - `End`: resets FOV, stops SFX, clears target UI, releases the held ultimate pose via `gunFX:StopUltimate(0.25)` so the viewmodel falls back to its normal idle, re-enables normal shooting
6. Processes `HighNoonShot` events: plays local gun FX for own shots, laser beam for others. The server sends one of these per locked target, `HighNoonServerConfig.Timing.ShotDelay` (0.12s) apart, and each one now replays **Fan-The-Hammer** rather than the plain Shoot pop — sped up so a whole fan completes between shots
7. Updates charge UI on `HighNoonChargeUpdate` from server
8. Creates mobile ultimate button via [[HunterMobileAbilityButton]] (replaces former Dust-only `HighNoonMobileButton`); passes a `ResolveFrame` callback that walks `PlayerGui.TemplateGameGui.Canvas.UltimateFrame.Ultimate` and `WatchGuiRecreate = "TemplateGameGui"` so the button rebuilds when that GUI is re-added
9. Resets all local state on `CharacterAdded`

## Dependencies

- **Requires:** HighNoonFOV, HighNoonChargeUI, HighNoonTargetUI, HighNoonLocalSFX, HighNoonGunFX, laserBeamEffect (all from `ReplicatedStorage.Hunters.Dust.Modules`), [[HunterGate]] and [[HunterMobileAbilityButton]] (from `ReplicatedStorage.Hunters.Shared`), [[HighNoonChargeUI]], [[HighNoonFOV]], [[HighNoonGunFX]], [[HighNoonLocalSFX]], [[HighNoonTargetUI]], [[HunterClientState]], [[laserBeamEffect]]
- **Required by:** Nobody

## Connections

### RemoteEvents

| Remote | Direction | Other script |
|--------|-----------|--------------|
| `HighNoonRequest` | → Server | [[HighNoonModule]] activates ultimate |
| `HighNoonAimUpdate` | → Server | [[HighNoonModule]] receives aim direction updates |
| `HighNoonShootRequest` | → Server | [[HighNoonModule]] processes shoot request |
| `HighNoonVisual` | ← Server | [[HighNoonModule]] sends Start/TargetUpdate/End to the caster (`CasterStart`/`CasterEnd` go to `HighNoonPublicFXClient`) |
| `HighNoonShot` | ← Server | [[HighNoonModule]] replicates individual shot visuals |
| `HighNoonChargeUpdate` | ← Server | [[HighNoonModule]] sends charge value |

### BindableEvents

| Bindable | Direction | Other script |
|----------|-----------|--------------|
| `HighNoonAimNudge` | → | [[HighNoonViewModelOrbit]] receives hit position for gun flick |
| `FireRequested` | ← | [[HunterGuiClient]] mobile Fire button — routes the tap to `requestHighNoonShot()` while High Noon is active |

### Direct require()

| Target | Function | Purpose |
|--------|----------|---------|
| HighNoonFOV | `.new()`, `:PlayIntro()`, `:Reset()` | FOV zoom in/out during ultimate |
| HighNoonChargeUI | `.new()`, `:Initialize()`, `:Update()`, `:GetIsReady()`, `:GetCharge()` | Charge bar UI and readiness check |
| HighNoonTargetUI | `.new()`, `:UpdateTargets()`, `:Clear()` | Live target lock-on indicators (driven by `TargetUpdate`) |
| HighNoonLocalSFX | `.new()`, `:Play()`, `:Stop()` | Start/mid/whistle sounds for caster |
| HighNoonGunFX | `.new()`, `:GetShootTrack()`, `:RebuildFireSoundPool()`, `:PlayLocalShot()`, `:PlayCanShootCue()`, `:ClearFireSoundPool()`, `:Reset()` | Muzzle flash, fire sounds, orbit nudge |
| [[HunterMobileAbilityButton]] | `.new()`, `:Start()` | Mobile touch button for ultimate activation (replaces former Dust-only `HighNoonMobileButton`) |
| laserBeamEffect | `(muzzle, hit)` | Renders third-person shot tracer beams |
| [[HunterGate]] | `.IsHunter()` | Top-of-script hunter gate (replaces the former inline `waitForSelectedHunter`) |
