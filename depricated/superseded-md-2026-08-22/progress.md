# Progress Log — Team Deathmatch

## Session 2026-08-18 (execution session)
- Read spec, archived tutorial-relocation planning files to depricated/superseded-md-2026-08-18/.
- All three places connected in edit mode.
- Starting Phase 0 (anchor pads).

## Phase 0 + 1 (2026-08-18)
- Pads anchored ×4, positions == spec §3.2 (mass_get_property returns null for Vector3 —
  known serializer gap, verified via execute_luau instead).
- Gamemode axis landed. Key shapes: rules modules self-identify via `.Id` (folder scan, not
  name match); ctx = { row } passed to Init/PrepareRound; State.gamemodeRules shares the rules
  with SpawnService (and later BotService); killer resolution HOISTED out of the
  RoundStatsService guard in the death handler so rules.OnDeath learns the killer even when
  stats are degraded; roundLength read per-round from GamemodeConfig (Config.ROUND_TIME stays,
  secondsLeftFor still reads it).
- Added Config.FORCE_GAMEMODE (nil) — Studio/off-live twin of TUTORIAL_FORCE_MODE, needed to
  playtest TDM before the Bounty picker exists. Flag to user in report.
- Fold verify: all 7 scripts byte-identical Redwater/Frostbite, loadstring OK ×14.
- The `-- 360` Config drift the tutorial task logged is GONE (peer cleaned it); both Configs
  13233b identical before my edit.

## Phase 3 (2026-08-18)
- Strategy shift from spec 8.2's letter: gates live at TARGET SELECTION (so hit markers/
  sounds/charge skip together -- returning (false,0) from damage services would NOT stop the
  callers' unconditional runHitPipeline), with DamageGate backstops at damage helpers.
  DamageGate delegates to rules.CanDamage so damage policy stays a rules decision.
- SetCanAimAssistCheck turned out to be a ZERO-ARG on/off predicate, not per-candidate -- the
  spec's assumption was wrong. Ally filter went inside AimAssistController (isEnemy + tagged
  gather) which fixes all 5 consumer instances incl. Vesper's autoFireLockSource.
- IsEnemy/AreTargetsEnemies both had dead Player.Team checks; TeamAffinity slotted beside them.
- Frostbite mirror DEFERRED: Phases 3-7 develop in Redwater, one /mirror reconcile after.
  Phase 1-2 files already hand-mirrored + fold-verified.

## Phases 4-8 + mirror (2026-08-18, same session)
- Score chips + TeamBanner authored (builders in ChangeHistory; re-runnable). Screenshots OK
  (PC + galaxy_a06 for chips; picker verified after user restored the Bounty window).
- Phase 8 wire: PlayTeleportEvent now carries the mode id; mode filter splits the matchmaking
  pool (accepted, decision 1). TDM access-code records are TABLES like tutorial's.
- Mirror push Redwater->Frostbite: 33 items (30 swapped, 3 created: chips x2 + banner),
  .rbxm staged + fold-verified per item, TOTALs agree at a4e11668. Undoable via Ctrl+Z waypoints.
- REMAINING: Phase 9 (mode ballot -- timing budget is an OPEN spec question 18.4), Phase 10 docs
  (vault/graph/changelog held for playtest), CLAUDE.md + /mirror skill GamemodeConfig listing,
  spec corrections. FFA playtest owed before any publish (Phase 1 gate).

## Session 2 -- 2026-08-18 (continued, post-compaction)

