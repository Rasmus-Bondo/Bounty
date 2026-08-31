# Task Plan: Tutorial Relocation (execute TUTORIAL_RELOCATION_SPEC.md)

**Plan of record: `TUTORIAL_RELOCATION_SPEC.md`** — this file tracks execution status only.
Authored 2026-08-16, executing same day.

## Goal
Move the Redwater onboarding lesson from the canyon floor into the walled tutorial bowl
(X −1446…−1809), per the spec. All phases + verification + mirror + vault/graph/changelog.

## Phases
- [x] Phase A — Inspect live Studio state (26 root instances, the 6 scripts, TutorialDummies)
- [x] Phase 0 — Geometry DONE + verified: folder built, 26 reparented, 25 anchored (audit 0
      unanchored), 17 markers hidden, 2 canyon markers deleted, 4 Stands + 3 TutorialDummySpawn
      markers created. CP2 look == spec (−0.748, 0.218, −0.627); worst ult off-axis 30.1°;
      live-fire picks 140/112/110/86/80.
- [x] Phase 1 — DONE: MapConfig.Instances.Tutorial added (+TutorialCenterOffset removed);
      Config zone consts + spawn names removed, ceiling 330; TutorialDirector fully
      marker-driven (STEP6/7/11 tables → hunters-only; dummies via TutorialDummySpawn
      markers with raycast seat + bbox foot-drop)
- [x] Phase §4 — DONE: Ult step teleports to CP2.Stand at boundary via SpawnService,
      payload `face` full-3D vector, client faceFromPayload (pitch kept), __sync resends face
- [x] Phase §5 — DONE: runtime picks 5 furthest FreeRoam markers (140/112/110/86/80)
- [x] Phase 3 — DONE: gates open in exitStep(Fan/Bounty) wall+sign destroyed together;
      awaitAreaArrival 20s on top of STEP_BEAT, death restarts clock, backstop teleport;
      travelTeleports in TutorialRun field03 as |W
- [x] Phase 2/4 — DONE: startTutorialZone call + whole tutorialZone machinery deleted
      (ZoneService 4 sites), RoundController comment corrected, per-area respawn via
      State.tutorialRespawnStand, TutorialClient folder/stand lookup (streaming-safe
      FindFirstChild, no cached list)
- [x] Verify (partial): all 4 scripts + Config + MapConfig compile via loadstring; zero
      leftover refs; 4 Stands resolve as BaseParts; paths: passive/bounty→CP2 Success with
      walls up; freeroam×5→CP3 + walk legs Success with gates down (restored after)
- [x] Mirror — DONE: 5 scripts exported .rbxm from Redwater, staged + fold-verified in
      Frostbite, swapped; match-tier TOTAL fold ae9bec09 identical both places; MapConfig
      untouched
- [x] Verification — spec §8 items 1-5 all pass (see Phase notes above)
- [x] Docs — 7 vault .md updated, graph rebuilt (226 nodes / 734 extracted edges, new
      tutorialdirector→spawnservice/mapconfig + tutorialclient→mapconfig edges verified),
      changelog entry in UNRELEASED.md, capture retired, memory updated

## TASK COMPLETE 2026-08-16
Only remaining item: the spec §8 MANUAL PLAYTEST checklist (not runnable via MCP).

## Phase 5 — post-playtest tweaks (2026-08-16, second pass)
- [x] Tutorial walls fully invisible: 23 BaseParts under `workspace.Tutorial.Walls` set
      Transparency 1 (were 0.65 yellow / 0.70 red); the 2 sign parts were already 1 and keep
      their SurfaceGui text. CastShadow cleared on the two signs. Audit: 0 visible parts left.
- [x] Step 2/3/4 dummies are no longer spawned: the whole `Shoot` branch of `enterStep`
      (ServerStorage.TutorialDummies clone + reseat), `destroyDummies`, `s.dummyClones` and the
      now-unused `ServerStorage` service handle removed. The two authored `Dummy` rigs in the
      bowl (52 and 61 studs out, 16-17 deg off the spawn facing) are the targets; the gate was
      always "3 shots FIRED", so nothing gated on them existing.
