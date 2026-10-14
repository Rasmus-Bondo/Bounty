---
tags: [server, script, missions]
path: game.ServerScriptService.Missions.MissionServer
type: Script
lines: 1491
---

# MissionServer

The PVE expedition loop: vote, travel, fight or complete an objective, secure the reward, call the train, then extract or ride on.

## What it does
1. Restores legacy mission sites (`PVE_Outpost`, `PVE_Graveyard`, `PVE_SaltFlats`, `PVE_OutpostRepair`, `PVE_Salvage`, `PVE_TrainStation`) from `ServerStorage.LegacyMissionSiteTemplates` if missing, validates the station with StationTemplateValidator, and drives all state through attributes on `ReplicatedStorage.PVE.Encounter` (`Phase`, `EndsAt`, `Day`, `Wave`, `Reward`, `Mission*`, `Objective*`, `Modifier*`, `Boon*`, `Decision*`).
2. The camp `StartEncounter` (job board) prompt no longer starts a run. The first `MissionVote` click while `Phase=Idle` calls `startFromVote` (voter within 16 studs of camp), which rosters up to 4 living players within 55 studs, resets their run attributes, and applies that pending vote once Voting opens. A `ChangeStandardJob` prompt cycles the Standard mission between Mine, Escort, TNT and Valves.
3. Each day: a `Voting` phase with no timer; the board prompt stays enabled as "Open job board" so a player who closed the panel can reopen it. The most-voted job (ties go to the starter's vote) starts 10 s after the first vote, and the countdown resets if every vote is withdrawn. Then a destination from `PVEWorldDestination` (or `PVEWorldTemplateDestination` for the Mine/TNT templates), mission sites placed and reserved through `PVEWorldQuery`, and a `Travel` phase with a distance-based deadline. Day modifiers (Restless, Thick Hide, Blood Moon) and an 8%/day threat and reward bonus scale the run.
4. Runs the objective: enemy waves (with a Warden boss inside a BossArena on the final wave), Holdout zone, Repair, Mine supplies (MineSupplyMission), or Escort/TNT/Valves (MissionVariety, paced by EscortPacing); pressure enemies spawn at MissionPlacement points through EnemyService.
5. `SecureReward`: a line-of-sight check at the reward cache (placed by RewardCachePlacement) pays `PVEScrap` to every non-eliminated roster member, then heals up to 25.
6. `Return` to the station, `CallTrain` by shooting the bell (`PVETrainBellHit`), a 40 s `TrainHoldout` with `TrainThreatCue` warnings before each pressure group, then the train arrives.
7. `Boon` (15 s): each player picks Gunsmoke (+8% damage), Ironhide (+15 HP) or Fleetfoot (faster Quickstep), defaulting to Gunsmoke. `Decision` (35 s): `Continue` to the next day or `Extract` by boarding the train, which force-dismounts (`PVEForceDismountNow`), drops any carried revive token (`PVEReleaseCarriedToken`), secures loose supplies and writes the `PVELastRun*` summary. Players who give no Continue/Extract answer by the end of the 35 s window are extracted too (a sentinel boarding entry if they are too far from the door). `finishBoardedPlayer` banks carried scrap into `PVEScrap`, drops the player at camp and then calls `LobbyReturn.Send(p, "Extract")`.
8. Any failure (wipe, travel timeout, uncollected reward) or an error in the loop ends with `cleanupRun`, which resets players and returns the phase to `Idle`. A lost run (`Failed`/`TravelFailed`) sends everyone still in it, tracked in a `participants` set because the roster drops the dead, to the lobby after 6 s; the crash-recovery path passes `skipLobby` and is excluded.
9. `PVE.ReturnToLobby` remote: an explicit "leave for town" for players who are not active runners (idle at camp, already extracted or eliminated); boarding or already-pending players are ignored.
10. Lobby hand-off (#48): reads `GetJoinData().TeleportData.mission` (`Easy`, `Hard`, or a Variety kind) from the first server join with `source="lobby"`, then once a living player stands at camp (and the party has landed or 8s passed) sets the Standard slot and calls `startFromVote`, so the lobby pick skips the camp vote. An unknown token changes nothing.

## Dependencies
- **Requires:** [[RewardCachePlacement]], [[EnemyService]], [[BossArena]], [[StationTemplateValidator]], [[WorldGenerationConfig]], [[MineSupplyMission]], [[MissionPlacement]], [[MissionVariety]], [[EscortPacing]], [[LobbyReturn]]
- **Required by:** Nobody

## Connections
### RemoteEvents
| Remote | Direction | Other script |
|--------|-----------|-------------|
| `PVE.MissionVote` | ← Client | [[MissionClient]] mission vote; the first vote while Idle starts the run |
| `PVE.ReturnToLobby` | ← Client | [[MissionClient]] LEAVE TO LOBBY button, Idle phase only |
| `PVE.ExpeditionDecision` | ← Client | [[MissionClient]] Continue / Extract |
| `PVE.ExpeditionBoon` | → Client / ← Client | [[RunBoonClient]] open/close the boon picker and receive the choice |
| `PVE.TrainThreatCue` | → Client | [[MissionClient]] incoming pressure-group positions during the train holdout |

### BindableEvents
| Bindable | Direction | Other script |
|----------|-----------|-------------|
| `ServerStorage.PVETrainBellHit` (BindableEvent) | ← | [[CombatServer]] bell shot calls the train |
| `ServerStorage.PVEReleaseCarriedToken` (BindableEvent) | → | [[ReviveServer]] drop a carried token on extraction |
| `ServerStorage.PVEForceDismountNow` (BindableFunction) | → Invoke | [[HorseServer]] dismount before boarding |
| `ServerStorage.PVEWorldQuery` (BindableFunction) | → Invoke | [[WorldRuntime]] Sample, RoadCenter, RailCenter/Height, StationSlot, PinStation, ReserveMission(Route), Coordinates |
| `ServerStorage.PVEWorldDestination` (BindableFunction) | → Invoke | [[WorldRuntime]] next mission site |
| `ServerStorage.PVEWorldTemplateDestination` (BindableFunction) | → Invoke | [[WorldRuntime]] Mine/TNT template site |
| `ServerStorage.PVEWorldLoadedChunks` (BindableFunction) | → Invoke | [[WorldRuntime]] loaded chunk records |

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[EnemyService]] | `Spawn` | Waves, pressure groups and the Warden boss |
| [[BossArena]] | `Start`, `Pulse`, `Stop` | Boss-fight boundary |
| [[MissionVariety]] | `Prepare`, `Enable`, `TryInteract`, `Step`, `Status` | Escort / TNT / Valves objectives |
| [[MineSupplyMission]] | `Prepare`, `Enable`, `Count`, `Cleanup` | Mine crate objective |
| [[EscortPacing]] | `New`, `Step`, `Pause` | Escort ambush schedule |
| [[MissionPlacement]] | `FindSpawn` | Pressure enemy spawn points |
| [[RewardCachePlacement]] | `Choose` | Reward chest placement |
| [[StationTemplateValidator]] | `Validate` | Station model sanity check at boot |
| [[WorldGenerationConfig]] | `ChunkSize` and world tuning | Site placement |
| [[LobbyReturn]] | `Send`, `IsPending` | Teleport extracted, failed-run and leaving players to the lobby |
