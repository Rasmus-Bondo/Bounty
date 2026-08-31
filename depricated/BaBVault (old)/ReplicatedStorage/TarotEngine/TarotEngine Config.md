# Config (TarotEngine)

All numeric constants for the card animation and effects system.

**Path:** `game.ReplicatedStorage.TarotEngine.Config`
**Type:** ModuleScript
**Runs on:** Client

## Constants by Category

### Card Hover & Tilt
| Key | Value | Description |
|-----|-------|-------------|
| CARD_OFFSET_Y | 1 | Height above landing position |
| HOVER_LIFT | 0.35 | Extra lift when hovered |
| BOB_SPEED | 6 | Hover bob oscillation speed |
| BOB_AMOUNT | 0.12 | Hover bob amplitude |
| MAX_TILT_DEGREES | 12 | Max mouse-follow tilt |
| TILT_SMOOTHNESS | 0.18 | Tilt interpolation factor |

### Card Flip Animation
| Key | Value | Description |
|-----|-------|-------------|
| FLIP_DURATION | 1.65 | Flip animation time (seconds) |
| FLIP_ARC_HEIGHT | 4.5 | Vertical arc during flip |
| FLIP_Z_PUSH | 5.7 | Forward push during flip |
| FLIP_ROTATION_DEGREES | 180 | Rotation amount |
| FLIP_SNAP_STRENGTH | 1.9 | Overshoot snap for easeOutBack |
| FLIP_SETTLE_AMOUNT | 0.12 | Settle bounce at end |

### Lighting Effects
| Key | Value | Description |
|-----|-------|-------------|
| LIGHT_BRIGHTNESS_IDLE/HOVER | 4 / 6 | PointLight brightness |
| LIGHT_RANGE_IDLE/HOVER | 6 / 7 | PointLight range |
| LIGHT_TWEEN_TIME | 0.15 | Light transition duration |
| LIGHT_PULSE_TIME | 0.6 | Pulse cycle duration |

### Preview Mode
| Key | Value | Description |
|-----|-------|-------------|
| PREVIEW_MOVE/RETURN_DURATION | 0.45 / 0.35 | To/from preview position |
| PREVIEW_ARC_HEIGHT | 3.5 | Arc height to preview |
| PREVIEW_TILT_MULTIPLIER | 0.8 | Reduced tilt in preview |
| PREVIEW_BLUR_SIZE | 7 | Background blur amount |

### Legendary Reveal
| Key | Value | Description |
|-----|-------|-------------|
| LEGENDARY_REVEAL_ASCEND_DURATION | 2.55 | Rise animation time |
| LEGENDARY_REVEAL_LIFT | 8 | How high card rises |
| LEGENDARY_REVEAL_SPIN_Y_DEGREES | 1440 | 4 full Y-axis spins |

## Used By

- [[CardAnimator]] — flip, fly, preview, legendary animations
- [[CardEffects]] — light, border, blur effects
- [[CardController]] — hover/tilt updates