- [x] 3 dead `TutorialDummySpawn` markers deleted from `workspace.Tutorial.BotSpawns`.
- [x] Travel prompt: `awaitAreaArrival` pushes an `id = "Travel"` payload as an ordinary
      transition (so the finished line gets its cue + fade + beat) then demotes `lastAdvance`
      to `"travel"`, which the client reads as fade-and-beat with NO completion chime. The
      section moved below `fireStepRemote` — scope, not style. Client COPY gains `Travel`.
- [x] Both scripts compile; mirrored to Frostbite via .rbxm (staged, fold-verified, swapped):
      TutorialDirector 3057d17d / TutorialClient 8608d701 identical both places.
- [ ] Vault / graph / changelog — HELD until the user has seen it in a playtest.

## Phase 6 — route guide beam (2026-08-16, third pass)
- [x] Steps are gated on STOPS, not areas: `STOP_PADS` is now 4 entries (spawn, CP1, CP2, CP3)
      and `step.stop` is an index into it. `Move` gained `stop = 2` — the lesson's first
      instruction now waits until the player has walked to checkpoint 1. `area` → `stop`
      renamed throughout (AREA_PADS, awaitAreaArrival, getAreaAnchorPosition, s.area);
      anchors re-indexed 2→3 (ult) and 3→4 (live fire).
- [x] `FIRST_TRAVEL_WINDOW = 30` for the opening walk (20 elsewhere); Config ceiling comment
      re-derived 272 → 304 against 330.
- [x] Travel payload carries `stop` and `pad` (the pad NAME — the map owns positions).
- [x] Client route guide: pathfinding-driven Beam ribbon from the player's feet to the target
      pad, rebuilt every 8 studs of travel, cleared by any non-Travel payload. Origin
      attachment rides the HumanoidRootPart (measured foot drop), waypoints on Terrain.
      Straight-line fallback when the route fails.
- [x] First-walk copy variant (`pcFirst`/`touchFirst`) — it names the movement control, since
      nothing has taught it yet.
- [x] Verified: all three scripts compile; leg 1 ribbon BUILT in edit mode and screenshotted
      (11 segments, hugs the ground, runs between the two dummies to the yellow pad); preview
      instances removed afterwards. Mirror re-synced: TutorialDirector 633309ee /
      TutorialClient 9704c182 identical in both places; Frostbite's Config comment hand-edited
      so its `TUTORIAL_FORCE_MODE = false` survived.

## Phase 7 — the guide is chevrons, not a ribbon (2026-08-16)
- [x] `rbxassetid://16848361091` resolved with GetProductInfo BEFORE use: AssetTypeId 1
      (Image), name "Arrow", creator Wenbebis. It is a white chevron pointing DOWN with a soft
      upward gradient.
- [x] Orientation established by RENDERING it on a beam, not by reasoning: a Beam maps the
      texture's Y axis along the beam, so a down-pointing chevron comes out pointing from
      Attachment0 to Attachment1 — i.e. player -> goal, given the origin attachment is the
      player end. Backwards would point every arrow home.
- [x] Guide retuned: texture swapped, colour flat gold (255,209,0) to match the checkpoint
      pads, Width 3.5, TextureLength 4.5 (spacing > width so they read as separate arrows),
      TextureSpeed 1.5, lift 1.5 -> 2.5 studs, Transparency 0.
- [x] `foldCollinear` added: pathfinding hands back a waypoint every ~4 studs and Wrap mode
      restarts the texture per segment, so 4-stud beams chopped each chevron in half. Corners
      only, 10 deg threshold, tested in 3D. Leg 1: 11 waypoints -> 2 beams. Leg 2: 32 -> 14.
- [x] Screenshotted from the spawn pad at both 4.5 and 3.5 width; 3.5 chosen. Preview
      instances and the asset probe removed, gate collision restored (audit: 0 left open).
