# StaminaBarClient

Smoothly animates the stamina bar fill based on the player's Stamina attribute, avoiding jerky updates from network replication.

**Path:** `game.StarterPlayer.StarterPlayerScripts.StaminaBarClient`
**Type:** LocalScript (20 lines)
**Runs on:** Client

## How It Works

1. Gets HealthDisplayGui.Canvas.StaminaBar.Fill from PlayerGui
2. Each RenderStepped: reads `player:GetAttribute("Stamina")` (defaults to 100)
3. Applies exponential interpolation: `displayedStamina += (target - displayed) * min(1, dt * LERP_SPEED)`
4. Sets Fill.Size width to `stamina / MAX_STAMINA` (clamped 0-1)

## Constants

| Constant | Value |
|----------|-------|
| MAX_STAMINA | 100 |
| LERP_SPEED | 10 |

## Dependencies

- Player "Stamina" attribute — set by [[MovementService]] on the server
- PlayerGui.HealthDisplayGui.Canvas.StaminaBar.Fill — UI element in [[HealthDisplayGui]]

## Used By

- Runs automatically for all players in StarterPlayerScripts
