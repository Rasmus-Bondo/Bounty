---
tags: [client, localscript, ui, health]
path: game.StarterPlayer.StarterPlayerScripts.LocalHealthBarHide
type: LocalScript
lines: 24
---

# LocalHealthBarHide

Removes the server-created health bar billboard from the local player's own head so they don't see their own health bar.

## What it does

1. Waits for the local player's `Head`
2. Destroys any existing `HealthBarGui` on it
3. Watches for new `HealthBarGui` children and immediately destroys them
4. Repeats on each respawn via `CharacterAdded`

## Dependencies

- **Requires:** Nothing

## Connections

No RemoteEvents or BindableEvents. Directly destroys the `HealthBarGui` BillboardGui that HealthBarModule (server) creates on the local player's head.
