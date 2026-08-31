# Task Plan: Domination (execute DOMINATION_SPEC.md)

**Plan of record: `DOMINATION_SPEC.md`** — this file tracks execution status only.
Spec authored 2026-08-22, executed the same day by a cold session. All 20 decisions were honoured.
Previous TDM planning files archived to `depricated/superseded-md-2026-08-22/`.

## Places (all connected, edit mode)
- Bounty `place:131701626847012` · Redwater `place:98517073248449` · Frostbite `place:134041618959520`

## Status: BUILT 2026-08-22 — unverified (open item 121 carries the playtest checklist)
- [x] A. Universe tier x3: GamemodeConfig row (+scoreLimit 500), MapCatalog gamemodes, Wallet 3 reasons —
      identical across all three places (3308/644830434 · 5238/2646449618 · 6361/1408998788).
- [x] B. Per-place MapConfig (Redwater 81 lines, Frostbite 97): Gamemodes + Instances.CapturePoints.
- [x] C1. RoundSystem.Config DOMINATION_* block (324 lines).
- [x] C2. Gamemodes.Domination (706 lines, 26470 b, checksum 1493799817).
- [x] C3. RoundController ShouldEndRound hook, 0.25 s wait (2902 lines).
- [x] C4. BotBrain gamemodeRules() + _patrolObjective (1220 lines).
- [x] C5. RoundStatusClient chip gate (362).
- [x] C6. ProgressionService.awardObjective (548) + CombatFeedClient 3 styles (844).
- [x] C7. DominationGui.DominationClient (244) + ResetOnSpawn false.
- [x] C8. StarterPlayerScripts.CapturePointVisualClient (290).
- [x] C9. Device matrix: HUD (hd_1080 / galaxy_a06 / ipad_9) and Bounty picker — both fine.
- [x] C10. Mirrored to Frostbite: 13 scripts byte-identical by length + checksum; DominationGui imported
      (88 descendants, same properties). No edit_script_lines after the imports.
- [x] D. Bounty: DominationButton (clone), Dialog 0.5 → 0.58 tall, GameModeClient wired (366 lines).
- [x] C11. (owner follow-up, same day) Pads + beams only in Domination: new RoundSystem.CapturePointService
      (99 lines, 3864 b, checksum 1227665123) parks/restores them; RoundController calls it at the three
      dressing sites BEFORE Init (2914 lines); Domination.UsesCapturePoints = true (712 lines). Mirrored,
      checksums equal; edit-mode park/restore round-trip passed on both maps.
- [x] C12. (owner playtest 2026-08-22: bots stood around) Root cause: a team-mode bot is NEVER idle
      (700-stud detection, no LOS), so the _patrol hook never ran. BotBrain._objectiveTarget /
      _objectiveDecision + the _step branch (1304 lines, 53830 b, 608692953); BotConfig
      ObjectiveEngageRange 65 / ObjectiveCloseThreatRange 20 (437 lines, 19752 b, 2150319708).
      Mirrored, compile-verified, NOT re-playtested. Frostbite spawn-house navmesh islands found on
      the way -> open item 123. Follow-up (owner: capture and fight must not be a choice): on the pad
      hold + fight from it; on the way fight only close/visible threats; threat = NEAREST enemy,
      cone-free LOS (BotCombat.CanSee ignoreCone, 2304 lines), ObjectiveThreatLock 2 /
      ObjectiveFightStrafeInterval 2.
- [x] E. Vault: 3 new .md + 18 patched (Redwater), 4 patched (Bounty); both graphs rebuilt and the
      13 new edges verified; changelog UNRELEASED entry + mirror bullets; open items 121/122;
      spec header marked BUILT with as-built deviations; memory notes written.

## Deviations recorded in the spec header
- DomMeter_<L> is SIGNED (-1..1); DomRate_<L> + Player.DomPad added; beam Letter stamped at runtime;
  DominationGui copied to Frostbite now; ResetOnSpawn=false.

## Not done (by design / deferred — open item 122)
- Captures stat-card column; XP/min soak (open item 122). Pads + beams in other modes: DONE, see C11.
- `.changelog/pending/<session>.jsonl` left in place for /preflight's sweep; the entry was written by hand
  because the Bounty dialog re-spacing went through execute_luau (not captured).
