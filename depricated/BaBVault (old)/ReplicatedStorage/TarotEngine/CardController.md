# CardController

Main orchestrator for the card gacha system. OOP class that manages the full card lifecycle: spawning, hovering, flipping, previewing, and collecting. Handles both mouse and touch input.

**Path:** `game.ReplicatedStorage.TarotEngine.CardController`
**Type:** ModuleScript
**Runs on:** Client

## Constructor: `CardController.new(player)`

Sets up references to:
- `BuyCardsEvent` (RemoteEvent) — triggers card spawning
- `CardTemplates.BorderPart` — border glow mesh template
- SFX templates: CardPick, CardFlip, PreviewCard, LegendarySound, SatchelSound
- `SparkleLegendary` particle template
- [[Shime]] module for legendary shimmer
- `CardsGui` — ScreenGui with `PreviewingCard` BoolValue and `CanBuyPack` BoolValue
- Workspace parts: `DeckPosition`, `CardDisplay`, `CardSatchel`, `CoinPouch`, `CardPosition1/2/3`
- `LocalCards_{playerName}` folder in workspace (created if missing)

## Key Methods

### Card Spawning
| Method | Description |
|--------|-------------|
| `SpawnLocalCards()` | Main entry — rolls 3 cards, animates fly-in from deck |
| `SendExistingCardsToSatchel(onComplete)` | Collects old cards one-by-one before spawning new pack |
| `ClearOldCards()` | Destroys all card parts and resets state |

### Interaction
| Method | Description |
|--------|-------------|
| `HandleCardInteraction(clickedCard)` | Routes click to flip, legendary reveal, or preview |
| `OnInputBegan(input)` | Handles MouseButton1 and Touch input |
| `PreviewCard(cardData)` | Moves flipped card to display position with blur |
| `ReturnPreviewedCard(onComplete)` | Returns previewed card to board position |

### Hover System
| Method | Description |
|--------|-------------|
| `UpdateHover()` | Raycasts from mouse to detect card under cursor |
| `SetHoveredCard(newHovered)` | Switches hover visuals between cards |
| `SetCardHoverVisuals(cardData, isHovered)` | Toggles highlight, light pulse, border breathing, legendary effects |

### State
| Method | Description |
|--------|-------------|
| `CanBuyNewPack()` | Returns true if all cards are flipped and no animations running |
| `Update()` | Called every frame — updates hover, tilt, and bob animations |

## State Fields

| Field | Type | Description |
|-------|------|-------------|
| SpawnedCards | table | Array of active cardData objects |
| HoveredCard | cardData? | Currently hovered card |
| PreviewedCard | cardData? | Currently previewed card |
| InteractionLocked | bool | Blocks input during animations |
| Animating | bool | True while spawning/collecting |

## Workspace References

| Part | Purpose |
|------|---------|
| DeckPosition | Cards spawn from this CFrame |
| CardPosition1/2/3 | Landing positions for the 3 cards |
| CardDisplay | Preview viewing position |
| CardSatchel | Collection destination |
| CoinPouch | Bounce animation target |

## Dependencies

- [[TarotEngine Config|Config]], [[CardEffects]], [[CardAnimator]], [[CardFactory]], [[CardRoller]]
- [[Shime]] — for legendary card shimmer
- [[SFX Folder]] — sound templates
- [[CardTemplates Folder]] — BorderPart template

## Used By

- [[CardClientScript]] — creates CardController instance and runs update loop
