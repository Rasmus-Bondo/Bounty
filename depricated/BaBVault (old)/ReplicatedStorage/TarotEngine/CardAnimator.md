# CardAnimator

Handles all card movement animations using RenderStepped frame-by-frame updates with bezier curves and custom easing.

**Path:** `game.ReplicatedStorage.TarotEngine.CardAnimator`
**Type:** ModuleScript
**Runs on:** Client

## Animations

### `flyCard(card, deckPos, targetPart, soundTemplate, onComplete)`
Fly a card from the deck to a landing position with an arc. Duration: 0.45s fixed.

### `playFlipAnimation(cardData, flipSound, legendaryVol)`
Standard card flip — 180° rotation on X and Y with arc, z-push, roll, and settle bounce. Uses easeOutBack for snappy feel. Duration: 1.65s from [[TarotEngine Config|Config]].

### `playLegendaryRevealAnimation(controller, cardData)`
Cinematic legendary reveal — card rises 8 studs with 4 full Y-axis spins (1440°), continuous sparkle emission, then transitions to preview position. Locks all interaction during sequence.

### `animateCardToCFrame(cardData, target, duration, arcHeight, onComplete)`
Generic arc-move from current position to target CFrame. Used for preview enter/exit.

### `sendCardToSatchel(cardData, satchelPart, onComplete)`
Shrinks card to 15% size, fades to transparent, and arcs toward the satchel part. Duration: 0.25s.

### `bounceCoinPouch(coinPouchPart)`
3-step squash-and-stretch bounce on the coin pouch model (puff → squash → restore). Triggers when a card is collected.

## Pattern

All animations follow the same pattern:
1. Increment a `moveId` counter (prevents stale callbacks)
2. Connect to `RunService.RenderStepped`
3. Calculate normalized time `t` with easing
4. Interpolate position via [[CardUtils]]`.quadraticBezier()`
5. Disconnect and call `onComplete` at `t >= 1`

## Dependencies

- [[TarotEngine Config|Config]] — animation durations, heights, rotation amounts
- [[CardUtils]] — bezier interpolation, easing functions
- [[CardEffects]] — updates border positions, manages effects during animations

## Used By

- [[CardController]] — calls all animation functions during card lifecycle