**User playtest feedback:** team red/blue outline needs work around Bram, Dust and the bounty
highlight -- NOTED in task_plan.md Playtest findings, deliberately not acted on yet (user: "just
note it for later"). Need the specific symptom before touching anything.

**Phase 9 BUILT + mirrored.** Mode ballot as second sequential ballot on the existing MapVote
remote/panel. Touched exactly 4 scripts, all match-tier, all mirrored to Frostbite via .rbxm
staging with per-script fold verification:
- Config: SUMMARY_COUNTDOWN_TIME 6->10, POST_GAME_VICTORY_TIME 13->17.0,
  MAP_VOTE_RESULT_TIME 0.5->1 (now the mid-window hold on the map result), NEW MODE_VOTE_TIME 3,
  NEW MODE_VOTE_RESULT_TIME 0.5 (the tail). Constraint is now map+hold+mode == countdown.
- MatchDirectoryService: NEW switchGamemode (writes through the boot guard + requestPublish
  nudge); registerAccessCode(_, _, modeId) writes { code, mode } for non-default (Bounty's shape).
- RoundController: ballot machinery generalised to kinds, runBallotsDuringSummary fixed-offset
  schedule, switchGamemode helper (TeamService.ResetRound on team->FFA), loop tail runs the
  stay-case switch AFTER the move check (aborted move re-validates via pcall'd resolve),
  moveToMap carries nextModeId into the record + BOTH TeleportData payloads (group clone was a
  silent stale-mode carrier).
- MapVoteClient: kind-aware header strings, PANEL plate behind imageless mode tiles.

Verification: 4x loadstring OK; ballot truth table + mode-option builder probed in edit mode
(incl. unknown-destination fallback to default); Config sum invariants probed; match tier TOTAL
10703 8f67934e in BOTH places (was a4e11668 pre-phase-9).

Deliberate default where spec 18.4 left the number open: mode window 3s. Rationale: binary,
familiar choice; total lands on the 17.0s summary that shipped before 2026-08-16. Retune =
MODE_VOTE_TIME / MAP_VOTE_RESULT_TIME + SUMMARY_COUNTDOWN_TIME + POST_GAME_VICTORY_TIME in
Config (the comment there spells the constraint).

NOT done: ballot-screen screenshot (needs a live summary -- no MCP playtesting), vault/graph/
changelog (held for playtest sign-off), spec 3.4 corrections.

## Session 2 continued -- playtest notes round 2 (2026-08-18)

User published to dev places and played the full flow (Bounty -> Redwater -> mode-switch ->
Frostbite). Four notes, all executed:
1. Vote flow 6/1/6 (Config; summary now 20.0s). Spec 18.4 closed by the owner.
2. TeamAssignBanner in RoundStatusGui + RoundStatusClient attribute-driven show/fade.
   Screenshots PC + samsung_galaxy_a06 OK; staged state restored.
3. Capacity 14: caps 11/12/2, bot fill 14 (MaxBots 13), TDM 7v7 floor 2, slab 3x4,
   GamemodeConfig targetParticipants/blurb. CREATOR HUB visitor cap 10->14 owed by user, both
   match places, before ship.
4. Vesper perch tune (user: perch camping): hold 7, rotation 14, eviction ratio 0.15.
Verification: 5 scripts loadstring-OK in Redwater, staged folds matched per item, match tier
TOTAL 10706 bebfee34 in BOTH match places, GamemodeConfig 3c683452 in all three.

## Session 2 continued -- playtest notes round 3 (2026-08-18)
TDM-only trio (user corrected scope mid-turn: must not touch FFA): per-team bot hunter
coverage (BotService), team outline 0 -> 0.45 both copies, bounty highlight in team color
both writers. 4 scripts compiled + fold-verified into Frostbite. Match-tier TOTAL delta is
exactly Redwater's FORCE_GAMEMODE = "tdm" test flag (user's, left in place; revert to nil
before publish). Coverage logic probed: 6-bot fill = 4 distinct then repeats; FFA untouched.

## Session 2 continued -- playtest notes round 4 (2026-08-18)
Two fixes: HunterCaps per-team in TDM (Vesper 2/side, FFA untouched) + per-ballot header
countdown in MapVoteClient (payload.duration finally rendered; big counter spans both
ballots and no longer matches either window). 3 scripts mirrored; TOTAL 40fbb320 both match
places (user had reset FORCE_GAMEMODE to nil -- no delta any more). Incident: failed
edit_script_lines rolled back import recordings in Frostbite twice (Config, then
BotService+MapVoteClient temporarily missing); TOTAL gate caught both, re-imported, verified.

### 2026-08-18 — Frostbite invisible bullet-stopper (playtest note, marker `prope`)
- Cause: `FinishSpawns.BoxPlayerSpawns.CameraPartAnimation`, invisible + non-collidable but
  `CanQuery = true`, floating 5.5 studs over the Bridge deck. 52/72 sightlines from 80 studs
  terminated on it. Redwater carries the identical stray at (-20.4, 43.8, -232.8).
- Fix: `CanQuery = false` + `CanTouch = false` on the part in BOTH match places; `prope` deleted.
  Part is a camera CFrame source only, so the victory cinematic is unchanged.
- Verified: exposure probe now 0/72 in both places; showcase lookup path intact. Workspace is not
  mirrored, so the two edits are independent and no fold changes.
- Not done (owner chose narrow scope): 37 SpawnPoints pads, 4 ground podium pads,
  VictoryScreenRigSpawn and 35 health-pack TouchHitboxes remain invisible + query-able. See
  findings.md for the table.

### 2026-08-18 — Bounty card ring wears the team colour (owner request)
- Server `BountyService`: new `targetTeamColor(target)` (Player -> `Team` attribute, bot record ->
  `.Team`) and `ringColor` added to each snapshot entry. The COLOR ships, not the team name — three
  copies of the team pair already exist (BountyService / TeamService / BotVisualClient) and a fourth
  in the HUD could paint a ring that disagrees with the mark the shooter is chasing. 22206 -> 23048b.
- Client `BountyListClient`: registration seeds `BountyRingColor` (authored gold) on the IconDisplay
  UIStroke; `showSlot` assigns `entry.ringColor or authored` every snapshot, so a slot reused by a
  different holder can never keep the previous occupant's colour. 24565 -> 25720b.
- FFA untouched by construction: no Team attribute -> `ringColor` nil -> authored gold (255,170,0).
- Verified: helper truth table (player/bot x red/blue/FFA) run against the real function body with
  stubbed deps; client block run against a cloned authored slot (red -> blue -> FFA -> garbage all
  correct); screenshot preview of the three ring states, staged StarterGui Enabled state restored
  (17 guis, 0 mismatches).
- Mirrored via .rbxm staging + fold compare. Match tier TOTAL `284 10706 4119022 6b27a789` in BOTH
  places.
- PENDING owner sign-off: vault `.md` updates (BountyListClient's "Reading as a bounty" section
  still says the ring is gold; BountyService.md) + graph rebuild. No new edges — no new require or
  remote, the existing BountyListUpdated payload just carries one more field.

### 2026-08-18 — Phase 10 documentation pass (vault + graphs + changelog)
- Vault was a full phase behind: SIX TDM modules had no `.md` at all. Created GamemodeConfig,
  TeamAffinity, TeamService, DamageGate, Gamemodes/Deathmatch, Gamemodes/TeamDeathmatch.
- 22 existing files gained the real `require()` edge they were missing (16 -> TeamAffinity,
  6 -> DamageGate, 3 -> GamemodeConfig, RoundController -> TeamService + both rules modules) plus a
  short per-file note; 9 more got line-count refreshes. Bounty vault: GamemodeConfig.md added,
  3 consumers updated.
- Bounty-ring prose corrected in BountyListClient.md / BountyService.md (the ring was documented as
  always gold).
- Graphs rebuilt: Redwater 227 nodes / 679 edges (was 232 files -> 39 changed), Bounty 108/303.
  Every new edge verified against a real require in graph.json; no invented edges, no `Required by:`
  wikilinks in the new files.
- /changelog: curated the 287-line capture into UNRELEASED.md (Added/Changed/Fixed), flagged
  GamemodeConfig as mirrored module 19 and the Creator Hub visitor-count action, retired the capture
  to consumed/. Coverage checked with -Mine; every SUSPECT is described in player terms.
