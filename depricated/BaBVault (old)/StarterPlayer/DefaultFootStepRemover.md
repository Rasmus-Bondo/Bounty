# DefaultFootStepRemover

Silences Roblox's built-in character running sounds so that the custom [[FootstepService]] can play material-based footstep audio instead.

**Path:** `game.StarterPlayer.StarterCharacterScripts.DefaultFootStepRemover`
**Type:** LocalScript (17 lines)
**Runs on:** Client (per character)

## How It Works

1. On character load: iterates all descendants, sets Volume = 0 on any Sound named "Running"
2. Listens to DescendantAdded: mutes any future "Running" sounds added by Roblox

## Dependencies

- None — self-contained

## Used By

- Works in conjunction with [[FootstepService]] (server) which plays custom footstep sounds via [[FootstepSounds]] remote
