# CardFactory

Creates card data objects from template meshes. Clones the template, adds visual effect components (highlight, border, legendary sound/sparkle/shimmer), and returns a structured data table.

**Path:** `game.ReplicatedStorage.TarotEngine.CardFactory`
**Type:** ModuleScript
**Runs on:** Client

## `createCardData(template, folder, borderTemplate, legendarySound, sparkleTemplate, Shime)`

1. Clones the template MeshPart (anchored, no collision)
2. Adds a `Highlight` instance via [[CardEffects]]
3. Finds existing `PointLight` on the card mesh
4. **If Legendary:** clones looping hover sound, sparkle emitter, and creates [[Shime]] shimmer on the SurfaceGui frame
5. Creates a border glow part via [[CardEffects]]`.createBorderPart()`
6. Returns the `cardData` table

## cardData Structure

```lua
{
    part = MeshPart,           -- the cloned card
    border = MeshPart,         -- border glow part
    highlight = Highlight,     -- hover highlight
    light = PointLight,        -- card glow light
    isLegendary = bool,
    legendarySound = Sound?,   -- looping hover sound
    sparkle = ParticleEmitter?,
    shimmer = Shime?,          -- shimmer animation object
    -- Generation counters (prevent stale callbacks):
    legendaryStopTaskId, lightDisableTaskId, lightPulseId,
    borderPulseId, moveId = 0,
    -- Animation state:
    baseCFrame, previewBaseCFrame, previewReturnCFrame,
    landed, hovered, flipped, flipping, previewing, moving = false,
    -- Tilt tracking:
    targetTiltX, targetTiltZ, currentTiltX, currentTiltZ = 0,
}
```

## Dependencies

- [[CardEffects]] — `createHighlight()`, `createBorderPart()`
- [[Shime]] — shimmer effect for legendary cards

## Used By

- [[CardController]]`:SpawnLocalCards()` — creates cardData for each rolled card
