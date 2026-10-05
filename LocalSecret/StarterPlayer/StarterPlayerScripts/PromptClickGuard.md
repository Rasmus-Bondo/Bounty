---
tags: [client, localscript, input]
path: game.StarterPlayer.StarterPlayerScripts.PromptClickGuard
type: LocalScript
lines: 27
---

# PromptClickGuard

Turns off `ClickablePrompt` on ProximityPrompts for keyboard players so a prompt under the locked centre cursor cannot trap the mouse.

## What it does
1. Exits on touch-only devices, which need clickable prompts to tap them.
2. Sets `ClickablePrompt = false` on every existing workspace ProximityPrompt, on each one added later, and on any prompt as it is shown (`PromptShown`). PC players still trigger prompts with E.

## Dependencies
- **Requires:** Nothing
- **Required by:** Nobody

## Connections
None.
