# Mobile Auto-Fire + Aim Assist Rework — Implementation Guide

**Status:** spec, not yet implemented
**Written:** 2026-08-06
**Place:** Redwater Canyon only (the settings key also touches Bounty — see §7)
**Audience:** a fresh session implementing this end to end

---

## 1. What changes

Mobile players currently shoot by tapping the on-screen **FIRE** button. Emptying a
6-round revolver means six taps with the same thumb that also has to aim, which is why
mobile DPS sits well under PC's.

After this change, a touch player fires by **putting the crosshair on an enemy and keeping
it there**. The weapon fires on its own cadence for as long as the crosshair holds the
target. The FIRE button stays exactly as it is — it is still the way to shoot at a wall,
a health pack, or an enemy the lock has not picked up, and it is still the only way to
shoot with auto-fire turned off.

Aim assist is retuned rather than rebuilt: camera magnetism gets **weaker**, because the
lock tolerance is now what carries a mobile player's aim.

### Decisions already made — do not re-litigate

| Decision | Choice |
|---|---|
| Hunter coverage | **All four** — Dust, Vesper, Bram, Fortuna — through one shared module |
| Player control | **Settings toggle, default ON, row hidden on non-touch devices** |
| Aim assist direction | **Soften magnetism** (`MaxYawOffsetDeg` 1.5 → 1.0); lean on lock tolerance, not camera pull |
| Vertical assist | **Stays off** (`MaxPitchOffsetDeg = 0`). Vertical pull was tested and rejected — it dragged clean head aim down into the torso |

Considered and deliberately **not** taken, so nobody quietly adds them later:

- A magnetism *deadzone* that decays the pull to zero inside the lock cone. Sensible, but
  it belongs to the "keep magnetism strong" branch that was not chosen.
- Stronger target tracking (wider cone, higher closure). Rejected — reads as aimbot to PC
  players in the same lobby.
- A `Tap-assist` middle mode. The toggle is binary.

---

## 2. How firing works today

All four hunters converge on the same shape: **a `FireRequested` BindableEvent fired by the
shared FIRE button, handled by one self-gating fire function per hunter.** Every one of those
functions already checks its own cooldown, ammo, reload and ability state and returns early,
which is what makes auto-fire cheap to add — the ticker does not need to know anything about
weapon state.

| Hunter | Fire entry (as of 2026-08-06) | Cadence gate | Notes |
|---|---|---|---|
| Dust | `FPSRevolverClient` → `shoot()` (line 1045), wired at 1156 | `canShoot` flag + `task.delay(fireCooldown)` | During High Noon the ultimate steals the event in `HighNoonClient` (line 258) |
| Vesper | `SunspikeClient` → `tryFire()` (line 378), wired at 1375 | `os.clock() - S.LastFireTime < BasicConfig.Cooldown` | Starfall ultimate uses a separate shot pool |
| Bram | `GrudgekeeperClient` → `tryFire()` (line 543), wired at 1657 | `os.clock() - S.LastFireTime < getFireCooldown()` | Returns immediately while `S.IsBreachCharging` |
| Fortuna | `CardsClient` → `useBasic()` (line 1336), wired at 2171 | `os.clock() < S.NextBasicTime`, where the interval is the animation's own length | Button uses **hold** style: `FireRequested(true/false)` drives `startBasicHold` / `stopBasicHold` |

The button itself is `ReplicatedStorage.Hunters.Shared.HunterMobileFireButton` — one
authored `StarterGui.HunterFireGui > MobileFireButton`, shared by all four, built only on
touch. **Nothing in this change touches that module.**

### Aim assist today

`ReplicatedStorage.Hunters.Shared.AimAssistController` (375 lines) — instantiated
identically in `FPSRevolverClient` (152), `CardsClient` (45), `GrudgekeeperClient` (1449)
and `HunterFirstPersonClient` (252), all reading `RevolverConfig.AimAssist`:

```lua
RevolverConfig.AimAssist = {
	Enabled = true, MaxRange = 200, AcquireConeDeg = 4,
	MaxYawOffsetDeg = 1.5, MaxPitchOffsetDeg = 0,
	ClosureSpeed = 3, DecaySpeed = 8,
	TargetUpperChest = true, RequireLOS = true,
}
```

