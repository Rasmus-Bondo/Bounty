---
tags: [client, modulescript, ui, tween]
path: game.StarterPlayer.StarterPlayerScripts.CollectionClient.Tween
type: ModuleScript
lines: 41
---

# Tween

Shared TweenService runner. Cancels any tween already running on the same object before starting a new one so animations never fight each other.

## What it does
1. Holds an `activeTweens[object]` cache mapping a target instance to its current Tween
2. `Tween.run(object, tweenInfo, properties)` cancels the prior tween on that object, creates a new TweenService tween, registers it, plays it, and removes it from the cache on Completed
3. `Tween.cancel(object)` cancels and clears any tween currently registered for the object

## Dependencies
- **Requires:** Nothing
- **Required by:** CollectionClient, SurfaceAnimator, HunterList, Reel

## Connections
### RemoteEvents
None

### BindableEvents
None

### Direct require()
None
