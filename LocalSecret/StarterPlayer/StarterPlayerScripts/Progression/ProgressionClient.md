---
tags: [client, localscript, progression, ui]
path: game.StarterPlayer.StarterPlayerScripts.Progression.ProgressionClient
type: LocalScript
lines: 104
---

# ProgressionClient

The Camp Workbench upgrade menu (Revolver / Shotgun tuning, Hardened Grit) for spending secured scrap.

## What it does
1. Builds the `PVEProgressionGui` ScreenGui in code with three upgrade cards; ranks, costs (75/150/250 and 100/200/325) and descriptions are hard-coded in this script.
2. Opens when the server sends `Open` on `Remotes.Progression`; every server message re-renders scrap, rank N/3 and the upgrade button (maxed, affordable or not) and flashes an optional status message.
3. An upgrade button fires `Buy` with the upgrade id.
4. Closes on ×, Escape, a click outside the panel, or when the player is in an encounter and `PVE.Encounter.Phase` is not `Voting` (the workbench stays usable while the job vote is open and closes once the job really starts).
5. Labelled "PROTOTYPE LOADOUT · SESSION DATA ONLY".
6. Takes part in menu gating by name: ClientMenuState treats an enabled `PVEProgressionGui` as an open menu.

## Dependencies
- **Requires:** Nothing
- **Required by:** Nobody

## Connections
### RemoteEvents
| Remote | Direction | Other script |
|--------|-----------|-------------|
| `Remotes.Progression` | → Server | [[ProgressionServer]] `Buy` upgrade request |
| `Remotes.Progression` | ← Server | [[ProgressionServer]] `Open` + state (scrap, levels) + message |

### BindableEvents
None

### Direct require()
None
