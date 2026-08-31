# CardEffects

Handles all visual and audio effects for cards — hover highlights, border breathing, light pulses, blur, and legendary-specific sparkle/sound/shimmer effects.

**Path:** `game.ReplicatedStorage.TarotEngine.CardEffects`
**Type:** ModuleScript
**Runs on:** Client

## Key Functions

### Sound & Blur
| Function | Description |
|----------|-------------|
| `playSoundFromTemplate(template, parent)` | Clones a sound, plays it, auto-destroys via Debris |
| `tweenPreviewBlur(targetSize)` | Tweens the `CardPreviewBlur` BlurEffect in Lighting |
| `tweenSoundVolume(sound, volume, time)` | Smoothly fades a sound's volume |

### Card Visuals
| Function | Description |
|----------|-------------|
| `createHighlight(card)` | Adds a warm-toned Highlight instance (disabled by default) |
| `tweenLight(light, brightness, range, time)` | Smoothly transitions a PointLight |
| `startLightPulse(cardData)` | Loops light brightness between idle and hover values |
| `disableLightAfterTween(cardData)` | Delayed light disable with generation counter |

### Border System
| Function | Description |
|----------|-------------|
| `createBorderPart(card, template)` | Clones BorderPart mesh, matches card color |
| `updateBorderPart(cardData)` | Syncs border CFrame to card CFrame |
| `startBorderBreathing(cardData)` | Transparency pulse loop (0 ↔ 0.3) while hovered |
| `stopBorderBreathing(cardData)` | Cancels pulse, hides border |

### Legendary Effects
| Function | Description |
|----------|-------------|
| `startLegendaryHoverEffects(cardData, vol)` | Enables sparkle, plays/fades-in hover sound |
| `stopLegendaryEffects(cardData, vol)` | Disables sparkle, fades-out and stops sound |
| `startLegendaryPreviewShimmer(cardData)` | Starts [[Shime]] shimmer animation |
| `stopLegendaryPreviewShimmer(cardData)` | Stops shimmer |
| `emitLegendaryBurst(cardData, amount)` | Emits sparkle particles |

## State Safety

Uses generation counters (`lightPulseId`, `borderPulseId`, `lightDisableTaskId`, `legendaryStopTaskId`) to prevent stale callbacks from modifying state after a new interaction has started.

## Dependencies

- [[TarotEngine Config|Config]] — all timing/brightness/transparency constants
- `Lighting.CardPreviewBlur` — BlurEffect (auto-created if missing)

## Used By

- [[CardAnimator]] — calls border update, stop effects during animations
- [[CardController]] — calls hover visuals, preview blur, legendary effects
- [[CardFactory]] — calls `createHighlight()` and `createBorderPart()`
