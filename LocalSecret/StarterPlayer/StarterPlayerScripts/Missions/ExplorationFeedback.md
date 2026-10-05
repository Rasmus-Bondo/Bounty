---
tags: [client, localscript, missions, ui]
path: game.StarterPlayer.StarterPlayerScripts.Missions.ExplorationFeedback
type: LocalScript
lines: 12
---

# ExplorationFeedback

Short green toast for exploration messages pushed by the server through player attributes.

## What it does
1. Builds the `PVEExplorationFeedback` ScreenGui with one label.
2. When the `PVEExplorationMessageId` player attribute changes, shows the text of `PVEExplorationMessage` for 4 s (a generation counter keeps a newer message from being hidden early).

## Dependencies
- **Requires:** Nothing
- **Required by:** Nobody

## Connections
None. Reads player attributes only.
