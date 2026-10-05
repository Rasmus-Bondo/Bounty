---
tags: [client, localscript, progression, ui, missions]
path: game.StarterPlayer.StarterPlayerScripts.Progression.RunBoonClient
type: LocalScript
lines: 95
---

# RunBoonClient

Trail-boon draft (Gunsmoke / Ironhide / Fleetfoot) shown during the Boon phase, plus the in-run boon summary.

## What it does
1. Builds the `PVERunBoon` ScreenGui with three boon cards; opens on `Open` and closes on `Close` from `PVE.ExpeditionBoon`. While the draft is active, a click on the dark area outside the panel hides it and shows a `PVERunBoonHint` button ("PRESS B TO CHOOSE A TRAIL BOON"); B or clicking the hint reopens it.
2. Clicking a card locks all cards and fires the chosen boon id; a timer reads `PVE.Encounter.EndsAt` and notes that unclaimed boons default to Gunsmoke.
3. Builds the `PVERunPerkSummary` panel listing owned boons with stack counts from `PVEBoonGunsmoke` / `PVEBoonIronhide` / `PVEBoonFleetfoot` player attributes, visible only while `PVEInEncounter`.
4. Takes part in menu gating by name: ClientMenuState treats an enabled `PVERunBoon` as an open menu.

## Dependencies
- **Requires:** Nothing
- **Required by:** Nobody

## Connections
### RemoteEvents
| Remote | Direction | Other script |
|--------|-----------|-------------|
| `PVE.ExpeditionBoon` | → Server | [[MissionServer]] chosen boon id |
| `PVE.ExpeditionBoon` | ← Server | [[MissionServer]] `Open` / `Close` the draft |

### BindableEvents
None

### Direct require()
None
