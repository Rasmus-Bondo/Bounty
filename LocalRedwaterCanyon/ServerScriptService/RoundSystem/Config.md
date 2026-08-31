---
tags:
  - server
  - modulescript
path: game.ServerScriptService.RoundSystem.Config
type: ModuleScript
lines: 352
---

# Config

Shared configuration constants for the round system and progression.

## What it does

1. Defines round timing constants (countdown, round duration, respawn delay)
2. Defines player settings (max health, min players)
2a. Defines the join-gating numbers read by MatchDirectoryService and published to the Bounty lobby on every heartbeat, so this file stays their single source of truth. **Three** ceilings as of 2026-08-03, not two, and they are deliberately different:
   - `MATCH_PLAYER_CAP` (7) — the matchmade **party** ceiling. A party of 2-4 that does not fit under it is turned away and seeds a fresh server. A denied party still has a fine game, and parties are what *creates* the half-full matches solos need
   - `SOLO_PLAYER_CAP` (8) — the matchmade **solo** ceiling. Seat 8 belongs to lone players and no party may consume it. A denied solo gets 1 human and 4 bots, the worst game this produces and one that scores ~0 RP against a bot-padded field. 8 rather than 9 because 8 + a friend *pair* is still 10; at 9 only a lone friend fits
   - `FRIEND_SLOTS` (2, was 3) — seats 9-10, friend joins only
   - `JOIN_LOCK_SECONDS` (**0 — disabled** as of 2026-08-12; was 90, before that 180) — the tail of a fight during which a server refuses matchmade players. Turned off because servers loop rounds: a late arrival plays the tail and then a whole fresh round, the same deal as one matchmade into `Summary`. Both gates read this number and treat `<= 0` as "no lock at all" rather than `secondsLeft > 0`, so a fight on its last second still reads open. At 90 it closed ~23% of a server's cycle, and the lobby's age re-check stretched that to ~30%
2b. **`SOLO_PLAYER_CAP + FRIEND_SLOTS` must equal the place's Maximum Visitor Count** (Creator Hub → Redwater Canyon → Access), which is 10. Exceed it and FriendJoinService (Bounty) admits a player Roblox then rejects with `GameFull`, making the friend slots fiction — that was the state when the cap was 12 and the ceiling was believed to be 60. Note this is **not** `MATCH_PLAYER_CAP + FRIEND_SLOTS`; the friend slots sit on top of the *solo* ceiling. The old 7+3 arithmetic reached the same 10 by two cancelling errors. Roblox's own **Social Slots** setting is now a no-op — Redwater runs on reserved servers so its matchmaker never places anyone there and has nothing to reserve; leave it alone. Bots are Models in `workspace.ArenaBots` and never occupied any of these slots, and the fill is floored at 4, so 8 humans still gets 4 bots
2c. **Defines the match summary in three parts, and `POST_GAME_VICTORY_TIME` as their sum** (2026-08-06, the infinite match loop). `SUMMARY_CINEMATIC_TIME` (4.1) is the halved Dust cinematic, `SUMMARY_REVEAL_TIME` (2.4) the 3rd → 2nd → 1st podium reveal, `SUMMARY_COUNTDOWN_TIME` (**7** as of 2026-08-27, was 13, before that 10) the on-screen `NEXT MATCH IN: n` counter. Only the countdown crosses the wire — RoundController puts it on the `VictoryShowcase` payload as `countdownSeconds` so VictoryShowcaseClient never holds its own copy. `POST_GAME_VICTORY_TIME` is written as `4.1 + 2.4 + 7 + 0.5` = **14.0** rather than a bare number so the relationship is visible where it is defined: the **server must outlast the client's whole sequence, never the reverse**. The trailing 0.5 is `MODE_VOTE_RESULT_TIME` (see 2c-ii). Retuning step 1 means retuning this sum with it. It was 30 when the server closed after a single round and the timer only had to be "long enough", and 20.0 while the summary carried two ballots
2c-i. **`SUMMARY_CINEMATIC_TIME` did not move when step 1 was fixed on 2026-08-06, and that is deliberate.** VictoryShowcaseClient now resolves the cinematic clip's `Length` *before* it starts playing rather than during, which sits the load cost in FRONT of step 1 instead of eating the animation. Left alone that cost would push the client's whole summary past `POST_GAME_VICTORY_TIME` and have the podium yanked away mid-countdown, so it is paid for **on the client**, out of the full-blackout hold between the cut and the podium, and the wait is bounded (`CINEMATIC_LENGTH_WAIT` 0.55) below what that hold can absorb. Step 1 measures 4.08s warm and 4.08s cold; the margin here is still +0.57s. Retuning either number is a client-side change that must not need a server-side one
2c-ii. **Defines the end-of-match ballot's beat**, which **RIDES the match summary** (2026-08-16) — so both numbers are terms *of* the sum in 2c rather than time added on top of it. As of **2026-08-27 there is one ballot, not two** (SERVER_CONSOLIDATION_SPEC §2): `MAP_VOTE_TIME` and `MAP_VOTE_RESULT_TIME` are **deleted** along with the map vote itself, because the map is a routing consequence now rather than a player choice. `MODE_VOTE_TIME` (**7**, was 6) is the ballot window and **must equal `SUMMARY_COUNTDOWN_TIME`** — the invariant that used to read `MAP_VOTE_TIME + MAP_VOTE_RESULT_TIME + MODE_VOTE_TIME` and had to be rewritten, not merely retuned. It is one window, not two that overlap: the ballot is open exactly as long as `NEXT MATCH IN` is on screen. Break the equality and you get either a tile that stops responding with seconds still on the counter, or a screen that tears off mid-ballot. MapVoteClient still renders its own seconds from the `Start` payload's `duration`, kept deliberately rather than reverted — it is what stopped the header freezing the last time the two diverged. `MODE_VOTE_RESULT_TIME` (0.5) is the tail of `POST_GAME_VICTORY_TIME` and nothing more: a confirmation glimpse before the curtain, not a reveal. Never zero, though — a panel that vanishes on the buzzer reads as a bug. The beat is skipped when fewer than two modes are offered, which is a safety for a future one-mode map and **not** a population gate

