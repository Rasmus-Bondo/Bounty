# Domination — Gamemode Spec

**Status:** BUILT 2026-08-22 — unverified, no playtest yet (open item 121; the closing checklist is
in that item). Written 2026-08-22 for a cold session to execute; executed the same day.
**As-built deviations from the text below:** `DomMeter_<L>` carries the **signed** meter (-1..1 in
0.05 steps) instead of §8.1's 0..1 `DomProgress`, because the authored HUD draws BOTH teams' bars per
pad and the sign cannot be rebuilt from owner + capturing alone; `DomRate_<L>` (meter units/s) and
`Player.DomPad` (the letter a player stands on) were added for the local capture countdown; the
beam↔pad pairing is a runtime `Letter` attribute the rules module stamps on the nearest
`CapturePointBeam` at `Init` (warning past 30 studs); `DominationGui` was copied to Frostbite in the
same pass rather than "once proven" (§8.2) — a Domination match on Frostbite would otherwise have
no HUD — and its `ResetOnSpawn` is `false`; `RoundController`'s fight loop tests
`activeRules.ShouldEndRound ~= nil and activeRules.ShouldEndRound()`; the objective reward values
live in `RoundSystem.Config` as `DOMINATION_CAPTURE/NEUTRALISE/DEFEND_XP/CASH`; and
`ProgressionService.awardObjective(player, kind, xp, cash)` plus three `CombatFeedClient` rows were
added for §12.1. Added 2026-08-22 by owner request after the build, beyond the text: the pads and
their beams are in the workspace **only in Domination** — `RoundSystem.CapturePointService` (modelled
on `TeamBaseService`) parks them in `ServerStorage.ParkedMapGeometry` for every other mode, keyed on a
`UsesCapturePoints` flag on the rules module and called by `RoundController` before each mode's `Init`.
Everything else is as specified.
**Owner:** unassigned.
**Places affected:** Redwater Canyon (`98517073248449`), Frostbite Claim (`134041618959520`),
Bounty (`131701626847012`).
**Live state was measured 2026-08-22** against both match places. Do not re-derive §4 or §5.1; do
re-verify anything you are about to edit, because peer sessions work this project concurrently.

**Read §5.1 before tuning anything.** The two maps' capture pads are already authored, and they are
laid out on *fundamentally different* principles — Redwater along the red→blue axis, Frostbite in a
band across the midpoint. That difference drives average-areas-held, which is the only input to
match length (§3.1), so the single tuning value in §3 cannot be right for both maps as they stand.

---

## 1. What this is

Domination is the **third gamemode** and the first *objective* mode — the first one where the thing
that wins is not "kills". Two teams, three capture areas, first to **500 points** wins. Points
accrue per second for every area a team holds, plus a small passive trickle to both teams.

It changes nothing about the gamemode axis itself. `TEAM_DEATHMATCH_SPEC.md` §4 built that axis and
it holds: a new gamemode is **a row in `GamemodeConfig` plus a rules module under
`ServerScriptService.RoundSystem.Gamemodes` in each match place** — never a new place, never a fork
of `RoundController`.

Domination declares `teamCount = 2`, and that one field inherits the whole of Team Deathmatch's
stack for free: team stamps, the two spawn houses, one-way base doors, relative team colours
(everyone sees their own side as blue), friendly-fire gating, the red/blue score chips on the HUD,
and team-aware bot fill. **Do not rebuild any of it.** The genuinely new work is the capture
mechanic, its HUD, the bot objective bias, and one edit to `RoundController`.

---

## 2. Decisions

| # | Question | Decision |
|---|---|---|
| 1 | Score to win | **500 points.** Carried on the `GamemodeConfig` row as `scoreLimit` so the client can render "137 / 500" without a server round trip (§3). |
| 2 | Points per second, per area held | **0.65/s.** One area = 0.65/s, two = 1.3/s, all three = 1.95/s. This is *the* tuning dial (§3.1). Raised from 0.6 on 2026-08-22 to pay back the neutral window the two-stage capture introduced (§5.3). |
| 3 | Passive trickle | **0.15/s to both teams, always** — 1 point per ~6.7s. Contributes ~65 points over a 7-minute match (13% of the target): enough that a team being rolled is not staring at zero, never enough to win on its own (§3.2). |
| 4 | Round time cap | **600s / 10 min.** The score limit is the normal ending; this is the backstop for a true stalemate, decided on score at the buzzer (§3.3). |
| 5 | Number of areas | **Three.** Already authored in **both** match places as three `workspace.CapturePoint` models (§5.1). |
| 6 | Pad state at round start | **All three neutral** (owner call, 2026-08-22). Neither team starts owning its home pad — every match opens on a scramble. Costs each side ~15-20s before their first pad pays (travel plus a 7.5s solo / 5s paired capture), which the §3.1 model absorbs. |
| 7 | Capture model | **Two-stage, one signed meter** (`-1` red … `0` neutral … `+1` blue). An enemy pad must be drained to neutral before it can be filled, so stealing costs double (§5.3). |
| 8 | Capture time | **Owner-set table, by number of allies on the pad** (2026-08-22). Neutral pad: **7.5 / 5 / 3.5s** for 1 / 2 / 3 allies. Enemy pad: **15 / 10 / 7s** — exactly double, because a steal traverses the whole meter (§5.3). |
| 9 | Four or more allies | **Capped at the 3-ally rate.** The owner's table stops at three, so a fourth body buys nothing and a full team cannot steamroll a pad. Not owner-specified — flagged in §5.3 as the one assumption in the table. |
| 10 | Progress when the pad empties | **Decays back toward the previous owner at 0.5x.** Progress is never banked — a team cannot chip a pad down across several lives and steal it with a one-second touch (§5.3). |
| 11 | Teams, spawns, friendly fire, doors | **Identical to TDM.** `teamCount = 2` inherits all of it; no new code. |
| 12 | Bot fill | **Same as TDM:** `max(2, TEAM_SIZE - humans)` per side, `TEAM_SIZE = 7`. |
| 13 | Match end / podium | **Team banner over the existing individual podium,** exactly as TDM. Podium still ranks every fighter by kills (§12). |
| 14 | Tie at the buzzer | **DRAW.** No sudden death, no tiebreaker — same rule TDM settled (§12). |
| 15 | Zone / firewall | **Off.** `usesZone = false`, like TDM. Full map. |
| 16 | Objective rewards | **Objective play pays** (owner call, 2026-08-22). Capture = **2x** a kill, neutralise = **1x** a kill, pad defence = a flat bonus on the kill. Paid to **every** ally on the pad, not just whoever finished it (§12.1). RP is still by individual placement (§12.2). |
| 17 | Where the three areas sit | **Already authored** (§5.1). The remaining work is identification and volume derivation, not placement. |
| 18 | Both teams on a pad | **The meter freezes** until one side wins the fight. Defending a pad is about killing, not out-standing (§5.3). |
| 19 | Do kills score team points? | **No** (owner call, 2026-08-22). Points come only from held pads and the passive trickle. Kills still pay the individual XP/Cash and still feed the podium — they just do not move the team score (§6 hook 4). |
| 20 | Which HUD shows the score | **`DominationGui` only** (owner call, 2026-08-22). `RoundStatusGui`'s red/blue score chips are **hidden in Domination** — the new panel shows the same numbers with the target beside them (§8.2). |