Per frame it picks the enemy closest to camera-forward inside a 4° cone, LOS-checks it, and
lerps an accumulated yaw offset toward "point at target", clamped to 1.5°. It already
solves the two hard problems this change depends on:

1. **Candidate building** — enemy `Player.Character` rigs (team-filtered) plus everything
   tagged `AimAssistTarget` (arena bots, `BotSpawner2` dummies).
2. **Bot geometry resolution** — arena bots are *rendered* as smoothed clones in
   `workspace.ClientBotVisuals`; their server rig is invisible but still queryable and
   trails the clone by ~1 stud. `buildBotVisualMap` indexes the clones by `BotId`, and
   `_evaluateCharacter(character, geometry, …)` takes **liveness from the server rig,
   position from the rendered clone**. Hidden rigs are excluded from the LOS ray.

**The lock must be computed inside this module for exactly that reason.** A second,
independent "is an enemy under the crosshair" implementation would re-introduce the
bot-visual bug that was fixed on 2026-07-25, and it would drift the moment either copy is
touched.

---

## 3. Architecture

Two modules, one new:

```
AimAssistController  (modified)
  ├── acquires the best target                      (existing)
  ├── applies yaw magnetism                         (existing, retuned)
  └── publishes a LOCK REPORT via :GetLock()        (NEW)
                    │
                    ▼
MobileAutoFireController  (NEW, ReplicatedStorage.Hunters.Shared)
  ├── dwell / grace / cadence
  ├── per-hunter CanAutoFire gate
  ├── reads the AutoFireEnabled player attribute
  └── calls OnFire() -> the hunter's existing fire entry
```

Per-frame order in every hunter client, inside the render step that already exists:

```lua
aimAssistController:Update(deltaTime)   -- acquires + rotates the camera
autoFireController:Update(deltaTime)    -- reads this frame's lock, may fire
```

`autoFire` **must** run after `assist`, so the lock it reads was measured against the camera
the shot ray will actually use.

---

## 4. The lock test

### 4.1 What "the crosshair is on an enemy" means here

**Do not implement this as a raycast down `camera.CFrame.LookVector`.** It is the obvious
approach and it is wrong in this codebase:

- Client bot visuals have `CanQuery = false` on all visible rig geometry. The *only*
  queryable parts are the `BotAssistHitbox` volumes — 4.5 × 3.0 × 3.4 studs for a body
  (vs ~2 × 1.6 × 1 for a real R15 torso) and 3.15³ for a head. A raycast lock would be
  wildly more generous on bots than on players, and would fire at a crosshair sitting a
  full stud off a bot's shoulder.
- `workspace.RewindHitboxes` — lag-compensation snapshots at *historical* positions — are
  queryable too and would produce phantom locks.

Instead, compute the lock from the same rendered geometry the assist already resolves:

```
aimPoint   = midpoint(HumanoidRootPart.Position, Head.Position)   -- the assist's own point
offset     = aimPoint - cameraPos
distance   = |offset|
angle      = acos(clamp(camera.LookVector · offset.Unit, -1, 1))  -- already computed

tolerance  = math.min(math.atan(LockRadiusStuds / distance), MaxLockAngleRad)
locked     = angle <= tolerance
```

`LockRadiusStuds` is an **apparent-size** radius, so the cone shrinks with distance on its
own. There is deliberately **no minimum angle**: at 150 studs the tolerance is a quarter of
a degree and the player has to genuinely aim. A floor would be an aimbot.

### 4.2 Lock radius vs. server hit forgiveness — the safety ordering

The server already forgives near-misses. Dust and Vesper resolve a miss through a **3.5-stud
sphere** around the ray (`RevolverServerConfig.HitForgiveness` / `VesperConfig.HitForgiveness`,
both `Radius = 3.5, MaxDistance = 350`). Bram's blast is a **2-stud spherecast** with no
forgiveness pass. Fortuna has no forgiveness module at all — her lag-comp spheres
(`CardsConfig.PartRadii`: torso 2.4, head 1.3) double as it.

**Lock radius must stay below the hunter's effective hit radius.** That ordering is the whole
design:

- the player locks onto what they can *see* (a body-sized silhouette), and
- the server's forgiveness absorbs the residual error, so a lock reliably becomes a hit.

Invert it and auto-fire starts firing at empty air next to an enemy — technically a hit
thanks to forgiveness, but it reads as the gun shooting at nothing, and it is the version
that looks like cheating on a spectator's screen.

