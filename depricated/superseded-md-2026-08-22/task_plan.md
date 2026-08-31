# Task Plan: Team Deathmatch (execute TEAM_DEATHMATCH_SPEC.md)

**Plan of record: `TEAM_DEATHMATCH_SPEC.md`** — this file tracks execution status only.
Spec authored 2026-08-18, executing same day. All 13 product decisions are made; do not reopen.

## Goal
Gamemode becomes a real axis. TDM = 5v5, 6 min, most kills, team-base spawns, no zone,
no friendly fire, bots fill to 5/side (floor 1/team). FFA stays byte-identical through Phase 1.

## Places (all connected, edit mode)
- Bounty `place:131701626847012` · Redwater `place:98517073248449` · Frostbite `place:134041618959520`

## Phases (spec §5)
- [x] **0** DONE 2026-08-18: 4 pads anchored via mass_set_property, positions verified == spec §3.2, opaque+collidable kept.
- [x] **1** DONE 2026-08-18 (code): GamemodeConfig (2533b ×3 places), Gamemodes.Deathmatch
      (3331b ×2), State.gamemode+gamemodeRules, MatchDirectoryService setGamemode (record.mode
      → TeleportData.gamemode → default) + writeEntry mode field, Config.FORCE_GAMEMODE test
      flag, RoundController: resolveGamemodeRules (errors on missing row / MapConfig mismatch),
      waits State.gamemode, hooks Init/PrepareRound/UsesZone/roundLength/OnDeath/GetOutcome/
      DecorateVictoryPayload/EndRound; SpawnService: teleportPlayerToCFrame split + ResolveSpawn
      consults. All compile; fold-identical both match places (RoundController 7dae8d59).
      **OWES: FFA playtest before publish (spec gate).**
- [x] **2** DONE 2026-08-18: TeamAffinity (2610b, fail-open areAllies, isTeamMode via
      GamemodeConfig row), TeamService (5744b, attribute stamps + CharacterAdded restamp
      hooks, AssignAll parties-whole/solos-shuffled, AssignArrival preferred-team-wins,
      TeamScoreRed/Blue workspace attrs), TeamDeathmatch rules (10464b, all 9 hooks incl.
      marker-folder spawn w/ 2x4 slab-cell fallback + resolveSpawnForTeam for bots),
      RoundController modeCtx {row, groupIdOf}, MapConfig +tdm +TeamSpawns both places.
      Edit-mode probe: spawn cells + facing verified on BOTH maps; ally truth table OK.
- [x] **3** DONE 2026-08-18 (Redwater; Frostbite mirror PENDING /mirror pass): re-grep matched
      spec's 8 sites exactly. DamageGate module (rules.CanDamage chokepoint); Pierce gained
      5th arg `shooter` -> allies excluded, never a layer (probe: Ally skipped, Enemy hit, 0
      layers); shooter threaded through RevolverModule/SunspikeModule/GrudgekeeperModule/
      RevolverShooting/SunspikeClient/AimAssist LOS; ally filters in RevolverLagCompensation
      rewind candidates + RevolverHitForgiveness candidates+cover; gates in HighNoonDamage.Apply,
      AreTargetsEnemies (HighNoon acquisition), HunterCharacterUtil.IsEnemy (covers CardsServer,
      PinningRound, ShrapnelShell), StarfallSight ring loop, Grudgekeeper applyAbilityDamage +
      resolveShot + spherecast + collectConeTargets, BreachCharge _scanForPins (no ally pin/carry/
      clash), BotCombat consider()/_applyUltimateHit/_damageTarget/_pinningVictims, CardsServer
      buildRaycastParams ally-transparent card flight, GrudgekeeperClient tracer parity,
      HunterStatusEffects Apply* optional attacker refusal (all callers pass it), AimAssistController
      isEnemy + tagged-rig gather + LOS pierce. 21 scripts compile.
- [x] **4** DONE 2026-08-18 (Redwater): TeamScoreRed/Blue chips authored as RoundStatusGui
      children (fixed +/-56px from center, 64x33, team plates + white bold number, dark strokes),
      RoundStatusClient shows them only in team mode && roundActive, mirrors TeamScoreRed/Blue
      workspace attrs, mobile fade extended to chips. Sweep-safe by construction (sweep flips
      ScreenGui.Enabled by name; chips are child Frames). Screenshot-verified PC + galaxy_a06;
      staged state restored. TEAM_RED/TEAM_BLUE tokens added to UI_STYLE_GUIDE 2.4.