---

## 3. The scoring model

This is the part the whole mode is tuned on. Everything else is plumbing.

### 3.1 The one dial

```
POINTS_PER_SECOND_PER_POINT = 0.65
```

Equivalent framing: **roughly 1 point every 1.5s per area**. For reference, Call of Duty Domination
is 200 to win at 1 point per flag per 5s (0.2/s); scaled to a 500 target that is 0.5/s, so this is a
faster game than CoD's, matching a 7-8 minute target against their ~10.

It was **0.6/s until 2026-08-22**, when the capture model became two-stage (§5.3). That introduced a
window in which a flipping pad pays *nobody*, worth about 5% of a match's income, and 0.65 pays it
back almost exactly. **0.7 was considered and rejected** — it lands at 6:57 / 6:04 below, which is
faster than the original target rather than a correction to it. Keep 0.7 in reserve if playtest says
the mode drags.

Match length is a function of the **winning team's average areas held across the match** — not of
any single moment:

| avg areas held | total rate/s | time to 500 | + neutral window |
|---|---|---|---|
| 1.0 (pure stalemate) | 0.80 | 10:25 | past the 600s cap |
| 1.25 | 0.96 | 8:40 | ~9:06 |
| **1.5** | **1.125** | **7:24** | **~7:46** |
| **1.75** | **1.288** | **6:28** | **~6:48** |
| 2.0 | 1.45 | 5:45 | ~6:02 |
| 2.5 | 1.775 | 4:42 | ~4:56 |
| 3.0 (total blowout) | 2.10 | 3:58 | ~4:10 |

The last column adds the ~5% the two-stage neutral window costs (§5.3); it is the one to read.

A winning Domination team realistically averages **1.5-1.75** areas — it holds its side and trades
the middle — which is the **7-8 minute** target. The target sits in the *middle* of the curve rather
than at an edge, so the mode does not swing wildly on one lucky push.

**To retune:** 0.65 → 0.7 pulls the 1.5-area case to ~7:18; 0.65 → 0.6 pushes it to ~8:20. Nothing
else has to move.

### 3.2 The passive trickle

```
PASSIVE_POINTS_PER_SECOND = 0.15
```

Both teams, unconditionally, for the whole live round. A team holding **nothing** for an entire
match would need 55 minutes to win on trickle alone, so this can never decide a game — it exists so
a team being spawn-trapped still sees its number move.

### 3.3 The round cap interacts with server lifetime

`roundTime = 600` is 240s longer than the other two modes. `Config.SERVER_RETIRE_AFTER_ROUNDS = 5`
therefore implies ~52 minutes of Domination per server against `SERVER_MAX_LIFETIME = 3600`. It
still fits, but the headroom is thinner than the ~32 min a deathmatch server uses. **If the cap ever
goes above 600, re-check that sum.**

### 3.4 Fractional accrual, integer HUD

`TeamService.AddScore(team, amount)` does `scores[team] += amount` and publishes the result straight
onto the `TeamScoreRed` / `TeamScoreBlue` workspace attributes, which the score chips render with
`tostring()`. Handing it 0.15 would put **`137.25`** on screen.

So Domination carries the fraction itself and only ever hands `TeamService` whole points:

```lua
-- Fractional remainder, never published. TeamService stays integer-only and the
-- authored score chips need no change at all.
local carry = { red = 0, blue = 0 }

local function accrue(team, dt)
    local held = areasHeldBy(team)
    carry[team] += dt * (held * POINTS_PER_SECOND_PER_POINT + PASSIVE_POINTS_PER_SECOND)

    local whole = math.floor(carry[team])
    if whole >= 1 then
        carry[team] -= whole
        TeamService.AddScore(team, whole)
    end
end
```

At the winner's ~1.1/s the on-screen number ticks up roughly once a second, which reads as a steady
climb rather than a stutter.

### 3.5 Where the numbers live

`ServerScriptService.RoundSystem.Config` — it is server-only and mirrored Redwater↔Frostbite, and
this is gamemode **tuning**, which is exactly the dividing line `MapConfig.md` already draws ("the
zone takes 25% off per phase" is tuning and lives in Config; "this map's zone runs from Z -700" is
map data and does not).

```lua
DOMINATION_POINTS_PER_SECOND_PER_POINT = 0.65,
DOMINATION_PASSIVE_POINTS_PER_SECOND   = 0.15,
-- Seconds per HALF-traverse of the signed meter (§5.3), indexed by how many
-- allies stand on the pad. A steal crosses BOTH halves, so an enemy pad costs
-- double these: 15 / 10 / 7s against a neutral pad's 7.5 / 5 / 3.5s.
-- Owner-set 2026-08-22. A literal table, not a formula: the 1 -> 2 step is a
-- 1.5x speedup and the 2 -> 3 step is 1.43x, so no clean curve reproduces it.
-- Index is clamped to the table length -- a 4th body buys nothing (§5.3).
DOMINATION_HALF_TIME_BY_ALLIES         = { 7.5, 5, 3.5 },
DOMINATION_DECAY_MULTIPLIER            = 0.5,
DOMINATION_TICK_INTERVAL               = 0.25,
DOMINATION_CAPTURE_HEIGHT              = 20,
```

`scoreLimit = 500` goes on the **`GamemodeConfig` row instead**, because the client HUD needs it and
`Config` is server-only.

---

## 4. Current state — what already exists

Measured live 2026-08-22 against Redwater Canyon.

### 4.1 Free, because `teamCount = 2`