| Hunter | Server hit radius | `LockRadiusStuds` | Why |
|---|---|---|---|
| Dust | 3.5 (forgiveness sphere) | **1.6** | Torso half-width plus a little; forgiveness covers the rest |
| Vesper | 3.5 (forgiveness sphere) | **1.6** | Same weapon shape; scoped shots are gated separately (§6.2) |
| Bram | 2.0 (spherecast, 60-stud cap) | **2.2** | Shotgun — the blast is already wide, and `MaxRange = 60` keeps the cone honest |
| Fortuna | 2.4 torso (lag-comp spheres) | **1.6** | Projectile at 1400 studs/s over 100 studs ≈ 0.07s flight; no lead needed |

`MaxLockAngleDeg = 20` is a point-blank sanity ceiling, not a tuning knob — it only binds
inside ~4.5 studs.

### 4.3 LOS

Reuse the assist's existing `_hasLineOfSight` and `_buildExcludes` untouched. They already
handle: the local character, the viewmodel (via `GetExtraExcludes`), the `VesperHookSpotsBot`
and `WallMap` folders, every health pack's floating `Pickup` + `TouchHitbox` (the solid
`Base` still blocks), and hidden bot server rigs.

---

## 5. `AimAssistController` changes

### 5.1 Split eligibility

Today `_isEligible()` folds three things together, and `Enabled = false` would stop target
acquisition entirely — which would silently kill auto-fire if magnetism is ever switched off.
Split it:

```lua
function AimAssistController:_isTouchOnly()      -- unchanged
function AimAssistController:_canAcquire()       -- touch-only + CanAimAssistCheck
function AimAssistController:_canRotate()        -- _canAcquire() and self._enabled
```

`Update` acquires whenever `_canAcquire()`, and rotates the camera only when `_canRotate()`.
`Enabled` now means "magnetism on", not "assist system on".

### 5.2 Publish the lock

`_acquireTarget` already computes `bestAngle` and `bestTargetPos` — carry the distance out
with them and store a report. New public accessor:

```lua
-- Returns nil when nothing is locked, else:
-- { Model = <rendered model>, Position = Vector3, AngleRad = n, ToleranceRad = n, Distance = n }
function AimAssistController:GetLock()
	return self._lock
end
```

Set `self._lock = nil` at the top of every `Update`, including the ineligible early-outs, so
a stale lock can never survive a frame in which acquisition did not run. It must also clear
on `Destroy`.

New config keys, both read from `RevolverConfig.AimAssist`:

| Key | Default | Meaning |
|---|---|---|
| `LockRadiusStuds` | `1.6` | Apparent-size radius for the lock test |
| `MaxLockAngleDeg` | `20` | Point-blank ceiling on the tolerance |

### 5.3 Retune

```lua
RevolverConfig.AimAssist = {
	Enabled = true,
	MaxRange = 200,
	AcquireConeDeg = 4,
	MaxYawOffsetDeg = 1.0,   -- was 1.5 — auto-fire carries the aim now
	MaxPitchOffsetDeg = 0,   -- DO NOT RAISE. Vertical pull steals headshots.
	ClosureSpeed = 3,
	DecaySpeed = 8,
	TargetUpperChest = true,
	RequireLOS = true,
	LockRadiusStuds = 1.6,   -- NEW
	MaxLockAngleDeg = 20,    -- NEW
}
```

**Known quirk, load-bearing — do not "fix" it.** `_acquireTarget` reads the *already-offset*
camera each frame and lerps toward the remaining delta, so the offset converges to roughly
**half** the angle from player intent to target rather than snapping fully on. That is what
makes the assist feel soft. Removing it makes magnetism far more aggressive without any
config change.

Note the lock is measured on the assisted camera, which is correct — the shot ray uses the
same camera. It does mean magnetism can nudge a near-miss into a lock. With yaw capped at 1°
that is a sub-degree effect and is the intended relationship between the two systems.

---

## 6. `MobileAutoFireController` (new shared module)

`ReplicatedStorage.Hunters.Shared.MobileAutoFireController` — OOP, same shape as
`AimAssistController` and `HunterMobileFireButton`, no `require`s of its own, everything
injected.

### 6.1 API

