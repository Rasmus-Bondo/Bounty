# Findings — Tutorial Relocation

## Live Studio audit 2026-08-16 (Redwater, place:98517073248449)
Matches spec §0/§1b exactly. Deltas/details the spec didn't state:

- **Both connected places:** Redwater `place:98517073248449`, Frostbite `place:134041618959520`.
  Every MCP call needs instance_id.
- **25 unanchored+CanCollide parts confirmed** (14 WallPartTutorial, 4 Step1Walls, 5 Step2Walls,
  2 SurfaceGuiTutorialPart). SurfaceGui parts are already Transparency=1.
- **17 bot markers are already Anchored=true, CanCollide=false** — hiding needs only
  Transparency=1, CanQuery=false, CastShadow=false.
- **All 4 pad Models** contain `Union` (UnionOperation) + `Checkpoint` (Part 10×0.1×10),
  both anchored, CanCollide=false. Checkpoint top surface = Union top; players stand on terrain.
- Checkpoint positions: Spawn (−1538.70, 6.46, −26.08) · CP1 (−1576.09, 8.61, −40.48)
  · CP2 (−1637.29, 38.07, −118.71) · CP3 (−1728.00, 23.11, −199.60)
- Old canyon markers present at root: `TutorialSpawn` Part (−69.44, 9.00, −257.44),
  `TutorialBountySpawn` Part (41.24, 11.50, −249.34), both transp 1.
- `ServerStorage.TutorialDummies`: TutorialDummy1/2/3 Models, canyon pivots as spec §3 says.

## Script paths (Redwater)
| Script | Path |
|---|---|
| TutorialDirector | game.ServerScriptService.Onboarding.TutorialDirector (ModuleScript) |
| Config | game.ServerScriptService.RoundSystem.Config |
| ZoneService | game.ServerScriptService.RoundSystem.ZoneService |
| RoundController | game.ServerScriptService.RoundSystem.RoundController |
| Telemetry | game.ServerScriptService.PlayerServices.Telemetry |
