---
tags: [client, localscript, missions, ui, hud]
path: game.StarterPlayer.StarterPlayerScripts.Missions.MissionClient
type: LocalScript
lines: 722
---

# MissionClient

The expedition HUD: mission vote, phase titles, waypoints and markers, train extraction, boss bar, downed overlay and the end-of-run report, all driven by replicated `PVE.Encounter` attributes.

## What it does
1. Binds the `PVE_CombatHUD.HealthPanel` bar to the character's Humanoid health.
2. Builds the `PVE_MissionVote` ScreenGui in code: the three-card job vote (Easy / Standard / Hard; reward text is hard-coded), the Continue / Extract decision panel, and the results report shown when `PVELastRunFinished` changes (reads the `PVELastRun*` player attributes). The vote panel shows during Voting, or while Idle if it was opened from the job board (`StartEncounter` prompt, E); a click on the dark area outside the panel closes it, a "PRESS J" hint appears, and E at the board or J reopens it. While Idle the timer reads "THE VOTE STARTS WHEN YOU DO", then "STARTS 10s AFTER THE FIRST VOTE" until a countdown begins.
3. Every Heartbeat reads `PVE.Encounter` attributes (`Phase`, `EndsAt`, `Wave`, `ObjectiveProgress/Goal`, `Escort*`, `Valve*`, `Boss*`, `BossArena*`, `Day`, `ThreatMultiplier`, `MissionId`, …) and writes the `PVE_CombatHUD` Title/Subtitle for every phase from Idle through Voting, Travel, combat and objective phases to TrainHoldout, Boon, Decision, Complete and Failed.
4. Shows a job-progress panel for Escort / TNT / Valves (wagon health and ambush status, rocket countdown, valve green-window gauge), a day/threat badge, loose-salvage badge and Grave Warden health bar.
5. Guides the player: a compass waypoint (revive shrine while carrying a token, nearest relevant objective `ProximityPrompt` in `workspace.PVEMissionObjectives`, mission site, reward cache, station bell, train door), plus billboard markers for repair parts, machinery, station, bell, reward cache and train door, with highlights.
6. Train flow: banners on phase changes, holdout countdown, and per-wave `INCOMING` billboards at the positions sent on `TrainThreatCue`; the board button is only active within 18 studs of the train door.
7. Boss arena: dust-storm banners, a boundary `ColorCorrectionEffect` that strengthens near the arena edge, and a push-back warning; also eases Lighting toward a fixed daylight target.
8. Downed overlay with the revive-token countdown.
9. The vote panel and job board never show on day 1 (arrival from the lobby); only `Encounter.Day` > 1, i.e. after Continue on the train, opens them. A LEAVE TO LOBBY button on the vote panel, visible only while `Phase=Idle`, fires `PVE.ReturnToLobby` (#48).

## Dependencies
- **Requires:** Nothing
- **Required by:** Nobody

## Connections
### RemoteEvents
| Remote | Direction | Other script |
|--------|-----------|-------------|
| `PVE.MissionVote` | → Server | [[MissionServer]] job vote (`Easy` / `Standard` / `Hard`); the first vote while Idle starts the run |
| `PVE.ExpeditionDecision` | → Server | [[MissionServer]] `Continue` / `Extract` |
| `PVE.ReturnToLobby` | → Server | [[MissionServer]] leave for the lobby; ignored for active runners |
| `PVE.TrainThreatCue` | ← Server | [[MissionServer]] train-holdout wave spawn positions and labels |

### BindableEvents
None

### Direct require()
None