```lua
local controller = MobileAutoFireController.new({
	Player        = player,                 -- required
	AimAssist     = aimAssistController,    -- required; the lock source

	Enabled       = true,                   -- master default; the setting overrides live
	AcquireDelay  = 0.08,                   -- seconds the lock must hold before the first shot
	LossGrace     = 0.12,                   -- seconds a lock survives a dropout (strafe behind a post)
	FireInterval  = 0.35,                   -- minimum seconds between auto-fired shots

	CanAutoFire   = function() return true end,   -- per-hunter gate, see 6.2
	OnFire        = function() shoot() end,       -- the hunter's existing fire entry
	OnLockChanged = function(isLocked) end,       -- optional, for crosshair feedback
})

controller:Update(dt)      -- call once per frame, AFTER aimAssist:Update(dt)
controller:IsLocked()
controller:SetEnabled(bool)
controller:Destroy()
```

### 6.2 Update logic

```
Update(dt):
  if not touchOnly()               -> reset, return
  if not self._enabled             -> reset, return          (settings toggle)
  if CanAutoFire and not CanAutoFire() -> reset, return

  lock = AimAssist:GetLock()

  if lock then
      self._lockHeld += dt
      self._lostFor = 0
  else
      self._lostFor += dt
      if self._lostFor > LossGrace then reset() end
  end

  if self._lockHeld < AcquireDelay then return end
  if os.clock() < self._nextFireTime then return end

  self._nextFireTime = os.clock() + FireInterval
  OnFire()
```

`reset()` zeroes `_lockHeld` and fires `OnLockChanged(false)` if the state changed. Fire
`OnLockChanged(true)` the first frame `_lockHeld` crosses `AcquireDelay`, not on raw
acquisition — the crosshair should confirm what will actually shoot.

**`AcquireDelay` is the anti-drive-by knob.** Without it, sweeping the camera across three
enemies to reach a fourth fires three wasted shots. 0.08s ≈ 5 frames at 60fps.

**`FireInterval` is a floor, not the cadence.** Every hunter's fire entry re-checks its own
cooldown, so it is safe (and correct) for `FireInterval` to be shorter than the weapon's
actual cooldown. Fortuna needs this: `useBasic()`'s interval is the animation's own length,
which varies per combo step, so she polls at `0.05` and lets `S.NextBasicTime` gate.

Per-hunter values:

| Hunter | `FireInterval` | `CanAutoFire` must also return false when |
|---|---|---|
| Dust | `RevolverConfig.Combat` fire cooldown | `isUsingHighNoon` — the ultimate owns `FireRequested` and has its own targeting |
| Vesper | `BasicConfig.Cooldown` | Scoped **and** Deadeye Focus not yet full — see below |
| Bram | `GrudgekeeperConfig.Basic.Cooldown` (0.5) | `S.IsBreachCharging` |
| Fortuna | `0.05` (poll) | `S.IsUltimateInvisible or S.IsUltimateCasting or S.IsAbility1Casting` |

**Vesper's scope gate is the one with real design weight.** Her passive ramps Deadeye Focus
while scoped (`VesperConfig.Passive.DeadeyeFocus.RampTime`), and firing early throws the
bonus away. Auto-firing the instant a scoped crosshair crosses an enemy would make the
passive unusable on mobile. Gate it: while `S.IsScoped`, only auto-fire once the ramp is
complete. `SunspikeClient` already receives `E.ScopeChanged` (line 1275) but does not record
a timestamp — add `S.ScopedSince = os.clock()` there, mirroring the `scopedSince` local that
`VesperHunterGuiClient` keeps for the ramp bar (line 814).

### 6.3 Side effect worth knowing

Dust's `shoot()`, Vesper's and Bram's `tryFire()` all call `sprintController:Cancel()`
*before* their cooldown check. So a held lock suppresses sprint for as long as it lasts.
That matches manual firing and is almost certainly what you want — but it means a mobile
player cannot sprint while an enemy sits under their crosshair. Flag it in playtest notes;
if it reads badly, the fix is to move the sprint cancel below the cooldown check in each
hunter, not to special-case auto-fire.

Likewise: all four fire entries call their reload function when the magazine is empty, so
auto-fire triggers auto-reload. `HunterAutoReload` already does this, so it is a no-op in
practice — but it means the ticker can never spin on an empty gun.

---

## 7. The `AutoFireEnabled` setting

Persisted per player, default **true**, surfaced only on touch devices.

### 7.1 Server — both places

