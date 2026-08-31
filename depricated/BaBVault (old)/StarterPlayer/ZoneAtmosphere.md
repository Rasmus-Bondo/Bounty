# ZoneAtmosphere

Applies post-processing visual effects when the player is outside the shrinking zone — orange color grading and screen blur that intensify with distance.

**Path:** `game.StarterPlayer.StarterPlayerScripts.ZoneAtmosphere`
**Type:** LocalScript (77 lines)
**Runs on:** Client

## How It Works

1. Creates ColorCorrectionEffect and BlurEffect in Lighting (initially disabled)
2. Each Heartbeat: reads `workspace:GetAttribute("ZonePhase")`
3. If ZonePhase < 2: disables effects immediately (zone not active yet)
4. Finds `ZoneFire_South` and `ZoneFire_North` parts in workspace
5. Compares player Z position against wall Z positions
6. If outside: calculates distance-based intensity (0 to 1, clamped at 40 studs)
7. Smoothly interpolates currentIntensity (lerp speed = 3)
8. Applies scaled effects when intensity > 0.01

## Effect Scaling

| Property | Value at max intensity |
|----------|----------------------|
| Brightness | +0.08 |
| Contrast | -0.15 |
| Saturation | -0.6 |
| Blur Size | 6 |
| Tint Color | (255, 140, 40) orange |

## Constants

| Constant | Value |
|----------|-------|
| TARGET_LERP_SPEED | 3 |
| Max distance for full effect | 40 studs |
| ZonePhase threshold | >= 2 |

## Dependencies

- `workspace.ZonePhase` attribute — set by [[ZoneService]]
- `workspace.ZoneFire_South` / `workspace.ZoneFire_North` — zone wall parts managed by [[ZoneService]]

## Used By

- Runs automatically for all players in StarterPlayerScripts