| Thing | Where | Why it just works |
|---|---|---|
| Team stamps, assignment, parties-seated-whole | `RoundSystem.TeamService` | Called by the rules module's `PrepareRound`, exactly as TDM does |
| Ally test | `ReplicatedStorage.Modules.TeamAffinity` | `isTeamMode()` reads `GamemodeConfig.get(...).teamCount > 0` — no mode ids hardcoded |
| Spawn houses + one-way doors + collision matrix | `RoundSystem.TeamBaseService` | `RoundController` calls `Apply((activeRules.TeamCount or 0) > 0)` |
| Relative team colours (own side always blue) | `StarterPlayerScripts.TeamVisualClient`, `Modules.TeamView` | Driven off the `Team` attribute |
| Red/blue score chips + "YOUR TEAM IS BLUE" banner | `StarterGui.RoundStatusGui` (`TeamScoreRed`, `TeamScoreBlue`, `TeamAssignBanner`) | Chips mirror the `TeamScoreRed`/`Blue` workspace attributes and gate on `TeamAffinity.isTeamMode()` |
| Team-aware bot fill and retirement | `Bots.BotService` | Reads `State.gamemodeRules.DesiredBots` |
| Mode ballot at match end | `RoundController.runBallotsDuringSummary` | Enumerates `MapCatalog.get(map).gamemodes` ∩ `GamemodeConfig` — fully data-driven |
| Lobby picker | `Bounty.StarterGui.GameModeGui.GameModeClient` | Already handles a third mode; three tables plus one authored button (§11) |

### 4.2 Does not exist at all

- Any code that reads the capture pads. The **geometry is authored, nothing consumes it** (§5).
- Any notion of an objective, or a score that is not a kill count.
- Any way for a round to end **before** its clock runs out (§7).
- Any bot behaviour that walks toward a place because the *round* wants it there (§9).

### 4.3 One thing that is deliberately fine

`GameModeClient`'s 3D sign cannot spell "DOMINATION" — the mesh letter set has no U/O/R/I/L. It does
not need to: the sign's `showAlternate = (mode ~= DEATHMATCH)` branch already routes every non-
deathmatch mode through the shared `SurfaceGui` plates, which is how TDM and TUTORIAL render today.
**Do not try to build the letters.**

---

## 5. The capture areas

### 5.1 What is authored today (both maps, measured 2026-08-22)

Both match places already carry three `Model`s at the **workspace root**, each named `CapturePoint`,
each a visible **pad** built from 5-11 parts that are *also* all named `CapturePoint`. The same three
prefabs were reused across both maps, though not in equal numbers: **Redwater's C is the only
large pad** (10 `CapturePoint` parts, 33.6 x 42.3). Every other pad on both maps is the small
5-part prefab at 28.7 x 36.4. That matters only for §5.4 — the large pad has 10 colour surfaces to
drive where the others have 4.

The useful measure of "whose side is this pad on" is **`t`, the pad's position projected onto the
red→blue base axis**: `t = 0` is the red base, `t = 1` is the blue base, `t = 0.5` is the exact
midpoint. Raw distance-to-base cannot answer that on a diagonal map. `perp` is how far the pad sits
off the straight line between the bases.

**Redwater Canyon** — bases `(54, 28, -459)` red / `(-37, 35, -82)` blue, 389 studs apart:

| Letter | `t` | `perp` | Pad centre | Bounding box | Parts | dist red | dist blue |
|---|---|---|---|---|---|---|---|
| **A** | 0.217 | 105 | `187.4, 0.3, -340.6` | 28.7 x 2.5 x 36.4 | 5 | 179 | 343 |
| **B** | 0.520 | 60 | `-45, 12, -276` | 28.7 x 4.9 x 36.4 | 5 | 209 | 194 |
| **C** | 0.616 | 86 | `80.9, 30.3, -206.7` | 33.6 x 3.3 x 42.3 | 11 | 254 | 172 |

**Frostbite Claim** — bases `(175, 25, 183)` red / `(-147, 23, -184)` blue, 488 studs apart:

| Letter | `t` | `perp` | Pad centre | Bounding box | Parts | dist red | dist blue |
|---|---|---|---|---|---|---|---|
| **A** | 0.410 | 109 | `124.8, 3.8, -39.6` | 28.7 x 3.4 x 36.4 | 5 | 228 | 308 |
| **B** | 0.470 | 44 | `-10.5, 14.6, 39.1` | 28.7 x 2.5 x 36.4 | 5 | 235 | 262 |
| **C** | 0.700 | 136 | `-152.4, 2.9, 16.2` | 28.7 x 5.2 x 36.4 | 5 | 368 | 200 |

**Both layouts were re-cut by the owner on 2026-08-22 and both now match what §3.1 assumes:** one
pad each side that a team can hold, one contested middle. The tables above are post-move.

The measure that matters is each pad's **edge** — how much closer it is to one base than the other:

| | red-side pad | middle | blue-side pad |
|---|---|---|---|
| **Redwater** | +164 red | +15 | +82 blue |
| **Frostbite** | +80 red | +27 | +168 blue |

A middle pad inside ~30 studs is even (about two seconds of running). The two maps mirror each
other — Redwater's strong home pad is red's, Frostbite's is blue's — so neither side is favoured
across a rotation.

What they looked like before, and why it mattered, is §14.2.

**Beam anchors: both maps carry three.** Each is a small anchored, non-collidable, fully transparent
`CapturePointBeam` part at the **workspace root**, holding a real `Beam` (`BeamTexture19`) — see
§5.4. Coordinates are deliberately not listed here; they move whenever a pad moves.

**They are matched to pads by PROXIMITY, not by parenting.** Each currently sits within ~1 stud of
its pad on Frostbite and within ~8 on Redwater. Nothing enforces that, so a pad dragged in Studio
can leave its beam behind — resolve each pad's beam as the nearest one at boot and **warn if the
nearest is further than about 30 studs**, rather than trusting the pairing silently.

Frostbite's three did not exist when this spec was first written (a full workspace sweep returned
zero on 2026-08-22); they were authored during the same pass that repositioned its pads.

### 5.2 Two things the geometry needs before code can use it

