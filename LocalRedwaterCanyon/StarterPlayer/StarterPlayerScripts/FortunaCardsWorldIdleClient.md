---
tags:
  - client
  - localscript
  - combat
  - fortuna
  - cards
  - animation
path: game.StarterPlayer.StarterPlayerScripts.FortunaCardsWorldIdleClient
type: LocalScript
lines: 242
---

# FortunaCardsWorldIdleClient

Plays a looping idle animation on every Fortuna player's third-person world-model cards prop, as seen by other players. Fortuna's counterpart to WorldRevolverAimIdleClient.

## What it does
1. For every player in the server, watches for their character's `CardsWorldCards` part (created server-side by CardsWorldVisualServer) and plays Fortuna's world `Idle` clip — resolved once at boot from the Fortuna manifest via `HunterAnimations.id("Fortuna", "World", "Idle")` — looped on their Humanoid's Animator
2. Retries playback up to 80 times (0.1s apart) if the cosmetic or Animator isn't ready yet
3. Re-evaluates a player's idle animation whenever their `SelectedHunter` attribute changes (starts it if they become Fortuna, stops it otherwise)
4. Stops the track on death, character removal, or player leaving

## Dependencies
- **Requires:** [[AnimationLoader]], [[HunterAnimations]]
- **Required by:** Nobody

## Connections
### RemoteEvents
None

### BindableEvents
None

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[AnimationLoader]] | `AnimationLoader.load()` | Load the world idle only once the clip is confirmed fetched, so `playIdle` returns an honest false and the retry loop in `setupCharacter` actually retries |
| [[AnimationLoader]] | `AnimationLoader.prewarm()` | Warm the clip at script start so the first spawn does not pay the fetch inside the retry loop |
| [[HunterAnimations]] | `HunterAnimations.id()` | Resolve the world Idle clip id from the Fortuna manifest |
