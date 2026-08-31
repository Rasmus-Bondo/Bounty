# StartProceduralLocomotion

Bootstrap script that creates a [[ProceduralLocomotion]] controller for the character on spawn and cleans it up when the character is removed.

**Path:** `game.StarterPlayer.StarterCharacterScripts.StartProceduralLocomotion`
**Type:** LocalScript (22 lines)
**Runs on:** Client (per character)

## How It Works

1. Requires [[ProceduralLocomotion]] module from the same character
2. Creates controller with custom config overrides:
   - FootSpacing = 0.82 (wider than default 0.78)
   - ForwardBase = 0.05
   - IdleFollow = 12
   - MoveDirectionThreshold = 0.05
   - VelocityThreshold = 1.0
3. On AncestryChanged (character removed from game): calls `controller:Destroy()`

## Dependencies

- [[ProceduralLocomotion]] — ModuleScript in StarterCharacterScripts

## Used By

- Runs automatically per character in StarterCharacterScripts
