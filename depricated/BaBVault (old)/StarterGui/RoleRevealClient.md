# RoleRevealClient

Flashes a "FIGHT!" text overlay for 3 seconds when the player is assigned the "Bandit" role at round start.

**Path:** `game.StarterGui.GameplayGui.Canvas.RoleRevealClient`
**Type:** LocalScript (37 lines)
**Runs on:** Client

## How It Works

1. Listens for changes to the player's `Role` attribute
2. When role is `"Bandit"`: shows BanditText + BanditTextShadow with "FIGHT!"
3. Waits 3 seconds, then hides both labels

## GUI Elements

| Element | Type | Description |
|---------|------|-------------|
| BanditText | TextLabel | Main "FIGHT!" text with UIStroke + UIGradient |
| BanditTextShadow | TextLabel | Shadow copy with UIStroke for depth effect |
| UISizeConstraint | UISizeConstraint | Constrains the Canvas frame |

## Constants

| Constant | Value |
|----------|-------|
| SHOW_TIME | 3 seconds |

## Dependencies

- Player `Role` attribute — set by [[RoleService]] on the server

## Used By

- Runs automatically in PlayerGui when the player joins