- [x] Mirrored: TutorialClient 101753 bytes / fold 50960378 in both places.

## Phase 8 — flat arrows, straight line (2026-08-16)
Pathfinding is GONE from the guide (user: the bends read as noise, and they walk the climb
fine). The row is now a straight XZ line from the player to the pad, each chevron seated on
the ground beneath it by a downward raycast, so it rides the terrain without bending in plan.

- **Flat is the attachment's Up, not FaceCamera.** Measured by rendering three orientations and
  looking from overhead: a Beam spreads its width along `Attachment.UpVector`, so up = world Y
  stands the ribbon upright and up = the HORIZONTAL PERPENDICULAR lays it on the ground.
  `CFrame.fromMatrix(pos, direction, direction:Cross(Vector3.yAxis).Unit)`.
- **One chevron per beam, `TextureMode.Stretch`** — exactly one arrow fitted to each 5-stud
  beam, so nothing is chopped or smeared regardless of the seated length. Width 5, spacing 9,
  lift 0.4, 7-stud gap at the player and 6 at the pad, cap 60.
- Spacing is measured back FROM THE PAD so the arrows hold their place in the world while the
  player walks past them; measured from the player they slid like a treadmill on every rebuild.
- Re-seat every 4 studs of travel (no ComputeAsync left to pay for). Ground rays exclude the
  character and the Tutorial folder; a sample with no ground under it is skipped.
- Removed with the pathfinder: `computePath`, `foldCollinear`, the reversed-route trick,
  `ensureOrigin` and the character-borne origin attachment.
- Verified by rendering both legs: leg 1 seats 4 of 4 chevrons, leg 2 seats 8 of 10 (worst
  seated pitch 24.6 deg on the climb). Preview torn down, gate collision restored.
- Mirrored: TutorialClient 99848 bytes / fold 7be0f882 in both places.

**Known trade-off:** on the CP1 -> CP2 leg the straight line points into the boardwalk
structure, so the arrows go through it rather than around. That is the cost of straight over
routed, chosen deliberately.

## Phase 9 — the row updates every frame (2026-08-16)
The poll (0.3s / 4-stud threshold) rebuilt the whole row from scratch, so it both lagged and
blinked. Now `RunService.Heartbeat`, with the instances POOLED — created once, re-aimed after,
never destroyed between frames. Parked arrows get `beam.Enabled = false`, not `:Destroy()`.

- Ground rays fire only when a chevron's seat has drifted more than 0.35 studs, which is what
  makes per-frame affordable: the row is pad-anchored, so walking straight at the target moves
  none of them.
- Measured on a simulated walk: straight leg = 8 rays across 140 frames (1% of frames re-seat),
  0.087 ms/frame; strafing (worst case, the line rotates about the pad) = 2.2 rays/frame,
  0.012 ms/frame.
- Near arrow now FADES out over 6 studs instead of vanishing at the gap; start gap 7 -> 5.
  Transparency is only rewritten when it moves 0.02, since a NumberSequence is an allocation.
- Index stability was the reason to anchor at the pad end: index 1 is always the arrow nearest
  the pad, so an arrow leaving the near end just drops the highest index and nothing else
  re-seats.
- `GUIDE_MAX` 60 -> 24 (longest leg needs 13). Removed: `guideToken`, `guideInstances`,
  `paintChevron`, `buildRoute`, `GUIDE_REPATH`, `GUIDE_POLL`.
- Mirrored: TutorialClient 101567 bytes / fold eed53dea in both places.

## Phase 10 — under the bridge, and a 12-second High Noon (2026-08-16)

**Bridge.** The seat ray started 25 studs above each sample, so on the checkpoint 2 -> 3 walk it
landed on the bridge DECK (measured: Part at y 49.4 over walking terrain at 31.8). It now starts
`GUIDE_PROBE_UP = 8` above the height the player will be at when they reach that point --
interpolated from where they are now to the pad -- which ducks under anything overhead while
still clearing bumps. A miss (a climb steeper than the line predicts) retries from +70. Verified
by re-seating all three legs: the bridge leg is now Terrain at every sample, tracking 22 -> 38.

