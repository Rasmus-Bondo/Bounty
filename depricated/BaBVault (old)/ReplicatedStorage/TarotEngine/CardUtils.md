# CardUtils

Small math utility module with easing and interpolation functions used by the card animation system.

**Path:** `game.ReplicatedStorage.TarotEngine.CardUtils`
**Type:** ModuleScript
**Runs on:** Client

## Functions

| Function | Description |
|----------|-------------|
| `quadraticBezier(p0, p1, p2, t)` | Quadratic bezier curve interpolation — used for arc trajectories |
| `easeOutCubic(t)` | Cubic ease-out: `1 - (1-t)^3` — smooth deceleration |
| `easeOutBack(t, snapStrength)` | Back ease-out with configurable overshoot — snappy "bounce past target" feel |

## Used By

- [[CardAnimator]] — all animation functions use these for smooth motion paths