2d. **Defines how long a server lives.** `SERVER_MAX_LIFETIME` (3600) is a wall-clock cap checked **after** the buzzer, so the round in progress always plays out — worst case is therefore ~66 minutes, not 60. It is load-bearing for a second reason and must never be raised on its own: `RedwaterAccessCodes_v1` entries carry a 3600s TTL, so a server older than that has lost the key the lobby resolves it through. The two matching is not a coincidence
2d-i. **`SERVER_RETIRE_AFTER_ROUNDS` was deleted on 2026-08-27** (SERVER_CONSOLIDATION_SPEC §1). It stopped a server accepting matchmade players after 5 rounds, for code freshness — publishing does not update servers that are already running. A server now rotates to a sibling place at **every** round end that did not merge, which is a fresh boot on fresh code and does retirement's job for free; retirement was also the last rule in the system that deliberately made a full, healthy server unjoinable. The old live test recipe for the retirement exits (drop `SERVER_MAX_LIFETIME` to 180 with a `ROUND_TIME` of 10) still exercises the wall-clock exit, and the warning it came with still stands: **a `SERVER_MAX_LIFETIME` under an hour in a published place is always a mistake**, because at 180 every server evacuates itself three minutes after it boots
3. Defines zone shrink **schedule** constants (base damage, ramp rate, max damage cap, phase duration, centre-jitter range, fire spawn/move fractions). The Z **boundaries** left this file on 2026-08-13 — geometry differs per map and this file is mirrored verbatim into every match place, so `ZONE_START_Z` / `ZONE_END_Z` now live in `MapConfig.Zone`
4. Holds LOBBY_PLACE_ID for TeleportService
5. Defines progression/economy constants (XP per kill/round, Cash per kill/round, time reward values, leveling curve knobs XP_BASE / XP_LINEAR / XP_QUADRATIC)
6. Defines bounty system constants (kill threshold, base/scaled XP and Cash rewards, survivor bonus rates)
7. Defines the onboarding tutorial block (2026-08-09): **`TUTORIAL_FORCE_MODE` — the testing switch that makes this server resolve `State.tutorialMode = true` at boot with no Bounty dispatch (press Play in Studio and the lesson runs); honoured only in Studio or on a non-live environment, ignored with a warn on live. Currently `false`.** It was on for part of 2026-08-17 to drive the per-step reward from a Studio Play, and went back off the same day for a reason worth keeping: **"non-live" includes the DEV universe, not only Studio.** A DEV Redwater server has `isLive == false`, so the flag forces *every* DEV match server into the lesson — a DEV build then cannot test a normal round at all, and the onboarding round trip becomes lobby → tutorial → lobby → PLAY → tutorial. It has to be `false` in anything that gets published, DEV included; Studio Play is the only place it belongs. It was also `false` from 2026-08-11 for the first live onboarding publish, because the live lesson is reached through Bounty's `TutorialDispatchService` gate and leaving the flag on would have warned on every live Redwater boot and converted every server the moment an environment reported `isLive ~= true`. It is mirrored into Frostbite like the rest of this file, which has no `Tutorial` folder — a forced lesson there resolves no geometry at all, so do not press Play on Frostbite while it is on. Plus **`TUTORIAL_COMPLETE_CASH` (250) and `TUTORIAL_COMPLETE_TOKENS` (50), which are RUN TOTALS rather than per-step figures** — TutorialDirector pays them a step at a time (`floor(total / #STEPS)` per advance, remainder at the end), so changing either number here re-splits the lesson with nothing else to edit. `TUTORIAL_HARD_CEILING` (330s — 300 → 330 on 2026-08-16 when the two travel windows landed; the sum is re-derived in the comment beside it and currently reads 222 step timeouts + 7 welcome + 20 beats + 3 bounty lead-in + 4 outro + 44 travel = **300**, leaving 30s of headroom. Keep the arithmetic in the comment current when a step's timeout moves — a worst-case run that reaches the ceiling ends as `Ceiling` rather than `Completed` and is paid by a different door), and **`TUTORIAL_RESPAWN_DELAY` (0)** — a lesson death costs nothing and teaches nothing, so `RESPAWN_DELAY`'s six seconds of kill cam would just be six seconds of an unactionable instruction on screen while that step's timeout runs