- [x] **5** DONE 2026-08-18 (Redwater): _desiredBotCount consults rules.DesiredBots (map ->
      per-team); Reconcile -> _reconcileBucket(desired, team) with team-filtered passes
      (retire/un-retire/create/respawn logic byte-preserved); _newRecord(team) + record.Team;
      _spawnController stamps rig Team pre-parent; _spawnPosition(record) -> resolveSpawnForTeam
      ("bot:<id>" slot key); _onBotDied fires rules.OnDeath after credit/assists/bounty;
      GetBotTeam accessor; HunterCaps stay per-arena (comment); BotBrain _targetCandidates
      drops allies (both pools); TeamService.AssignArrival nudges a deferred Reconcile (the
      join-time one runs before the joiner has a team). Firewall escape verified self-no-op
      (infinite clearance when no zone). Compiles OK x3.
- [x] **6** DONE 2026-08-18 (Redwater): TeamBanner authored in StarterGui.VictoryShowcase
      (Oswald Bold plate, top-center), VictoryShowcaseClient shows it with the podium reveal
      from payload.teamOutcome (team win + DRAW both handled), hidden in hideVictoryShowcaseGui
      + Clear. Screenshot-verified; authored state restored (Enabled recovered from Frostbite
      mirror). Server side landed in Phase 2 (GetOutcome/DecorateVictoryPayload).
- [x] **7** DONE 2026-08-18 (Redwater): TeamOutline Highlight (fill transparent, Occluded)
      -- players via TeamService (setPlayerTeam/CharacterAdded/ResetRound + ChildAdded/Removed
      watchers so BountyHighlight WINS and hands back), bots via BotVisualClient on the visual
      clone (attrs copied from rig; setBountyHighlight toggles TeamOutline). KillFeed remote
      gained killerTeam/victimTeam 5th/6th args from all THREE emitters (HunterHitPipeline,
      HighNoonDamage, BotController); KillFeedClient colors names. StatMenu leaderboard rows
      colored from live Player.Team attribute (self keeps amber ring; one kill-ranked list).
      Compiles OK x7. NOTE: GUI instances to replicate to Frostbite: RoundStatusGui chips x2,
      VictoryShowcase.TeamBanner (re-run builder snippets there).
- [x] **8** DONE 2026-08-18: TeamDeathmatchButton (cloned TutorialButton, dialog re-proportioned
      0.34x0.5 / ratio 1.05 / min 270 max 560, screenshot-verified); GameModeClient TDM entry
      driven off GamemodeConfig (READOUT upper displayName, BLURB table now paints ModeBlurb --
      tutorial blurb preserved as hand-written entry); ReworkedUIPlay selectedMode passes
      GamemodeConfig-valid ids + FireServer(mode); PartyService validates mode, stamps
      teleportData.gamemode, threads mode through both chooseDestination call sites (re-route
      reads batch.teleportData.gamemode); MatchmakingService LEGACY_MODE normalize-on-read,
      candidate filter entry.mode == modeId, provisional entry carries mode, reserveFreshServer
      rolls via rollLiveMapForMode (MapCatalog.gamemodes finally READ), TDM reservation writes
      { code, mode } table (deathmatch keeps bare string), resolveAccessCode accepts table shape;
      MapCatalog rows +tdm mirrored x3 (4160fb62). All compile. Friend joins: no filtering needed
      (mode resolves server-side; first arrival on a fresh server is always the reserving party).
