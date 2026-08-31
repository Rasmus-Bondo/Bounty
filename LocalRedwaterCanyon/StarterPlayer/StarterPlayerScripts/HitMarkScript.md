---
tags:
  - client
  - localscript
  - ui
  - combat
  - audio
  - settings
path: game.StarterPlayer.StarterPlayerScripts.HitMarkScript
type: LocalScript
lines: 1029
---

# HitMarkScript

Client-side crosshair, hitmarker, and kill indicator system with layered audio feedback. Shared across all hunters — no hero gate, listens to the cross-hero `HitConfirm` remote so it only reacts to hits the local player actually landed.

## What it does

1. Clones GunGui template from ReplicatedStorage.GuiTemplates or StarterGui into PlayerGui
2. Hides the default mouse cursor and displays a custom crosshair dot at true screen center — the GunGui ScreenGui is forced to `ScreenInsets = None` (set on the template and re-applied to the clone) so the dot lands on the camera's optical center, matching where the bullet (fired along `camera.CFrame.LookVector`) actually goes. Without this, `IgnoreGuiInset = true` silently forces `DeviceSafeInsets`, which re-centers the dot inside the mobile safe area and offsets it from the shot by the camera notch (worst for long-range hunters like Vesper)
3. On `HitConfirm` from server: plays a full hit feedback sequence:
   - Three triangle hitmarker arms expand outward in an equilateral triangle pattern, then contract back
   - Crosshair dot pulses (larger for headshots)
   - Flash frame expands behind the crosshair
   - Layered hit sounds: separate body/headshot sounds with randomized pitch
   - Screen shake on headshots via RenderStepped
   - Headshot glow color flash on triangles
4. On kill: plays a skull icon that expands, holds, then splits into upper/lower halves that fly apart and fade
5. Implements hit stacking: rapid consecutive hits within 0.55s increase visual intensity (up to 6 stacks) — bigger triangles, larger dot, more flash
6. All sizes scaled by `HITMARKER_SCALE` (0.65) for consistent sizing
7. Re-creates GunGui on `CharacterAdded` to survive respawn
8. Crosshair customization: reads `Player:GetAttribute("CrosshairColor")` (Color3) and `Player:GetAttribute("CrosshairSize")` (number multiplier, ~0.5-2.5) — set live by SettingsController. Attribute changes are wired via `GetAttributeChangedSignal` to repaint the dot's color / scale its `Size` immediately. `NORMAL_COLOR` (white) and the base `DOT_*_SIZE` constants are used only as fallback defaults now
9. Hit sounds (`HeadshotSound`, `NormalHitSound`, `BodyLayerSound`, `HeadshotLayerSound`) are assigned to the `SoundService.HitSound` `SoundGroup` when GunGui references are refreshed, so SettingsController's Hit Sound Volume slider can attenuate them independently of SFX/Music

(An auto-fire crosshair lock ring lived here for part of 2026-08-07 and was removed the same day at the user's request — auto-fire currently ships with no lock indicator. The hunter clients still publish the `AutoFireLocked` player attribute; if lock feedback returns, watch that attribute from this script and keep this script the visual's only writer, same single-writer rule as the dot.)

## Dependencies

- **Requires:** Nothing (pure UI)
- **Required by:** Nobody

## Connections

### RemoteEvents

| Remote | Direction | Other script |
|--------|-----------|--------------|
| `HitConfirm` | ← Server | Listened from `Hunters.Shared.Remotes` (cross-hero — created by [[HunterSharedRemoteSetup]]); [[RevolverModule]] and [[HighNoonModule]] fire it for Dust hits/kills |

### BindableEvents

None

### Direct require()

None
