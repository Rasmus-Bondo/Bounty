# Progress Log — Tutorial Relocation

## Session 2026-08-16 (execution session)
- Read spec, created planning files.
- Phase 0 built + verified in one execute_luau pass (ChangeHistory waypoints set).
- Phases 1-4 landed as anchored edit_script_lines edits; all compile via loadstring.
- Pathfinding: NoPath results with walls up are CORRECT (gates sealed); all Success with
  gates down. Gate parts' CanCollide restored after the test.
- Next: /mirror the 5 gamemode scripts to Frostbite (NOT MapConfig), then vault + graph +
  /changelog.

## Session 2026-08-16 (post-playtest tweaks)
Three user tweaks after seeing the bowl in a playtest: invisible walls, no spawned dummies for
steps 2-4, and a banner line during the walk between areas. All three landed; scripts compile
and are fold-identical in Frostbite.

- The two `Dummy` rigs already in the bowl sit 52 / 61 studs from the spawn Stand at 16-17 deg
  off its facing, so they are in view down the course. The Shoot gate is `FireBullet` x3 —
  never the dummies — so deleting the spawn path cost the step nothing.
- The travel prompt had to move `awaitAreaArrival` BELOW `fireStepRemote`: a Lua local declared
  later is not in scope inside a function defined earlier, so the push would have been a nil
  global call at runtime and would have compiled clean.
- Found while re-folding: `Config.TUTORIAL_FORCE_MODE` is `true` in Redwater, `false` in
  Frostbite. Not mine, not mirrored, left as is — it is how you press Play on the lesson in
  Studio. Must go back to `false` before a publish.
- Vault / graph / changelog deliberately NOT written yet — waiting on the playtest sign-off.

## Session 2026-08-16 (step 1 = the opening walk; CP1→CP2 waypoint)
- Step 1 no longer sits behind the walk; it IS the walk. `arriveAt` is a new step field, gated by
  the server's own `playerIsOnPad` poll rather than a client report, so the look-sweep/sprint
  gate and `startMoveGate` are gone. Sprint survives as copy, not as a gate.
- `middlepoint` arrived unanchored, opaque and solid — it would have fallen out of the world on
  a live server's first physics step, same trap as the 25 wall parts in Phase 0.
- The guide is a polyline now, not a segment. The waypoint drops out on a plane test, so nothing
  points backwards after the corner.
- Only the CP1→CP2 leg has a waypoint. CP2→CP3 measured clean without one (the bridge fix in
  Phase 10 was what that leg needed).
- Vault / graph / changelog still held for the playtest. Note for the docs pass: TutorialClient
  no longer requires `HunterMovement`, so that edge must leave the graph.

## Session 2026-08-16 (the ult step, four fixes)
- The early "expanding effect" was NOT UltimateReadyFX or the HUD bump — both already key off
  `charge >= maxCharge` exactly. It was the TUTORIAL's own cue, which fires with the step line
  while the director fills the charge a second later, on purpose.
- Scope call, flagged to the user: the skull-gated trigger is TUTORIAL-ONLY. Making it global
  changes live Dead Eye (a player mid-ult whose lock breaks as they fire would be stuck until
  the hold expires), and the ask arrived inside a list of tutorial items.
- The trigger gate had to go on the CLIENT even though the house rule is server-authoritative:
  `hasRequestedHighNoonShot` is one-shot per activation, so a server-side drop locks the player
  out of firing for the rest of the window. Nothing is at stake — the worst a bypass does is
  waste the player's own tutorial ultimate.
- `HunterMovement.SetOverride(.., 0, { LockJump = true })` is the documented "victory freeze"
  shape and outranks High Noon's own crawl base. Probe-tested in edit mode rather than assumed.
- Note for the docs pass: TutorialDirector now requires `HunterMovement` (new graph edge), and
  TutorialClient reads `Revolver.Remotes.HighNoonChargeUpdate` (runtime-created, so a lazy
  FindFirstChild — do NOT record it as a WaitForChild dependency).

## Session 2026-08-16 (Vesper joins the live-fire roster)
- `STEP11_HUNTERS` = Bram, Dust, Dust, Fortuna, **Vesper** (replaced the second Fortuna; still
  five bots, still the five furthest markers). Fold 4734b4b1 in both places.
- The old "No Vesper" rule was a CANYON fact, not a Vesper fact. Measured: the nearest
  `workspace.VesperHookSpotsBot` marker to the bowl is 1445 studs, and a 20-stud sweep of the
  whole bowl footprint never gets closer than **1339** — against `GrappleHook.Range = 125`. So
  `_bestVesperHookSpot` returns nil everywhere in the bowl and she fights on foot.