1. **DONE 2026-08-22 — the pads are identified.** All three models in each place previously shared
   the name `CapturePoint` and carried no attributes, so nothing could tell them apart: Explorer
   child order is **not stable** (it read back `C, A, B` in Redwater and `B, C, A` in Frostbite on
   the very pass that renamed them, and the TDM spawn markers already learned the same lesson with
   `Point10` sorting before `Point9`). Each top-level model is now named **`CapturePointA` /
   `CapturePointB` / `CapturePointC`** *and* carries a matching **`Letter`** string attribute.
   - The letters were **derived, not typed** — assigned by sorting on each map's own red→blue `t`
     projection (§5.1), so both maps use one rule and the script is safe to re-run.
   - The **parts inside are still all named `CapturePoint`** and were deliberately left alone.
   - **Code should read the `Letter` attribute, not the model name.** The name is for the human in
     the Explorer; the attribute is the contract, and it survives a later rename.
2. **The pads are visible floors, not trigger volumes.** The capture volume has to be *derived*:
   - flat radius = `math.max(bbox.X, bbox.Z) / 2` (so 18.2 / 18.2 / 21.2 studs for A / B / C)
   - height band from the pad's top surface up by `DOMINATION_CAPTURE_HEIGHT` (20 studs), so a
     player standing on the pad is inside it and someone on a rock above is not

   A flat-radius + height test, **not** a rotated-box test: a cylinder is what a capture area reads
   as to a player, and a rotated `GetPartBoundsInBox` reports false hits across half a room.

**Never use `Touched`.** It is unreliable for a standing body and expensive for 14 fighters.

### 5.3 The capture meter — two-stage, one signed number

**Decided 2026-08-22.** An enemy pad must be neutralised before it can be taken. This is the
Battlefield Conquest model, deliberately **not** CoD Domination's single straight-to-enemy bar,
even though CoD was the reference for the mode overall.

Represent it as **one signed meter per pad**, not two bars:

```
       -1 ─────────────── 0 ─────────────── +1
      RED owns         neutral          BLUE owns
```

Blue fighters on the pad push the value **up**, red fighters push it **down**. Ownership is the
endpoint and nothing else: red owns at `-1`, blue owns at `+1`, **every value in between is
neutral and pays nobody.** One number drives the state, the HUD bar and the beam colour.

A steal therefore traverses the whole meter — `-1 → 0 → +1` — which is why it costs double.

**The rules:**

- Only fighters who are **alive** count. Use the project's `IsAlive` predicate, **never a bare
  `Health > 0`** — corpses regenerate in Redwater and a dead body would hold a pad forever.
- `n` = alive fighters of the pushing team inside the volume (players *and* `workspace.ArenaBots`
  rigs — bots capture).
- Rate = `1 / DOMINATION_HALF_TIME_BY_ALLIES[math.clamp(n, 1, 3)]`, so each half-traverse takes
  **7.5 / 5 / 3.5s** for 1 / 2 / 3 allies. A steal crosses both halves and therefore costs
  **15 / 10 / 7s**; a neutral pad costs half that. Owner-set 2026-08-22.
- **`n` is re-read every tick, so the rate is not fixed for a whole capture.** Three fighters who
  drain a pad and then leave one behind to fill it finish at the solo rate, not the trio rate. The
  table describes an instantaneous speed, never a promised duration.
- **The 4+ case is the one assumption in that table.** The owner specified 1-3; the index is clamped,
  so a fourth body buys nothing. Change the clamp if a full stack should keep scaling.
- **Both teams present → the meter FREEZES.** Not slower, not tug-of-war: it stops dead until one
  side wins the gunfight. Defending a pad is about killing, not about out-standing. Keep this in a
  single `resolveContest(redCount, blueCount)` function so it stays one place to change.
- **Empty pad → the meter decays back toward the previous owner** at `DOMINATION_DECAY_MULTIPLIER`
  (0.5x). Progress is never banked. Without this a team could chip a pad down over several lives and
  steal it with a one-second touch, which rewards dying rather than holding ground.
- A pad that was **neutral** when the attacker died decays to `0` and stays there.

**The cost of this model, and it is the reason §3.1 moved:** between leaving `-1` and reaching `+1`
the pad pays *nobody*. Under the old single-bar model the previous owner kept earning right up to
the flip. That is worth roughly 5% of a match's income, which is what taking the rate from 0.6 to
0.65 pays back.

**These times are deliberately long.** 15s solo on an enemy pad is Battlefield's pace, not CoD
Domination's ~8-10s, and it means a lone fighter cannot realistically steal a pad against any
resistance — which is the entire point of the ally scaling. If it plays sluggish, cut the *first*
entry of the table before touching anything else; the points rate is a separate problem and moving
both at once makes neither measurable.

They also lengthen the dead window: a solo steal now pays nobody for 15s where the earlier 6s/12s
draft paid nobody for 12. That nudges the neutral-window cost from ~5% toward ~6% of match income,
which 0.65/s still absorbs — but it is the first thing to re-measure if matches run long.

Cost is trivial: ≤14 fighters × 3 pads = 42 distance checks, four times a second.

### 5.4 Ownership colour — three authored surfaces per pad

Measured 2026-08-22. Every one of these is authored **neutral** today and is meant to take the
owning team's colour. This is the world-space ownership tell, and it is already built — nothing
here needs creating, only driving.

| Surface | Where | Count per pad | Authored state |
|---|---|---|---|
| **Pad parts** | the `CapturePoint` parts in the model | 4 on A and B, **10 on C** | `Color` grey `(163, 162, 165)`, `Material = ForceField` |
| **`TeamGui`** | a `SurfaceGui` on each of those parts, `Face = Front`, holding one `Frame` + `UIGradient` | one per pad part | Frame white, gradient white → white, `Rotation = -90` |
| **`Beam`** | `BeamTexture19` on the sibling `CapturePointBeam` part | 1 | white `ColorSequence`, width 10, `FaceCamera = true`, 5 transparency keypoints |

The `CapturePointBase` part carries **no** `TeamGui` and is not part of the tell. `Material =
ForceField` on the pad parts is why they glow — the colour reads as energy rather than paint, and it
is the reason a plain `Color` assignment is enough to sell a capture.

That is **39 instances across the three pads** (18 parts, 18 gradients, 3 beams). Resolve them
**once** into a cached per-pad table at boot; never `GetDescendants` on a state change.

#### It must be coloured on the CLIENT

Not a stylistic preference — a hard constraint. Team colour in this game is **relative**: every
player sees their own side as blue and the enemy as red. A colour written on the server is one value
replicated to everybody, which is the single thing that scheme cannot survive. It is exactly the
trap that moved the rig outline out of `TeamService` into `StarterPlayerScripts.TeamVisualClient` on
2026-08-19.

