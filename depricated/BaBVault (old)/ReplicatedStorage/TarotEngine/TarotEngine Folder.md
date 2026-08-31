# TarotEngine Folder

Complete client-side card gacha system. Players buy 3-card packs, cards fly from a deck, land face-down, and can be clicked to flip/reveal. Legendary cards get a special cinematic reveal with sparkles and spinning.

**Path:** `game.ReplicatedStorage.TarotEngine`
**Type:** Folder (7 ModuleScripts)

## Architecture

```
CardController (orchestrator)
├── CardRoller      → rolls rarity, picks template
├── CardFactory     → clones template, adds effects
├── CardAnimator    → fly-in, flip, preview, satchel animations
├── CardEffects     → hover glow, border pulse, legendary sparkle/sound
├── CardUtils       → math helpers (bezier, easing)
└── Config          → all animation/timing constants
```

## Module Index

| Module | Description |
|--------|-------------|
| [[TarotEngine Config\|Config]] | All numeric constants for animations, lighting, and effects |
| [[CardUtils]] | Math utilities: quadratic bezier, easeOutCubic, easeOutBack |
| [[CardEffects]] | Visual/audio effects: highlights, border breathing, light pulses, legendary sparkle |
| [[CardAnimator]] | Animation sequences: fly-in, flip, preview, satchel collect, legendary reveal |
| [[CardController]] | Main orchestrator: input handling, state management, card lifecycle |
| [[CardFactory]] | Creates card data objects from templates with all effect components |
| [[CardRoller]] | Weighted random rarity selection and template lookup |

## Data Flow

1. Player clicks buy → [[BuyCardsServer]] relays `BuyCardsEvent` to client
2. [[CardController]]`:SpawnLocalCards()` triggered
3. For each of 3 cards: [[CardRoller]] → [[CardFactory]] → [[CardAnimator]]`.flyCard()`
4. Player clicks face-down card → [[CardAnimator]]`.playFlipAnimation()` (or legendary reveal)
5. Player clicks revealed card → preview mode with tilt tracking
6. On next purchase → old cards animate into satchel via [[CardAnimator]]`.sendCardToSatchel()`

## Workspace Dependencies

Cards reference these workspace objects (see [[CardController]]):
- `DeckPosition` — where cards spawn from
- `CardDisplay` — preview position part
- `CardSatchel` — collection destination
- `CoinPouch` — bounces when cards collected
- `CardPosition1/2/3` — landing positions for 3 cards

## Related

- [[BuyCardsServer]] — server relay for purchase event
- [[TarotPurchaseValidation]] — server-side cash validation
- [[CardClientScript]] — StarterPlayerScript that initializes CardController
- [[Shime]] — shimmer effect used on Legendary card SurfaceGui
- [[CardTemplates Folder]] — the physical card mesh templates
- [[SFX Folder]] — card-related sound templates