Settings live in the profile, and **the profile is shared across Bounty and Redwater**. A key
accepted in one place and rejected in the other silently loses the player's choice.

| File | Change |
|---|---|
| `ServerScriptService.PlayerServices.DataService` (**both places**) | Add `AutoFireEnabled = true` to the `Settings` sub-table of the profile template (next to `CrosshairSize`, line ~62 in Redwater) |
| `ServerScriptService.PlayerServices.PlayerSettingsService` (**both places**) | Add to the `SETTINGS` whitelist: `AutoFireEnabled = { default = true, validate = function(v) if typeof(v) ~= "boolean" then return nil end return v end }` |

These are per-place files, not byte-identical mirrors — the requirement is *the same key with
the same default and the same validator*, not identical files. Adding it to only one place is
the failure mode: `SetPlayerSetting` in the other place drops the write with no error.

This is **not** a profile schema bump (an added key with a default reconciles cleanly), but it
*is* a data-affecting change in the changelog sense — mark the release accordingly.

### 7.2 Client — `SettingsController`

Follow the `ShowPingFPS` pattern exactly (Redwater `SettingsController` line 1049–1063):

```lua
local AUTO_FIRE_ATTRIBUTE = "AutoFireEnabled"

local function applyAutoFire(value)
	setToggleVisual(autoFireToggle, value)
	localPlayer:SetAttribute(AUTO_FIRE_ATTRIBUTE, value == true)
end

autoFireToggle.Activated:Connect(function()
	local newValue = not (localPlayer:GetAttribute(AUTO_FIRE_ATTRIBUTE) == true)
	applyAutoFire(newValue)
	setPlayerSetting:FireServer("AutoFireEnabled", newValue)
end)
```

Then, alongside the other seeds near line 858: `applyAutoFire(true)`, and in the
`playerSettingsResponse` handler (~line 871):
`if typeof(payload.AutoFireEnabled) == "boolean" then applyAutoFire(payload.AutoFireEnabled) end`.

**Publish it as a player attribute, not a bindable.** That is how `CrosshairSize`,
`CrosshairColorIndex` and `AbilityDescriptions` already reach their consumers, and it means
the auto-fire controller reads current state at any moment without a join-order handshake:

```lua
-- inside MobileAutoFireController:Update
if self.Player:GetAttribute("AutoFireEnabled") == false then reset(); return end
```

Note the `== false` test, not `not …`. **The attribute is absent until the settings payload
lands**, and absent must mean *on* (the default), not off — otherwise every player spends
their first seconds in a match with auto-fire mysteriously dead. This is the same ordering
trap the `ShowPingFPS` comment block documents at length.

### 7.3 UI — authored row, not built in code

Add `AutoFireRow` under `StarterGui.ReworkedSettingsGui.Canvas.Background.Content`:

- **Clone `ShowPingFPSRow`** — `Frame`, `Size = {1, 0}, {0, 34}`, `BackgroundTransparency = 1`,
  `ZIndex = 6`, children `Label` (TextLabel) + `ToggleButton` (TextButton). Rename, retext.
- Read `UI_STYLE_GUIDE.md` before touching any property — colours, fonts and the
  sharp-panel/rounded-button corner rule are specified there.
- Place it under a new **`INPUT`** header (`TextLabel`, same treatment as `HUDHeader` /
  `GRAPHICSHeader`), positioned between `CROSSHAIR` and `HUD`. Firing behaviour is not a HUD
  setting and does not belong in the crosshair group.
- Label text: **`Auto Fire`**. Nothing longer — the row is 34px and the toggle owns the right
  edge.
- **Hide it on non-touch devices:** `autoFireRow.Visible = UserInputService.TouchEnabled`, and
  hide the `INPUT` header with it if it has no other rows. `Content` uses a `UIListLayout`, so
  an invisible row collapses correctly and leaves no gap.
- `Content` is a **ScrollingFrame**. Adding a row grows the content by 34px + padding; confirm
  `AutomaticCanvasSize` is doing the work, or extend `CanvasSize` by hand. See the
  scrolling-canvas rule: canvas scale is relative to the parent, children are relative to the
  canvas minus padding.
- Mirror all of the above into **Bounty's** `ReworkedSettingsGui` too — the panel is a mirror,
  and a player who opens settings in the lobby must see the same toggle.

---

## 8. Crosshair lock feedback