So the server owns `DomOwner_*` (§8.1) and nothing else; a client renderer reads that attribute and
paints all three surfaces through `TeamView`. Neutral is the authored grey/white.

#### Two traps

- **Streaming.** The pads are `ModelStreamingMode = Default`, so a distant client may not have the
  parts at all when ownership changes. The renderer must tolerate absent instances **and re-apply on
  stream-in** — otherwise a player who walks up to a pad that streamed in after the last flip sees
  it neutral while everyone else sees it owned. Do not "fix" this by making the pads `Persistent`;
  that costs every client the whole pad model for the entire match.
- **`LightInfluence = 1` on `TeamGui`.** The panel is lit by the scene, so the same team colour
  reads differently in shade than in open sun. If a capture is hard to read in Redwater's canyon
  shadow, that property is the reason — not the colour choice.

#### Both maps are ready

Verified 2026-08-22: Frostbite's three pads each carry 5 parts, 4 `TeamGui`s and 4 gradients with the
same grey `ForceField` authoring as Redwater's, and all three of its beams exist. Nothing is missing
on either map.

The one asymmetry is **Redwater's C**, the only large pad: 10 parts and 10 `TeamGui`s against every
other pad's 4. Resolve the surfaces per pad rather than assuming a fixed count.

---

## 6. The rules module

`ServerScriptService.RoundSystem.Gamemodes.Domination`, implementing the same interface
`TEAM_DEATHMATCH_SPEC.md` §4.2 defines. `RoundController` finds it by matching `.Id`, so the script
name and the wire id stay independently renameable.

```lua
Id        = "domination",
TeamCount = 2,
UsesZone  = false,
```

The nine existing hooks:

| # | Hook | Domination |
|---|---|---|
| 1 | `Init(ctx)` | Resolve the three pads once; assert all three exist and carry distinct `Letter` attributes. |
| 2 | `PrepareRound(ctx)` | `TeamService.AssignAll`, then reset all three pads to neutral, zero `progress`, zero the `carry` table. |
| 3 | `ResolveSpawn(player)` | **Delegate to the TDM implementation** — the spawn houses and their `Points` markers are identical. Do not reimplement; call `TeamDeathmatch.resolveSpawnForTeam`, which is already exposed on that module for exactly this kind of reuse. |
| 4 | `OnDeath(...)` | **Nothing.** Kills do not move the team score — owner call, decision 19. The pads and the trickle are the only scoring sources. Kills still pay their own XP/Cash and still rank the podium; they simply are not points. |
| 5 | `GetOutcome()` | Higher score wins; equal is `{ kind = "draw" }`. `statusLine` of the form `"Blue team wins 500-361!"`. |
| 6 | `DecorateVictoryPayload(payload)` | Same `teamOutcome = { kind, team, red, blue }` shape TDM adds. |
| 7 | `CanDamage(a, v)` | Nothing crosses teams — same as TDM. |
| 8 | `DesiredBots()` | `max(2, 7 - humans)` per side — same as TDM. |
| 9 | `EndRound()` | Zero the scores, clear the pad attributes, stop the accrual loop. |

Plus **two new optional hooks** (§7, §9). Both are `nil` on Deathmatch and TeamDeathmatch, so
neither mode changes behaviour by a single line.

**The accrual loop belongs to this module, not to `RoundController`.** Start it in `PrepareRound`,
guard every iteration on `State.roundActive`, stop it in `EndRound`. That keeps the round loop
mode-agnostic and means the only `RoundController` edit in this whole spec is §7.

---

## 7. Where `RoundController` changes — one edit

The round currently ends on its clock and nothing else (`RoundController` ~line 2724):

```lua
repeat
    task.wait(1)
until tick() - roundStartTime >= roundLength
```

There is **no** score-limit exit anywhere in the file. Add a tenth, optional hook:

```lua
-- Mode hook #10: an objective mode may end its own round early. FFA and TDM do not
-- define ShouldEndRound, so nil keeps the clock as the only exit and neither mode moves.
repeat
    task.wait(0.25)
until tick() - roundStartTime >= roundLength
    or (activeRules.ShouldEndRound and activeRules.ShouldEndRound())
```

The wait tightens 1s → 0.25s so a 500th point does not sit on screen for up to a second before the
buzzer. Everything downstream — the freeze, the payout block, the podium, the ballots, the loop tail
— is untouched and already reads `GetOutcome()` for the winner.

---

## 8. Replication and HUD

### 8.1 Replication — workspace attributes

Same idiom `TeamScoreRed` already uses. Per pad, keyed by letter:

| Attribute | Type | Meaning |
|---|---|---|
| `DomOwner_A` | string | `"red"` / `"blue"` / `""` for neutral |
| `DomProgress_A` | number | 0..1, **quantised to 0.05 steps** |
| `DomCapturing_A` | string | which team is filling the bar, `""` for none |
| `DomContested_A` | boolean | both teams present |

Quantising matters: unquantised progress at the tick rate is 12 attribute writes per second per pad
replicated to every client, for a bar 20 pixels tall. At 0.05 steps a full 6-second capture costs
20 writes total.

The score itself needs **no new replication** — `TeamService` already publishes it and the chips
already render it.

### 8.2 HUD — `StarterGui.DominationGui`, already authored

**The HUD exists.** It was authored in the *Bounty - UI Update* place and copied into Redwater on
2026-08-22 (87 descendants, verified identical). **It supersedes the "three pills inside
RoundStatusGui" this section used to describe** — the authored design is better and more complete:
per-team score bars, per-pad indicators, an announcer line and a personal capture bar.

**It is not yet in Frostbite.** Copy it there once it is wired and proven, not before.

#### The tree, and what drives each node