**High Noon.** `HighNoonServerConfig.Timing.MaxHoldTime` is 5s, which is a fight's worth of Dead
Eye and about a third of what a first-timer needs. `HighNoonModule` now takes
`TUTORIAL_MAX_HOLD_TIME = 12` when `workspace:GetAttribute("TutorialMode") == true` -- an
attribute rather than a `RoundSystem.State` require, so the module gains no dependency and stays
byte-identical across the mirror (Frostbite never sets the flag).
- `TIMING_VISUAL_DATA` became `timingVisualData(holdTime)`, built per activation: the client
  times its own visuals off `shootTime`, so a stale 5 would have pulled the skulls off screen
  while the server still accepted the shot.
- Ult step timeout 20 -> 30 so a slow starter is not timed out mid-ultimate; ceiling comment
  re-derived 304 -> 314 against 330 (16s headroom).
- Mirrored: TutorialClient 61fe7085, TutorialDirector 79174574, HighNoonModule 3a3b8ac4 --
  identical in both places. Config comment hand-applied in Frostbite again to preserve its
  `TUTORIAL_FORCE_MODE = false`.

## Phase 11 — step 1 IS the opening walk, and a waypoint on the CP1 -> CP2 climb (2026-08-16)

**Step 1.** `Move` was a client-observed gate (60 deg look sweep AND sprint activating) that ran
AFTER a Travel gate walked the player to checkpoint 1. It is now one thing: `arriveAt = 2` on the
step, gated by the server polling `playerIsOnPad`, timeout 15 -> 30 (the window the Travel gate
used to carry). Its payload ships `pad`/`via` like a Travel push, so the beam draws from the spawn
platform, and the client's rule is now "a payload with a pad has a route" rather than "id ==
Travel".
- Removed: `startMoveGate` (~55 lines), `Move` from `CLIENT_GATED`, `FIRST_TRAVEL_WINDOW`,
  `Travel.pcFirst`/`touchFirst` + the `copyFor` branch that chose them, and the now-unused
  `HunterMovement` require in TutorialClient (**vault edge to drop when docs are written**).
- The Move line keeps the sprint teach as a parenthetical -- taught, not demanded.
- Backstop: a timeout still teleports onto the pad and advances `State.tutorialRespawnStand`,
  counting BOTH `travelTeleports` and a step timeout.

**Waypoint.** `workspace.Tutorial.Areas.middlepoint` (authored by the user; anchored + hidden +
CanCollide/CanQuery off by me -- it arrived unanchored and solid). Server `STOP_VIA = { [3] =
"middlepoint" }`; client `updateGuide` now walks a polyline (`routeSegments` + `routePoint`) and
drops the waypoint once the player is level with it or past (plane test + 10-stud radius).
- Measured why: the direct CP1 -> CP2 line crosses the boardwalk `Part` and jumps 13.0 -> 30.9
  between t=0.4 and t=0.5. Via the marker, all 13 chevrons seat on Terrain and climb 8.1 -> 37.8
  smoothly. Screenshotted from the CP1 pad.
- Ceiling comment re-derived: 222 + 7 + 20 + 3 + 4 + 44 = 300 against 330 (30s headroom; the 3s
  `holdAfter` term was missing from the old sum).
- Mirrored: TutorialDirector 64491 / 4b25bda3, TutorialClient 103325 / c5d02cc9 identical in both
  places; Config hand-applied in Frostbite (10666 vs 10665 -- the `TUTORIAL_FORCE_MODE` byte).

## Phase 12 — the ult step: cue timing, a self-rebuilding line, a gated trigger, a pinned player (2026-08-16)