A player needs to know the gun is about to fire on its own. Without it, auto-fire feels like
a bug the first time it happens.

`HitMarkScript` (`StarterPlayerScripts.HitMarkScript`, 1029 lines) owns
`StarterGui.GunGui.CrosshairDot` and already tweens it for hitmarks, kill skulls and the
`CrosshairSize` / `CrosshairColorIndex` settings. **Do not write to the dot from the auto-fire
module** — two writers on one tweened property produce flicker that only shows up under fire.

Instead: `MobileAutoFireController`'s `OnLockChanged` sets a player attribute
(`AutoFireLocked`), and `HitMarkScript` watches it and owns the visual. Recommended treatment
is a small authored ring `ImageLabel` under `GunGui` that fades in on lock — a colour change
on the dot itself competes with the headshot/hitmark colour states already in that script.

The ring is an **authored instance**, added in Studio, not built with `Instance.new`.

---

## 9. Traps

Ordered by how much time each one costs if missed.

1. **No MCP playtesting.** `start_playtest` hangs the plugin connection. Verify by
   recompiling each edited script with `loadstring(script.Source)` via `execute_luau`, then
   hand the checklist in §10 to a manual playtest.
2. **`execute_luau`'s `require()` cache is stale.** Recompile with `loadstring(script.Source)`
   before trusting an error from a module you just edited.
3. **`set_script_source` eats `\n` escapes** inside Lua string literals. Use a `[[long
   string]]` and verify by loading it back.
4. **Never partially overwrite a script.** `set_script_source` needs the whole file; use
   `Edit`-style spot changes through `edit_script_lines` for anything smaller.
5. **Teardown on mid-match hunter switch.** Every hunter client registers
   `HunterClientState.registerCleanup(...)` — Dust `FPSRevolverClient` 1294, Vesper
   `SunspikeClient` 1415, Bram `GrudgekeeperClient` 1705, Fortuna `CardsClient` 2275. The new
   controller must be destroyed in each, `pcall`-guarded, alongside the existing
   `aimAssistController` teardown. A leaked controller keeps firing for the hunter you
   switched away from.
6. **Streaming.** Both places run `StreamingEnabled`. A distant enemy's model can replicate as
   an empty container — `FindFirstChild("HumanoidRootPart")` returns nil. `_evaluateCharacter`
   already returns nil in that case; do not add a code path that assumes descendants exist.
7. **Touch-only gate is a fairness boundary.** The assist's
   `TouchEnabled and not KeyboardEnabled and not GamepadEnabled` test is what keeps this off
   PC and console. Reuse it verbatim — do not test `TouchEnabled` alone, or a touchscreen
   laptop gets free auto-aim.
8. **Studio's device emulator leaves `TouchEnabled` false for the first moment** after client
   scripts start. `HunterMobileFireButton` polls for ~12s rather than sampling once
   (`:Start()`, line 358). The auto-fire controller re-checks every frame, so it is immune —
   but any *one-shot* touch check you add elsewhere will be wrong in the emulator.
9. **Fortuna's hold state machine.** Auto-fire must call `useBasic()` directly, **not**
   `startBasicHold()`. The hold owns `S.HoldingBasic` / `S.HoldToken` and is driven by the
   FIRE button's press/release pair; hijacking it means a real button release
   (`stopBasicHold`) cancels an auto-fire the player never started, and vice versa.
10. **Dust's High Noon steals `FireRequested`.** `HighNoonClient` (line 258) connects the same
    bindable and fires the ultimate shot. Auto-fire calls `shoot()` directly rather than
    firing the bindable, so it does not collide — but its `CanAutoFire` gate must still return
    false during High Noon, exactly like the existing `SetCanAimAssistCheck` callback at
    `FPSRevolverClient:486`.
11. **`RoundClientController` sweeps `PlayerGui` at round boundaries** and snapshots each
    ScreenGui's `Enabled`. Any new ScreenGui you add for the lock ring needs the same
    treatment the mobile buttons got — an attribute the sweep restores from, not a snapshot.
    Adding the ring inside the existing `GunGui` avoids the whole problem.
12. **The server is unchanged and stays authoritative.** Fire cooldowns are enforced
    server-side per hunter (`RevolverModule:426` plus a `weaponGuard:TryConsume`,
    `SunspikeModule:263`, `GrudgekeeperModule:269`), so auto-fire cannot outrun the weapon
    even if the client ticker is wrong. Do not add client trust anywhere in this change.

