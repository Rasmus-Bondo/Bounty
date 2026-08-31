---
tags: [client, localscript, audio]
path: game.StarterPlayer.StarterCharacterScripts.DefaultFootStepRemover
type: LocalScript
lines: 17
---

# DefaultFootStepRemover

Mutes the default Roblox footstep sound by setting the volume of all `Running` sounds in the character to 0.

## What it does

1. On character load, iterates all descendants and sets `Volume = 0` on any Sound named `Running`
2. Watches `DescendantAdded` to catch late-added Running sounds

## Dependencies

- **Requires:** Nothing
- **Required by:** Nobody
- Lives in `StarterCharacterScripts` so it runs fresh each respawn with `script.Parent` = character
