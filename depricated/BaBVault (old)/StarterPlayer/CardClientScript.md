# CardClientScript

Client-side bootstrap for the tarot card system — creates a [[CardController]] instance, routes input and render updates to it, and binds remote events.

**Path:** `game.StarterPlayer.StarterPlayerScripts.CardClientScript`
**Type:** LocalScript (25 lines)
**Runs on:** Client

## How It Works

1. Requires [[CardController]] from ReplicatedStorage.TarotEngine
2. Creates controller instance: `CardController.new(player)`
3. Routes `InputBegan` (non-processed) to `controller:OnInputBegan(input)`
4. Calls `controller:Update()` every RenderStepped
5. Calls `controller:BindRemoteEvents()` to set up server communication

## Dependencies

- ReplicatedStorage.TarotEngine.[[CardController]] — the actual card logic module
- UserInputService — for input routing
- RunService — for per-frame updates

## Used By

- Runs automatically for all players in StarterPlayerScripts