---

## 10. Verification

Static, before any playtest:

- [ ] `loadstring(script.Source)` clean on every edited script (both places).
- [ ] Both copies of `PlayerSettingsService` and `DataService` carry `AutoFireEnabled` with
      the same default and validator.
- [ ] `/preflight check` passes — mirrored-module gate included.

Device matrix — `set_device_simulator` + `capture_screenshot` at a small phone, a tablet and a
**windowed** desktop (Studio's default viewport is the one size no player has):

- [ ] `AutoFireRow` visible and tappable on touch; toggle ≥ 44×44px at the smallest screen.
- [ ] Row hidden on desktop, `INPUT` header hidden with it, no gap in the list.
- [ ] Settings list still scrolls to the bottom row on the shortest screen.

Manual playtest (mobile or emulator, one per hunter):

- [ ] Crosshair swept onto a bot → fires within ~0.1s; swept off → stops.
- [ ] Sweeping *past* three bots to reach a fourth does not fire at the first three.
- [ ] Lock holds through a bot strafing behind a thin post (grace) but drops behind a wall (LOS).
- [ ] Auto-fire never outpaces the weapon's manual fire rate.
- [ ] FIRE button still fires normally, including at a wall with nothing locked.
- [ ] Toggle off → auto-fire stops immediately, button still works; rejoin → still off.
- [ ] Dust: nothing auto-fires during High Noon.
- [ ] Vesper: scoped shots wait for full Deadeye Focus; hipfire does not.
- [ ] Bram: no auto-fire during Breach Charge; charge still commits on impact.
- [ ] Fortuna: auto-fire respects the combo cadence and never fires while ultimate-invisible.
- [ ] Arena bots (`ClientBotVisuals`) lock at the position they are *rendered*, not a stud
      behind — the same bug class as the 2026-07-25 assist fix.
- [ ] PC session in the same match: no lock, no auto-fire, crosshair ring never appears.

---

## 11. Documentation and release tasks

- **Vault** — new `LocalRedwaterCanyon/ReplicatedStorage/Hunters/Shared/MobileAutoFireController.md`
  from the standard template. Update `AimAssistController.md` (new `GetLock` API, split
  eligibility, retune), the four hunter client `.md` files, `RevolverConfig.md`,
  `SettingsController.md` and `HitMarkScript.md`. Bounty side: `SettingsController.md`,
  `PlayerSettingsService.md`, `DataService.md`.
- **Wikilinks** — `[[MobileAutoFireController]]` only where a script actually `require()`s it.
  The controller requires nothing, so its own Dependencies section is `Nothing` /
  the four clients. Do **not** wikilink `AimAssistController` from prose comparisons.
- **Graphs** — `python update_redwater_canyon_graph.py` and `python update_bounty_graph.py`,
  bare commands, one per tool call, issued together. Then verify:
  `Grep "\"_src\": \"mobileautofirecontroller\"" graphs/RedwaterCanyonGraph/graph.json -A 1`
  — every `_tgt` must correspond to a real `require()`. Node counts drop needs `--force`.
- **Changelog** — `Edit` (never `Write`) `changelog/UNRELEASED.md`, anchored on a heading.
  Mark the release **data-affecting** (new profile Settings key). Player-facing note can name
  auto-fire directly — it is a feature, not an exploit fix.
- **Publish both places together.** The settings key exists on both sides; shipping one alone
  is a live drift bug.

---

## 12. Open questions for after the first playtest

- Does `AcquireDelay = 0.08` feel responsive or laggy? It is the single knob most likely to
  need moving.
- Is `LockRadiusStuds = 1.6` too tight at 40+ studs, where the cone is under 2.3°? The honest
  fix is a per-hunter value, not a minimum angle floor.
- Should the lock prefer the target the player is *already* locked to over a marginally closer
  new one? Right now a crossing enemy can steal the lock mid-burst. Hysteresis on target
  identity (not just on lock/unlock) is the fix if this reads badly.
- Does suppressing sprint while locked (§6.3) hurt more than it helps?
- Telemetry: worth logging auto-fire on/off at match start through the existing `Telemetry`
  chokepoint to see what fraction of mobile players keep it? Deliberately out of scope here —
  adding an event means mirroring it across both places.
