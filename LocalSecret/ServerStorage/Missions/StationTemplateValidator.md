---
tags: [server, modulescript, missions]
path: game.ServerStorage.Missions.StationTemplateValidator
type: ModuleScript
lines: 57
---

# StationTemplateValidator

Validates the gameplay interface of a replaceable train station model.

## What it does
1. `Validate(model)` requires `StationAnchor`, `Platform` and `Bell` BaseParts, a `Train` Model with a `BoardDoor` part carrying a `BoardTrain` ProximityPrompt.
2. If a `StationMarkers` folder exists, requires `TrackCenter`, `TrackIn`, `TrackOut` and `TrainStop` and warns when they sit off the rail axis or too close to the centre.
3. Warns about missing guidance attachments (`PlatformCenter`, `BellPoint`, `BoardPoint`) and a platform more than 75 studs from the anchor.
4. Returns `{Ok, Errors, Warnings}`; never mutates the model.

## Dependencies
- **Requires:** Nothing
- **Required by:** MissionServer (also referenced by the 01_Railway_Stations authoring guide)

## Connections
None.