- [x] **9** DONE 2026-08-18 (second session): mode ballot rides the summary as a SECOND
      sequential ballot on the same MapVote remote/panel. RoundController: tally/resolve/receiver
      generalised (ballotVotes/ballotOpen kind + per-ballot ballotValidIds set), runBallot(kind,
      options, incumbent, window), runMapVoteDuringSummary -> runBallotsDuringSummary on a FIXED
      offset schedule (skipped beat stays podium time, never pulls the next forward; os.clock
      offsets so overruns can't push past the curtain). Mode options = MapCatalog row of the map
      WINNER (sequential = can filter by destination) ∩ GamemodeConfig, ∩ MapConfig.Gamemodes when
      staying; incumbent falls back to DEFAULT_ID if current mode unsupported at destination (probed:
      unknown-map id -> default). Stay-case switch: RoundController.switchGamemode (pcall resolve,
      TeamService.ResetRound on team->FFA to strip stamps/outlines, re-Init modeCtx) +
      MatchDirectoryService.switchGamemode (validates, writes State.gamemode + workspace attr through
      the first-write-wins guard, requestPublish nudge so the lobby mode filter updates). Move case:
      moveToMap(nextMapId, nextModeId) -- registerAccessCode gains modeId ({ code, mode } table for
      non-default, Bounty's exact shape) and BOTH TeleportData payloads always stamp .gamemode
      (group clone would otherwise carry the OLD mode silently). MapVoteClient: kind-aware headers
      (VOTE FOR NEXT MODE / NEXT MODE:), PANEL-brown plate behind imageless mode tiles (ImageButton
      is authored transparent), Start tears down prior ballot's tiles (buildTiles->clearTiles).
      Timing (§18.4 was OPEN — default chosen, ONE-KNOB retunable in Config): map 6 (untouched) +
      map-result hold 1 (MAP_VOTE_RESULT_TIME, was the 0.5 tail) + mode 3 (MODE_VOTE_TIME) =
      countdown 10; MODE_VOTE_RESULT_TIME 0.5 tail -> POST_GAME_VICTORY_TIME 17.0 = the exact
      pre-2026-08-16 shipped length. Sum invariants probed true. resolveBallot truth table probed
      (no votes/tie/incumbent-lead keep; clear win switches). All 4 scripts loadstring-OK; mirrored
      to Frostbite via .rbxm staging (per-script folds match), match tier TOTAL 10703 8f67934e BOTH.
      **OWES: stopwatch pass on a real summary (spec says user picks the number) + ballot screenshot.**
- [~] **10** PARTIAL: match-tier /mirror DONE 2026-08-18 (33 items via .rbxm staging, fold-verified,
      both places TOTAL 10703 a4e11668); MapConfig/MapCatalog rows DONE. GamemodeConfig registered in all
      mirrored-module lists 2026-08-18 (CLAUDE.md 19, /mirror universe tier, CONVENTIONS.md,
      /changelog skill). REMAINING: spec corrections (§3.4:
      FROSTBITE_CLAIM_SPEC 9.0 strike + CLAUDE.md blurb, mark FROSTBITE 9.7 done); vault .md files +
      graphs + /changelog -- **held for playtest sign-off per feedback_preview_before_writeup**.

## Playtest findings (user, 2026-08-18)
- **Team outline vs Bram / Dust / bounty highlight — needs work, noted for later (user: "just
  note it").** With the red/blue TeamOutline on rigs, something about Bram's and Dust's visuals
  and the bounty highlight clashes. Known by design: bounty Highlight WINS the rig (TeamService +
  BotVisualClient watchers) — but the user saw something beyond/around that worth fixing. Get the
  specific symptom from the user before changing anything (which hunter FX, world vs viewmodel,
  bot or player rig). Candidate suspects: Roblox's 31-Highlight budget, hunter ability Highlights
  (High Noon targeting / Bram charge-clash FX) fighting the TeamOutline on the same rig.

## Post-playtest notes, round 2 (user tested full Bounty->Redwater->Frostbite flow on dev, 2026-08-18)
All four notes executed same day; match tier TOTAL 10706 bebfee34 BOTH places, GamemodeConfig
2534 3c683452 ALL THREE.
- [x] **Vote flow**: 6s map ballot -> winner shown (1s hold) -> 6s mode ballot (user's numbers;
      MODE_VOTE_TIME 3->6, SUMMARY_COUNTDOWN_TIME 13, POST_GAME_VICTORY_TIME 20.0). §18.4 is
      now CLOSED -- the owner picked the numbers off a real summary.
- [x] **Team-assign banner**: authored RoundStatusGui.TeamAssignBanner (300x40 plate at
      {0.5,0},{0.175,8}, chip recipe: team plate bgT 0.15, 38/38/38 stroke, white Bold HUD-font
      TextScaled label). RoundStatusClient shows it 4s + 0.5s fade on the Player Team attribute
      (nil->team bounce at every AssignAll = re-announces each round; lazy first-spawn stamp =
      mid-round joiners; nil hides). Sits in PhaseAnnounce's band -- safe, TDM has no zone and
      FFA has no teams. Screenshot-verified PC + samsung_galaxy_a06 (device id changed from
      galaxy_a06 -- preset list renamed), sim + Visible restored.
- [x] **Capacity 14**: Config caps 7/8/2 -> 11/12/2 (sum 14); BotConfig
      DesiredRoundParticipants 10->14, MaxBots 8->13 (solo fill = 13); TDM TEAM_SIZE 5->7,
      DesiredBots floor 1->2, slab fallback 2x4->3x4 cells (worst case one side = 9 humans +
      2 bots = 11 > 8 old cells); GamemodeConfig targetParticipants 14 + tdm blurb "Two teams
      of seven" (blurb shows in Bounty picker readout). **USER ACTION OWED: Creator Hub ->
      Maximum Visitor Count 10 -> 14 on BOTH match places (and their dev twins) BEFORE this
      ships, or friend slots 13-14 are fiction (Config 2b).** Spec's 5v5 (decision, 9.1) is
      superseded by the owner.
- [x] **Vesper perch camping** (user picked "perch camping" from the options): BotConfig knobs
      only, no behaviour code -- SniperPerchHoldDuration 11->7, SniperRotationDuration 9->14
      (perch:ground flips 11:9 -> 7:14), SniperEvictionDamageRatio 0.22->0.15 (one solid hit
      evicts). OWES: user re-playtest for feel.
- [ ] **Still open from round 1**: team outline vs Bram/Dust/bounty highlight (below) -- still
      needs the user's specific symptom.

## Post-playtest notes, round 3 (2026-08-18) -- ALL TDM-ONLY (user's explicit scoping)
- [x] **Bot hunter coverage per team**: BotService._chooseHunter(team) -- per-team counts;
      while any eligible hunter is absent from the team, roll only among absentees (still
      weighted, still honouring arena HunterCaps). team==nil (FFA) keeps the pure weighted
      roll -- guarded twice after the user's mid-turn "only TDM" correction. Probe: fill of 6
      = all 4 hunters first, repeats after; buckets isolated; FFA path "weighted".
- [x] **Team outline turned down**: OutlineTransparency 0 -> 0.45 in BOTH copies
      (TeamService player rigs + BotVisualClient clones).
- [x] **Bounty in team color**: TDM bounty highlight wears the carrier's team color
      (lifted pair 255,70,60 / 85,140,255) for fill+outline instead of gold/orange; the
      fuller AlwaysOnTop style still says "bounty". FFA keeps gold. Both writers:
      BountyService.applyHighlight (Team attr, character-then-Player fallback for the
      respawn restamp race) + BotVisualClient.setBountyHighlight (clone's copied Team attr).
- Mirror: 4 scripts .rbxm-staged, per-script folds identical. Match-tier TOTAL differs by
  EXACTLY the user's live test flag: Redwater Config has FORCE_GAMEMODE = "tdm" (their
  Studio playtest toggle, left untouched, NOT copied to Frostbite which stays nil).
  Redwater a71f6899 / Frostbite afef9e79; delta = 2 bytes = that one line.
  **MUST return to nil before publishing (it warns and is ignored on live, but DEV
  inherits it -- Config comment 7 documents why that is a trap).**

## Post-playtest notes, round 4 (2026-08-18)
- [x] **HunterCaps per team in TDM** (user: "the 2 Vesper bot limit in normal deathmatch
      should not be there for tdm"): BotService.atCap judges a team mode by the TEAM's own
      count, FFA still by the arena count. Vesper cap 2 now means 2 PER SIDE; one side
      rolling both no longer locks the other side out of the hunter (which also broke the
      coverage promise). Probe: FFA capped at 2 arena-wide; TDM blue free at 0 own / 2 on
      red; TDM red capped at 2 own.
- [x] **Per-ballot vote timer** (user: "something was off with the timer for the match
      vote"): the 13s NEXT MATCH IN counter spans both ballots, so the map ballot froze
      with ~7s still showing. MapVoteClient now renders each ballot's own seconds in the
      panel header ("VOTE FOR NEXT MAP  •  6") from the Start payload's server-sent
      duration (ignored since 2026-08-16 -- the one-window identity it relied on is gone).
      Result/Clear cancel via token. Stale comments rewritten (client header + Config).
- Mirror: match tier TOTAL 40fbb320 BOTH places -- fully byte-identical again; the user
  flipped FORCE_GAMEMODE back to nil themselves, so the accepted round-3 delta is gone.
- **Incident, recovered**: a FAILED edit_script_lines (old_string not found -- the flag
  was already nil) rolled back the MCP plugin's ChangeHistory recording, silently undoing
  the just-swapped imports TWICE; Frostbite briefly lost Config, then BotService +
  MapVoteClient. Caught by the TOTAL gate both times; re-imported from the .rbxm and
  verified. Lesson saved to memory: never chain edit_script_lines straight after an
  import/swap -- verify the target string first or write Source via execute_luau.

## Standing rules for this task
- Every match-tier edit lands in BOTH Redwater and Frostbite, byte-identical (fold-verify).
- Verify each script compiles via loadstring after edit (feedback_verify_code).
- No MCP playtesting (feedback_no_mcp_playtest) — edit-mode probes + manual checklists.
- UI work: read UI_STYLE_GUIDE.md first; screenshot-verify; check round sweep exemption.
- Bots: for every gate added, ask "is there a bot version?" (three sites in BotCombat).

## Errors Encountered
| Error | Attempt | Resolution |
|-------|---------|------------|