## Vote windows and the participant cap

The summary carries two ballots, and three constants have to stay in step: `MAP_VOTE_TIME` (6) plus
`MAP_VOTE_RESULT_TIME` (1) plus `MODE_VOTE_TIME` (6) must equal `SUMMARY_COUNTDOWN_TIME` (13), which
is the NEXT MATCH IN counter, and `POST_GAME_VICTORY_TIME` must cover the cinematic and reveal on
top of it. Changing one window means changing the sum.

`MATCH_PLAYER_CAP` (11) plus `FRIEND_SLOTS` (2) is the real ceiling; `SOLO_PLAYER_CAP` is 12. The
total must equal the Creator Hub **Maximum Visitor Count** on both match places -- that setting is
not readable from the data model, so nothing here can assert it.

`FORCE_GAMEMODE` is a test flag that pins the mode for a locally started server. It must be nil in
anything published, dev places included.

`FORCE_ROUND_TIME` (2026-08-23) is its round-LENGTH twin: seconds, overriding the elected mode's
`GamemodeConfig` `roundTime` on this server only, for reaching the match summary without playing a
full round first. It is here and not in GamemodeConfig because that file is mirrored verbatim
into all three places and Bounty's mode picker and matchmaking read the same rows, so a test value
there would follow the mode into the lobby and out to every server that reads it; this one is
server-only and per-place. Unlike the two flags above, its live-server guard is applied **in this
file**, at the bottom, where the value is set back to nil with a warn -- so every reader is gated by
construction and RoundController has no environment check of its own to forget. Note that a
short round is not a small version of a real one: below `ZONE_PHASE_DURATION` (80) the zone never
completes a phase, so deathmatch's ring never moves.

## Domination tuning (2026-08-22)

Carries the `DOMINATION_*` block read by Gamemodes.Domination (DOMINATION_SPEC 3, 5.3, 9, 12.1):
`DOMINATION_POINTS_PER_SECOND_PER_POINT` (1.05 — the one match-length dial; 0.65 was raised on
2026-08-23 after an owner playtest ran long, and a whole-map hold now reaches 500 in 2:31),
`DOMINATION_PASSIVE_POINTS_PER_SECOND` (0.15), `DOMINATION_HALF_TIME_BY_ALLIES` (`{ 7.5, 5, 3.5 }`
seconds per half-traverse of the signed capture meter, indexed by allies on the pad, index clamped),
`DOMINATION_DECAY_MULTIPLIER` (0.5), `DOMINATION_TICK_INTERVAL` (0.25), `DOMINATION_CAPTURE_HEIGHT`
(20), the objective rewards (`DOMINATION_CAPTURE_XP/CASH` 80/10, `DOMINATION_NEUTRALISE_XP/CASH`
40/5, `DOMINATION_DEFEND_XP/CASH` 15/2) and `DOMINATION_BOTS_PER_PAD` (3). The 500-point target is
**not** here — it is `scoreLimit` on the GamemodeConfig row, because the client HUD renders it. The
reasoning behind every value sits in the source comment beside it.

## Dependencies

- **Requires:** [[GameEnvironment]]
- **Required by:** Domination, RoundController, ZoneService, SpawnService, State, ProgressionService, BountyService, MatchDirectoryService

## Connections

### Direct require()

| Target | Function | Purpose |
|--------|----------|---------|
| [[GameEnvironment]] | `GameEnvironment.bountyPlaceId` | `LOBBY_PLACE_ID`, resolved per-universe so a DEV Redwater returns players to the DEV lobby |
