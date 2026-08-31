# HitMarkScript

Client-side crosshair and hitmarker system — renders a center dot, animated triangle hitmarkers on hit confirmation, kill skull on eliminations, with hit stacking that intensifies visuals for consecutive hits.

**Path:** `game.StarterPlayer.StarterPlayerScripts.HitMarkScript`
**Type:** LocalScript (681 lines)
**Runs on:** Client

## How It Works

### Crosshair Dot
- White dot at screen center (replaces default mouse cursor — `MouseIconEnabled = false`)
- Pulses on hit: grows to DOT_HIT_SIZE (or DOT_HEADSHOT_SIZE), then shrinks back
- Changes color to HEADSHOT_COLOR on headshot hits

### Triangle Hitmarker
- Three ImageLabels (Triangle1-3) arranged in equilateral triangle formation
- Rotated 0/-120/120 degrees to form a "Y" shape
- On hit: expand outward (REST → HIT_SIDE_FRACTION) while stretching vertically
- On headshot: extra stretch, glow flash (HEADSHOT_GLOW_COLOR), longer hold time

### Hit Stacking
- Tracks consecutive hits within STACK_DECAY_TIME (0.55s)
- Stack count (max 6) intensifies all effects:
  - Larger triangle spread and stretch
  - Bigger dot pulse
  - Larger flash frame
- Resets to 0 after 0.55s without a hit

### Screen Shake
- Headshots only: random XY offset on canvas, decaying over SHAKE_DURATION (0.12s)
- Uses RenderStepped connection with ID-based cancellation

### Flash Frame
- Semi-transparent background flash behind triangles
- White for body, HEADSHOT_COLOR for headshot
- Expands and fades to transparent

### Kill Skull
- On kill: skull image appears at center, expands with Back easing
- After hold: splits into upper-left and lower-right halves that fly apart and fade
- Body kills: pink skull (255, 145, 145)
- Headshot kills: deeper red skull (255, 90, 110)

### Sound Design
- Normal hit: NormalHitSound + BodyLayerSound (layered, randomized pitch 96-104%)
- Headshot: HeadshotSound + HeadshotLayerSound (randomized pitch 98-103%)

### Tool Connection
- Watches character for Tools with a `HitConfirm` RemoteEvent
- Connects to `HitConfirm.OnClientEvent(isHeadshot, didKill)`
- Reconnects on tool swap

## Visual Constants

| Constant | Value |
|----------|-------|
| HITMARKER_SCALE | 0.65 |
| REST_SIDE_FRACTION | 0.22 |
| HIT_SIDE_FRACTION | 0.50 |
| OUT_TIME | 0.07s |
| IN_TIME | 0.08s |
| HEADSHOT_HOLD_TIME | 0.12s |
| SHAKE_DURATION | 0.12s |
| SHAKE_INTENSITY | 0.005 |
| STACK_MAX | 6 |
| STACK_DECAY_TIME | 0.55s |

## Kill Skull Constants

| Constant | Value |
|----------|-------|
| SKULL_EXPAND_TIME | 0.19s |
| SKULL_HOLD_TIME | 0.14s |
| SKULL_SPLIT_TIME | 0.18s |

## Colors

| Element | Color |
|---------|-------|
| Normal | (255, 255, 255) white |
| Headshot | (241, 121, 123) |
| Headshot glow | (255, 175, 185) |
| Kill skull (body) | (255, 145, 145) |
| Kill skull (headshot) | (255, 90, 110) |

## Dependencies

- PlayerGui.GunGui — Canvas, CrosshairDot, SkullMark, SkullMarkUpper, SkullMarkLower, FlashFrame, Triangle1-3
- GunGui sounds: HeadshotSound, NormalHitSound, BodyLayerSound, HeadshotLayerSound
- Tool.HitConfirm RemoteEvent — fired by [[BanditGun GunServer]] or [[HitBoxTestTool GunScript]]

## Used By

- Runs automatically for all players in StarterPlayerScripts
- Receives hit data from any equipped tool with a HitConfirm remote
