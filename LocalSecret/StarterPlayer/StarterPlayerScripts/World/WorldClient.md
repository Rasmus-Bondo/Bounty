---
tags: [client, localscript, world, streaming]
path: game.StarterPlayer.StarterPlayerScripts.World.WorldClient
type: LocalScript
lines: 70
---

# WorldClient

Client-side decoration streaming: spawns and removes per-chunk scenery that the server tells it about.

## What it does
1. Keeps a `workspace.PVE_ClientWorld` folder with one `Decor_<key>` sub-folder per loaded chunk.
2. On `WorldChunk` `Load`, clones each placement's asset from `ReplicatedStorage.WorldAssets`, scales it, sets yaw, and drops its bounding-box bottom onto the given ground height.
3. Makes every decoration part anchored and non-interactive (no collide / touch / query) and deletes any ProximityPrompt or ClickDetector inside.
4. On `Unload`, destroys that chunk's folder; reloading a key replaces it.

## Dependencies
- **Requires:** Nothing
- **Required by:** Nobody

## Connections
### RemoteEvents
| Remote | Direction | Other script |
|--------|-----------|-------------|
| `Remotes.WorldChunk` | ← Server | [[WorldRuntime]] chunk decoration `Load` / `Unload` |

### BindableEvents
None

### Direct require()
None
