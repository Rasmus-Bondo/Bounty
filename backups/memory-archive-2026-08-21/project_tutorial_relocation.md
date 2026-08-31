---
name: project_tutorial_relocation
description: "Tutorial relocated to the walled bowl 2026-08-16 — EXECUTED and mirror-synced; manual playtest (spec §8 checklist) still owed before publish"
metadata: 
  node_type: memory
  type: project
  originSessionId: 40641a8d-7060-4dfc-b27f-6462dbad8b88
  modified: 2026-08-16T18:18:03.096Z
---

The Redwater onboarding lesson now runs in the walled tutorial bowl at X −1446…−1809, Z +58…−289
(~1500 studs west of `WallMap`), three wall-gated areas carrying steps 1-4 / 5-7 / 8-10.
`TUTORIAL_RELOCATION_SPEC.md` in the project root was **executed in full on 2026-08-16**: geometry
under `workspace.Tutorial` (Areas/Walls/BotSpawns, 25 parts anchored, 4 `Stand` parts, 3
`TutorialDummySpawn` markers, canyon marker Parts deleted), all five gamemode scripts rewritten to
resolve geometry through `MapConfig.Instances.Tutorial` (Redwater only — Frostbite omits the
entry), the tutorial zone deleted outright, ceiling 330, `TutorialRun` gains `|W<travelTeleports>`,
funnel indices unchanged. Mirror to Frostbite fold-verified same day; vault + graph + changelog
(`UNRELEASED.md`) updated.

**A tuning pass followed the first playtest, same day**, and it changed the shape of the lesson:
the bowl has **four STOPS, not three areas** (stop 2 is a walk inside the opening area), step 1 IS
the opening walk (`arriveAt`) rather than a look/sprint gate, every walk draws a chevron guide beam
bending around an authored `middlepoint`, arriving at a checkpoint plays the completion chime, the
ult step freezes movement and pins the camera, its firing line respawns, Vesper is back in
live-fire, and the range uses the map's own `Dummy` rigs (nothing clones `ServerStorage.
TutorialDummies` any more — tag authored rigs `AimAssistTarget` or touch auto-fire ignores them).

**Still owed: the spec §8 manual playtest checklist** (spawn facing, gate/sign timing, ult plant
with all six bots in the cone, travel backstop, per-stop respawn, sub-330s run, no fire damage).
Everything else was verified by read-back only.

**How to apply:** trust the bowl as the lesson's home; never hardcode a tutorial coordinate in the
mirrored gamemode code — author a marker in the folder and resolve it by name. Seven scripts are
match-tier mirrored now (`TutorialDirector`, `TutorialClient`, RoundSystem `Config`, `ZoneService`,
`RoundController`, plus `HighNoonModule` and `HighNoonClient`, whose tutorial-only branches are
gated on the `workspace.TutorialMode` attribute precisely so they stay byte-identical), so both
places publish together. Relates to
[[project_onboarding_tutorial]], [[project_streaming_constraints]], [[project_spawn_zone_safety]].
