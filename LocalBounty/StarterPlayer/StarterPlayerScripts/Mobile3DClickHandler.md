---
tags: [client, localscript, input, party, invite]
path: game.StarterPlayer.StarterPlayerScripts.Mobile3DClickHandler
type: LocalScript
lines: 547
---

# Mobile3DClickHandler

Handles PC and mobile clicking on 3D invite parts in the lobby using screen-projected hitboxes.

## What it does
1. Finds the InviteButtons/InviteParts container in Workspace holding the clickable invite objects. Resolved **lazily, on every use**, through `getInvitePartsFolder()` — a cached `FindFirstChild` over the three candidate names that re-resolves whenever the cache is empty or the folder has lost its `Parent`. It is never class-checked, so it is unaffected by `InviteButtons` being a `Model` (`ModelStreamingMode = Persistent`) rather than a Folder. The container used to be captured **once at script load**, which was a load-order race rather than a streaming-distance one: `Persistent` guarantees the model *arrives*, not that it exists on the line a StarterPlayerScript runs first. Losing that race left the local `nil` for the whole session — the invite buttons were dead and every later tap warned, which is where the 546 launch-day warnings came from. A `task.spawn` per candidate name also warms the cache with a bounded `WaitForChild` (30 s) so the first tap does not have to lose the race to notice; the names are spawned in parallel rather than chained so their timeouts do not stack
1b. The "no container found" warning is once per session, not once per tap — it previously sat behind only the 0.18 s click cooldown
2. Projects invite objects onto screen space and checks tap/click positions against bounding boxes
3. Resolves UserId from clicked objects via attributes (UserId, PlayerUserId, TargetUserId, PlayerName)
4. Sends party invite via PartyInviteEvent when a valid invite object is tapped
5. Supports both mouse click (PC) and touch tap (mobile) with movement limit validation
6. Uses configurable hitbox padding for PC vs mobile accuracy

## Dependencies
- **Requires:** Nothing
- **Required by:** Nobody

## Connections
### RemoteEvents
| Remote | Direction | Other script |
|--------|-----------|-------------|
| `PartyInviteEvent` | -> Server | [[PartyService]] sends invite action |

### BindableEvents
None

### Direct require()
None