- Checked and NOT changed: `resolveGrappleAim` already range-checks before it spherecasts, so a
  33-marker scan that can never succeed costs three magnitude compares per marker, not 33 long
  sweeps. I nearly "optimised" a non-problem — read the callee before assuming the cost.
- Her ult cannot fire in the step: passive charge 0.4/s = 250s to full, the step is 30s.
- Training's `DamageMultiplier = 0.35` was already sized against Vesper's 125 headshot (43.75,
  three hits to kill) — the tier comment says "nothing in the roster", so she was always
  budgeted for.

## Session 2026-08-16 (touch auto-fire on the tutorial dummies)
- Cause: `AimAssistController` gathers enemy players plus `CollectionService:GetTagged(
  "AimAssistTarget")` and NOTHING else. The two authored rigs in the bowl
  (`workspace.Dummy.TargetDummy`) carried no tags, so the lock never formed and auto-fire —
  which reads `GetLock()` and never raycasts — had nothing to fire at.
- **This was a regression from removing the dummy-spawn path.** The three
  `ServerStorage.TutorialDummies.*.TargetDummy` templates are ALREADY tagged: the original
  design tagged the clone sources, and when the tutorial stopped cloning them in favour of the
  two rigs already standing in the bowl, the tag stayed behind on templates that no longer
  spawn. Worth remembering — deleting a spawn path can silently drop authored data with it.
- Fixed as DATA, not code: tagged the two bowl rigs. Tag the `TargetDummy` (the model holding
  the Humanoid + HumanoidRootPart), never the `Dummy` wrapper — `_evaluateCharacter` reads both
  as direct children. No mirror impact; workspace is never mirrored.
- Verified before tagging: LOS clear from both the spawn pad (61/52 studs) and checkpoint 1
  (25/18) using the assist's own exclusion set + BulletPenetration; MaxRange is 350 and the
  lock tolerance at 25 studs is ~8 deg. The invisible tutorial walls are NOT in the exclude
  list, so that check mattered.
- `ServerStorage.TutorialDummies` is now referenced by zero scripts. Left in place — dead but
  harmless, and deleting it is the user's call.

## Session 2026-08-16 (checkpoints 2 and 3 chime like checkpoint 1)
- Checkpoint 1 always chimed because its walk is an ordinary step (`arriveAt = 2`) that ends with
  `lastAdvance = "action"`. Checkpoints 2 and 3 are `awaitStopArrival` gates, which deliberately
  DEMOTE `lastAdvance` to `"travel"` — the client chimes only on `"action"`.
- Fix is the demotion's mirror image, not a new cue path: promote back to `"action"` on arrival,
  so the next step's push carries it and the client flashes exactly as it does at checkpoint 1.
  Nothing on the client changed.
- Gated on `walked and s.lastAdvance == "travel"`: the backstop teleport stays silent (it
  completed nothing, same as step 1's own timeout), and the `== "travel"` half means a stop the
  player was already standing on can't upgrade a previous step's `"timeout"` into a chime.
- 70651 bytes / fold `ba54472f` in BOTH places; compiles in both.
- The live playtest server holds the OLD module in its require cache — restart the playtest.

## Session 2026-08-16 (docs pass — vault, graph, changelog)
- Vault updated: `TutorialDirector`, `TutorialClient`, `HighNoonClient`, `HighNoonModule`,
  `RoundSystem/Config`. `ZoneService` / `RoundController` were already current.
- Graph rebuilt (5 changed / 226). Edges verified in `graph.json`: `tutorialdirector ->
  huntermovement` present, `tutorialclient -> huntermovement` GONE, `tutorialclient ->
  highnoonmodule` present (HighNoonVisual + the new HighNoonChargeUpdate).
- **The mirror was NOT clean when I checked it.** `TutorialClient` was 5 bytes stale in Frostbite —
  my last three edits landed after the import that was supposed to carry them. Pushed; both places
  are now 107673 / `1a08c2fb`. Lesson: fold AFTER the last edit, not after the import you think was
  last.
- Remaining match-tier drift is 7 bytes and belongs to a PEER session: `RoundSystem.Config` line 12
  has a trailing `-- 360` note on `ROUND_TIME` in Redwater only. Same value both sides. Left alone.
- `TUTORIAL_FORCE_MODE` is `false` in both places now — somebody else flipped it back, so the
  publish blocker this file has been carrying since the first tweak session is clear.
- Match-tier TOTAL: Redwater `386b75ff` / Frostbite `7ce5b49d` (the 7 bytes above).
- Capture retired to `.changelog/consumed/`. Coverage clean — the one SUSPECT is the Frostbite
  `ZZ_MirrorStaging` folder, which is scaffolding.
