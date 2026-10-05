---
tags: [client, localscript, mounts, character]
path: game.StarterPlayer.StarterPlayerScripts.Mounts.WadingClient
type: LocalScript
lines: 10
---

# WadingClient

Disables swimming on the owning client so players wade through water.

## What it does
1. On each character spawn, calls `SetStateEnabled(Swimming, false)` on the Humanoid. Humanoid state permissions don't replicate, so the server's setting alone doesn't stick on the owner.

## Dependencies
- **Requires:** Nothing
- **Required by:** Nobody

## Connections
None.
