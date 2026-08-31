# CurrencyDisplayScript

Animated cash counter that smoothly tweens between old and new values when the player earns or spends money. Displays as "$X.XX" format.

**Path:** `game.StarterGui.CurrencyGui.CurrencyDisplayScript`
**Type:** LocalScript (40 lines)
**Runs on:** Client

## How It Works

1. Reads `leaderstats.Cash` value
2. On each `RenderStepped`: lerps `displayedValue` toward `targetValue` using `dt * TWEEN_SPEED`
3. Updates both the main label and an optional glow label with formatted text

## Constants

| Constant | Value | Purpose |
|----------|-------|---------|
| TWEEN_SPEED | 8 | Lerp speed multiplier per frame |

## GUI Elements

| Element | Type | Description |
|---------|------|-------------|
| CurrencyDisplay | TextLabel | Main cash readout |
| CurrencyDisplayGlow | TextLabel | Optional glow duplicate for visual effect |

## Dependencies

- `leaderstats.Cash` — NumberValue created by [[LeaderstatService]], updated by [[DataService]]

## Used By

- Runs automatically in PlayerGui when the player joins