**1. Cue lands with the charge.** The tutorial's own tile cue (`attachGlow` + `attachBreathe`)
fired with the step line; the director fills the charge a second LATER, deliberately last. Now
`glowForStep` waits on a `HighNoonChargeUpdate` push at >= max before lighting the ult tile, and
calls `restartAbilityIconPulse` so the tile and banner icon stay in phase. `lightTile` is guarded
`tileLit` -- attachGlow refuses a re-light but attachBreathe is additive, and two breathes on one
BumpScale ping-pong through each other's Cancelled handler. Remote resolved LAZILY: it is created
at server boot from Dust's manifest, not authored.

**2. The firing line rebuilds itself.** `spawnUltLineBot(s, index)` replaces the inline loop; a
death during the step respawns the same hunter at the same marker after 1.5s, capped at 12. The
ULT's own kills are not replaced and need no test for it -- the gate fires on the shot REQUEST, so
`stepDone` is already true when the executes land.

**3. Trigger gated on a skull.** `requestHighNoonShot` drops the request when nothing is locked,
on a tutorial server only (`workspace.TutorialMode`). `hasLockedTarget` is maintained from the
server's own TargetUpdate pushes. **Deliberately client-side**: the request is one-shot per
activation (`hasRequestedHighNoonShot`), so a server-side reject would lock the player out of
firing for the rest of the window -- strictly worse than the problem.

**4. Player pinned at checkpoint 2.** Server: `HunterMovement.SetOverride(character,
"TutorialUltStep", 0, { LockJump = true })` applied on the step boundary with the teleport,
re-applied on CharacterAdded, cleared in `exitStep("Ult")` AND in `finishSession` (a run that ends
mid-step never reaches exitStep). Verified in edit mode on a probe rig: 16/50 -> 0/0 with Jumping
disabled, High Noon's own base of 6 cannot lift it, release restores 16/50.
Client: new payload field `pin` -> `startCameraHold`, a `BindToRenderStep` at
`Camera.Value + 1` that rewrites the camera's ORIENTATION only (position stays the PlayerModule's).
No Dust script writes `camera.CFrame`, so nothing fights it.
- The `__sync` resend now carries `pin`, `pad` and `via` too -- pad/via was a gap from Phase 11.
- Mirrored: TutorialDirector 69210 / 0375d5dd, TutorialClient 107678 / e9424b41, HighNoonClient
  14132 / f914abd8 -- identical in both places. Config and HighNoonModule untouched this round.

## The CP1 -> CP2 climb was a ROUTER problem, not a map problem (now moot)
Pathfinding returns `NoPath` uphill from checkpoint 1 to checkpoint 2 at every agent setting
(radius 2-3, jump on, slope to 89 deg) — the navmesh scores the boardwalk face at about
(-1601.5, -83) as a 16.4-stud cliff. **The player walks it fine** (user, 2026-08-16), so no
geometry changed.

Fix is in the guide: `buildRoute` computes forward, and on `NoPath` computes pad -> player and
reads the waypoints backwards. Verified in edit mode — the reversed route gives 33 waypoints
from CP1 up over the boardwalk to the CP2 pad, and the ribbon was built and screenshotted
along it. Straight-line fallback now only fires when BOTH directions fail.

## Open flag (not mine to change)
`RoundSystem.Config.TUTORIAL_FORCE_MODE` is `true` in Redwater and `false` in Frostbite — a
local Studio-testing flip that appeared after this morning's mirror. It is the ONLY match-tier
drift left (Redwater TOTAL 22358a33 vs Frostbite 0532aa0b, one byte). Flip it back to `false`
before publishing or the mirror ships drifted.

## Errors Encountered
| Error | Attempt | Resolution |
|-------|---------|------------|

## Decisions made during execution
- "Retire the old canyon markers" = delete `workspace.TutorialSpawn` (Part) and
  `workspace.TutorialBountySpawn` (Part). Keeping a root Part named TutorialSpawn preserves
  the §1a ambiguity trap; post-Phase-1 nothing references them.
