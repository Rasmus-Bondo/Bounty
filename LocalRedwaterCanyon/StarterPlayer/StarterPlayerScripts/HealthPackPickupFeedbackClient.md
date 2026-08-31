---
tags:
  - client
  - localscript
  - ui
  - combat-feedback
path: game.StarterPlayer.StarterPlayerScripts.HealthPackPickupFeedbackClient
type: LocalScript
lines: 127
---

# HealthPackPickupFeedbackClient

Renders health pack feedback on the client: the local player's own pickup polish, and the world FX every nearby client draws on whoever healed.

## What it does

1. Listens on two shared remotes fired by [[HealthPackSystem]]. `HealthPackPickedUp` is fired to the healing player alone and drives the **local** feedback; `HealthPackWorldFX` is fired to everyone with the healed character and draws the **world** effect, so a player sees other people heal
2. **Local:** three layered heal sounds staggered 0 / 0.045 / 0.105s at falling volume and alternating pitch (1.0 / 1.03 / 0.97), cloned from `ReplicatedStorage.SFX.HealingSFX` onto the root part and cleaned up by Debris on their own length — one sample played three times reads fuller than one hit
3. **Local:** the green screen-edge pulse, via `HealingVignette.play()`
4. **World:** emits the `HealthCross` (15) and `Crescent` (5) particle templates off the root part, and expands a `ForceField`-material ball welded to the root — fades in to 0.35 over 0.08s, then out to 1 while growing 0.45 → 6 studs over 0.34s. Debris-cleaned at 0.7s
5. Every template is read with `FindFirstChild` and type-checked before use, so a missing asset costs an effect rather than throwing

## The vignette moved out on 2026-08-10

The screen-edge flash used to be built and animated here, and this script was 652 lines. The onboarding tutorial wanted the identical effect on a completed step, so it became the shared [[HealingVignette]] module plus an authored `StarterGui.HealingVignetteGui`, and this file dropped to 127.

Copying it would have been the cheaper edit and the wrong one: two hand-tuned greens drift, and the module's overlap token only works if every caller comes through it — picking up a health pack *during* a tutorial step is precisely the collision it guards.

## Dependencies

- **Requires:** [[HealingVignette]]
- **Required by:** Nobody

## Connections

### RemoteEvents

| Remote | Direction | Other script |
|--------|-----------|-------------|
| `HealthPackPickedUp` | ← Server | [[HealthPackSystem]] fires it to the healing player only; drives the sounds and the vignette |
| `HealthPackWorldFX` | ← Server | [[HealthPackSystem]] fires it to everyone with the healed character; drives the particles and the burst sphere |

### BindableEvents

None

### Direct require()

| Target | Function | Purpose |
|--------|----------|---------|
| [[HealingVignette]] | `HealingVignette.play()` | The green screen-edge pulse on a local pickup |

Reads (plain, not code-level connections): the `ReplicatedStorage.SFX.HealingSFX` folder's authored `Heal` / `Heal2` / `Heal3` Sounds and `HealthCross` / `Crescent` ParticleEmitters.