```
StarterGui.DominationGui            ScreenGui — DisplayOrder 7, DeviceSafeInsets, Enabled = false
├── Canvas                          Frame, UIGridLayout, 2 cells side by side
│   ├── 1Team                       YOUR side, LayoutOrder 1 ("BLUE TEAM ..." announcer)
│   │   └── BackgroundShadow
│   │       └── BackgroundBar
│   │           ├── BarFill         team score. Anchored LEFT, fills left -> right
│   │           ├── ProgressText    "500 / 500"  <- score / scoreLimit
│   │           └── Captures        UIGridLayout, 3 cells
│   │               ├── CaptureA    LayoutOrder 1, Letter = "A"
│   │               ├── CaptureB    LayoutOrder 2, Letter = "B"
│   │               └── CaptureC    LayoutOrder 3, Letter = "C"
│   │                   ├── BarFill              that pad's capture meter
│   │                   └── Announcer            "BLUE TEAM IS CAPTURING AN OBJECTIVE"
│   └── 2Team                       ENEMY side, LayoutOrder 2 ("RED TEAM ..." announcer)
│       └── ... identical, except BarFill is Position {1,0} Size {-1,0}: fills RIGHT -> LEFT
└── CaptureBar                      Frame — the LOCAL player's own capture
    └── BackgroundShadow.BackgroundBar
        ├── BarFill
        └── ProgressText            "CAPTURING : 15.0"  <- counts the §5.3 half-traverse down
```

`1Team` is **your** side and `2Team` the enemy's, resolved through `TeamView` exactly as the
`RoundStatusGui` score chips already are — everyone is blue from where they stand, so the panels
are never "red's" and "blue's" absolutely. The authored `Announcer` strings encode that convention
and must not be read as absolute team names.

Every `BarFill` is authored white with a `UIGradient` over it, so **colour comes from the gradient,
not from `BackgroundColor3`.** Recolour the gradient; assigning the fill colour will look wrong.

#### Layout order — FIXED 2026-08-22

As authored, all three indicator frames shared the one name `BackgroundCapture` **and**
`LayoutOrder = 0`, and `1Team` / `2Team` were both `LayoutOrder = 0` too. Both `UIGridLayout`s are
`SortOrder = LayoutOrder`, so with every value tied the grid fell back to child order, which is not
stable — the identical trap the capture pads had (§5.2). Two things could have gone wrong:

- the pad indicators mapping to A / B / C differently between sessions, and
- **the two team panels swapping sides**, putting the enemy's score where yours belongs.

Both are now stamped: `1Team` = 1, `2Team` = 2, and the indicators renamed **`CaptureA` /
`CaptureB` / `CaptureC`** with `LayoutOrder` 1 / 2 / 3 and a matching **`Letter`** attribute. Left
to right is A, B, C.

**Key off the `Letter` attribute, not the name and not the position** — same contract §5.2 settled
for the pads, and it survives a later rename or reflow.

#### The client script

A **new LocalScript** parented to `DominationGui`. Do not grow `RoundStatusClient` — it is 357 lines
and shared by every mode, and mode-specific rendering inside it is how that file rots.

It must:

1. **Enable the ScreenGui only in Domination.** It is authored `Enabled = false` (the mode-gated
   pattern `MapVoteGui` and `TutorialGui` already use). Gate on the `Gamemode` workspace attribute,
   which `MatchDirectoryService` mirrors and `TeamAffinity.isTeamMode` already reads.
2. Drive both `ProgressText`s off `TeamScoreRed` / `TeamScoreBlue` and the row's `scoreLimit`, and
   both score `BarFill`s off `score / scoreLimit`.
3. Drive each indicator off its pad's `DomOwner_*` / `DomProgress_*` / `DomContested_*` attributes
   (§8.1), and show the `Announcer` only while that pad is actually being captured.
4. Drive `CaptureBar` off the **local player's own** pad occupancy — visible only while standing on
   a pad that is not already yours, counting down the remaining half-traverse seconds.

#### The score chips are hidden in Domination

**Owner call, decision 20.** This panel is the only score readout — it shows the same
`TeamScoreRed`/`Blue` numbers with the target beside them, so shipping both would be two copies of
one number a few pixels apart.

The gate is in `RoundStatusClient.updateTeamScores`, which today reads:

```lua
local visible = TeamAffinity.isTeamMode() and roundActive.Value == true
```

Domination declares `teamCount = 2`, so `isTeamMode()` is **true** and the chips would show by
default — this needs an explicit exclusion, not silence. Gate on the `Gamemode` workspace attribute
alongside the team test. It is a one-line change and the only edit `RoundStatusClient` needs.

`TeamAssignBanner` ("YOUR TEAM IS BLUE") **stays** — it teaches the team rule once per round and has
no equivalent on the new panel.

#### One open interaction

**Both sit in the top-centre band.** `DominationGui.Canvas` is at `{0.5, 0}, {0.049, 0}` and the
match timer is in the same strip. `DisplayOrder 7` makes the stacking deterministic, but if they
actually overlap the fix is layout, not layering. Hiding the chips frees some of that band, which
helps. Run `capture_device_matrix` on the **first** draft (`UI_STYLE_GUIDE.md` §9), not the last.

#### Properties changed on copy (2026-08-22)

| Property | Was | Now | Why |
|---|---|---|---|
| `DisplayOrder` | 0 | **7** | 0 collided with `GunGui` / `VictoryShowcase` / `ReworkedSettingsGui`. 7 is above `RoundStatusGui` (5) and the mobile combat buttons (6), below `StatMenuGui` (20). |
| `ScreenInsets` | `CoreUISafeInsets` | **`DeviceSafeInsets`** | Matches `RoundStatusGui`, which it shares the top band with. `CoreUISafeInsets` reserved the Roblox topbar and pushed the panel below the timer it aligns to. |
| `Enabled` | `true` | **`false`** | It would otherwise render in deathmatch and TDM. The client enables it for Domination only. |

---

## 9. Bots

**This is the piece most likely to be underestimated.** Without it, bots ignore the objective
entirely and every match is decided by whichever side has more humans — which, with a bot fill of
`max(2, 7 - humans)`, is most matches.

`BotBrain:_patrol(now)` (BotBrain ~line 748) currently paths to a **random spawn point** whenever a
bot has no target. That is the single hook point. Add the second new optional rules hook:

```lua
-- Mode hook #11: where should an idle bot go? nil = keep the random-spawn patrol.
PatrolTarget = function(botModel) return nil end,
```

Domination returns the position of the pad that bot should contest. Selection, in order:

1. a pad currently **contested**,
2. a **neutral** pad,
3. an **enemy-held** pad,
4. otherwise the **own-held** pad nearest the enemy.

Nearest-first within each tier, and **cap the number of bots assigned per pad** so a side's whole
bot allocation does not stack on B.

A bot that arrives must **hold inside the radius** while the pad is not yet its team's, rather than
treating arrival as "patrol complete" and wandering off.

Two constraints from prior bot work, both learned the hard way and both applicable here:

- **Fix target choice, never choreograph the path.** Bot movement has to look natural; the fix is
  always *where* it decides to go, not a scripted route to get there.
- `_patrol` measures arrival against its stored destination directly, **not** `Pathing:HasArrived`,
  which returns true whenever `Pathing.Destination` is nil.

---

**As built (2026-08-22, after the owner's first playtest):** "idle bot" was the wrong premise —
`BotBrain._scanTarget` has no line-of-sight test and `DefaultDetectionRange` (700) spans the map, so
in a team mode a bot always has a target and the `_patrol` path that consulted hook #11 never ran;
bots hunted rigs they could not see and went nowhere near a pad. The hook is now asked every brain
tick (`_objectiveTarget`, memoised per tick) and the **objective owns the bot's movement unless the
target is an immediate threat** (`_objectiveDecision`: shot within `DamageResponseDuration`, damage
lock held, inside `BotConfig.ObjectiveCloseThreatRange` = 20, or visible inside
`ObjectiveEngageRange` = 65; a perched Vesper is left alone). A visible target inside attack range is
shot at on the way, firewall-escape style. Deathmatch and TDM are untouched. Same-day follow-up
(owner: a bot that can only capture OR fight "feels not right"): capture and fight are no longer a
choice — **on its pad a bot holds the pad and fights from it** whatever happens (feet inside the
radius, gun on the nearest enemy it can see, `ObjectiveFightStrafeInterval` = 2 s mill), and **on
the way** it breaks off only for an enemy inside `ObjectiveCloseThreatRange` or visible inside
`ObjectiveEngageRange`, resuming after; sniped from afar it keeps walking and shoots back if it can
see the shooter. The threat judged is the nearest enemy, not the committed target, line of sight is
tested without the fire cone (`BotCombat.CanSee` gained an `ignoreCone` argument), and the pick is
held for `ObjectiveThreatLock` = 2 s. Not yet re-playtested.

## 10. Per-place work

**Per-map and therefore NOT mirrored** — the same trap `MapConfig` carries. Anything map-specific
stored in a mirrored tree is silently overwritten by the next sync.

Per match place:

1. ~~Stamp `Letter` on the three pads~~ — **done 2026-08-22 in both places** (§5.2).
2. `Instances.CapturePoints = "CapturePoint"` in `MapConfig` — the three pads are **workspace-root
   siblings**, not a folder, so the resolver collects by **name prefix** (`CapturePointA/B/C`) and
   then keys each one off its `Letter` attribute.
3. `"domination"` appended to `MapConfig.Gamemodes`.

Both places were measured on 2026-08-22 and both already carry their three pads, so the `Letter`
values to stamp are the ones in §5.1's two tables — they are **not** interchangeable between maps,
because the letters are assigned by each map's own red→blue projection.

Both maps' pads, `TeamGui`s and beams are present and correctly stamped as of 2026-08-22, so §5.4
has everything it needs on both. The only per-place asset still outstanding is `DominationGui`,
which is **Redwater only** by decision until it is wired and proven (§8.2).

---

## 11. Bounty (lobby) changes

Small, because the picker already carries a third mode.

1. An authored `DominationButton` in `GameModeGui.Scrim`, cloned from the existing
   `TeamDeathmatchButton` rather than built from typed property values (style guide §1.1 — a
   property read-back is not verification).
2. Three entries in `GameModeClient`: `BUTTONS`, `READOUT`, `BLURB`, alongside a
   `local DOMINATION = "domination"`. `READOUT` and `BLURB` should read `GamemodeConfig.get(...)`
   rather than hardcoding copy, as the TDM entries already do.
3. Nothing in matchmaking. `MatchmakingService` reads `MapCatalog`'s per-map `gamemodes`.

---

## 12. Match end and rewards

Team banner over the existing individual podium, podium ranks every fighter by kills across both
sides, draw on equal score with no tiebreaker — all exactly as TDM.

### 12.1 Objective rewards

**Owner call, 2026-08-22: taking objectives pays.** Without this a player who spends the match
capping and defending earns strictly less than a teammate who ignores the pads and farms kills,
which makes the mode's own win condition the worst way to play it.

| Event | XP | Cash | When |
|---|---|---|---|
| **Capture** | 80 | 10 | The meter reaches your team's end (`+1` / `-1`) |
| **Neutralise** | 40 | 5 | The meter reaches `0` from the enemy's end |
| **Pad defence** | +15 | +2 | A kill inside a pad your team owns, **on top of** the normal kill reward |

**Anchored to the kill reward** (`Config.XP_PER_KILL = 40`, `CASH_PER_KILL = 5`): a capture is worth
**two kills**, a neutralise **one**. Owner call 2026-08-22 — objective play is meant to out-earn
slaying, not merely match it, because the mode's win condition should also be its best way to earn.

A full solo steal is neutralise + capture = **120 XP for ~15s stood in the open**, i.e. three kills'
worth. Read §12.3 before changing these: they are the reason that section exists.

**Paid to every ally standing on the pad when the event fires,** not to whoever happened to complete
it. Paying only the finisher would punish exactly the grouping that the ally-count scaling in §5.3
exists to encourage. Bots are skipped — they have no profile.

**Route it through the existing banked-rewards path,** the one kills already use: accumulate into
`ProgressionService`'s pending bucket so boosts and the level recompute apply, and so the buzzer
flush pays it. A player who leaves before the buzzer gets nothing, consistent with every other
earning in the round.

**Cash must go through `Wallet.award` with a new reason** — `domination_capture`,
`domination_neutralise`, `domination_defend`. **Add all three to Wallet's reason map in every place.**
An unmapped reason does not error; it silently falls back to the "Gameplay" transaction type, so the
failure mode is mislabelled economy analytics rather than a crash.

### 12.2 What deliberately does NOT change

- **RP** stays on individual placement. TDM left the ranked ladder alone and this does too; one
  ladder across three modes is the existing decision, not something to revisit inside a mode build.
- **The podium still ranks by kills.** Ranking by a blended objective score is a bigger change than
  it looks — it touches the summary, the stat card and the showcase payload. Deferred, but the stat
  card should gain a **Captures** column so the work is at least visible to the player who did it.

### 12.3 The one number to watch

`Config` XP was deliberately retuned to 0.40x on 2026-07-25 because new players were reaching L14 in
five games; the target is ~1,020 XP per match.

At 80 / 40 / 15 these rewards add roughly **3,500-4,000 XP across a full match** on top of kills —
close to **doubling** match XP. The sharpest way to state the risk is not levelling speed but
**cross-mode balance**: Domination runs ~7.5 min against deathmatch's 6, so paying ~1.8x the XP in
1.25x the time makes it roughly **1.4x the XP per minute of any other mode**. The end-of-match mode
ballot then elects Domination every time and the other two modes quietly die — not because players
prefer them less, but because they pay less.

**This was raised with the owner and the values are their decision.** It is recorded here so a later
session does not "fix" it, and so the DEV soak knows what to look at.

**Measure on the soak:** total XP per player per match in Domination against the same figure in TDM,
normalised per minute. If Domination is more than ~1.15x, the capture value is the dial — 80 → 60
gets most of the way back without touching the other two. Do **not** compensate by cutting the kill
reward; that is shared with the other modes and would drag them down with it.

---

## 13. Mirror obligations

Two different mirror scopes, and confusing them is how this breaks silently:

**All three places** (universe tier, on the 19-module list):
- `ReplicatedStorage.Config.GamemodeConfig` — the new `domination` row
- `ReplicatedStorage.Config.MapCatalog` — `"domination"` appended to **both** maps' `gamemodes`

**Redwater ↔ Frostbite only** (the gamemode codebase, synced by `/mirror`):
- `RoundSystem.Gamemodes.Domination` (new)
- `RoundSystem.Config` — the tuning block
- `RoundSystem.RoundController` — the §7 edit
- `Bots.BotBrain` — the §9 hook
- `StarterGui.RoundStatusGui.RoundStatusClient` — the one-line score-chip gate (§8.2)
- `StarterGui.DominationGui` + its client LocalScript — **currently Redwater only.** Copy to
  Frostbite once wired and proven (§8.2)

**Neither** (per-place, never mirrored):
- `ReplicatedStorage.Config.MapConfig`
- The `CapturePoint` models, their `Letter` attributes and the `CapturePointBeam` parts

Run `/preflight` before publishing. Never publish one place alone.

---

## 14. Things that will bite

### 14.1 Two separate mode lists, and they fail differently

`MapConfig.Gamemodes` is asserted by `RoundController.resolveGamemodeRules` at boot — miss it and the
match place **errors on startup**. `MapCatalog`'s per-map `gamemodes` is read by Bounty's matchmaker
and the end-of-match ballot — miss it and the mode boots fine but **nobody can ever be matched into
it**. Both need `"domination"`, in all the copies §13 lists.

### 14.2 Pad placement was wrong on both maps, and was fixed before build (2026-08-22)

**Resolved — kept because it is the reasoning behind the current geometry, and because it is the
thing to re-check if anyone moves a pad again.** Average-areas-held is the only input to match
length (§3.1), and pad placement is what sets it. Both maps were originally laid out in ways that
would have broken the §3 tuning, in opposite directions:

- **Redwater started lopsided.** Pad A sat at `t = 0.067`, practically inside the red base (195
  studs from red against 411 from blue), so red began every match a free pad up. Pad B was also
  red-side at `t = 0.428`, making red closer to *two* pads and blue to one — and 2 pads against 1 is
  a 6-minute win against an 11-minute one.
- **Frostbite started bunched.** All three sat at `t = 0.47-0.54`, a 7% band across the exact
  midpoint, with base-distance edges of only 21-30 studs — roughly two seconds of running. No pad
  belonged to anyone, so all three would flip constantly, neither team would build a lead, and most
  matches would have hit the 600s cap without either side reaching 500.

Both were corrected by moving pads only — no code, and no per-map tuning values. That last option
was deliberately not taken: `Config` is mirrored Redwater↔Frostbite, so per-map rates would have had
to move into `MapConfig`, which is real structural cost to work around a map problem.

**The check to re-run if a pad moves:** each outer pad at least ~80 studs closer to its own base,
the middle pad within ~30. Current values are in §5.1.

### 14.3 The rest

1. **Never infer a pad's letter from Explorer order** (§5.2). It is not stable — the same three pads
   read back in a different order in each place. Read the `Letter` attribute.
2. **The mode ballot goes from 2 tiles to 3.** `MapVoteClient` renders the mode tiles into an
   authored layout sized for two. Check it on a phone viewport before shipping.
3. **`TeamService.AddScore` must keep receiving integers** (§3.4). A fractional call puts `137.25`
   on the score chip.
4. **Dead fighters must not hold a pad.** `IsAlive`, never `Health > 0` — corpses regenerate.
5. **Bots stacking on one pad** turns the whole bot fill into a single blob. Cap per pad (§9).
6. **Round cap of 600s thins the server-lifetime headroom** (§3.3).
7. **Streaming.** The pads are `ModelStreamingMode = Default`, so a distant client may not have them.
   Server-side capture logic is safe (the server always has full geometry) and the HUD reads
   attributes rather than parts, so it is safe too — but the §5.4 beam is a *client* renderer and
   must tolerate its part being absent. Do not make the pads `Persistent` to work around it; that
   costs every client the whole pad model permanently.
8. **Do not try to spell DOMINATION on the 3D sign** (§4.3).

---

## 15. Open questions

### 15.1 Do the pads move? (Decide AFTER the first playtest, not before)

§14.2 predicts Redwater plays short-and-red-favoured and Frostbite plays long-and-stalemated, from
geometry alone. Both predictions are testable in one session each once the mode runs. The options,
in ascending cost:

- **Ship as authored, tune later.** Cheapest, and the prediction may simply be wrong — cover and
  sightlines are not in the numbers.
- ~~Square both maps up along the axis~~ — **done 2026-08-22** (§5.1, §14.2). Both now read one
  pad each side plus a contested middle, so the single §3 tuning value should be right for both.
- **Per-map tuning rates.** Requires moving the rates out of the mirrored `Config` and into
  `MapConfig`. Only worth it if the layouts are deliberately meant to play differently.

### 15.2 ~~What happens when both teams occupy a pad?~~ — RESOLVED 2026-08-22

**The meter freezes.** Tug-of-war and slow-capture were both considered and rejected; see §5.3 for
the rule and the reasoning. The capture model became two-stage in the same pass, and the points rate
moved 0.6 → 0.65 to pay for it.

### 15.3 Deferred

- Objective-based RP and rewards (§12). Not part of this build; open-item it on ship.
- The `CapturePointBeam` FX itself (§5.4) — the anchor parts exist, the beam does not.
