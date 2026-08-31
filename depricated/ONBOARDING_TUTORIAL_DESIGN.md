# Onboarding Tutorial — Design Spec

**Status: BUILT — NOT VERIFIED. Both places, 2026-08-09.** The lesson has been driven repeatedly
in Studio and tuned across those runs (spawn facing, instant respawn, bot choreography and
distances, step copy, keycaps, gate arming, the ult grant), but **§11's checklist has not been
worked through and nothing here is signed off**. Two gaps in particular:

- **It has never been run on a phone.** Every touch path — the touch copy variants, the auto-fire
  shooting gate (§5.4), the skipped Alt step and `/ 10` progress count, the banner against the
  bottom-right button cluster, the reload-button line — is reasoned from code and untested on
  device. This is the single largest unverified surface.
- **Live transport is untested by definition** — dispatch, reserved servers and the return teleport
  do not run in Studio at all (§11).

**`Config.TUTORIAL_FORCE_MODE` is still `true`.** It is honoured only in Studio / non-live and a
live server ignores it with a warn, so it cannot convert a production match server — but it is a
testing switch and should be turned off deliberately, not discovered later.

Test it in Redwater by setting `Config.TUTORIAL_FORCE_MODE = true`
(`ServerScriptService.RoundSystem.Config`) and pressing Play; the flag is honoured only in
Studio / non-live and the whole lesson runs with no Bounty dispatch. Five deliberate deviations
from this spec, found against live code during the build:

1. **The zone DOES burn bots in live code** (§4.10/§5.3 claimed `_applyZoneDamage` iterates
   players only — stale). The bot half of the damage loop is now guarded on `State.tutorialMode`,
   which delivers the property the spec assumed.
2. **The four-outcome funnel terminal (§7) is unimplementable** — Roblox backfills skipped steps,
   so a "LeftGame" terminal above "Completed" would mark completion for exactly the players who
   quit. Step 12 ("Completed Training") fires only on genuine completion; the other outcomes ride
   the `TutorialRun` aggregate's CF02 (value = seconds, CF03 = `T<timeouts>|S<exitStep>`).
   Per-step durations are NOT packed into the aggregate — any per-step string field would explode
   the 8,000-combination budget constraint 4 warns about.
3. **The grandfather rule skips profiles with `Attempts > 0`** — §5.1's ordering note contradicted
   §9's "crash-out gets one more try": a crash-out accrues TotalPlaytime and would have been
   grandfathered into never seeing the tutorial again. Dispatched profiles are governed by the
   `Attempts < 2` rule alone.
4. **The hard ceiling pays the bonus** and writes Completed — it is a backstop for a stuck
   machine, not a player failure; telemetry still separates it (outcome "Ceiling").
5. **§4.3's "THIS MATCH reads 3 kills" is arithmetically stale** against §4.1's own count — step
   7's five executes credit through `_creditPlayerKill`, so the panel reads 8 by step 10. Left
   as-is; the panel shows the truth.

Written 2026-08-04; bounty step added the same day (§4.1).
**Working name:** Training (player-facing) / `Tutorial` (code).

> **Start at §4.5 if you are picking this up cold.** The bot side of the lesson — peaceful bots,
> standing still, confinement, authored walks, spawning to a spot, despawning, and a gentler difficulty
> tier for step 11 — is already written and in the live place. It supersedes the `SetTutorialPlan`
> sketch in §5.4 and §8, and it changed the choreography in §4 (step 7 is now a five-bot line, step 11
> is `Training` rather than `Easy`). Nothing else has been built.
>
> **Then read §4.6 and §4.7 before writing any tutorial UI.** The touch buttons were rebuilt on
> 2026-08-08 into one bottom-right cluster and three of them lost their labels, which changed the
> banner copy (decision 19); §4.7 is how a step points at a button, and it rules out the two approaches
> most likely to be tried first.

**Revised 2026-08-07, again 2026-08-08, again 2026-08-09** — the last of those is the map: the
tutorial's spawn point and facing are now captured from a live playtest, and the fire wall is
deliberately *shown* rather than skipped (decisions 21 and 22, measured in §5.3).

Four things shipped after the first draft and each
invalidated part of it:

| Shipped | What it broke here |
|---|---|
| **Mobile auto-fire** (Hotfix 10, resized in Hotfix 11) | Touch players now fire by holding the crosshair on an enemy. The single most important mobile shooting mechanic went untaught, and step 3's gate ("3 shots fired") could pass without the player doing anything. |
| **The bounty list rebuilt as portrait cards** (Hotfix 8) | It moved from a text list at the upper-left to a row of 3D portraits at **top-centre under the match timer** — exactly the slot §5.5 gave the tutorial banner. §4.1's "the panel is upper-left, so they do not collide" was inverted. |
| **The stats menu rebuilt** (Hotfix 11) | New styling, a dim backdrop, a close button, and per-match counters that reset each round. It is also the subject of the new step 10. |
| **The touch cluster rebuilt** (2026-08-08) | Five buttons now share one bottom-right cluster — **SPRINT moved off the left edge**, and **JUMP and RELOAD are new**. All five are now **icon-only**, so every banner line naming a touch button described a word that is not on screen. Two of the glyphs are also indistinguishable in a sentence, which is what makes the glow (§4.7) a dependency rather than a polish item. See **§4.6**. |

The lesson is now **eleven steps, ten on touch** (was ten / nine). Revised sections are marked
**[revised 2026-08-07]**; unmarked sections were re-read and still hold.

> **Read this first.** Every claim below about existing code came from the Obsidian vaults
> (`LocalBounty/`, `LocalRedwaterCanyon/`), which are documentation, **not** the source of truth.
> Before implementing any integration point, re-read the live script over MCP (`get_script_source`).
> Line counts, function names and remote names may have moved.

---

## 1. Goal

A player joining **Bounty** for the first time never sees the menu. They are sent to a **private,
one-human Redwater server** where they play a ~2-minute guided fight as **Dust** against bots that
teach the kit one button at a time, then return to Bounty and queue normally.

**Why it is worth building:** `HunterAbilityIntroClient` already exists precisely because "new players
press PLAY and land in Redwater with no idea what their hunter does" — but a 2-4 word tag above a HUD
icon is a reminder, not a lesson, and it competes with a live match that is already shooting at them.
The tutorial is the same problem solved with the one thing a real match can never give: **time and no
opponents**.

---

## 2. Decisions taken

| # | Decision | Chosen |
|---|---|---|
| 1 | Bounty entry | Brief welcome card (~4s or press), then auto-teleport. Small **skip for now** link. |
| 2 | Round mode | **Tutorial flag on RoundController** (`State.tutorialMode`), plus a new `TutorialDirector` that owns the lesson. Not a separate place, not a separate controller. |
| 3 | Pacing | **Gated on the player performing the action**, with a per-step timeout that auto-advances. |
| 4 | Rewards | **One flat Cash bonus** on completion via `Wallet`. No RP, quests, daily streak, battle-pass XP, or `MatchesPlayed`. |
| 5 | Exit | **Always-visible EXIT TRAINING button**, live from the first frame of the tutorial HUD, on every device. |
| 6 | PC mouse | The **hold-Alt to free the cursor** mechanic is taught as its own gated step (PC only). |
| 7 | Bonus | **250 Cash.** A quarter of the 1000-Cash default skin price — reads as a real reward without moving the economy. |
| 8 | Replay | **None for now.** `BonusPaid` already guards the reward, so adding a replay entry later is a button and a remote, not a rework. |
| 9 | Confinement | **Fixed `TutorialSpawn` + bots leashed to ~60 studs. No boundary.** A wanderer finds an empty canyon and comes back; nothing new is authored into a streamed place. |
| 10 | Sprint | **Folded into step 2**, which now gates on sprinting rather than on distance walked. Still 9 steps — 10 since decision 13, 11 since decision 15. |
| 11 | Friend-join message | **Leave it.** Saying *"your friend is in training"* needs the tutorial server to publish a marker, which cuts against the fail-closed invisibility in §5.2. |
| 12 | `TotalPlaytime` | **Counts.** It is real time in the experience — with the ordering constraint in §5.1. |
| 13 | Bounty lesson | **A tenth step, after the ultimate.** The demonstration bounty sits on a **bot**, marked through the real `registerBotKill` path. Pays nothing. **Amended 2026-08-09:** the player's own bounty was to arrive as a *consequence* of claiming it — it no longer arrives at all, because steps 6+7 already mark them mid-ultimate. See §4.1. |
| 14 | Mobile auto-fire | **Taught, inside step 3.** The step-3 dummy carries the `AimAssistTarget` tag, so a touch player who puts the crosshair on it watches the revolver fire itself. Touch copy changes; PC copy does not. See §4.2. |
| 15 | Stats panel | **A new step 10**, in the existing zero-bot lull between `FreeMouse` and `LiveFire`. Gates on the panel actually opening. Eleven steps, **ten on touch**. See §4.3. |
| 16 | Banner position | **Below the bounty card row**, in the slot `RoundStatusGui.PhaseAnnounce` occupies, with phase announcements suppressed in tutorial mode so the two never share it. The old slot under the timer belongs to the bounty cards now. See §5.5. |
| 17 | Bot roster | **All four hunters, mixed** — not the all-Dust roster decision 13 assumed. The step 8 bounty bot is **Vesper**. This supersedes "Dust, `Easy`" everywhere in §4's choreography. See §4.4. |

| 18 | Step 8's bounty bot | **It comes to the player.** The bot still spawns behind cover — the through-the-wall highlight is still the first thing seen — but then walks to the player and waits there to be claimed, rather than sitting behind its rock waiting to be found. Taken 2026-08-08; **supersedes the "go and look" framing throughout §4.1.** |
| 19 | Naming touch buttons | **Never by label — by colour, glyph or position.** Three of the five cluster buttons carry no text at all, so "tap **SPRINT**" names a word the player cannot find. Forced by the 2026-08-08 cluster rebuild, not chosen. See §4.6. |
| 20 | Showing which button | **A rim glow on the target widget, plus a pulsing keycap in the banner for PC-only keys. No blur, no scrim.** Blur is a Lighting post-process and cannot dim a GUI at all (§4.7). A dim scrim *would* work and is recorded there as the deferred fallback, but it darkens the world during the steps that need it most. Taken 2026-08-08. |
| 21 | Where the tutorial happens | **The centre of the existing map — `TutorialSpawn` at `(-69.44, 9.00, -257.44)`, facing yaw −119.82°.** Captured from a live playtest on 2026-08-09, position *and* facing. Not a quiet corner and not new geometry: the middle of the arena is the one place the fire wall cannot reach inside the tutorial's lifetime. See §5.3. |
| 22 | The fire wall | **Shown on purpose, and never named.** It opens already at phase 2's target (±337.5 studs) and closes to the final ±112.5 over **~90s — timed to land as step 11 opens** — **centred on `TutorialSpawn`** rather than on the randomised match centre. The player watches it move and learns the map has an edge; no banner, no copy, no phase label ever mentions it. Taken 2026-08-09; **supersedes both the `ZoneService.startZone()` skip row and the earlier "runs exactly as a normal match" version of this decision.** See §5.3. |

| 23 | Where the player is standing | **At or near `TutorialSpawn` for the whole lesson.** Nothing in steps 1-8 asks them to advance: step 6's two bots walk to them and hold at ~35-42 studs, step 8's Vesper walks to them, and both the step 3 dummies and the step 7 line are engaged from the spawn. This **resolves both open placement conflicts** — step 7 locks all five and step 8's cover holds — and replaces them with one measured number: a **~22-stud drift envelope** (§4.1). Taken 2026-08-09. |

Decisions 5 and 6 were added after the first four; they are requirements, not options.
Decisions 7-12 resolved the original open-questions list. Decision 13 was added on 2026-08-04.
**Decisions 14-16 were added on 2026-08-07 and were forced rather than chosen** — each is a response
to something that shipped after the first draft (see the header table), not a change of mind.
**Decision 17 was taken the same day** and is the one that *was* a free choice.

---

## 3. Player-facing flow

```
  first join
      |
  [BOUNTY]  profile loads -> Tutorial.Completed == false -> welcome card
      |         "WELCOME TO BULLETS AND BOUNTY  /  Learn the ropes in a quick
      |          training match."   [ START TRAINING ]   skip for now
      |
      |  ~4s auto, or press. Skip -> normal lobby, never asked again.
      v
  [REDWATER]  reserved server, 1 human, no directory entry, no zone, no RP
      |
      |   11 gated steps (10 on touch), ~120-190s
      |   EXIT TRAINING available throughout
      v
  [BOUNTY]  "TRAINING COMPLETE  +250 Cash"  -> normal lobby, PLAY highlighted
```

---

## 4. The lesson — **[revised 2026-08-07]**

Eleven steps. Each shows one instruction line in the tutorial banner, waits for the player to actually
do the thing, plays a confirm beat (tick + banner flash), then advances. **Every step also has a
timeout (default 15s) that auto-advances** so a confused player is never trapped — that timeout is
the entire reason gating is safe.

| # | Step id | Banner copy (PC) | Banner copy (Touch) | Advances on | Timeout |
|---|---|---|---|---|---|
| 1 | `Look` | Move the mouse to look around | Drag the right side of the screen to look | camera yaw+pitch delta > 60° cumulative | 12s |
| 2 | `Move` | **W A S D** to move — hold **SHIFT** to sprint | Use the stick to move — tap the **glowing** button to sprint | sprint activated | 12s |
| 3 | `Shoot` | Click to fire — you have 6 shots | Put the crosshair on the target — your gun fires itself | 3 shots fired | 15s |
| 4 | `Dash` | **Q** — dash and reload in one move | Tap **Q icon** — dash and reload in one move | 1 dash | 15s |
| 5 | `Fan` | **E** — fan the hammer for rapid fire | Tap **E icon** — fan the hammer for rapid fire | 1 activation | 15s |
| 6 | `FirstBlood` | Take them down | Take them down | 2 bot kills | 30s |
| 7 | `Ult` | **F** — Dead Eye. Lock on, then fire | Tap **F icon** — Dead Eye. Lock on, then fire | HighNoon fired | 20s |
| 8 | `Bounty` | That one has a **bounty** — you can see it through the rock. Claim it. | *(same)* | the marked bot is killed by the player | 30s |
| 9 | `FreeMouse` | Hold **ALT** to free your cursor — that is how you reach settings | *(skipped)* | LeftAlt or RightAlt held | 12s |
| 10 | `Stats` | **M** — your stats and the scoreboard. Hold **ALT** to click around it. | Tap **STATS**, top right | the stats panel opens | 15s |
| 11 | `LiveFire` | They shoot back now. Good luck. | They shoot back now. Good luck. | timer only | 30s |

**Step 9 is skipped outright on touch** — not shown, no timeout, no elapsed time. `SettingsController`
skips the Alt mechanic entirely on touch devices, so teaching it there would be a lie. Step 10 is the
only other step whose copy differs by more than a verb, and it is shown on both.

**Step 8 opens with a ~3s lead-in line** — *"Three kills without dying puts a bounty on your head."* —
which is then replaced by the instruction line in the table. Same `StepLabel`, a timed text swap, no
new instances. **The 30s timeout starts when the instruction line appears**, not when the lead-in does,
or the lesson eats a tenth of its own budget explaining itself.

**Copy rules.** Steps 4/5/7 name what the button *does* before what it is called, matching the
existing `Manifest.Abilities.Slots[].Tag` convention (`DASH + RELOAD`, `RAPID FIRE`,
`LOCK ON, THEN FIRE`). Do not restate the ability's proper name in the banner; the HUD tag already
carries it. Step 3's touch line follows the same rule for the opposite reason — it names the
*behaviour* ("your gun fires itself") because auto-fire has no button to name (§4.2).

**Sprint is two different verbs and one trap.** `SprintController` binds PC to **hold LeftShift**;
touch is a **toggle** driven by `HunterMobileSprintButton` (`SetMobileSprinting` /
`ToggleMobileSprint`) — hence "hold SHIFT" versus "tap". Step 2 gates on sprint *activating*,
not on distance, so a player who only walks is timed out rather than passed.

> **The touch half of this line was rewritten twice on 2026-08-08 and the reason is not cosmetic.**
> The sprint button no longer says SPRINT — it is a **running-figure glyph on a dark slate circle** —
> and it is no longer above the movement thumbstick. It moved into the bottom-right cluster with every
> other action verb (§4.6), so the copy must not say "on the left".
>
> It then could not name the glyph either: **JUMP sits directly beside it and is also a human figure**,
> so "the runner button" picks out two adjacent buttons. The line therefore points at the **glow**
> (decision 20), which is the only unambiguous handle. That makes step 2 the one step whose copy has a
> hard dependency on §4.7 shipping — see the note there. Do not restore either earlier wording from
> memory of playing the game.

> **Trap:** `SprintController.SetCanSprintCheck(fn)` lets each hunter gate sprint on "alive **and
> round active**". Tutorial mode skips the normal countdown/activation path, so if `State.roundActive`
> is never set true, sprint is dead for the entire session and step 2 can only ever time out. Tutorial
> mode must still raise that flag — see §5.3.

**Bot choreography**

| Steps | Bots | Behaviour |
|---|---|---|
| 1–5 | **3 immortal target dummies — the authored `workspace.Dummy` prop, not bots** (§4.2). Was 1 killable dummy, then 3 `StandDown` bots, both superseded 2026-08-09 | Anchored range targets already in the map at `MaxHealth` 1e9. They do not move, turn, shoot or die, and they are outside `BotService` entirely. **They must be tagged `AimAssistTarget` by hand** — nothing tags them today. Retired when step 6's two bots arrive |
| 6–7 | 2 bots — **Dust + Fortuna**, `Easy` | `HoldFire` + leashed ~60 studs to `TutorialSpawn` — they walk, path and take damage, but never fire and never use abilities. **They spawn out of sight 111 studs out and walk in to where the middle dummy stood — authored positions and the `HoldAtEnd = false` trap in §4.8** |
| 7 | those 2 retired; **5 `StandDown` bots in a line** for the High Noon showcase | `StandDown` + `HoldFire`. They stand still and are executed by the ultimate. **Positions authored in §4.9**, which also carries the measured standoff rule (≥20 studs). Engaged from `TutorialSpawn` (decision 23), where all five lock at 15.6° worst angle. §4.5 has the three constraints behind it |
| 8 | **1 Vesper bot, `Easy`, at `TutorialBountySpawn` = step 6's entry point `(41.243, 11.496, -249.344)`** (2026-08-09), marked | `HoldFire`, and **`SetApproach(record, player)` — it walks out from behind its cover to the player and waits there** (decision 18, 2026-08-08). It is no longer leashed to its anchor and the player is no longer asked to go and find it |
| 9–10 | 0 | — |
| 11 | 3 bots — **Bram + Fortuna + Vesper**, **`Training`** (not `Easy` — see §4.5) | Normal combat at the `Training` tier. **No authored position — the ordinary round spawn pool, by omitting `Position` from the spec (§4.10)**, which puts them 4–412 studs out and half of them inside the fire wall |

All four hunters appear, and **no Dust bot is alive during step 11** — deliberate, see §4.4.

`HoldFire` bots still *move*, which is the point: a stationary bot teaches nothing about leading a
target, and a bot shooting back during the ability steps drowns the lesson. The steps that want
stillness — the step 7 line; **and the step 3 dummies until 2026-08-09, which are now authored props
rather than bots (§4.2)** — use `StandDown` instead, which is a separate and
stronger state (§4.5).

**Ultimate charge** is set directly, not multiplied: on entering step 7, `TutorialDirector` calls
`UltimateChargeService:Set(player, MaxCharge)` — the service already exposes `:Set`, so no charge-rate
override, no new config knob, and the HUD charge ring animates to full on its own.

### 4.1 The bounty step (8) — **[revised 2026-08-07; the bot now comes to the player, 2026-08-08]**

> **Decision 18 changes this step's shape, and several paragraphs below still argue the old one.**
> The bot spawns behind cover exactly as described — the gold `Highlight` reading through terrain is
> still the first thing the player sees, and the anchor requirements below are unchanged, because a
> bot that starts in the open has nothing to demonstrate. What changed is what happens next: it
> **walks to the player** (`BotService.SetApproach`, §4.5) instead of holding position to be found.
>
> So: the ~15-stud leash is gone (approach overrides movement entirely and would fight a leash), and
> the 30s timeout is now generous rather than tight, since the player is not being asked to travel.
> **The step still gates on the same thing — the marked bot dying to the player.** Everything below
> about `registerBotKill`, the highlight, the bounty card, the claim feedback and the guards is
> unaffected. Read "the player finds it" as "it arrives" and the section holds. (**The payoff was in
> that list until 2026-08-09** — it is now deleted outright, for an unrelated reason: see *"The player
> never becomes the bounty"* below.)
>
> Why: relying on a new player to notice a glow behind a rock and walk to it was the step's biggest
> failure risk, and §7 already flagged its timeout rate as the one number to watch on day one. Having
> the bot deliver itself removes the risk without weakening the lesson — the through-wall highlight,
> the gold card and the claim all still happen.

**What it teaches:** three kills without dying marks you, a marked target is visible **through terrain**,
and killing one pays. All three land in one ~25s beat with no new systems.

**Why the demo is on a bot.** `Config.BOUNTY_KILL_THRESHOLD` is 3, and a lesson about a gold outline
behind a rock has to be shown from the outside — you cannot see your own. This was always the reason;
since 2026-08-09 it is also the *only* way the player meets a bounty, because they are never marked
themselves (below).

**Marking the bot uses the production path, not a new API.** `placeBounty` is module-local; the only
public way in is `BountyService.registerBotKill(record, character)`, which increments that record's
streak and places the bounty itself once the streak hits the threshold. So `TutorialDirector` calls it
**three times** on the freshly spawned bot. `registerBotKill` is precisely what
`BotController:RecordKill` calls to advance a bot's streak — the kill-feed remote and the stat writes
sit outside it, in `RecordKill` — so three calls emit the bounty and nothing else, and cannot
double-count against anything, because a tutorial bot never records a real kill.

**The see-through effect is already built and needs no tutorial-specific work.** `placeBounty` parents a
`Highlight` named `BountyHighlight` to the rig: `FillColor` 255,170,0, `OutlineColor` 255,85,0,
`FillTransparency` 0.7, and **`DepthMode = AlwaysOnTop`** — that last property *is* the through-walls
effect. Bots get the identical highlight on their `workspace.ArenaBots` rig.

**Which means the anchor is the whole design.** `TutorialBountySpawn` must sit ~35-45 studs from
`TutorialSpawn` **with terrain or geometry directly between the two**, or the step demonstrates
nothing — a gold outline in the open is just a gold outline. Verify once at author time with a raycast
from the player's eye height at `TutorialSpawn` to the anchor: it must **hit**. Two authored points, no
new geometry, consistent with decision 9. If the cover happens to be streamed out client-side the
highlight still draws, so the failure is a weaker lesson, never a broken one.

**`TutorialBountySpawn` = step 6's entry point, `(41.243, 11.496, -249.344)` — [decided 2026-08-09].**
One anchor serves both steps. Measured consequences:

| | Value | Against the spec above |
|---|---|---|
| Distance from `TutorialSpawn` | **111.0 studs** | the ~35–45 band is missed by a long way — but decision 18 retired that requirement when the bot started walking to the player |
| Cover from `TutorialSpawn` | ray **HITS `workspace.Lumber.Lumber.Part`** | **passes** the raycast test verbatim |
| Vesper's walk in | ~6.9s to `TutorialSpawn`, ~4.3s to the step 7 line | comfortable inside the 30s timeout |

> **Resolved 2026-08-09 by decision 23 — the cover holds, because the player is still at the spawn.**
> The version of this note that stood open for a few hours assumed step 7 left the player standing at
> the firing line, 59-69 studs out with nothing between them and the anchor. **The premise was wrong:
> nothing in steps 1-8 asks the player to walk anywhere.** Step 6's bots come to them and hold at
> ~35-42 studs, step 8's Vesper is on `SetApproach`, and both the dummies and the step 7 line are
> engaged from where they spawned. So the measurement that governs is the one from `TutorialSpawn`,
> where the ray **HITS** the lumber — and the through-terrain lesson survives intact.

**How far they may drift before it stops being true — measured, not assumed [2026-08-09].** Decision 23
is a claim about player behaviour, so it is worth knowing its tolerance rather than trusting it. Ray to
the anchor's torso from sample points walking away from the spawn:

| Drift from `TutorialSpawn` | Ray to `TutorialBountySpawn` |
|---|---|
| 0 studs (the spawn itself) | **BLOCKED by `Lumber.Lumber.Part`** at 38.0 of 111.0 |
| +10 | **BLOCKED** at 34.2 of 102.3 |
| +20 | **BLOCKED** at 30.6 of 94.0 |
| **+25** | **CLEAR at 89.9 — cover lost** |
| +55 (the step 7 line itself) | CLEAR at 69.2 |

Sampled toward the step 7 line and again toward step 6's arrival; both break between **+20 and +25**.
**Call the envelope ~22 studs.** It is the tightest constraint the lesson has on where the player
stands — step 7 tolerates 33 (§4.9) — so if any step ever needs the player moved, this is the number
it has to clear.

**Two steps push against it, and they are the ones to watch in the first playtest.** Step 2 gates on
*sprint activating* rather than on distance, so it can be satisfied in a fraction of a second — but a
new player who holds the key keeps running, and nothing brings them back. Step 3's dummies sit 37-46
studs out (§4.2), which is far enough that a player may close on them rather than shoot from where they
stand. Neither is a defect and neither is worth pre-emptively engineering around; **if the funnel or a
playtest shows step 8's outline reading in the open, drift is the first suspect, not the anchor.**

**The money half is delivered by a panel that is already on screen — and that panel got much better at
this job in Hotfix 8.** `publishBountySnapshot` puts the bot on `BountyListGui`, which since 2026-08-05
is no longer a text list at the upper-left but **a row of up to three portrait cards at top-centre,
flush under the match timer** (`Canvas` at `{0.5, 0}, {0, 60}`, size `{0.34, 0}, {0.175, 0}` — 17.5% of
viewport height on every device). The card carries a live 3D portrait of the hunter and skin the holder
is actually wearing, their name above it, and the duration-scaled cash below. It is empty for the entire
rest of the tutorial, so the card animating in *is* the "bounties are worth something" beat, with no new
copy and no new UI.

**The rebuild made the lesson land harder, and this is worth exploiting rather than merely surviving.**
The portrait ring is `(255, 170, 0)` — deliberately the exact `Highlight.FillColor` that `BountyService`
puts on the target's body. So the gold circle at the top of the screen and the gold figure glowing
through the rock are, visibly, the same colour on purpose. That is precisely the association step 8
exists to teach, and it is now authored into the UI rather than left to the player to infer. The
`BOUNTY` stamp across the portrait names the concept in the game's own word, so the banner does not
have to.

**The number is small and must stay that way.** `BOUNTY_BASE_CASH` 10 plus `BOUNTY_TIME_SCALE_CASH`
0.5/s puts it near **$15** by the time the player reaches the bot. **Do not backdate the bounty start
to inflate it.** A number on that panel has to be a number the real game can produce, and the
alternative is teaching new players to expect a payout that does not exist.

**The bounty bot is a Vesper, and that is what makes the card legible** (decision 17). For a bot the
portrait spec is read off `BotConfig.HunterBehavior[<hunter>].DefaultCharacter`, so the hunter the bot
wears *is* the picture on the card. A Dust bounty bot would render a Dust card at a player who is
themselves Dust — and the problem is not only the "is that *me*?" first read. **Players and bots share
one bounty list**, so the panel's real sequence across this step is:

1. step 8 opens — one card → *the bot*
2. the claim — that card reads CLAIMED, shakes red, clears
3. ~~moments later — a new card → **the player**~~ · ~~step 11 — that card sits there while three bots
   come hunting~~ — **struck 2026-08-09.** The player is never marked (see *"The player never becomes
   the bounty"* below), so the row is empty from the claim onward and steps 9–11 run with no card at all

**One leg of the Vesper argument died with steps 3 and 4 of that sequence; the rest stands.** The
original case leant hardest on the state change *you took theirs, now you are wearing one* rendering, on
two Dust cards, as a card that looked identical before and after — and that comparison no longer
happens at all. What survives is the **first read**: the player is Dust, and a Dust portrait at the top
of the screen the first time they ever see this panel invites *"is that me?"* from someone who has not
been told they cannot be marked. The name cannot carry that distinction on its own: `fitName`
clamps to 12 codepoints and the name band is `0.00–0.19` of a card in a row that is 17.5% of viewport
height, so it is roughly **12px on a 360px-tall phone** — the smallest element on the card, against a
portrait that is the largest.

**Vesper also happens to be the cheapest kill in the roster**, which suits a step that is on a 30s
timer and asks the player to *find* something first: `HunterBehavior.Vesper.MaxHealth` is **125**
against Dust/Fortuna's 150 and Bram's 225, so at the revolver's 35 body damage she dies in **4 body
shots or 2 headshots** — inside one cylinder, with no reload between finding her and claiming her.

**Claim feedback — and the trap.** The obvious script to reason from is wrong twice over:
`BountyClient`, which would show *"KillerName killed the bounty VictimName!"*, is **`Enabled = false` in
the live place**, and even when it ran it deliberately skipped the local killer. What actually fires on
the claim is `CombatFeedClient`'s **TOOK DOWN** row, `BountyListClient` setting the card's amount to
**CLAIMED** and shaking its name red for ~1.2s before the card clears,
`BountyMusicClient`'s claim stinger, and `CombatTextClient`'s `bounty_claim` popup off
`ProgressionService.fireCombatReward`. That is enough; the step's own confirm beat carries the rest.
**Do not add a fifth path.**

**One accepted wrinkle:** that popup shows the real reward — roughly *+70 XP, +$15* — for money the
tutorial never pays, because `awardBountyKill` still runs and `fireCombatReward` reports what
`addRewards` banked. This is already true of every kill popup in step 6, and it is arguably the honest
reading — *this is what the shot is worth in a real match* — with the flat 250 on the completion card
being a separate thing. If that trade is not wanted, the fix is to route the tutorial's claim through
`fireCombatReward(player, "bounty_claim", 0, 0)` and accept a popup with no number on it. Decide once;
do not leave the two paths disagreeing.

**The player never becomes the bounty — [decided 2026-08-09, reversing the payoff this section used to
end on].** Step 6 credits 2 kills and step 7's High Noon executes 5 more, so the player crosses
`BOUNTY_KILL_THRESHOLD` 3 **in the middle of the ultimate showcase**: the gold outline goes on, the
"BOUNTY ON YOU!" popup fires and `BountyMusicClient` switches tracks — one full step before the lesson
has said what a bounty is. Step 8 then opens by pointing at a *bot* and calling it the marked one, at a
player who is already glowing. That is the confusion, and it cannot be reordered away: 7 kills do not
fit under a threshold of 3.

**The guard is one early-return in `BountyService.registerKill` when `State.tutorialMode`.** That
function is the player-only door — it is the only caller that reaches the module-local
`registerTargetKill` with a Player — so **step 8 is untouched and still works exactly as described
above**: `registerBotKill` is a separate public function, still marks the bot on three calls, and
`claimBounty` still pays out on the claim. Guarding `registerTargetKill` itself instead would kill the
step this whole section exists for.

What this costs, recorded so it is not re-added later as an improvement:

- **The old payoff is gone.** `BotService:_creditPlayerKill` runs `claimBounty(killer, record)` and
  *then* `bounty.registerKill(killer)`, so the claiming kill used to mark the player in the same
  instant — *you took theirs, now you are wearing one* — and they walked into step 11 wearing the gold
  outline while three bots came hunting. It read well and cost nothing to arrange. It is deleted anyway,
  because it can only ever fire **after** the mid-step-7 marking that reaches the player first; keeping
  it would mean keeping the thing that confuses them.
- **The one-shot banner beat goes with it** — *"Now they're hunting you."*, fired on `BountyPlaced`
  naming the local player. There is no longer an event to hang it on.
- **Step 11's framing is plainer.** "They shoot back now" stands on its own; the player is not marked.
- **`QuestEvents "becomeBounty"` and `BattlePassService.onBecomeBounty` become unreachable for the
  player.** Keep both guards below anyway — they are module doors, one line each, and the surrounding
  code still runs for the bot.

The step 3 dummies are now defended twice over: they are immortal (§4.2) **and** the player's streak
cannot move. Keep both — they defend different things. Immortality is also what keeps step 5 supplied
with something to fan at, and this guard also covers the 7 kills from steps 6 and 7 that no dummy rule
ever touched.

**Guards — this is a correction to §5.3.** The bounty path never touches `RoundController`, so
suppressing quest and battle-pass writes at *its* call sites does not cover it. A player killing a bot
runs `_creditPlayerKill` → `ProgressionService.awardKill` → `BountyService.claimBounty` →
`awardBountyKill` → **`BattlePassService.onBountyClaim`**, plus `QuestEvents.track(killer,
"bountyClaim")`, and then `registerKill` → `notifyBountyPlaced` → **`QuestEvents "becomeBounty"`** and
**`BattlePassService.onBecomeBounty`**. This is already true of step 6's two kills — the bounty step
only makes it obvious. Put the guard on the two module doors instead of a dozen call sites:

- `QuestEvents.track` — early-return when `State.tutorialMode`. One line, covers every quest emission in
  the tutorial including the ones step 6 already fires.
- `BattlePassService`'s combat entry points (`onBountyClaim`, `onBecomeBounty`, `onBountyTakenDown`, and
  whatever `awardKill` reaches) — same guard.

Those are the only writes that reach the profile. Everything else is discarded, for a reason worth
stating explicitly rather than inheriting: `addRewards` **banks instead of crediting only while
`State.roundActive` is true**, tutorial mode sets that flag (§5.3), and `flushPendingRewards` is
skipped — so the bounty's ~$15 and ~70 XP are never written. **With `roundActive` false, `addRewards`
credits the wallet immediately** — the same flag that makes sprint work is what keeps tutorial kills out
of the economy (and `_creditPlayerKill` early-returns on it, so the kills would not even register).
Call `ProgressionService.clearPendingRewards(player)` at tutorial end anyway: it exists, it is one line,
and it makes "the tutorial pays nothing but the flat 250" a fact instead of a consequence of two other
decisions holding.

`RoundStatsService`'s bounty counters need no guard — they feed the `MatchEnd` telemetry aggregate that
tutorial mode never emits. **`BountyService` used to be unchanged; as of 2026-08-09 it takes exactly one
edit** — the `State.tutorialMode` early-return in `registerKill` above. Nothing else in it moves.

---

### 4.2 Mobile auto-fire, inside step 3 — **[new 2026-08-07]**

Since Hotfix 10 a touch player does not really shoot by tapping **FIRE**: they shoot by putting the
crosshair on an enemy and leaving it there. `MobileAutoFireController` pulls the trigger on its own
whenever `AimAssistController:GetLock()` reports a held target, and since Hotfix 11 each hunter's lock
is sized to that hunter's own server hit radius (Dust 3.5 studs), so it fires across the whole band
where the shot would actually score. **This is now the first thing a touch player needs to understand
about the gun, and the original step 3 did not mention it.**

**The dummy must be tagged, and the tag is the whole mechanism.** `AimAssistController`'s acquire loop
walks `Players:GetPlayers()` plus `CollectionService:GetTagged("AimAssistTarget")` — nothing else is
targetable.

> **Superseded 2026-08-09 — the dummy is an authored prop, and the tagging is NOT done.** What follows
> was written on 2026-08-08, when the plan was `SpawnBot({ Hunter = "Dust", StandDown = true, … })` and
> the tag came free because `BotController` tags every bot `AimAssistTarget` on spawn. The map already
> contains purpose-built immortal range targets (`workspace.Dummy`, surveyed below), so the bot path is
> dropped — **and with it the free tag.** Tagging is now a manual `CollectionService:AddTag` on each
> `Dummy`, and it is the single thing this whole section depends on. The two requirements below still
> apply verbatim; only the rig they apply to changed.

**Superseded, kept for the requirements:** `BotController` tags every bot `AimAssistTarget` on spawn and
removes it on destroy, and a bot rig always has a live Humanoid. So `SpawnBot({ Hunter = "Dust",
Position = …, StandDown = true, HoldFire = true })` *was* the dummy this section describes — no separate
rig path, no manual tag, no `BotSpawner2`. Requirements that still apply:

- place it inside the lock's reach: comfortably under `MaxRange` 350, at a normal fighting distance
  (~20-30 studs) so the 3.5-stud lock subtends an angle a shaky thumb can hold
- do **not** give it a `BotId` / `IsBotVisual` attribute — those route acquisition through
  `buildBotVisualMap` to a rendered clone. (A `SpawnBot` bot does not carry these, so this is a warning
  against adding them, not something to undo)

#### There are three dummies, not one — authored 2026-08-09

Captured from a live playtest by standing on each spot. **The reason is discoverability, not
difficulty:** the player is free to wander from step 1 (decision 9 authors no boundary), so a single
dummy is a single thing to miss. Three spread across the forward arc means a camera sweep finds one.

| # | Ground position | From `TutorialSpawn` | Bearing off the spawn heading | Backstop |
|---|---|---|---|---|
| 1 | `(-76.31, 10.71, -220.60)` | 37.5 studs | **70.7° right** | terrain 10.7 studs behind |
| 2 | `(-30.27, 10.00, -234.35)` | 45.5 studs | **0.7° — dead ahead** | terrain 28.0 studs behind |
| 3 | `(-37.31, 6.87, -283.71)` | 41.5 studs | **69.1° left** | terrain 149.6 studs behind |

One centred and one ~70° to each side, 48–74 studs apart. All three have **clear line of sight** from
the spawn's eye height (verified by raycast — this is the inverse of step 8's requirement, and it is
the one thing that must not be traded away when nudging these) and all three sit **inside the 60-stud
leash**, so they do not argue with decision 9's confinement.

**The y values above are ground, not root** — the captures were `HumanoidRootPart` positions (ground + 3
for a player rig) and are converted here. **Revised 2026-08-09 with the prop:** the earlier note about
`SpawnBot`'s default 4-stud lift no longer applies, because these are not spawned bots. The `Dummy`
model is a **3.0 × 5.4 × 4.0** stud prop standing on its own base, so place it with `PivotTo` and solve
the foot offset once against its authored pivot rather than inheriting a bot's lift — measure it, do not
assume 0 (`project_rig_pivot_foot_offset`: a pivot dropped exactly onto a floor buries the rig by an
amount that differs per model).

**Face each one at the player.** The rig is anchored and never turns, so its authored rotation is
permanent and one placed carelessly shows the player its back — or worse, the blank reverse of its
`Target` board. `CFrame.lookAt(pos, Vector3.new(-69.444, pos.Y, -257.437))` — level, aimed at
`TutorialSpawn` — gives yaws of **−10.6° / +59.5° / +129.3°**.

**The dummies are immortal, and they are not bots — the prop already exists in the map** (decided
2026-08-09, replacing the *"killing any one despawns all three"* rule written earlier the same day; the
prop was found the same afternoon, replacing a plan to spawn `StandDown` bots and make them immortal
with a `ForceField`). They take hits, flash, and give the shooter a hitmarker, but their health never
moves and none of them can be killed. All three stand from step 3 until step 6 retires them.

**What exists — surveyed live on 2026-08-09.** Seven models named **`Dummy`** sit at `workspace` root.
Each is a shooting-range target: a legless R15 rig named `TargetDummy` (Humanoid, HumanoidRootPart,
torso, arms, head) mounted on a stand of four Parts and two Unions, plus a `Target` UnionOperation
board. Bounding box **3.0 × 5.4 × 4.0** studs.

| Property | Live value | What it means here |
|---|---|---|
| `Humanoid.MaxHealth` / `.Health` | **1,000,000,000** | already immortal — no ForceField, no new code, and nothing to add |
| `HumanoidRootPart.Anchored` | `true` | stands where it is put; no physics, no `StandDown` state to enforce |
| CollectionService tags | **none** | **`AimAssistTarget` must be added** — this is the one real gap, and §4.2's whole mobile lesson depends on it |
| `ModelStreamingMode` | `Default` | **must become `Persistent`** or a client can arrive with the target streamed out |
| Position | six clustered at Y 19–36, Z −173 to −215; one outlier at (1075, 323, −527) | **79–125 studs from `TutorialSpawn`, and 10–27 studs above it** — far outside the authored positions above |

**Immortality is already true and needs nothing built.** At 1e9 HP against the revolver's 35, the
player would need ~28.6 million body shots. `didKill` can never be reached, so no kill-feed row, no
kill credit, no bounty streak, and no interaction with `BotService` at all — the dummies are outside
the bot system entirely, which is cleaner than the bot plan this replaces. The `ForceField` approach
that was written here first is **not needed** and is recorded only so it is not re-derived: it would
have been correct for a bot, and it is redundant for a rig that was authored immortal.

**Shooting one works end to end — checked, not assumed.** `RevolverModule`'s hit resolution accepts
**any** model with a live Humanoid (`hitModel ~= character and hitHumanoid.Health > 0`); there is no
player-or-bot filter, so a `TargetDummy` takes `damageService:ApplyDamage` and runs the hit pipeline
like anything else. `HunterHitPipeline:Register` is called *after* damage is applied and its
presentation half is unconditional — red flash, damage direction, `HitConfirm` (the hitmarker) and the
ultimate-charge award all fire whether or not health visibly moved. **Auto-fire works too once tagged:**
`AimAssistController` requires only `humanoid.Health > 0` and filters on nothing else.

**The one thing to watch in playtest is the health bar.** `_sendHealthBarReveal` reveals the target's
bar to the shooter on every hit and it will read full every time — at 1e9 HP, 35 damage does not move a
pixel. The hitmarker and the red flash are what actually carry step 3; if playtest says a frozen bar
reads as *"I am missing"*, the fix is to lower `MaxHealth` to something a cylinder cannot clear (say
2000, ~57 body shots) rather than to make the rig killable.

#### The three tutorial dummies are BUILT — 2026-08-09

`ServerStorage.TutorialDummies` holds **`TutorialDummy1` / `2` / `3`**: clones of the map's `Dummy`
prop, each placed at one authored position, tagged, and set `Persistent`. The map's original seven are
untouched. They live in `ServerStorage` on purpose — **the fail-safe window the bot plan had is back**,
because an instance that is not in `workspace` cannot be tagged-and-forgotten into a live match.

| Built | Value |
|---|---|
| Position | bbox centre on the authored XZ, **base on the terrain** — sink measured at 0.004 / 0.000 / 0.006 studs |
| Facing | rig yaw **−10.6° / +59.5° / +129.3°**, facing error to `TutorialSpawn` **0.00°** on all three |
| Tilt | **removed** — the source prop sits on a slope and carried 0.05 of pitch; the clones are level |
| Distance from spawn | 37.5 / 45.5 / 41.5 studs, matching the table above |
| Line of sight | **clear** from the spawn's eye height to each rig's `UpperTorso`, re-verified after placement |
| Tag | `AimAssistTarget` on the inner **`TargetDummy`**, and it survives `:Clone()` |
| Streaming | `Persistent` on both the wrapper and the rig; also survives `:Clone()` |
| Live `AimAssistTarget` instances inside `workspace` | **0** — the check that keeps ordinary matches clean |

**The tag goes on `TargetDummy`, not on the `Dummy` wrapper.** `AimAssistController:_evaluateCharacter`
does `character:FindFirstChildOfClass("Humanoid")` on the tagged instance itself, so tagging the wrapper
acquires nothing and fails silently — the exact shape of bug §4.2 exists to prevent.

**Orientation was taken from the rig, not from the model pivot.** They differ by **60.03°** on the
source prop, and the model pivot is tilted where it stands, so `PivotTo` with a `lookAt` built off the
pivot would have pointed the rig 60° away from the player. The build computes a rigid transform from
the `HumanoidRootPart`'s current CFrame to the desired level one and applies it to the whole model,
then translates the bounding box onto the ground. `Humanoid.HealthDisplayType` is already `AlwaysOff`
on this prop, so the frozen 1e9 health bar the section above worried about **never renders**.

**Placement is still open, and the distances are the reason.** The clones sit where the captures put
them; the map's original six sit 79–125 studs out and up to 27 studs overhead, further outside the
20–30 band than these are. Moving any of the three is a `PivotTo` on the template and nothing else.

**They are outside the bot system, so two earlier warnings do not apply.** No `SpawnBot`, no
`StandDown`, no `Despawn`, no `SetPopulationLocked` interaction, and no death watch — retiring them at
step 6 is a `Parent`/`Enabled` change or a move, not a despawn. High Noon's `SpawnProtected` skip is
also irrelevant: a 1e9-HP rig left standing into step 7 **would** be locked by Dead Eye and survive it,
so retiring them at step 6 still matters, but for a plainer reason than the ForceField version had.

**Damage dealt is still logged.** `Register` runs `RoundStatsService.RegisterDamage` before any of the
presentation and clamps to `OldHealth`, which never falls — so every shot into a dummy books its full
damage against the player's match stats. Step 10's panel shows kills rather than damage (§4.3), so this
is recorded rather than fixed; revisit it if a damage tile is ever added.

Four things this buys, which is why it replaced the despawn-on-kill version and then the bot version:

- **Step 5 always has something to fan at.** The despawn-on-kill version had a real hole: a Dust bot
  dummy is 150 HP — 5 body shots — while step 3's gate is 3 and the cylinder holds 6, so a player who
  kept firing killed one, cleared the whole set before step 4, and reached the fan step with an empty
  range. At 1e9 HP that is roughly 28.6 million body shots away.
- **No bot machinery at all.** No `SpawnBot`, no `SetPopulationLocked` ordering, no `Despawn`, no
  per-bot record to hold, and nothing for `Reconcile` to fight. Step 3 stops being a bot problem.
- **The bounty streak cannot move.** A dummy that cannot die credits no kill, so the three cannot feed
  the player toward `BOUNTY_KILL_THRESHOLD` 3 — the concern the despawn rule existed to solve, now
  solved by construction instead of by a death watch. §4.1's tutorial-mode guard on
  `BountyService.registerKill` covers the same ground from the other end, and both stay.
- **Nothing depends on the director noticing a death.** No `Despawn` cascade, and no window where two
  survivors stand around after the first one drops.

One accepted cost, recorded so it is not re-litigated:

- **All three are 37–46 studs out, none in the 20–30 band above.** At ~41 studs Dust's 3.5-stud lock
  subtends roughly half the angle that band was chosen for, so touch step 3 is harder than the spec
  assumed. Deliberately left: the gate is 3 shots *fired*, the FIRE button always works, and §7 already
  splits step 3's timeout rate by platform — **this is the number that measurement should settle, not
  argument.** Position 3 is also the one whose misses travel 149.6 studs before hitting anything, so it
  is the weakest of the three for miss feedback.

**Step 5 fans whatever step 4 left in the cylinder — the tutorial does not top it up.** Considered and
dropped on 2026-08-09; recorded here so it is not re-proposed. `RevolverSkill2` reads
`shotsToFire = AmmoController:GetAmmo()` at activation, so a two-round cylinder is a two-round fan, and
a player who lets step 4 time out without dashing never gets Quick Draw's refill and can reach step 5
empty. **On empty the fan does not activate at all** — it calls `OnReloadRequested` and returns false —
so that player's first E press starts a 1.5s reload and their second one fans a full six. The step's 15s
timeout covers the case either way. That self-heal, plus the fact that a topped-up cylinder would need
**two** writes to be honest (Dust tracks ammo twice: a client count in `RevolverAmmo` and a server
shadow magazine in `ServerWeaponGuard`, and refilling one without the other makes the fan half-work in
whichever direction the mismatch runs), is why the lesson leaves the revolver alone.

**Open the window on entering step 3 and close it when step 6's bots arrive. This is not tidiness.**
Auto-fire does not know what step it is; a tagged dummy standing in view during step 1 ("move the mouse
to look around") means a touch player sweeps the crosshair across it and the revolver empties itself
before they have been told what the trigger is. Steps 3–5 are the window where a target is wanted —
step 5 fans the hammer and needs something to fan at — and from step 6 the bots carry their own tag the
same way.

**With the authored prop the window is the tag itself, which is a step backwards in safety and needs
saying out loud — [revised 2026-08-09].** The bot version controlled the window by spawning and
despawning, and failed safe because a bot that does not exist cannot be locked onto. A persistent prop
cannot fail safe that way: it is standing there during step 1 whether or not the tutorial is ready for
it. So `AddTag` on entering step 3 and `RemoveTag` on entering step 6, and treat the untagged state as
the default the prop ships in — **never leave the tag on in the authored place**, or every ordinary
match gets an auto-fire magnet in the canyon. If the prop is also being parented in and out, do that
too; belt and braces is cheap here and the failure is silent.

**The gate does not change: 3 shots fired.** On touch those three may all be auto-fired, and that is
the correct pass condition rather than a loophole — "the gun went off three times because you held the
crosshair on it" *is* the lesson. The FIRE button still exists and still works; a touch player who taps
it passes the same step the same way.

**One robustness case: `AutoFireEnabled` can be off.** Clients read it as a player attribute where
**absent means ON** — the attribute only exists once the settings payload lands, and the default is
true, so a brand-new account entering a tutorial has auto-fire on either way. But the setting is real
(`AutoFireRow` in `ReworkedSettingsGui`, touch-only), so read the attribute when step 3 opens and fall
back to a fire-button line when it is explicitly `false`. Do not force the setting on; a tutorial that
overrides a player's own choice teaches them the choice does not work.

> **The fallback line changed on 2026-08-08.** It used to read *"Tap FIRE — you have 6 shots"*. There
> is no longer a button that says FIRE — it is a muzzle-flash glyph, and it is the **only red button**
> in the bottom-right cluster (§4.6, decision 19). Use **"Tap the red button — you have 6 shots"**.
> Colour is the right handle here rather than the glyph: it survives an icon swap, and red is unique
> in that cluster by design.

### 4.3 The stats step (10) — **[new 2026-08-07]**

**What it teaches:** that the panel exists, how to open it on this device, and that it holds both your
own numbers and the scoreboard. `M` on PC, the **STATS** button top-right on touch.

**Why it sits at 10.** Steps 9 and 10 are the only zero-bot lull in the lesson, and the panel dims the
whole scene behind a full-screen backdrop that also swallows clicks — teaching it while anything is
shooting would put the player behind a dim, unable to fire, in a fight. By step 10 the numbers are also
real: two kills from step 6 and the bounty claim from step 8 mean **THIS MATCH** reads 3 kills rather
than a wall of zeroes, which is the difference between showing a panel and showing a panel that means
something.

**Why it must come *after* step 9 on PC, and this is the load-bearing part.** Verified on 2026-08-07:
every `GuiButton` under `StatMenuGui` has `Modal = false`, and nothing in `StatMenuScript` writes
`UserInputService.MouseBehavior`. Dust's `FPSRevolverClient` holds `MouseBehavior = LockCenter` with
`CameraMode = LockFirstPerson`, and PlayerModule's `CameraUtils` re-forces `LockCenter` every frame for
as long as that camera mode is held — the reason `SettingsController` has to take the camera
`Scriptable` before it can free the cursor at all. **So on PC the stats panel opens with the cursor
pinned to screen centre: the Scoreboard tab and the close button cannot be clicked.** `M` closes it;
the hold-Alt mechanic from step 9 is the only way to reach inside it. Teaching `M` before `Alt` hands
the player a panel they cannot operate — hence the second clause in the PC copy, *"Hold **ALT** to click
around it."* Touch is unaffected: touch input reaches `GuiButton`s directly, and `MobileStatsButton`
sits at `ZIndex 10` above the backdrop specifically so it doubles as a way out.

**Gate on the panel, not on the key.** Watch
`StatMenuGui.Backdrop:GetPropertyChangedSignal("Visible")` — `setOpen` assigns `backdrop.Visible = open`
synchronously in both directions, so it tracks the real state exactly. Do **not** listen for the M
keypress or the button's `Activated`: that is the same trap §5.4 already calls out for sprint, and it
passes the step for a keypress the panel ignored. `MainFrame.Visible` is the wrong property for the
same reason in reverse — it stays true through the close tween. `_G.ToggleStatMenu` is exported but it
is a *setter*; it can close the panel, it cannot observe it.

**Close it on the way out.** When step 10 completes or times out, if the panel is still open, call
`_G.ToggleStatMenu()` before step 11 begins. This is the one legitimate use of that export — otherwise
"they shoot back now, good luck" is delivered to a player sitting behind a dim backdrop that eats their
first shot.

**Two things step 10 must not promise.** The Scoreboard tab will show exactly **one row** in a
tutorial: `populateScoreboard` reads `Players:GetPlayers()` and bots never appear on it, so a
one-human reserved server is a board of one. The copy says "your stats and the scoreboard", which is
honest; anything implying a leaderboard full of names is not. And the panel **pulls on open and never
again**, repainting only when the server pushes `StatsResponse` — see §5.3 for the round-start push
that tutorial mode has to keep.

### 4.4 The bot roster — **[new 2026-08-07]**

Decision 17: **all four hunters appear**, rather than the all-Dust roster the first draft assumed.
`BotConfig.EnabledHunters` is already `{ Dust, Fortuna, Vesper, Bram }`, so this is a per-bot choice in
the tutorial's own spec, not a config unlock — and because the plan names hunters explicitly it bypasses
the `HunterWeights` draw and the `HunterCaps` ceiling entirely (`Vesper = 2`, never approached here:
one at step 8, one at step 11, never concurrent).

| Where | Hunter(s) | Why there |
|---|---|---|
| ~~step 3 dummy~~ | — | **Removed from this roster 2026-08-09.** The step 3 dummies are not bots at all now — they are the authored `workspace.Dummy` range props (§4.2), so they draw no hunter, occupy no bot slot and never touch `HunterCaps` or `HunterWeights` |
| step 7 line | any — 5 bots | Added 2026-08-08. They exist to be executed by High Noon, so the hunters are a free choice; mixing them makes the ultimate's reach read more clearly than five identical rigs. `StandDown`, so they hold the line (§4.5) |
| steps 6–7 | **Dust + Fortuna** | Both 150 HP — 5 body shots each, a matched pair, so the player's first two kills cost the same and the step's 30s budget is predictable. A Dust bot here is *useful*: it shows that other people play your hunter, in the one step with no card on screen to confuse it with |
| step 8 | **Vesper** | Distinct portrait, and 125 HP is the fastest kill in the roster (§4.1) |
| step 11 | **Bram + Fortuna + Vesper**, at the **`Training`** tier | Bram's 225 HP is a *demonstration* here rather than an obstacle, because this step has no kill requirement. **No Dust bot** — the player's own gold card is on the panel throughout step 11, and keeping every enemy a hunter they are not means that card stays unambiguously theirs to the end of the lesson. **`Easy` was wrong and would have one-shot the player**: Vesper's headshot is 125 and Bram's near headshot 100 against a player's 100 max health, and no difficulty tier changed damage until `Training` added one (§4.5) |

**Call it `HoldFire`, not `Passive` — the name is taken.** `BotController:629` already runs
`HunterMovement.SetBase(model, "Passive", self.Behavior.WalkSpeed, HunterMovement.Priority.Passive)`:
"Passive" is the **movement base-speed layer key** in the service that owns every bot's `WalkSpeed`.
A second `Passive` in the same file, meaning "does not attack", is a collision waiting to mislead
someone reading either one — especially since the AI flag deliberately leaves movement alone, so the
two would be adjacent, similarly named and opposite in scope. `HoldFire` says what it does and claims
nothing about movement.

**It is one flag, not four — verified 2026-08-07.** The mix does not multiply the bot work,
because bot AI is **not** per-hunter code. There is one `BotBrain`, one `BotCombat` and one
`BotController`; hunter differences are branches *inside* those shared modules, keyed on
`self.Controller.Hunter`. Aggression leaves the brain through exactly **two calls**:

- `BotBrain:708` → `BotCombat:FireAt(target, options)` — all shooting, every hunter
- `BotBrain:715` → `BotCombat:ThinkAbility(target, distance)` — all abilities, every hunter

An early-return at the top of those two disarms all four hunters at once. **`TryUltimate()` is called
from inside `ThinkAbility`** (line 2033), so bot ultimates are covered for free — worth stating, since
an ultimate is the worst thing a supposedly passive bot could do during a lesson.

**And it covers Vesper's perch, which was the thing worth checking.** Her grapple is cast from inside
`ThinkAbility` (`_bestVesperHookSpot` → `Controller:GrappleToSpot`, lines 2132-2141), not from separate
movement logic. The perch *lifecycle* does live in the brain — `BotBrain:_updateVesperPerch` /
`_evictVesperPerch` — but both early-return unless `BotSniperPerchUntil` / `BotSniperPerchPosition` are
set, and those attributes are only written once she has actually hooked onto a spot. Block the cast and
the whole perch state machine is inert rather than half-running. So no Vesper-specific work is needed;
the concern that motivated checking turned out to be unfounded.

One implementation detail that follows from the same reading: `ThinkAbility` calls `FireAt` itself from
inside ability branches (Dust's fan, Fortuna's burst) in `task.spawn`ed loops. The veto must sit at the
**top of `FireAt`**, not only at the brain's call site, so a burst already in flight is stopped shot by
shot rather than running to completion.

**What `HoldFire` deliberately does not touch is movement** — these bots must still walk, or the lesson
teaches nothing about leading a target (§4). Confinement is the **leash's** job, and it is a separate
mechanism that has to hold independently. That matters most for step 8: Vesper's `DesiredRange = 150`
and `DetectionRange = 850` are a standoff instinct three times the distance the anchor is authored for,
so the ~15-stud leash has to beat her range preference even with every ability disarmed.

> **This advice was taken — `HoldFire` was built on 2026-08-08 and playtested, and the rest of the bot
> control layer grew from it. See §4.5 for what exists. The reasoning below is kept because it is why
> the layer is shaped the way it is, and it held up: the one-flag claim survived contact.**

**`HoldFire` is separable from the tutorial and should probably be built first.** It has no dependency
on `State.tutorialMode`, `TutorialDirector`, the reserved-server transport, the profile field or any of
the UI — the only thing the tutorial contributes is *who sets the flag*. Default it off and the change
is a no-op in production, which makes it shippable on its own in any release.

Three reasons to take it separately rather than as part of the tutorial build:

- **It is independently useful right now.** A bot that walks, paths and takes damage but never shoots
  back is the ideal target for verifying the mobile auto-fire work, whose per-hunter lock sizing is
  still pending a manual playtest. Measuring whether the crosshair acquires and the gun fires is far
  easier against something that does not kill you mid-measurement, and it exercises all four hunters'
  lock radii against a moving target rather than a static dummy.
- **It de-risks the tutorial's least-verified claim.** §4.4's central assertion — that one flag disarms
  all four hunters, ultimates and Vesper's grapple included — was established by *reading* the call
  graph, and MCP playtesting is unavailable here. Building `HoldFire` on its own means that assumption
  gets tested in a real playtest before a ten-step lesson is resting on it. If it turns out some branch
  reaches `FireAt` by a path the veto misses, finding that out now costs an afternoon; finding it out
  during a tutorial playtest costs a day of misattribution.
- **It matches the existing bot-state idiom, so it needs no new plumbing.** Bot cross-module state is
  already carried on model attributes — `BotUltimateActive`, `BotBrainActive`, `BotSniperPerchUntil`,
  `BotFightBackUntil`, `BotEscapeHookFrom`. `ThinkAbility` itself already reads
  `Model:GetAttribute("BotUltimateActive")` on its own hot path. A `BotHoldFire` model attribute
  therefore costs nothing new, can be toggled by hand on a live bot to verify the behaviour, and does
  not require `SetTutorialPlan` to exist yet. `SetTutorialPlan` then just sets the attribute at spawn.

Neither `FireAt` nor `ThinkAbility` is a per-frame call — one is per shot, the other runs on
`AbilityThinkInterval` — so an attribute read in either is genuinely free at this frequency.

**`BotBrain:SetActive(false)` is not a shortcut to this and must not be reused.** It is the
death/despawn path: it stops the step loop outright, calls `Pathing:Stop()`, clears `FacePosition` and
`IsStrafing`, and drops `SetWorldScoped`. That is a frozen bot, not a peaceful one — the opposite of
what steps 6-7 need, where the whole point is a target that walks so the player learns to lead it.
`HoldFire` is a veto on two combat calls; `SetActive` is an off switch for the entire brain.

**Vesper is still the strictest test in the tutorial** — lowest health, longest preferred range, the
only bot with a perch lifecycle at all — so build and verify against her rather than against Dust. The
flag itself is hunter-agnostic; what she tests hardest is the **leash**.

**The one real cost of the mix: Bram cannot be killed with one cylinder,** which is why he is in step 11
and not step 6. At 225 HP
against the revolver's 35 body damage he takes **7 body shots** — one more than the 6-round cylinder — so
a Bram in the first-kill step would force a brand-new player to reload mid-kill, twice, inside a 30s
timeout for two kills. At the falloff floor of 20 damage it is 12 shots, two full cylinders. Step 11 has
no kill requirement, so his bulk reads as "that one is tougher" instead of "why won't this die".

His rig is also physically larger and carries its own `PathAgent` (`AgentRadius 2.55`, `AgentHeight 6.4`)
so pathfinding stops wedging him — fine in step 11's open ground, and another reason not to park him
behind step 8's cover geometry.

---

### 4.5 The bot control layer — **BUILT 2026-08-08**

**This section describes code that exists.** Everything below is in the live Redwater place and
compiles; §4.4's advice to build `HoldFire` first was taken, and the layer grew from there as the
choreography above got specific. It is all **off by default** — no production behaviour changes — and
none of it depends on `TutorialDirector`, `State.tutorialMode` or the transport, so it can be
exercised from the command bar today.

`TutorialDirector` does **not** need to invent bot control. It needs to call these.

**This supersedes the `SetTutorialPlan(count, difficulty, passive)` sketch** in §5.4 and §8. That
signature could not express the roster anyway (§4.4 said as much), and what was built instead is
per-bot from the start: one `SpawnBot` call per bot, each returning the record that every other call
takes. A `SetTutorialPlan` wrapper over these, if wanted, is a loop — not a new system.

#### The two peaceful states

Distinct on purpose, because the lesson needs both:

| State | Moves | Tracks you | Attacks | Used by |
|---|---|---|---|---|
| `HoldFire` | yes | yes | no | steps 6–8 — the bot must walk, or the player never learns to lead a target |
| `StandDown` | no | no | no | the step 7 line — a live, damageable target that does not compete with the instruction on screen. (**It also served the step 3 dummies until 2026-08-09**, which are authored props now — §4.2) |

`StandDown` implies `HoldFire`. Both are model attributes (`BotHoldFire`, `BotStandDown`), stamped at
spawn from the record, so they survive a respawn — a rig-only flag comes back **armed** the first time
the player kills the bot, which would have broken step 6 directly.

`StandDown` is **not** `BotBrain:SetActive(false)`, which §4.4 already warned against: that stops the
step loop, calls `Pathing:Stop()` and drops `SetWorldScoped` — a frozen bot, not a peaceful one. A
stood-down bot is still stepping, so clearing the flag releases it into a normal fight on the next tick.

#### API — `ServerScriptService.Bots.BotService`

Every call takes a record (from `SpawnBot`) or a bot id.

| Call | What it does |
|---|---|
| `SpawnBot(spec)` | Spawns one bot to an authored spec, returning the record. **Names** the hunter, bypassing the `HunterWeights` draw and `HunterCaps` ceiling — which is the behaviour §4.4 wanted. Applies the flags before the controller is built, so a bot meant to stand still never gets a tick of ordinary behaviour |
| `SetHoldFire(t, bool)` / `SetStandDown(t, bool)` | Toggle the two states on a live bot |
| `SetLeash(t, anchor, radius)` | Confinement: a flat (XZ) radius around an anchor. The bot walks, chases and fights normally inside it. This is decision 9's leash |
| `SetRoute(t, waypoints, options)` | Choreography: an authored walk. Waypoints may be Vector3s, BaseParts, or **a folder of BaseParts** |
| `SetApproach(t, subject, stopDistance)` | Sends a bot **to a player** and keeps it there (~12 studs by default). This is step 8 (decision 18). Tracks the subject rather than a fixed spot, and overrides `DesiredRange` — mutually exclusive with `SetRoute` |
| `SetDifficulty(t, tierName)` | Per-bot difficulty. Applies on the bot's **next spawn** |
| `Despawn(t, reason)` | Removes a bot outright — no kill credited, no death recorded, no ragdoll |
| `DespawnAfter(t, seconds)` | The AFK case: the player never killed it, move on |
| `SetPopulationLocked(bool)` | Stops `Reconcile`. **Required** whenever the director owns the roster |

`spec` = `{ Hunter, Position, HeightOffset, Difficulty, HoldFire, StandDown, Name, Leash = { Anchor,
Radius }, Route, RouteOptions }`. `Position` takes a Vector3, CFrame or BasePart and is lifted 4 studs
by default — the same offset the ordinary spawn path uses, because a rig pivoted exactly onto an
authored floor part stands buried to the ankles by an amount that differs per hunter. `HeightOffset = 0`
places a CFrame exactly.

**`SetPopulationLocked(true)` is not optional.** `MinBots` is a floor, so an ordinary round refills a
despawned slot within a second and retires spawned bots to hit its target. Call it once when the
tutorial starts.

#### Six things that will bite a fresh session

1. **`SetPopulationLocked` first, `SpawnBot` second.** Otherwise `Reconcile` fights you.
2. **`SetDifficulty` applies on the next spawn**, not immediately — `BotController` resolves its tier
   table once at construction and hands the same table to the brain and to combat. Pass `Difficulty`
   in the `SpawnBot` spec instead of setting it after.
3. **Routes are lists, so they live on the record, not an attribute**, and are re-applied by
   `_spawnController` on respawn. The two flags and the leash *are* attributes and are hand-togglable
   in the Explorer on a live rig — useful for verifying behaviour without any director.
4. **A route's default `HoldAtEnd` sets `BotStandDown`** when the last waypoint lands. Pass
   `HoldAtEnd = false` to hand the bot back to ordinary behaviour, which combined with a leash is
   "walk here, then mill about". **For step 8 use `SetApproach`, not a route** — a route walks to a
   fixed spot and would arrive where the player no longer is.
5. **The leash is enforced in `BotPathing:RequestMove`**, the single door every destination goes
   through, *and* separately in `DirectMove` — Dust's combat strafe bypasses `RequestMove` entirely and
   aims 100 studs out. Do not add a third clamp at a call site.
6. **Despawn does not credit a death.** `OnDied` fires only from the Humanoid death handler, never
   from `Destroy()`, so a despawned bot pays nobody and records nothing.

#### Step 7's line — the three constraints

Verified against `HighNoonTargeting` on 2026-08-08:

- **`MaxTargets = 6`**, so five bots fit with one to spare.
- **Bodies do not block the lock.** `BuildSightParams` puts *every* rig in the ignore list — the code
  is explicit that being unlockable "must not also make you a wall" — so the line works single-file as
  well as side-by-side. Only map geometry blocks it.
- **Range 180 studs, cone 45°.** A wide line drops its outer bots off the lock if placed too close to
  the player. **Depth is cheaper than width.**

The locked shot is a true execute — a percentage of the victim's `MaxHealth` (100% by default, floor
175), ignoring damage reduction — so all five die regardless of hunter, Bram's 225 included.

One risk raised and cleared: `HighNoonTargeting` skips any rig carrying `SpawnProtected`, which would
be fatal for bots spawned moments before the step. `SpawnProtectionService.grant` is called only for
**players**, from `SpawnService`. Bots never get the attribute, so a freshly spawned line is
immediately lockable.

#### Step 11 is `Training`, not `Easy` — and this was a real defect

**A player rig carries `Humanoid.MaxHealth` 100.** Nothing overrides the authored value for players,
unlike bots, whose `BotController` raises to their `HunterBehavior` figure (Dust/Fortuna 150, Vesper
125, Bram 225). Players are the squishiest thing in the arena.

Against that 100, **Vesper's headshot is 125 and Bram's near headshot is 100 — either one-shots a
full-health player** — and the difficulty table contained *no damage term at all*. `Easy` versus `Hard`
changes reaction time, aim error, range and cadence: how **often** a bot hits, never what a hit costs.
So the first draft's "step 11 bots are `Easy`" would have put a brand-new player in front of two
hunters that one-shot them, on the step whose whole job is a gentle first taste of being shot at.

`BotConfig.Difficulties` therefore gained a `DamageMultiplier` (1 for `Easy`/`Normal`/`Hard`, so they
are unchanged) and a fourth tier below `Easy`:

```lua
Training = {
    ReactionTime = 1.2,   AimErrorDegrees = 11,  AttackRange = 90,
    AbilityUsageChance = 0.08, MovementAggression = 0.32,
    FireRateMultiplier = 0.7,  DamageMultiplier = 0.35,
}
```

0.35 puts Vesper's headshot at 43.75 and Bram's at 35, so **nothing in the roster kills in fewer than
three hits** and no single hit takes half a bar. It is one number to tune: above ~0.53 a Vesper
headshot plus a body shot kills again. `BotCombat` applies it to every damage path including abilities
and ultimates — a bot that cannot kill you with its gun but still slams you for full has not been made
gentler — and Dust's High Noon especially, since that passes a percentage of the victim's max health as
a true execute that would otherwise ignore every other lever. **The player's own High Noon is
unaffected**; it runs through `HighNoonDamage`, which this does not touch.

#### What is still unverified

`HoldFire` was confirmed in a playtest on 2026-08-08: bots walk, path and take damage and never fire.
**`StandDown`, the leash, routes, despawn and the `Training` tier have not been playtested** — the
geometry was verified in isolation (the leash clamp holds its radius exactly and ignores height;
waypoints sort `Point9` → `Point10`, not `Point1`), but nothing has walked a route yet. That is
deliberate: routes and leashes are being left until the match layout exists and the spawn and path
positions are authored, since a route with no authored map to walk is untestable anyway.

---

### 4.6 The touch cluster — **[new 2026-08-08]**

Redwater's mobile combat buttons were rebuilt on 2026-08-08 into a single bottom-right cluster. This
section is the lesson's view of it: what a touch player is actually looking at, and which of this
document's assumptions that changed. It is a **statement of the live layout, verified over MCP** —
not a proposal.

| GUI | Button | Reads as | Height fraction | New? |
|---|---|---|---|---|
| `HunterJumpGui` | `MobileJumpButton` | a **figure with an up-arrow**, dark slate | 0.186 | **new** — replaces Roblox's built-in touch jump button, which cannot be moved or restyled |
| `HunterFireGui` | `MobileFireButton` | a **muzzle-flash starburst** on the cluster's only **red** circle | 0.192 | moved |
| `HunterSprintGui` | `MobileSprintButton` | a **running figure**, dark slate | 0.156 | **moved off the left edge** |
| `HunterReloadGui` | `MobileReloadButton` | a **revolver cylinder in a circular arrow**, dark slate | 0.100 | **new** — mobile had no manual reload at all before this |
| `VesperScopeGui` | `MobileScopeButton` | a scope glyph, dark slate | 0.184 | moved; Vesper only |

All five are `AnchorPoint (1, 1)`, `DisplayOrder 6`, `ScreenInsets = None`, authored `Enabled = false`
and switched on only for touch by their own controllers.

**None of them carries any text.** All five are icon-only — `Text = ""` plus an `Icon` `ImageLabel` at
0.58 of the button's side. JUMP and RELOAD lost their `JUMP` / `RLD` labels on 2026-08-08, after the
rest of the cluster had already gone label-free. **There is now no button in the cluster that can be
named as written**, which is what forces decision 19.

> **And the glyphs are not all distinguishable in a sentence.** SPRINT is a running figure; JUMP is a
> figure with an up-arrow. Both read as "the one with the person on it". Copy that says *"tap the
> runner button"* points at two buttons that sit next to each other, and getting it wrong makes the
> player jump instead of sprint — which does not advance step 2 and looks like the tutorial lying.
> **This is the finding that makes the glow (§4.7) load-bearing rather than a polish item.** Colour
> still separates FIRE (the only red one); nothing separates SPRINT from JUMP in words.

**Positions are resolved at runtime, not authored.** `ReplicatedStorage.Hunters.Shared.HunterMobileClusterLayout.apply(playerGui)`
rewrites every button's `Position` from the live screen size, because each button is sized off screen
**height** while a `UDim2`'s X can only reference **width** — so an authored X scale shears as the
aspect ratio changes. Two rules follow for anything the tutorial adds:

- **Never read a cluster button's authored `Position`** to place something relative to it. The value
  in the data model is the pre-layout one; the rendered position differs on every device and is
  recomputed on every `AbsoluteSize` change.
- **Never author a tutorial element that must clear the cluster by hand-tuned numbers.** The cluster
  already moves as one object under two separate clamps (a pixel `MaxSize` and a width ceiling), and
  a tablet renders it at ~57% of its proportional size. Anything pinned against it by eye will be
  wrong on the first tablet.

#### What this changes for the lesson

1. **Step 2's touch copy** — rewritten, see §4. The glyph and the side of the screen both changed.
2. **Sprint now costs the aiming thumb.** The module's own comment calls this out as a deliberate
   reversal with a real cost: *"sprinting now requires the same thumb as aiming, so sprint-while-turning
   is harder than it was."* Step 1 teaches the player to drag the right side of the screen to look, and
   step 2 immediately asks that same thumb to leave the screen and hit a button. Worth watching in the
   first device playtest — if step 2's touch timeout rate is bad, this ordering is the first suspect,
   and the fix is copy ("tap it, then keep looking"), not a new step.
3. **Step 1's touch copy is now slightly untrue.** *"Drag the right side of the screen to look"* is
   where five buttons live. A drag that starts on one of them is swallowed by the button — and on FIRE
   that means a shot, during the step that is meant to be shooting-free. This is the same hazard §5.4
   already manages by withholding the step 3 dummy until step 3; it is not new, but it got wider.
   Consider *"Drag anywhere on the right to look"* → *"Drag the middle of the screen to look"*.
4. **The left band above the thumbstick is now empty.** This is the one piece of screen the rebuild
   gave back. §5.5's rationale for pinning EXIT TRAINING to the banner listed that band as occupied;
   it no longer is. **The conclusion still stands** — EXIT stays on the banner — but for the remaining
   reasons, not that one. See the corrected paragraph there.
5. **RELOAD and JUMP are untaught mobile verbs.** The lesson teaches dash-reload (step 4) and never
   mentions either button. That is defensible — `HunterAutoReload` covers running dry, and jumping is
   self-evident — but it is now a *decision*, not an omission, because before this rebuild neither
   button existed. If either is added later it belongs folded into step 2, not as a twelfth step.
6. **Check the HUD sweep before the first tutorial playtest.** `RoundClientController` restores these
   GUIs after intermission by name and by the `MobileCombatButton` attribute their controllers set,
   because their authored default is `Enabled = false`. Tutorial mode skips the normal round lifecycle
   (§5.3), so confirm on a touch device that the cluster is actually on screen for the whole lesson —
   a tutorial that hides its own combat buttons fails silently and only on mobile.

---

### 4.7 Showing the player which button — **[new 2026-08-08]**

Decision 19 stops the banner naming a button that has no name. This is the other half: **pointing at
it.** A rim glow on the target widget, and a pulsing keycap in the banner for the keys that have no
widget. Nothing is built yet — `TutorialGui` does not exist — so this is the spec, plus the list of
approaches already ruled out so they are not retried.

#### Blur cannot do this, and the reason is structural

`BlurEffect` is a **Lighting post-process. It blurs the 3D world only.** Every `ScreenGui` renders on
top of it perfectly sharp — including all five buttons. "Blur everything except the button" therefore
inverts into a blurry canyon behind five crisp buttons, which is worse than doing nothing.

Two further reasons not to reach for it: Redwater already has two blur owners in `Lighting`
(`ZoneAtmosphere`'s `ZoneBlur` and `RoundClientController`'s `IntermissionBlur`), so a third would
fight them for the same property; and the steps that most need a cue are the ones that need the world
**visible** — put the crosshair on the dummy (3), take the bots down (6), lock High Noon onto the line
(7), read the bounty outline through the rock (8).

#### The glow, and the traps `UltimateReadyFX` already paid for

`ReplicatedStorage.Hunters.Shared.UltimateReadyFX` is the reference implementation. It is **not a
drop-in** — `.new()` is shape-gated on `UltimateFrame > MainFrame > {Background, ReadyGlow}` and
returns nil otherwise — but its header is a catalogue of dead ends that apply here unchanged:

- **A single `UIShadow` cannot glow.** `Spread` dilates a hard silhouette with essentially no falloff:
  a solid band hugging the edge. Rejected twice, at spread 0.22 and 0.16. Widening it only widens the
  band. The falloff has to be rebuilt by **stacking many filled dilations at graded spread and alpha**
  (~24 layers on the ult tile).
- **Stacking `UIStroke` instead gives concentric rings**, not a glow — a stroke is an outline, so the
  trick that works for glyphs in `TitleStyles.bloom` fails here.
- **A radial glow image behind the widget is occluded by the widget.** Sized to stay contained,
  nothing shows; sized to show, it reaches across the screen.

**The translucency trap applies directly and will not be obvious.** Cluster buttons are authored
`BackgroundTransparency` **0.35** (FIRE) and **0.5** (SPRINT, JUMP, RELOAD, SCOPE). A glow behind a
half-transparent face comes *through* it and reads as sitting **in front of** the glyph — the exact
bug the ult tile hit at 0.45, where `ZIndex` was never the problem and the surface in front of the
glow was simply see-through. The fix there was to give the host an **opaque body while lit**, clipping
the glow to a rim, and restore the authored translucency when it goes out. Do the same, or the first
device screenshot will show a smeared button.

Two conventions inherited from the same module: glow spread is **a fraction of the widget's own side**,
and stroke thickness is **a multiplier on the authored value, never a pixel count** — so the cue scales
with a cluster that is already being resized by two separate clamps.

#### The structure differs by target, because the two hosts differ

This is the detail most likely to cost a session, and it was verified live rather than assumed:

| Host | `ZIndexBehavior` | Consequence for the glow |
|---|---|---|
| `HunterFireGui` / `HunterSprintGui` / `HunterJumpGui` / `HunterReloadGui` / `VesperScopeGui` | **`Global`** | ZIndex sorts across the whole GUI ignoring hierarchy, so a glow **parented inside the button** at a ZIndex below the button's **5** sits behind it — and inherits its position for free |
| `ReworkedHunterGui.ScreenGui` (desktop) / `.HunterGuiMobile` (touch) | **`Sibling`** | A child always draws over its parent; the glow must be a **sibling of the tile face** at a lower ZIndex. This is exactly the authored `ReadyGlow` frame `UltimateReadyFX` drives |

**One glow structure cannot serve both hosts.** Build it per-host, and confirm each by **rendering** —
a screenshot with the glow lit — not by reasoning about the enum. `ZIndexBehavior` is the single
easiest thing in Roblox UI to get backwards, and both readings look plausible on paper.

Position matters on the cluster for a second reason: `HunterMobileClusterLayout` **rewrites every
button's `Position` on every `AbsoluteSize` change**. A glow authored as a fixed-position sibling would
drift off its button on rotation or on a windowed resize; parented to the button, it cannot (§4.6).

**Author the glow as a template and clone it**, per the repeated-rows exception in the UI rules: one
`TutorialGlow` frame with its layer stack authored in `ReplicatedStorage`, cloned onto the target for
the duration of a step and destroyed on the transition. That keeps ~24 stacked layers inspectable in
the Explorer instead of buried in a loop, and it gives teardown one obvious call.

#### What each step can actually point at

| Step | Touch target | PC target |
|---|---|---|
| 1 `Look` | — (a drag) | — (mouse) |
| 2 `Move` | **SPRINT** button | keycap **SHIFT** |
| 3 `Shoot` | — (auto-fire is the lesson; the red FIRE button only in the `AutoFireEnabled = false` fallback) | — (click) |
| 4 `Dash` | **Q ability tile** | same tile |
| 5 `Fan` | **E ability tile** | same tile |
| 6 `FirstBlood` | — | — |
| 7 `Ult` | **F ability tile** | same tile |
| 8 `Bounty` | — (the world target already has `BountyHighlight`) | same |
| 9 `FreeMouse` | *(skipped)* | keycap **ALT** |
| 10 `Stats` | **STATS** button, top right | keycap **M** |
| 11 `LiveFire` | — | — |

**The ability tiles exist on desktop too**, so steps 4/5/7 get one cue on both platforms. Only steps 2
and 10 are touch-only widgets. Everything else is a key, a click or a drag with nothing to light.

> **Do not look for the ability tiles under `StarterGui.HunterGui.*`.** Every hunter's HUD is a runtime
> **clone** of `StarterGui.ReworkedHunterGui` (`ScreenGui` on desktop, `HunterGuiMobile` on touch); the
> older `HunterGui` tree is dead but still looks authoritative in the Explorer.

The glow reaches into `ScreenGui`s the tutorial does not own — the cluster, the HUD clone, `StatMenuGui`.
It must therefore tolerate its target being **absent**: no SCOPE button on a non-Vesper player, no
cluster at all on PC, no HUD clone until the hunter's client runtime has run. A missing target is a
step without a cue, never an error.

> **Step 2 is the exception, and it is a build-order constraint rather than a preference.** Its touch
> copy says *"tap the **glowing** button"*, because after the 2026-08-08 icon pass there is no other
> unambiguous way to name it — SPRINT and JUMP are adjacent and both are human figures (§4.6). So
> **step 2's touch line cannot ship before the glow does.** If §4.7 slips, step 2 falls back to
> *"tap the button with the running figure, second from the corner"* — worse copy, and the reason the
> glow is scheduled first.
>
> The general rule this makes explicit: **copy may only say "glowing" where the target is guaranteed
> to exist.** SPRINT is universal on touch, so step 2 is safe. Never write it for SCOPE (Vesper only)
> or for anything in the HUD clone, which may not have been built yet.

#### The scrim, recorded but not built

A full-screen dim with a rectangular hole over the target is the workable version of "blur everything
else", and it is the fallback if a device playtest shows the glow losing against Redwater's terrain —
a real risk, since that is the background `UltimateReadyFX` was tuned against. Recorded so it is not
re-derived:

- `Active = false` on the scrim, or it swallows every touch. `StatMenuGui`'s backdrop is the inverse
  precedent: it sets `Active = true` **deliberately**, to eat clicks.
- Roblox has no GUI mask, so the hole is **four frames forming a border** around the target rect.
  Prefer that to raising the target's `DisplayOrder` above the scrim — there is then nothing to restore
  if the player exits mid-step, which is the failure the always-live EXIT button makes reachable.
- It must not be on screen during steps 3, 6, 7 or 8.

---

### 4.8 Step 6's two bots walk in — **[authored 2026-08-09]**

Captured from a live playtest by standing on the entry point. The two `HoldFire` bots (Dust + Fortuna,
§4.4) **spawn out of sight and walk to where the middle target dummy was standing** — they are not
placed in front of the player, and they are not spawned where the player is looking.

| | Ground position | From `TutorialSpawn` | Notes |
|---|---|---|---|
| Entry, bot A (left of the walk line) | `(40.525, 10.603, -252.770)` | 110.1 studs | ±3.5 studs perpendicular to the walk line, so the two do not spawn inside each other |
| Entry, bot B (right) | `(41.961, 12.429, -245.918)` | 112.0 studs | |
| Arrive, bot A | `(-30.988, 10.000, -237.776)` | 43.2 studs | `TutorialDummy2`'s spot, split the same way |
| Arrive, bot B | `(-29.552, 10.030, -230.924)` | 47.9 studs | |

The captured centre line runs **(41.243, 11.496, −249.344) → (−30.270, 10.000, −234.350)**: 73.1 studs,
bearing **+25.6° off the spawn heading** at the entry (so it is within a 70° FOV, not behind the
player), over flat terrain the whole way — surface y stays between 10.0 and 10.8 after the first few
studs, and a 12-stud lateral sweep found **zero obstructions across 21 samples**. Nothing needs
smoothing.

**The entry is hidden and the arrival is not — that is the point, not a coincidence.** Raycasting from
the spawn's eye height: the entry point and the first ~60% of the walk are **blocked by
`workspace.Lumber.Lumber.Part`**, and the line is clear from ~75% on. So the player never sees two bots
appear out of nothing at 111 studs; they emerge from behind the lumber pile about 30 studs out, already
walking. **Any re-placement of this entry must keep that property** — a pop-in in open view is what
this position exists to avoid, and it is the one thing the numbers above cannot be nudged past.

**`HoldAtEnd` must be `false`, and this is the trap.** §4.5: *"A route's default `HoldAtEnd` sets
`BotStandDown` when the last waypoint lands."* Left at the default, both bots **freeze on arrival** and
step 6 becomes shooting statues — which contradicts §4's own rule that `HoldFire` bots still move
because *"a stationary bot teaches nothing about leading a target"*. Route them, then let them resume
ordinary passive behaviour.

**The entry sits outside the 60-stud leash, and that is fine.** `BotPathing` clamps *destinations*, not
spawn positions, and both route ends are 43–48 studs from `TutorialSpawn` — inside the sphere — so
nothing is clamped and the bot simply walks inward. Set the leash as §4.4 specifies **alongside** the
route, not instead of it.

Two consequences worth expecting rather than debugging:

- **Fortuna arrives first, by about 1.6s.** `HunterBehavior` WalkSpeed is 24 for Fortuna against Dust's
  16, so 73.1 studs takes ~3.0s and ~4.6s. They will not arrive together and should not be forced to.
- **The walk-in spends 3–5s of step 6's 30s timeout** before the player can engage at close range. They
  are killable the whole way, so a player who spots them early simply starts sooner.
- **They do not stop at the arrival point — they close a little further and hold in front of the
  player** [added 2026-08-09]. With `HoldAtEnd = false` the route hands them back to ordinary behaviour,
  and `BotCombat` computes its standoff as `Behavior.DesiredRange * 0.72`: **Dust 41.8 studs, Fortuna
  34.6**. Against a player still at `TutorialSpawn` (decision 23) the arrival at 43-48 studs is already
  about where they want to be, so they settle at ~35-42 and mill there. **This is what makes decision 23
  true rather than merely hoped for** — the fight comes to the player, so there is nothing to walk
  toward and the ~22-stud drift envelope (§4.1) is never tested by step 6.
- **Every shot in this step is full damage.** `RevolverServerConfig.FalloffStartDistance` is **50**
  studs (falling to `BodyMinDamage` 20 at 200), and the whole engagement happens at 35-48 — inside it.
  So §4.4's "150 HP is 5 body shots each" holds exactly at the distance the step is actually fought,
  which is the assumption its 30s budget rests on. The step 3 dummies (37-46 studs) are inside it too.

**No collision with the dummies.** The three targets are destroyed as step 6 opens (§4.2) and the
nearest bot needs ~3s to reach that spot, so neither bot ever paths into an anchored prop. If the
despawn is ever deferred, this is the thing it breaks.

---

### 4.9 Step 7's firing line — **[authored 2026-08-09]**

Two ends captured from a live playtest; the five `StandDown` bots are spread evenly between them.
**Ends: `(-31.649, 13.871, -215.617)` → `(-17.824, 10.000, -241.222)`** — 29.10 studs, so **7.27 studs
between bots**, comfortably clear of a ~4-stud body.

| # | Ground position | Face yaw (at `TutorialSpawn`) | Ground |
|---|---|---|---|
| 1 | `(-31.649, 13.873, -215.617)` | 42.1° | Terrain |
| 2 | `(-28.193, 12.105, -222.018)` | 49.4° | Terrain |
| 3 | `(-24.736, 10.497, -228.419)` | 57.0° | Terrain |
| 4 | `(-21.280, 10.000, -234.821)` | 64.8° | Terrain |
| 5 | `(-17.824, 10.000, -241.222)` | 72.6° | Terrain |

**Each y is raycast, not interpolated, and that matters here.** The line drops **3.87 studs** end to
end and the ground bows away from a straight lerp by up to **1.44 studs** at bot 3. Lerping the height
would bury the middle of the line to the shins. Re-raycast if either end ever moves.

**The live numbers this is measured against** — `HighNoonServerConfig.Targeting`: `Range = 180`,
`ConeAngle = 45` (a **half**-angle: `IsTargetInsideCone` tests `angle <= ConeAngle`, so the usable cone
is 90° wide), `MaxTargets = 6`. Five bots fit under the cap with one slot spare.

**From `TutorialSpawn` the line is comfortable.** Worst target sits **15.6°** off the aim at **56.4
studs**, line of sight clear to all five, and the line subtends only **30.5°** of arc. Nothing is
marginal.

**But the lock depends on standoff, and §4.5's "depth is cheaper than width" is the whole reason:**

| Player standoff from the line's centre | Worst angle off aim | Result |
|---|---|---|
| 10 studs | 59.0° | **2 of 5 outside the cone** |
| 15 studs | 46.8° | **1 outside** |
| **20 studs** | 38.0° | all five lock |
| 30 studs | 27.0° | all five lock |
| 53 studs (`TutorialSpawn`) | 15.6° | all five lock |

**≥20 studs is the rule.** Below it the ultimate still fires and still executes whatever it caught — it
just stops being the "all five at once" demonstration step 7 exists to be.

> **Resolved 2026-08-09 by decision 23 — the player fires from the spawn, not from the line.** The open
> version of this note assumed step 6 leaves the player standing where its two bots died, ~7 studs from
> this line's centre, where the line subtends 123.1° and only **2 of 5** lock. That is not where they
> are: step 6's bots walk to *them* and hold at ~35-42 studs (`BotCombat`'s standoff is
> `DesiredRange * 0.72` — Dust 41.8, Fortuna 34.6), so the player never advances to the arrival point at
> all. From `TutorialSpawn` this line is the comfortable case measured above: 15.6° worst angle at 56.4
> studs, line of sight clear, **all five lock**.
>
> **Drift tolerance: 33 studs**, from the standoff table — the line's centre is 53.3 studs out and the
> rule is ≥20. That is looser than step 8's ~22-stud cover envelope (§4.1), so **step 8 binds first and
> step 7 is never the step that breaks.** The old advice still stands for the case that never arrives:
> if the player somehow ends up inside their own firing line, move the line or step 6's arrival — **do
> not widen `ConeAngle`**, which is a live combat value.

---

### 4.10 Step 11 uses the ordinary spawn pool — **[decided 2026-08-09]**

Step 11's three bots (Bram + Fortuna + Vesper at `Training`) are **not** authored to a position.
**Omit `Position` from the `SpawnBot` spec** and the record's `SpawnCFrame` stays `nil`, which
`BotService` already handles: `local spawnCFrame = record.SpawnCFrame or self:_spawnPosition()`, over a
field the module documents as *"Authored spawn spot, nil = the ordinary round spawn pool."* No new code,
no new config — the absence of one field is the whole implementation.

What that pool actually is, measured on 2026-08-09: **`workspace.SpawnPoints`, 44 parts, 4 to 412 studs
from `TutorialSpawn`.**

| | Count | Consequence |
|---|---|---|
| Inside the final zone's Z band (−369.9 … −144.9) | **19 of 44** | normal |
| **Outside it** | **25 of 44** | the bot spawns **inside the fire wall** |
| Within 60 studs of `TutorialSpawn` | **1 of 44** | contact is never immediate |
| 120–240 studs | 21 | 7.5–15.0s of walking at WalkSpeed 16 |
| Over 240 studs | 11 | up to **25.8s** at 16, against step 11's **30s** |

**A bot spawning in the fire is cosmetically odd and mechanically harmless.** `_applyZoneDamage`
iterates `Players:GetPlayers()` only, so no bot ever burns (§5.3), and `BotPathing:RequestMove` runs
`clampPositionToSafeZone` before the leash clamp, so its destination is pulled back inside and it walks
out of the wall rather than standing in it. **The ~60-stud leash to `TutorialSpawn` is doing real work
here** and should not be dropped: it is what turns a 240-stud spawn into a walk *toward the player*
rather than a wander.

**The thing to watch is the clock, not the fire.** Step 11 runs 30s and half the pool is 120+ studs
out, so a slow draw can spend a third of the step walking. That is a tuning observation for the first
playtest — if step 11 keeps ending before a fight starts, the answer is a longer step or a filtered
pool, **not** authored positions, which is the thing this decision deliberately avoids.

---

## 5. Architecture

### 5.1 Bounty — detection and dispatch

**Profile field.** Add to the `PlayerData_v2` template in **both** places' `DataService`
(the templates must stay byte-aligned — see DataService's own note on `Settings.AbilityDescriptions`).
`:Reconcile()` backfills it; **do not bump `DATA_VERSION`** — adding a key is Reconcile-safe, and a
schema bump is one-way and wipes every account.

```lua
Tutorial = {
    Completed = false,   -- finished, skipped, or grandfathered
    Skipped   = false,   -- pressed "skip for now"
    BonusPaid = false,   -- the flat Cash award is once per account, ever
    Attempts  = 0,       -- incremented on dispatch; >= 2 stops auto-sending
    StartedAt = 0,
    CompletedAt = 0,
}
```

**Grandfather rule — this is the one that will break live players if it is missed.** `:Reconcile()`
adds `Tutorial` to *every existing profile*, so without a guard the entire live player base gets
teleported into a tutorial on their next join. On profile load, before anything reads the flag:

```
if not Tutorial.Completed
   and (MatchesPlayed > 0 or TotalPlaytime > 0 or Level > 1 or XP > 0)
then Tutorial.Completed = true end   -- silent, no card, no teleport
```

Four signals rather than one because each has a hole on its own: `MatchesPlayed` only started being
written when Telemetry landed, `TotalPlaytime` accumulates on leave (a crash loses it), and `Level` is
a cache of `XP`.

**Dispatch conditions — all must hold:**
- `Tutorial.Completed == false` and `Tutorial.Attempts < 2`
- profile loaded successfully (never dispatch on a failed/absent profile)
- the player is not arriving from Redwater (`GetJoinData().TeleportData` is nil / carries no
  `groupId`) — a returning player must never be re-dispatched
- the player is not in a party and did not arrive via a friend/follow join

**New module: `Bounty ServerScriptService.Onboarding.TutorialDispatchService`**
1. On profile load, evaluate the conditions; if met, fire `TutorialInvite` to that client.
2. On `TutorialInviteResponse("start")` — or after the client's 4s auto-timer — reserve a server and
   teleport. On `("skip")`, write `Skipped = true, Completed = true`, save, and do nothing else.
3. Reserving is **its own path, not `MatchmakingService.chooseDestination`.** Add
   `MatchmakingService.reserveTutorialServer()`: calls `TeleportService:ReserveServer` exactly as the
   normal path does, writes the `privateServerId -> accessCode` pair into `RedwaterAccessCodes_v1`
   **with `tutorial = true` alongside it**, and — critically — **writes no provisional entry into the
   match directory sorted map.** A tutorial server must be invisible to matchmaking from before it
   boots.
3a. **Tutorial time counts toward `TotalPlaytime`** (decision 12) — it is real time in the experience,
   and `DataService` accumulates it on leave with no special case needed. But that makes the
   grandfather rule in §5.1 **self-satisfying**, so ordering is load-bearing: `Tutorial.Completed`
   must be written before the leave-time playtime accrual. Otherwise a player who crashes out
   mid-tutorial comes back with `TotalPlaytime > 0`, is grandfathered as a veteran, and never sees
   the tutorial again — silently, and only for the players whose connection dropped.
4. Teleport with `TeleportOptions.ReservedServerAccessCode` plus teleport data:
   `{ tutorial = true, redwaterAccessCode = code, characterSelections = { [userId] = Dust/Default } }`.
   No `groupId`, no `members` — a tutorial player is not a party.
5. Increment `Tutorial.Attempts` and stamp `StartedAt` **before** `TeleportAsync`, so a player who
   crashes out of two tutorials in a row stops being sent to a third.

**Welcome card UI.** Authored instances under `StarterGui` (`TutorialWelcomeGui`), per the UI rules —
no `Instance.new` construction. `ScreenInsets = None`, full-screen backdrop, one panel with title,
one body line, a primary `START TRAINING` button (min 44×44px touch target) and a small
`skip for now` text button. The 4s auto-advance is a client timer on a visible progress sliver so it
does not feel like a hang.

**The card must wait for `BountyIntroComplete`, and the 4s timer must start when the card appears —
[added 2026-08-09].** Bounty opens on a cinematic `ReplicatedFirst.LoadingScreen` (753 lines) that
**seizes the camera before anything that can yield** and holds it every frame until the reveal:
`MIN_HOLD_TIME` 1.5s, `MAX_HOLD_TIME` 6s, then a sky shot (`MIN_SKY_TIME` 1.2), a 1.75s pan, a 0.45s
veil fade and a 0.25s handoff hold. §5.1 fires `TutorialInvite` on **profile load**, which will
routinely beat all of that. Left alone, the card is shown behind the veil, **its 4s auto-timer expires
unseen, and a first-time player is teleported into Redwater having never been told what is happening**
— the single worst first impression the feature could produce, and it would reproduce most reliably on
fast connections.

**The signal already exists and is a house convention, not something to invent.**
`LoadingScreen` sets `ReplicatedStorage:SetAttribute("BountyIntroComplete", true)` and **eight scripts
already gate on it** — `LobbySpawn`, `SettingsController`, `MenuHandlerScript`, `CurrencyHudController`,
`DailyLoginController`, `FriendsInMatchClient`, `MultiplierDisplayClient` and `GiftPopupClient`.
**Copy `GiftPopupClient`**, whose header states this exact requirement for the gift popup: *"Hold the
gift until the frontier is fully 'in': the loading screen + intro camera pan have finished … so the
gift never opens over the loading screen or mid-pan. The wait is capped at 25s so the gift still shows
if the attribute never lands."* Same shape, same cap.

Three details that make this safe rather than merely conventional:

- **It is set on both exit paths**, the normal reveal *and* the watchdog abort that fires when
  `CameraFolder` never resolves. So a broken intro still releases the card rather than stranding a new
  player behind a dead loading screen. Keep `GiftPopupClient`'s timeout anyway as the third line.
- **It is client-side only.** A LocalScript writes it, so the attribute never reaches the server and
  `TutorialDispatchService` cannot read it. **The gate belongs in the welcome card's controller, not in
  the dispatch service** — the server fires `TutorialInvite` whenever the profile lands, and the client
  holds it. Do not try to delay the server side.
- **The menu is enabled behind the card.** `LoadingScreen` restores `mainMenuGui.Enabled` at handoff,
  so decision 1's *"never sees the menu"* is delivered by the card's full-screen backdrop and
  `DisplayOrder`, not by the menu being absent. Author it to cover.

**Return leg.** On arrival back in Bounty with `TeleportData.tutorialComplete`, show
`TutorialCompleteGui` — "TRAINING COMPLETE / +N Cash" — and pulse the PLAY button once. Do **not**
auto-queue them.

### 5.2 Transport — how Redwater learns it is a tutorial server, and fails closed

This is the highest-risk part of the design, because getting it wrong routes a real party into a
one-player tutorial.

`MatchDirectoryService` publishes on an 8s heartbeat and also on `PlayerAdded`. A reserved tutorial
server has a real `PrivateServerId`, so **by default it would advertise itself** in the window between
booting and the first arrival's teleport data being read.

**Two independent signals, mirroring the access-code pattern the migration already uses:**
1. **The `RedwaterAccessCodes_v1` hash map entry**, read at boot against `game.PrivateServerId`
   (which a server *can* read, unlike its access code). Bounty writes `tutorial = true` there before
   the teleport is issued, so the flag is available before anyone arrives.
2. **The first arrival's `TeleportData.tutorial`**, as backup.

**And the publish must fail closed.** `MatchDirectoryService` gains a third state: it does not publish
while the mode is **unresolved**, and only begins publishing once it has resolved to
`tutorialMode == false`. A tutorial server therefore never writes an entry at all, and a normal server
delays its first publish by one MemoryStore read. Cost: a fraction of a second on a server that has no
players yet anyway. Benefit: the failure mode is "one server advertises a moment late" instead of
"a party lands in someone's tutorial".

Set `State.tutorialMode` (in `RoundSystem.State`) as soon as it resolves; everything downstream reads
that one field.

### 5.3 Redwater — RoundController branches — **[revised 2026-08-07; the map and the fire wall, 2026-08-09]**

`RoundController` is ~1562 lines and drives far more than a timer. In tutorial mode it must skip:

| Skip | Why |
|---|---|
| minimum-player wait / countdown loop | one human, start immediately |
| `SpawnService.teleportAllToRoundSpawns` | tutorial uses one fixed authored spawn |
| `MatchDirectoryService` publishing | §5.2 — handled at the source |
| `ProgressionService.flushPendingRewards` / `awardRoundCompletion` | no XP/Cash from bot kills |
| `RankedService.awardRound()` | no RP |
| `DailyRewardService.registerPlay()` | not a real match |
| `QuestEvents` emissions | not a real match |
| Battle-pass XP | not a real match |
| `Telemetry` `MatchStart` / `MatchEnd` and the combat aggregates | would poison per-match averages with a bot-only, non-standard-length round |
| **`Telemetry.logFunnelStep` — the `MatchLoop` funnel** | **Added 2026-08-09; this row was missing and the omission was not obvious.** It is a *different* funnel from the `tryLogFunnelStep` row below: `RoundController` fires MatchLoop steps **1 and 3 on join (lines 185-227), 4 at round start (line 312) and 5 at the buzzer (line 1760)**, none of which went through `tryLogFunnelStep` and so none of which that row covers. Left alone, every tutorial emits a complete "Match Requested → Reached Buzzer" journey for something that is not a match, inflating exactly the conversion rate the funnel exists to measure. **Less damaging than the onboarding funnel** — MatchLoop is recurring, so this is dilution rather than the once-ever destruction §7 describes — but it is the same argument the `MatchStart` row above already accepted. Suppressing it also drops the tutorial's event budget from 19 to 15 (§7) |
| `tryLogFunnelStep(4..7)` | see §7 — the tutorial gets its own funnel |
| `BountyService.awardSurvivorBonuses()` | it pays every player holding a bounty at the buzzer — a SPREE BONUS popup and a `bountyTime` quest track for a round in which nothing else was paid. **Its original rationale (the player ends the tutorial still marked) died on 2026-08-09; the skip did not** — the guard in §4.1 stops the player being marked, and skipping this is what keeps that a fact rather than a dependency on one guard holding. `resetAll()` at round start stays — it clears both halves of bounty state |
| `buildPostGameStats` / `VictoryShowcase` | no podium for a solo bot match |
| `forwardLateJoiner` | unreachable, but leave it armed as a backstop |
| `RoundStatusGui.PhaseAnnounce` | **added 2026-08-07.** The tutorial banner takes that slot (§5.5, decision 16), and a phase banner fading in on top of an instruction line is the one collision the new position can produce. Tutorial mode has no phases to announce anyway |

Keep unchanged: `SkinService` loading, `HunterMovement`, spawn protection, the hit pipeline, kill
feed, health packs.

**`hookCharacter`'s spawn placement is NOT unchanged — it is the branch point, and this list used to
say otherwise — [corrected 2026-08-09].** `RoundController.hookCharacter` fires on *every* character
load, respawns included, and parks the character with
`SpawnService.sendPlayerToRoundSpawn(player)` — which draws a **random** one of the 44 `SpawnPoints`.
Left alone, a tutorial player who dies reappears somewhere else in the canyon and the lesson's
geometry (the step 3 dummy, the step 8 cover sightline) is gone. Tutorial mode substitutes
`SpawnService.teleportPlayerToSpawn(player, TutorialSpawn)` at that one call site. That is the whole
change; the rest of `hookCharacter` — the health restamp, the death hook, the freeze branches — stays.

**Must still happen — `State.roundActive = true`.** It is tempting to treat "skip the countdown" as
"never activate the round", and that breaks more than sprint: `SetCanSprintCheck` gates on it,
`UltimateChargeService` auto-resets charge on `RoundActive` going true, and hunter clients read it to
decide whether the player is in gameplay at all. Tutorial mode skips the *wait* and the *countdown*,
then sets the flag exactly as a real round does.

**Must also still happen — the fire wall, and it is shown on purpose (decision 22) — [added
2026-08-09].** The first draft skipped `ZoneService.startZone()` on the reasoning that "the fire wall
kills a player who is reading instructions". It is now the opposite: **the wall is the one thing in
the lesson that teaches itself.** A closing wall of fire needs no banner — a new player sees a
200-stud-tall wall crawling toward them and understands the map has an edge. So the tutorial runs a
**compressed, spawn-centred** version of the zone and never says a word about it.

**The shape: open at phase 2's target, close to final over ~90s — landing as step 11 opens.**

| t | Half-span | Walls at Z | What the player sees |
|---|---|---|---|
| 0s | **337.5** | −594.9 / +80.1 | The **south** wall only. The north wall is 63 studs past the map's north edge |
| ~25s | 274.4 | −531.8 / +17.0 | The north wall crosses into the map and both are now on screen |
| ~32s | 257.4 | −514.9 / 0.0 | **The world origin enters the fire.** Nothing visible happens; see the respawn trap below |
| **90s** | **112.5** | **−369.9 / −144.9** | Final. 112.5 studs each side, static for the rest of the lesson |

Each wall travels at **2.5 studs/s** — slow enough to read as movement rather than a jump, and still
covering 225 studs where the player can watch it.

**Why 90s, and what it deliberately does not guarantee.** Step 11 has no clock time: the lesson is
player-gated, so it opens anywhere between **~90s** (the fast end of a normal 120-190s run) and
**176s** (every step timing out — the 206s timeout sum less step 11's own 30). Anything scheduled to
land *at* step 11 is therefore a bet on pacing, not a guarantee. 90s takes that bet on purpose: it
lands the final zone exactly as a normally-paced player walks into the free-roam step, and a slower
player simply gets the finished wall earlier, which costs nothing.

**The case it gives up is the genuinely fast player**, who can clear steps 1-10 in ~50s if they act on
every instruction immediately, and will reach step 11 with the wall still ~50 studs out and closing.
That is accepted rather than solved: a player moving that fast already knows what a closing zone is,
and the wall being slightly behind them reads as the map tightening rather than as a broken cue. **Do
not "fix" this by driving the zone from step transitions** — that couples `ZoneService` to the
director for a case the design has already decided it does not care about.

**Centre it on the spawn — `randomCenterOffset` must be pinned, not drawn.** A normal round draws it
from `rng:NextNumber(-40, 40)`, which in the live playtest put the walls **84.6 and 140.4 studs** from
the spawn — a 56-stud asymmetry, one wall arriving visibly sooner than the other. For the tutorial set
it to `-257.437 - (-250)` = **−7.437**, which lands the player dead centre with 112.5 studs each way.

**Show it, never name it — and this needs no suppression code, only restraint.** Three clients read
the zone attributes, and they split cleanly:

- `RoundStatusClient.updateZone` sets `zoneLabel.Visible = false` when `ZonePhaseName` is `""`, so
  **writing `ZonePhase` while leaving `ZonePhaseName` unset hides the "Zone: Final - 0:42" readout**
  while everything else still works.
- `refreshPhaseAnnounce` is connected to `ZonePhaseName` changes, so never writing the name also means
  the `PHASE N • NAME` banner never fires — consistent with §5.3 already suppressing `PhaseAnnounce`
  for the tutorial banner (decision 16).
- `ZoneAtmosphere` gates on `ZonePhase >= 2`, so it must see the phase. **It is harmless:** its tint
  and its `ZoneBlur` are proximity-driven, engaging only within `PROXIMITY` = **12 studs** of the
  inner wall face. At 112.5 studs nothing lights up, so this does **not** add a third contender to the
  two `Lighting` blur owners §4.7 warns about — unless the player walks up and touches the fire, which
  is exactly when a burnt orange grade is the correct feedback.

**Step 1 is what guarantees they see it.** At spawn the player's heading is ~30° off the +X axis, and
the walls are planes perpendicular to Z — so the north wall sits toward the left of their view rather
than dead ahead. Step 1's gate is a **60° cumulative look sweep**, which brings it through frame by
construction. The two steps reinforce each other and neither had to be written for the other.

Four consequences:

- **A wandering player can now burn, and decision 9's rationale inverts.** "A wanderer finds an empty
  canyon and comes back" becomes "a wanderer finds fire" — `ZONE_DAMAGE_BASE` 5 ramping to
  `ZONE_DAMAGE_MAX` 50. This is arguably the better outcome, since the fire is the real game's actual
  boundary and the tutorial now teaches it for free; §10's deferred "boundary handling" item is
  largely answered by it. But it is a **behaviour change to decision 9**, not a free addition.
- ~~**A tutorial death now has a cost beyond the respawn.**~~ **Moot since 2026-08-09.** This used to
  say that burning to death resets the bounty streak and so costs the player §4.1's payoff. The player
  is no longer marked at any point in the tutorial (§4.1), so the streak carries nothing and a death
  costs exactly the respawn. Burning is otherwise unchanged.
- **Bots never burn.** `_applyZoneDamage` iterates `Players:GetPlayers()` only, and `BotPathing`
  already clamps destinations out of the fire, so no bot roster or step 7 line can be spoiled by the
  wall landing on it. The 60-stud leash keeps every bot ~52 studs clear of the final face regardless.
- **It arms a clamp that would otherwise be dead.** `BotPathing:RequestMove` runs
  `ZoneService.clampPositionToSafeZone(destination, FirewallAvoidanceMargin)` *before* the leash clamp.
  With the zone skipped, `getSafeZBounds` returns `-inf, inf` and the call is a no-op; here it is a
  live clamp on every bot destination. Harmless at these distances — but do not reason about bot
  pathing as though the zone were absent.

**This is the one part of the tutorial that needs real `ZoneService` work,** where decision 22's
earlier "runs as a normal match" version needed none. Two entry points: pin the centre at start, and
drive a single 337.5 → 112.5 interpolation over ~90s instead of `floor(elapsed / ZONE_PHASE_DURATION)`
stepping through four phases. `currentPhase` still has to report **≥ 2** throughout, or
`getSafeZBounds` returns `-inf, inf`, `isPlayerInSafeZone` early-returns true, `_updateFirePositions`
never runs and the damage tick never fires — the whole wall becomes decorative.

**Must also still happen — the round-start stats reset and push.** Added 2026-08-07 for step 10.
`RoundController` zeroes `DataService`'s `sessionTracker` at the start of every round and pushes
`StatsResponse` unprompted, which is what makes the stats panel read **THIS MATCH** rather than
everything the server has ever played (the Hotfix 11 fix for launch issue #32). Skip it in tutorial
mode and step 10 opens a panel showing either nothing or a previous tutorial's numbers on a recycled
server. It has to rewrite **both** paths: the `sessionTracker` table behind My Stats *and* the
`SessionKills` / `SessionDeaths` player attributes the Scoreboard tab reads independently — zeroing
one leaves the other stale, which is the exact shape of the original defect.

**Spawn and confinement (decision 9; the point itself is decision 21) — [revised 2026-08-09].** One
authored `TutorialSpawn` point, used for the initial spawn and every respawn in place of
`SpawnService.teleportAllToRoundSpawns`. Bots are leashed to
~60 studs of it — `BotService.SetLeash(record, anchor, 60)`, or the `Leash` field of a `SpawnBot`
spec; the clamp itself is built and lives in `BotPathing` (§4.5). **No walls, no boundary warning, no waypoint:** a player who wanders finds
an empty canyon and walks back on their own. Nothing new is authored into a streamed place, and the
tutorial does not teach a boundary the real game does not have.

**The point, captured from a live playtest on 2026-08-09** — position *and* facing, because the facing
is load-bearing and the first draft never specified one. Every later "in front of the player" in §4
(the step 3 dummy, the step 7 line, the step 8 cover sightline) is measured off this heading:

```lua
-- workspace.TutorialSpawn -- a Part, centre at y 9.00
CFrame.new(Vector3.new(-69.444, 9.000, -257.437))
	* CFrame.Angles(0, math.rad(-119.82), 0)
-- player lands root-at (-69.44, 13.00, -257.44), LookVector (0.868, 0, 0.497)
-- standing on Terrain (Sand), surface y 10.00
```

**The part's centre is y 9.00, one stud *below* the sand surface, and that is not a mistake.**
`teleportPlayerToSpawn` places the root at `spawnPart.CFrame + Vector3.new(0, 4, 0)`, and a settled
R15 root stands 3 studs above its feet — so a part dropped visually onto the terrain spawns the player
a stud in the air. Author the part by CFrame, not by eye.

**Place the player with `SpawnService.teleportPlayerToSpawn(player, TutorialSpawn)`. Do not write
`root.CFrame` directly.** The rotation carries for free — that line is `CFrame + Vector3`, which
translates without touching rotation, so **the part's own orientation *is* the player's facing** and
no new code is needed to aim them. Rolling a bespoke placement instead silently drops four things the
existing function does:

- `verifyTeleport` — the asynchronous check that the write survived at all. This is the hazardous
  direction: a server CFrame write on a player-owned character can be **discarded outright**, which is
  the entire reason that verifier exists.
- `ACImmuneUntil` — without it the placement reads as a ~190 studs/s move and false-kicks.
- `resetPlayerFireTime` — **load-bearing under decision 22**, not the freebie an earlier draft of this
  paragraph called it. The burn ramp is per-player and survives death, cleared only by a live zone tick
  that finds the player back inside the safe area. Without this, a player who burned to death
  re-enters the lesson still ramped and takes cap damage instead of the 5 DPS base.
- `SpawnProtectionService.grant` — worth knowing it fires. `HighNoonTargeting` skips rigs carrying
  `SpawnProtected`, but that is granted to **players only**, so step 7's bot line is unaffected (§4.5).

**Death and respawn — [added 2026-08-09].** Every death returns the player to `TutorialSpawn`, on the
same heading, by the same call. There is no separate death path to write: substituting the one
`sendPlayerToRoundSpawn` line in `hookCharacter` (above) covers the initial spawn, every respawn, and
the late/straggler reconcile pass, because all three route through it.

> **The trap this walks into, and it is created by decision 22.** Redwater has **no `SpawnLocation`**,
> so `player:LoadCharacter()` drops every fresh character at the **world origin (0, 14, 0)** — the far
> north of the canyon — and `hookCharacter` teleports them out of it synchronously. The origin sits at
> Z 0; the tutorial's north wall inner face is at `-257.437 + halfSpan`, so **the origin is inside the
> fire from t ≈ 32s onward** (halfSpan drops below 257.4 there) — which is nearly the whole lesson.
>
> In a normal match the same code runs, but the zone does not reach Final until t=300s, so an early
> death lands on safe ground. **The tutorial compresses that to 90s and therefore spends almost all of
> its life with the respawn origin inside the wall.** The mitigation is already in the path and must
> not be weakened: the placement is synchronous, `ACImmuneUntil` covers the move, `verifyTeleport`
> re-teleports if the write was discarded, and `resetPlayerFireTime` clears the ramp. Rolling a
> bespoke placement here (see above) drops three of those four and turns a discarded CFrame write into
> a burn-at-origin death loop.

A **second** authored point, `TutorialBountySpawn`, holds the step 8 bot — at step 6's entry point,
111 studs out, with the lumber pile between it and `TutorialSpawn` (§4.1). Two points, still no
geometry.

**Both points are BUILT — 2026-08-09.** Two Parts at `workspace` root, authored by CFrame rather than
by eye:

| Built | Value |
|---|---|
| `TutorialSpawn` | `(-69.444, 9.000, -257.437)`, yaw **−119.82°**, LookVector `(0.868, 0, 0.497)` |
| Verified teleport target | `teleportPlayerToSpawn` yields root at **`(-69.444, 13.000, -257.437)`** on that same LookVector — the rotation carries for free, as the paragraph above predicted |
| `TutorialBountySpawn` | `(41.243, 11.496, -249.344)`, yaw 0° (unused — `SpawnBot` takes the position, not the facing) |
| Both | `Anchored`, `Transparency = 1`, `CanCollide = false`, `CanTouch = false`, **`CanQuery = false`**, `CastShadow = false`, `Size (4, 1, 4)` |

**`CanQuery = false` is the one non-obvious property and it is load-bearing.** `TutorialSpawn`'s centre
sits a stud *below* the sand, so a queryable part there would be struck by every downward ground
raycast in §4.2, §4.8 and §4.9 — and by `BotPathing`'s destination probes. Re-verified after building:
a ray dropped through `TutorialSpawn` still reports `Workspace.Terrain` at y **10.000**, so every
measurement in this document survives the parts existing. Do not "tidy" this to `true`.

**Round length.** `TUTORIAL_HARD_CEILING = 260s` as a backstop only. The real end condition is
"step 11 complete", so a normal run is ~120-190s. The ceiling has to clear the **sum of every timeout —
206s across eleven steps** — plus the confirm beats and step 8's lead-in, or the backstop starts firing
on players who were never stuck; that is why it is 260 and not 190. At the ceiling, end regardless.

*(Was 240 against a 191s sum over ten steps. Step 10 added 15s to the sum, and the ceiling moved with
it rather than eating the headroom — the gap between the two is the confirm beats and the lead-in, and
it is what stops a slow-but-progressing player being cut off mid-lesson.)*

**End of tutorial:**
1. `ProgressionService.clearPendingRewards(player)` — drop everything banked from bot kills and the
   bounty claim (§4.1). Skipping the flush already discards it; this makes it explicit.
2. `Wallet.award(player, TUTORIAL_COMPLETE_CASH, "tutorial_complete")` — **only if
   `Tutorial.BonusPaid == false`**, then set it true. New reason added to `Wallet`'s reason map in
   **both** copies (`Wallet` is one of the 17 mirrored modules; an unmapped reason silently mislabels
   itself as "Gameplay" rather than erroring).
3. Write `Tutorial.Completed = true`, `CompletedAt = os.time()`.
4. Teleport to Bounty with `{ tutorialComplete = true, tutorialCash = N }`.

Award **in Redwater, before the teleport** — Redwater holds the session lock at that moment, and the
grant survives a failed return teleport.

### 5.4 Redwater — `TutorialDirector` (new) — **[revised 2026-08-07]**

`ServerScriptService.Onboarding.TutorialDirector` (ModuleScript). Started by `Main` **only when**
`State.tutorialMode` is true. Owns:

- the step state machine (current step, deadline, completion predicate)
- bot choreography (§4) via the **built** `BotService` calls in §4.5 — `SetPopulationLocked(true)` once
  at the start, then one `SpawnBot` per bot and `Despawn` at each step transition
- **the step 3 target dummies: clone `ServerStorage.TutorialDummies`'s three children into `workspace`
  on entering step 3, and `:Destroy()` them when step 6's two bots walk in (§4.2).** **Not bots** — no
  `SpawnBot`, no `Despawn`, no death watch, nothing to reconcile; they are already positioned, already
  facing the player, already tagged and already immortal at 1e9 HP, so this is two lines. The window is
  the mechanism, not housekeeping: a tagged target standing in view during step 1 makes a touch player's
  revolver empty itself while they are being told how to look around. **Clone, never reparent the
  templates** — destroying reparented originals leaves the next tutorial session with nothing to shoot
- the step 7 line: 5 `StandDown` bots spawned in front of the player for the High Noon showcase, and
  despawned after it fires (§4.5)
- the step 8 bounty bot: spawning one at `TutorialBountySpawn`, marking it with three
  `BountyService.registerBotKill(record, model)` calls, then `SetApproach(record, player)` so it walks
  out to the player (decision 18) — and clearing it on timeout (§4.1)
- `UltimateChargeService:Set(player, max)` on entering step 7
- firing `TutorialStep` to the client on every transition
- the end-of-tutorial payout and teleport (§5.3)

> **Superseded 2026-08-08 — this is built, and `SetTutorialPlan` does not exist.** What was written
> instead is a per-bot API on `BotService`: `SpawnBot(spec)` returns the record, and
> `SetHoldFire` / `SetStandDown` / `SetLeash` / `SetRoute` / `SetDifficulty` / `Despawn` /
> `DespawnAfter` / `SetPopulationLocked` operate on it. **Read §4.5 before writing any bot code here.**
> The reasoning below is why that shape was chosen and still applies verbatim; only the entry point
> differs. A `SetTutorialPlan` wrapper is a loop over `SpawnBot`, not a new system.

`SetTutorialPlan` therefore has to **return the spawned records** (or take a per-bot spec and return
one), because marking a bot and clearing its bounty both need the `record` *and* the live rig — a
count-and-difficulty call alone cannot serve step 8.

**The spec is per-bot, and it names a hunter** (decision 17, §4.4). Each entry carries at least
`{ hunter, difficulty, passive, anchor, leash }` — the roster is mixed, so `count + difficulty` cannot
express it. Naming hunters explicitly also means the plan bypasses `BotConfig`'s `HunterWeights` draw
and `HunterCaps` ceiling rather than fighting them, which is the behaviour wanted: the tutorial's
roster is authored, not sampled.

**Step signals — no new hooks in combat code.** Split by who can observe them cheaply:

| Signal | Observed by | How |
|---|---|---|
| look, alt-held | client | `UserInputService` / camera CFrame delta |
| sprint (step 2) | client | `SprintController` state — **not** a raw LeftShift listen, or touch never passes and a PC player who presses Shift while sprint is gated off passes without moving |
| **shoot (step 3)** | **server** | **the existing `FireBullet` remote** (Dust's Manifest `Remotes.Events`). **Corrected 2026-08-07 — the original client-side answer was broken on the exact platform step 3 now teaches.** See the note below |
| **dash (4), fan (5)** | **server** | **the existing `DashRequest` and `Skill2Request` remotes** (Dust's Manifest `Remotes.Events`). **Corrected 2026-08-09 — the client-side answer here was broken on PC, the same way step 3's was broken on touch.** See the second note below |
| ultimate fired | server | the existing `HighNoonRequest` remote |
| bot kills | server | `BotService` bot-death path / `State.playerKills` |
| bounty claimed (step 8) | server | the same bot-death path — `_creditPlayerKill` runs `claimBounty` immediately before `registerKill`, so watching the marked record die *by a player* is the whole gate. No client signal, nothing new in combat code |
| ~~player became marked~~ | — | **Removed 2026-08-09.** It drove the one-shot *"Now they're hunting you."* beat and was never a gate. The player can no longer be marked at all (§4.1), so there is no signal and no beat. Do not re-add a listener for an event that cannot fire |
| stats panel opened (step 10) | client | `StatMenuGui.Backdrop:GetPropertyChangedSignal("Visible")`. `setOpen` assigns it synchronously in both directions, so it is the panel's real state — **not** the M keypress and **not** `MobileStatsButton.Activated`, which pass for input the panel ignored, and **not** `MainFrame.Visible`, which stays true through the close tween (§4.3) |

> **Why step 3's signal moved to the server — [added 2026-08-07].** The first draft gated it on Dust's
> `FireRequested` bindable. **Auto-fired shots do not raise that bindable.** `FPSRevolverClient`
> constructs `MobileAutoFireController` with `OnFire = shoot` and says so in a comment at the
> construction site: *"fires `shoot()` directly … never the `FireRequested` bindable, which
> `HighNoonClient` also connects for the ultimate shot."* So on touch — the platform where §4.2 now
> teaches auto-fire as the primary way to shoot — the bindable stays silent, the gate never sees the
> three shots, and **step 3 times out for every mobile player** while the revolver visibly fires. The
> `FireBullet` remote is raised by `shoot()` itself, so the server counts the shot however the client
> decided to take it: button, mouse, or auto-fire. The general rule is worth keeping — **gate on the
> action reaching the server, not on the input path that requested it**, wherever a second input path
> exists or might later.

> **Why steps 4 and 5 moved to the server as well — [added 2026-08-09].** It is the same defect with the
> platforms swapped, and it was found by applying the rule above to the rows that had not been rechecked.
> `DashRequested` and `Skill2Requested` are **inbound** bindables: `FPSRevolverClient` *listens* to them
> (`conn(dashRequestedEvent.Event, function() dash() end)`) and the only thing that fires them is the
> mobile ability tile. **The PC keybinds raise neither** — `RevolverInput` is constructed with
> `OnDash = dash` and `OnSkill2 = useSkill2` and calls them directly. Gating on the bindables therefore
> **times out steps 4 and 5 for every PC player** while the dash and the fan visibly happen in front of
> them. `DashRequest` and `Skill2Request` already exist, are already in Dust's Manifest, and are raised
> by the ability itself whichever input asked for it.
>
> They are also the **stricter** gate, which is what these two steps want. `Skill2Request` is fired from
> `RevolverSkill2`'s `OnUseStarted`, reached only after its dashing, reloading, cooldown, `CanUseCheck`
> and **ammo** tests all pass — so it fires when the fan actually happens, not when a button was pressed
> at it. Same for `DashRequest`, which the server answers with `dashService:DoDash` and only refills the
> magazine if that returns true. A player pressing E on an empty cylinder does not pass step 5, which is
> correct: the step teaches the fan, and no fan occurred (§4.2).

The client reports its signals up one `TutorialProgress` RemoteEvent as `(stepId)`. **No
validation is needed** beyond "is this the current step" — the server is private, one human, and the
worst possible exploit is skipping your own tutorial.

### 5.5 Redwater — tutorial HUD — **[revised 2026-08-07]**

New authored `ScreenGui`: `StarterGui.TutorialGui`. Authored instances only (UI rules); scripts set
`.Text` / `.Visible` / tween. Driven by `StarterPlayerScripts.TutorialClient`.

**`DisplayOrder`.** `TutorialGui` sits at **45** — above `BountyListGui` (41) and, critically, above
`StatMenuGui` (20), whose full-screen backdrop would otherwise dim the instruction line during step 10;
below the feeds at 8500+. Add the row to `UI_STYLE_GUIDE.md`'s registry when it is built.

**Banner** — **top-centre, below the bounty card row** (decision 16), holding:
- `StepLabel` — the instruction line
- `ProgressLabel` — `2 / 11` (reads `2 / 10` on touch, since step 9 does not exist there)
- a confirm tick that flashes on completion
- `KeyCap` — an authored keycap glyph that pulses on the steps whose PC input is a key with no
  on-screen widget (SHIFT, ALT, M). Hidden on touch and on the steps that glow a widget instead
  (decision 20, §4.7)

Plus one template outside the banner: **`TutorialGlow`**, the authored layer stack cloned onto whichever
widget the current step is pointing at (§4.7). It lives in `ReplicatedStorage`, not under `TutorialGui`,
because it is reparented into `ScreenGui`s the tutorial does not own.

**The banner does not go under the match timer any more, and this is the largest single revision in
the document.** Hotfix 8 moved `BountyListGui` into that slot: `Canvas` is `AnchorPoint (0.5, 0)` at
`{0.5, 0}, {0, 60}`, sized `{0.34, 0}, {0.175, 0}` with a `UIAspectRatioConstraint`, so the card row
occupies **17.5% of viewport height on every device**, directly beneath a timer stack that runs y 0-58.
The first draft's "the banner is top-centre and the bounty panel is upper-left, so they do not collide"
described a layout that no longer exists — and step 8 is precisely the moment both would be on screen.

**So the banner takes `PhaseAnnounce`'s slot instead:** `{0.5, 0}, {0.175, 68}` — the card row's own
height scale, plus its y offset, plus an 8px gap. That is the same expression `RoundStatusGui.PhaseAnnounce`
uses, and it is deliberate: it is the position the game already reserves for a transient centre banner
sitting under the cards, it tracks the row at a constant 8px on every device instead of drifting, and
tutorial mode suppresses phase announcements (§5.3) so the two can never occupy it at once.

Two consequences worth stating rather than discovering:

- **It costs vertical space.** On a 360px-tall phone the banner starts ~131px down — roughly 36% of the
  screen. That is the price of the slot and it was accepted knowingly; the device sweep below is what
  confirms the instruction line still reads at that size.
- **During step 8 it is an improvement, not a compromise.** The bounty card and the line telling the
  player what to do about it end up **stacked**, card directly above instruction. The old upper-left
  list never gave that.

**This inherits a hand-maintained coupling.** `BountyListClient`'s vault entry is explicit that nothing
reads the panel's geometry at runtime and nothing should — `KillFeedClient` tracked it once and was
carried across the screen when it moved. The `0.175` and the `68` are numbers kept in step **by hand**:
if the card row's height scale or y offset ever changes, `PhaseAnnounce` **and this banner** move in the
same pass. Note it in `TutorialGui`'s vault entry as `BountyListClient` and `RoundStatusClient` already
note it in theirs.

**One panel the lesson now opens on purpose.** Step 10 opens `StatMenuGui`, which dims the whole scene
behind an `Active` backdrop and swallows clicks. The banner clears it by `DisplayOrder`; the step sits
in the zero-bot lull so the dim costs nothing; and the step closes the panel on its way out (§4.3).

**One obsolete warning removed — and then the button it warned about moved.** The first draft told you
to watch the mobile SPRINT button for a ~6px collision with the bounty panel. That was true of the
**old** upper-left panel, and then stopped being true of anything. **As of 2026-08-08 it is doubly
dead: SPRINT is not on the left edge at all any more** (§4.6). Do not go looking for a collision that
was fixed a release ago, against a button that has since left the neighbourhood.

**EXIT TRAINING** — pinned to the **right end of the banner**, not free-floating. Placement is
deliberate: Redwater's top-right cluster (gear + mobile Stats) is **pixel-pinned**, top-left is
covered by chat, bottom-left holds the ping/FPS chip, and the **bottom-right holds all five touch
combat buttons** — FIRE, SPRINT, JUMP, RELOAD and Vesper's SCOPE (§4.6). Attaching to the banner is
the only placement that collides with nothing on both a phone and a windowed PC.

> **Corrected 2026-08-08.** This paragraph used to say the buttons occupied "the right edge +
> left-above-thumbstick". The cluster rebuild consolidated them into the bottom-right corner, so the
> **left band above the movement thumbstick is now free** — the only unclaimed real estate on a touch
> screen. The conclusion is unchanged and EXIT stays on the banner: that band is under the movement
> thumb during every step that asks the player to move, which makes it the worst possible home for a
> button that quits the tutorial. It is worth knowing it is free; it is not worth using for this.

> **Step 10 promoted this from a layout preference to a correctness requirement — [added 2026-08-07].**
> The touch copy is *"Tap **STATS**, top right"*, so the lesson now deliberately sends a player's thumb
> into the top-right cluster. `MobileStatsButton` is 60×44 with its right edge at -62; `SettingsButton`
> owns the corner at -10. **EXIT TRAINING must not be anywhere near that band.** A mis-tap there would
> eject a player from the tutorial at the exact moment it told them to tap up there — and unlike a
> mis-tap on the confirm dialog, this one is the tutorial's own fault. Keeping EXIT on the banner, which
> now sits well below the cluster, resolves it; do not "improve" the placement by moving it up.
- Fires the **existing** `LeaveToLobbyRequest` remote → `LeaveToLobbyService`, which already resolves
  return teleport data via `RoundController.getReturnTeleportData(player)`. Do not write a second exit
  path.
- One confirm tap/click (`LEAVE TRAINING?` → `YES` / `KEEP PLAYING`) so a mis-tap on a phone does not
  eject them.
- On exit: `Completed = true`, **no** Cash bonus (`BonusPaid` stays false — so if they ever replay,
  they can still earn it once).
- Min 44×44px at the smallest supported viewport.

**Verification is not optional here.** `set_device_simulator` across a small phone, a tablet and a
windowed desktop plus `capture_screenshot` / `capture_device_matrix`. The banner now sits below a panel
whose height is a pure 17.5% scale, on a screen whose top-right corner is pixel-pinned; "it looks right
in Studio" has been wrong on this exact HUD before. **Sweep it with a bounty card up**, not on an empty
screen — an 8px gap that reads fine against nothing is the one measurement that matters and the one a
default Studio viewport will not show you.

**Interaction with `HunterAbilityIntroClient`:** during a tutorial, force the ability tags **on**
regardless of the `AbilityDescriptions` setting — steps 4/5/7 point at those icons, and a player whose
setting is `Off` would be told to press an unlabelled icon. Restore the setting's behaviour on exit.

---

## 6. Economy

- One flat award, `Wallet.award(..., "tutorial_complete")`, once per account (`BonusPaid`).
- **Value: 250 Cash** (decision 7). A quarter of the way to a 1000-Cash skin — the default price
  `PurchaseSkinEvent` falls through to — so it reads as a real reward next to the shop while staying
  nowhere near a hunter price.
- No Tokens. No XP. No RP. No battle-pass XP. No quest credit. No daily streak.
- Because bot kills award nothing in tutorial mode, there is no farming surface even if replay ships.

---

## 7. Analytics

**The tutorial must not consume the existing onboarding funnel.** Steps 4-7 ("Joined Round", "Shot the
Gun", "Hit a Player", "Killed or Assisted") fire **at most once per player, ever**, persisted in the
shared profile. If the tutorial fires them, every player's *first real match* silently stops
registering, and the funnel quietly starts measuring the tutorial instead of the game. Suppress
`tryLogFunnelStep` entirely while `State.tutorialMode`.

**Instead, add a dedicated `Tutorial` funnel** through `Telemetry` — its own session id minted at
dispatch in Bounty, carried across in teleport data exactly like `matchFunnelIds`, with one step per
lesson step plus a terminal step for each of: completed, exited, timed out at the ceiling, left the
game. This is the most valuable output of the whole feature — *which button loses new players* is a
question nothing currently answers.

#### The funnel needs new code in `Telemetry`, and §8 listed it in neither place — **[added 2026-08-09]**

`Telemetry.logFunnelStep(player, step, funnelSessionId)` **cannot carry this funnel.** Verified live:
`FUNNEL_NAME` is a module-local constant (`"MatchLoop"`) and the step name is read from a fixed
`FUNNEL_STEPS` table — an unrecognised step `warn`s and returns `false`. The tutorial therefore needs a
**second entry point** (say `Telemetry.logTutorialFunnelStep(player, step, funnelSessionId)`), with its
own name constant and its own step table. **`Telemetry` is one of the 17 mirrored modules**, so it goes
into both copies byte-identical in the same pass, and `/preflight`'s checksum gate is what proves it.

Four constraints the live module imposes on the shape of that function. None is optional and each
would be found the hard way:

1. **Platform must be stamped on step 1.** The module's own comment: *"Funnel breakdowns consider
   custom fields from the FIRST step only, which is why Platform is stamped here on step 1."* §7 wants
   step 3 and step 10 split by platform — that split is only reachable if `CF01` carries
   `Telemetry.getPlatform(player)` on **step 1** of the tutorial funnel. Attaching it to step 3 gets a
   field that no breakdown will read.
2. **The rate limiter will be tighter here than anywhere else in the game, and it drops silently.**
   `takeToken` enforces `MAX_PER_PLAYER_PER_MIN = 30` on a sliding minute, sized against a design the
   module documents as *"roughly 10 events per player per 6-minute match."* The tutorial fires **11
   step events plus terminals plus the end-of-run aggregates inside 120-190s** — and a player who acts
   on every instruction clears steps 1-10 in ~50s, putting the whole funnel inside a single window. It
   fits under 30, but with far less headroom than any existing caller, and **a dropped event returns
   `false` with no warning**. A truncated funnel is indistinguishable from players quitting at step N,
   which would corrupt the exact measurement this section calls the feature's most valuable output.
   **Budgeted below and settled — one aggregate event, decided 2026-08-09.**
3. **`ENABLED` is `DEBUG_FORCE or (not RunService:IsStudio() and GameEnvironment.isLive)`** — the
   funnel is inert in Studio *and* on any non-live environment. It cannot be verified in the Studio
   pass of §11; it is a live-only check, and `DEBUG_FORCE` is the only way to exercise it earlier.
4. **`CF01-03` are all spoken for and the custom-field budget is per-experience.** The module's header
   notes an 8,000-unique-combination ceiling across the whole experience and says Version was left off
   events for exactly this reason. A new funnel's fields draw on that same budget — do not invent a
   fourth field, and keep the step names low-cardinality.

Step 8 is the one to watch on the first live day. It used to be because it asked the player to *find*
something; under decision 18 the bot comes to them, which should collapse its timeout rate — so the
number now answers a different question: whether a player who has a marked target walk up to them
understands that shooting it is the thing to do. A timeout here is no longer "I never found it".

**Split step 3's numbers by platform — [added 2026-08-07].** It is the only step whose *mechanic*
differs between PC and touch, so a blended timeout rate is meaningless. The touch figure is the first
real measurement anyone will have of whether auto-fire is discoverable, which is a question that
outlives the tutorial: it applies to every mobile player who never takes one. Step 10 is worth the same
split for a duller reason — the panel opens from a keypress on PC and a 60×44 button on touch, and
those fail differently.

Emit aggregates once per player at the end, never per step-attempt: total duration, per-step duration,
count of steps that auto-advanced on timeout (the direct measure of "this instruction did not land"),
and exit step if they left early.

#### The event budget, settled — **[decided 2026-08-09]**

**The aggregates are ONE event, not one per step.** That was the open choice constraint 2 turned on,
and it is taken deliberately rather than left to the implementer: eleven per-step-duration events would
put the run at 23-29 in a single sliding minute for a fast player, close enough to
`MAX_PER_PLAYER_PER_MIN = 30` that the funnel's own reliability would depend on how quickly someone
played. Pack the per-step durations into that one event's fields.

What a full tutorial run then costs, counted against the live module:

| Source | Events | Note |
|---|---|---|
| Tutorial funnel steps | **11** | 10 on touch — step 9 is not fired there at all |
| Terminal step | **1** | exactly one of completed / exited / timed out / left |
| End-of-run aggregate | **1** | the decision above |
| `ClientPerf` | **1** | once per player per server, guarded by `perfReportedByUserId` |
| `SessionEnd` | **1** | on the return teleport |
| `MatchStart` / `MatchEnd` / the seven `Match*` aggregates | **0** | already skipped by §5.3 |
| `HunterSwitch` | **0** | the tutorial is Dust throughout |
| MatchLoop funnel steps 1, 3, 4, 5 | **4** | **unless suppressed — see §5.3, which did not list them** |
| **Total per run** | **15**, or **19** if MatchLoop is left firing | against 30 per sliding minute |

**Worst realistic window is ~17.** A player who acts on every instruction clears steps 1-10 in ~50s,
so the funnel, the terminal, the aggregate, `ClientPerf` and MatchLoop's early steps can all land
inside one minute. That leaves **~13 events of headroom**, which is enough that the limiter stops
being a design constraint — but it is only true while the aggregates stay at one event.

**One trap that comes free with Roblox funnels and bites step 9.** The module's own header warns:
*"Do NOT add a step that later steps don't require"*, because Roblox backfills — *"if any steps are
skipped, the intermediate steps will be considered completed."* The tutorial is gated and sequential,
so reaching step 7 genuinely implies step 6 and the funnel is backfill-safe by construction — **except
for step 9, which touch players never see.** A touch player reaching step 10 will be backfilled as
having completed *"Hold ALT to free your cursor"*, a step that was never shown to them. That is
readable rather than broken, because Platform is on step 1 (constraint 1): **step 9's number is only
meaningful filtered to PC.** Write that down next to the chart, or it will be read as a 100% pass rate
on the one step half the player base never got.

---

## 8. Files touched

### Bounty
| Script | Change |
|---|---|
| `ServerScriptService.PlayerServices.DataService` | `Tutorial` profile field + grandfather rule |
| `ServerScriptService.PlayerServices.Wallet` | `tutorial_complete` reason (**mirrored — edit both copies**) |
| `ServerScriptService.PlayerServices.Telemetry` | **added to this table 2026-08-09 — it was missing.** `logTutorialFunnelStep` + its own funnel-name constant and step table; `logFunnelStep` is hardcoded to `MatchLoop` and cannot carry it (§7). **Mirrored — edit both copies.** Bounty also mints the funnel session id at dispatch and ships it in teleport data |
| `ServerScriptService.Party.MatchmakingService` | `reserveTutorialServer()`; writes `tutorial = true` into the access-code map; no directory entry |
| `ServerScriptService.Onboarding.TutorialDispatchService` | **new** |
| `ServerScriptService.Main` | start the dispatch service |
| `StarterGui.TutorialWelcomeGui` | **new authored UI** + controller |
| `StarterGui.TutorialCompleteGui` | **new authored UI** + controller |

### Redwater
| Script | Change |
|---|---|
| `ServerScriptService.PlayerServices.DataService` | same `Tutorial` field (templates stay aligned) |
| `ServerScriptService.PlayerServices.Wallet` | same reason (**mirrored**) |
| `ServerScriptService.PlayerServices.Telemetry` | **added to this table 2026-08-09 — it was missing.** The same `logTutorialFunnelStep` addition, **byte-identical to Bounty's** (§7). Redwater fires steps 1-11 and the terminals against the session id carried in teleport data |
| `ServerScriptService.RoundSystem.State` | `tutorialMode` field (tri-state: nil / false / true) |
| `ServerScriptService.RoundSystem.MatchDirectoryService` | resolve mode at boot; **do not publish while unresolved**; never publish when tutorial |
| `ServerScriptService.RoundSystem.RoundController` | tutorial branches (§5.3), including the round-start `sessionTracker` zero + `StatsResponse` push that step 10 depends on, and suppressing `PhaseAnnounce` |
| `ServerScriptService.RoundSystem.Config` | tutorial constants |
| `ServerScriptService.RoundSystem.ZoneService` | **the compressed tutorial zone (§5.3, decision 22).** Pin `randomCenterOffset` to −7.437 instead of drawing it, and drive one 337.5 → 112.5 interpolation over ~90s in place of the four-phase elapsed-time walk. Must still report `currentPhase >= 2` throughout, and must **never write `ZonePhaseName`** — that one omission is what hides the zone readout and the phase banner |
| `ServerScriptService.Bots.BotService` | **DONE 2026-08-08.** `SpawnBot` / `SetHoldFire` / `SetStandDown` / `SetLeash` / `SetRoute` / `SetDifficulty` / `Despawn` / `DespawnAfter` / `SetPopulationLocked`, plus per-bot flags on the record re-applied at spawn and an authored `SpawnCFrame`. Replaces the `SetTutorialPlan` sketch — see §4.5 |
| `ServerScriptService.Bots.BotBrain` | **DONE 2026-08-08.** `StandDown` (inert state, zero-speed `HunterMovement` root) and `SetRoute` / `_updateRoute` (authored walks). Now requires `HunterMovement` |
| `ServerScriptService.Bots.BotPathing` | **DONE 2026-08-08.** The leash — `_clampToLeash` in `RequestMove`, `_leashDirection` in `DirectMove` |
| `ServerScriptService.Bots.BotConfig` | **DONE 2026-08-08.** `HoldFire` / `StandDown` blanket test switches, `DamageMultiplier` on every tier, and the `Training` tier for step 11 |
| `ServerScriptService.Bots.BotController` | **DONE 2026-08-08.** Per-bot difficulty from `record.Difficulty`, falling back to the global |
| `ServerScriptService.PlayerServices.BountyService` | **one line, added 2026-08-09.** Early-return in **`registerKill`** when `State.tutorialMode`, so the player is never marked — steps 6 and 7 credit 7 kills against a threshold of 3 and would otherwise mark them mid-ultimate, a step before the lesson defines a bounty (§4.1). `registerBotKill`, `claimBounty` and `registerTargetKill` are **not** touched; step 8 depends on all three |
| `ServerScriptService.PlayerServices.QuestEvents` | early-return in `track()` when `State.tutorialMode` — the one guard that covers every quest emission from the tutorial's kills and bounty (§4.1) |
| `ServerScriptService.PlayerServices.BattlePassService` | same guard on the combat entry points (`onBountyClaim`, `onBecomeBounty`, `onBountyTakenDown`, the kill path) |
| `ServerScriptService.Bots.BotCombat` | **DONE 2026-08-08.** `HoldFire` flag — early-return at the **top** of `FireAt` and `ThinkAbility`, via an `isDisarmed` helper that reads `BotStandDown` too. Both are shared across all four hunters, `TryUltimate` sits inside `ThinkAbility`, and Vesper's grapple is cast from there too, so one flag disarms the roster (§4.4). `FireAt` checks it itself, not only at the brain's call site — ability branches re-enter it from `task.spawn`ed loops. Also applies the difficulty `DamageMultiplier` on every damage path |
| `ServerStorage.TutorialDummies` (authored instances) | **BUILT 2026-08-09.** `TutorialDummy1/2/3` — clones of the map's `Dummy` range prop, placed at the §4.2 positions, levelled, facing `TutorialSpawn` to 0.00°, `AimAssistTarget` on each inner `TargetDummy`, `ModelStreamingMode = Persistent`. Immortal already at 1e9 HP, so no damage-path work. The director clones them into `workspace` at step 3 and destroys the clones at step 6. **They stay out of `workspace` in the authored place** — that is what keeps ordinary matches free of an auto-fire magnet. The map's original seven `workspace.Dummy` props are untouched |
| `ServerScriptService.Onboarding.TutorialDirector` | **new** |
| `ServerScriptService.Main` | start the director when `tutorialMode` |
| `StarterGui.TutorialGui` | **new authored UI** (banner + exit button + `KeyCap`), `DisplayOrder` 45 — above `StatMenuGui` (20) and `BountyListGui` (41) |
| `ReplicatedStorage.TutorialGlow` | **new authored template** — the stacked glow layers cloned onto the current step's target widget (§4.7). Outside `TutorialGui` because it is reparented into GUIs the tutorial does not own |
| `StarterPlayer.StarterPlayerScripts.TutorialClient` | **new** |
| `StarterPlayerScripts.HunterAbilityIntroClient` | force tags on during tutorial |
| `UI_STYLE_GUIDE.md` | add `TutorialGui` to the §7 `DisplayOrder` registry |

**Nothing in `StatMenuGui` changes.** Step 10 observes `Backdrop.Visible` and closes via the existing
`_G.ToggleStatMenu` export (§4.3) — no new remote, no new hook, and no edit to `StatMenuScript`, whose
top-right button geometry is load-bearing for `QuestToastClient` and `VersionTagController`.

**Nothing in the auto-fire stack changes either.** Step 3 works by tagging a dummy `AimAssistTarget`
and reading the `AutoFireEnabled` attribute; `AimAssistController` and `MobileAutoFireController` are
untouched.

**Nothing in the touch cluster or `UltimateReadyFX` changes.** The glow is a **new** authored template
that borrows `UltimateReadyFX`'s findings (§4.7); it does not call it, extend it, or edit the five
mobile button modules or `HunterMobileClusterLayout`. The only thing the tutorial does to those GUIs is
parent a glow into one of them for the length of a step and take it out again — so a bug in the cue can
never reach the buttons themselves.

Plus two authored points in Redwater's Workspace — `TutorialSpawn` and `TutorialBountySpawn`, both
**BUILT 2026-08-09** (properties and the `CanQuery = false` rule in §5.3).

> **One line above used to say "no change to `BountyService`" — that is stale and has been removed.**
> It was written before the marking guard existed. Step 8 still rides `registerBotKill` /
> `claimBounty` / `clearBotBounty` exactly as the live game calls them, and those three are untouched;
> but `registerKill` takes the one-line `State.tutorialMode` early-return in the table above (§4.1).
> The table row is correct; the summary sentence was not.

Plus: a `.md` summary per new script in the matching vault path, then
`python update_bounty_graph.py` and `python update_redwater_canyon_graph.py`
(bare commands, one per tool call, issued together).

---

## 9. Failure modes

| Failure | Behaviour |
|---|---|
| `ReserveServer` fails at dispatch | Stay in Bounty. Card closes to the normal lobby. `Attempts` still incremented; they get one more try on their next join. |
| Teleport to the tutorial fails | Same — no retry ladder, no blank fallback. Failing into the lobby is a fine outcome; failing into a real match is not. |
| Player leaves mid-tutorial | `Completed` stays false, `Attempts` was already incremented. Next join they get it once more, then never again. |
| Return teleport to Bounty fails | The Cash and `Completed` flag are already written (§5.3). Retry the teleport; kick as a last resort — they rejoin into Bounty normally. |
| Profile fails to load in Bounty | Never dispatch. |
| `BountyIntroComplete` never lands | The welcome card's own timeout (25s, copied from `GiftPopupClient`) shows it anyway. The attribute is set on both of `LoadingScreen`'s exit paths including the watchdog abort, so this should be unreachable — the cap exists because a card that never appears silently strands a new player in the lobby with no tutorial and no explanation (§5.1). |
| A tutorial funnel step is rate-limited away | Silent — `takeToken` returns `false` and `logFunnelStep` returns `false` with no warning. Nothing player-facing breaks; the funnel grows a false cliff at whatever step got dropped. **Budgeted at 15 events per run against a 30/min ceiling (§7), so this should not be reachable** — it becomes reachable again the moment the aggregates are split per step, which is why that is written down as a decision rather than a preference. |
| Tutorial server somehow published | Fails closed by construction (§5.2) — but this is the single thing to verify first on live. |
| A friend taps "Join" on a player in a tutorial | Bounty's `getServerByJobId` scans the directory, finds nothing, and answers *"your friend's match has already ended."* Wrong message, harmless outcome. See open items. |
| Step 8 times out with the bot alive | `BountyService.clearBotBounty(record)` **then** retire the bot, in that order. Skipping the clear strands a row on the bounty panel naming a rig that no longer exists — it is the exact reason `clearBotBounty` is separate from `registerBotDeath`. |
| The bounty bot dies to something other than the player | `registerBotDeath` clears the bounty and nobody is paid, so the step cannot complete. Spawn and mark **one** replacement, restart the step timer; a second loss advances on the timeout rather than looping. |
| Player dies during step 8 | Nothing is lost. The bot keeps its bounty and the step still gates on the claim. **Simplified 2026-08-09** — this row used to trade on the player's streak resetting, which now carries nothing (§4.1). |
| ~~Player exits training while marked~~ | Unreachable since 2026-08-09 — the player is never marked (§4.1). `BountyService` still cleans up on `PlayerRemoving` and the survivor bonus is still skipped (§5.3), so this stays harmless if the guard is ever removed. |
| Step 10 times out with the panel open | Close it via `_G.ToggleStatMenu()` on the transition, exactly as on a successful advance. The dim backdrop must never survive into step 11. |
| Player opens the stats panel early (say during step 6) | Nothing special. It is not a gated action until step 10, and the step still requires an open *transition* while it is current, so an already-open panel does not auto-pass — close it on entering step 10 if it is open, then wait for the player. |
| A touch player has `AutoFireEnabled = false` | Step 3 falls back to the FIRE-button copy (§4.2) and gates identically on 3 shots. Never force the setting on. |
| The step 3 dummy fails to tag (or is streamed out) | Step 3 can still be passed by firing at nothing — the gate is 3 shots, not 3 hits. The lesson is weaker; it is not blocked. Do not add a hit requirement to "fix" this. **Reworded 2026-08-09:** the props are authored and always present, so "fails to spawn" is no longer the failure — an untagged or streamed-out prop is (§4.2). |

---

## 10. Open questions

All six original open questions were resolved on 2026-08-04 — see decisions 7-12 in §2. The three
raised by the 2026-08-07 revision were resolved the same day as decisions 14-16. Nothing in this spec
is waiting on an answer.

**One thing the revision surfaced that is flagged rather than decided:**

| Flagged | Detail |
|---|---|
| **The stats panel's tabs are unreachable by mouse on PC** | Not a tutorial defect — a live one the tutorial is the first thing to depend on. `Modal = false` on every `StatMenuGui` button and nothing frees the cursor on open, so with `MouseBehavior = LockCenter` held by the hunter client, only `M` (close) works without holding Alt. The tutorial works around it by teaching Alt first (§4.3), which is a reasonable lesson in its own right. **The underlying fix is one property** — `Modal = true` on the panel's buttons, or a cursor release in `setOpen` — and it belongs in `StatMenuGui`, not here. Worth raising as its own open item regardless of whether the tutorial ships. |

*(The other item flagged on 2026-08-07 — the bounty bot sharing the player's hunter — was resolved the
same day as decision 17: the bot is a Vesper and the roster is mixed. See §4.4.)*

What is **deferred rather than decided**, and where it would go if it comes back:

| Deferred | Re-entry point |
|---|---|
| Replay ("TRAINING" button in Bounty) | `BonusPaid` already guards the reward, and the whole Redwater side is mode-flagged rather than one-shot. Adding it is a button, a remote, and reusing `TutorialDispatchService`. Placement in the lobby is an open question if it ever ships — it is not implied by this spec. |
| "Your friend is in training" | Needs the tutorial server to publish *something* discoverable, which is exactly what §5.2 forbids. Would need a separate directory or a profile-side presence flag, not a match-directory entry. |
| Boundary handling | If the funnel shows players wandering off during steps 1-5, the cheapest fix is a distance check on `TutorialSpawn` driving a second banner state — no geometry. |
| A second hunter's tutorial | Everything hero-specific here is Dust's manifest bindables and the step copy. A Vesper or Bram version is a new step table, not a new system — but it is out of scope and unbudgeted. |

---

## 11. Test checklist

Nothing about routing is testable from Studio (MemoryStore needs API access, teleports do not run in
playtests, and `start_playtest` hangs the plugin connection). Studio can verify the lesson machine and
the UI; **live** must verify the transport.

**Studio:**
- [ ] The player spawns **at** `TutorialSpawn` and **facing** yaw −119.82° — not merely near it. Check
      the heading, not just the position: the facing is what every "in front of the player" in §4 is
      measured from, and a part authored by eye rather than by CFrame also spawns them a stud high
- [ ] Respawning mid-lesson returns them to the same spot on the same heading — **not** to a random
      one of the 44 `SpawnPoints`, which is what `hookCharacter` does if its `sendPlayerToRoundSpawn`
      call was not substituted
- [ ] **Die deliberately after t≈32s and confirm there is no burn-at-origin loop.** `LoadCharacter`
      drops at the world origin, which by then is inside the north wall; the player must never take
      fire damage on the way through, and must never respawn still carrying the burn ramp
- [ ] **The fire wall is visible and moving during the early steps**, and has settled at ±112.5 studs
      by ~90s. Watch it from the spawn without moving: the south wall is there from the first frame,
      the north wall enters the map at ~25s
- [ ] **The wall is at or near final when step 11 opens** on a normally-paced run. Deliberately rush
      every step and confirm the still-closing wall reads as the map tightening, not as a bug
- [ ] **The walls are symmetric** — 112.5 studs on *both* sides at rest. An asymmetric pair means
      `randomCenterOffset` is still being drawn rather than pinned (§5.3)
- [ ] **Nothing on screen ever names the zone.** No `Zone: Final - 0:42` readout, no `PHASE N • NAME`
      banner, no tutorial copy. If the readout appears, `ZonePhaseName` is being written
- [ ] Step 1's 60° look sweep brings a wall through frame — the step that teaches looking is what
      guarantees the wall is seen
- [ ] Walking into the fire burns and tints the screen (`ZoneAtmosphere` at 12 studs), and burning to
      death respawns at `TutorialSpawn` without breaking the step machine
- [ ] No bot ever takes zone damage or paths into the wall, at any step
- [ ] Each of the 11 steps advances on its real signal, and on its timeout with the signal withheld
- [ ] Step 9 does not appear on touch, and `ProgressLabel` reads `/ 10`
- [ ] **Step 3 passes on touch with the FIRE button never pressed** — crosshair held on the tagged
      dummy, three auto-fired shots, step advances. This is the check that would have caught the
      `FireRequested` defect (§5.4); a client-side gate fails it while the revolver visibly fires
- [ ] Step 3 still passes on PC by clicking, and on touch by tapping the red fire button
- [ ] The dummies are **not** present during steps 1-2 — sweep the crosshair across their spots on
      touch during the look step and confirm the revolver does not fire
- [ ] **All three dummies spawn, face the player, and stand still** — none turns to track, none walks,
      none reacts to being shot. Check each one's facing: a `StandDown` bot's authored rotation is
      permanent, so a mis-authored one presents its back for the whole step
- [ ] **The dummies cannot be killed.** Empty a full cylinder into one, fan the hammer at it, and land
      headshots — it stays up, its health bar never moves, no kill-feed row posts and no kill is
      credited to anyone
- [ ] **Shooting a dummy gives a hitmarker and the red hit flash.** That is the feedback step 3 actually
      runs on, and it is the thing most likely to be missing on a prop that is not a bot — if it is,
      check the rig still resolves through `HunterCharacterUtil.GetHitCharacterAndHumanoid`
- [x] **No `AimAssistTarget` instance sits inside `workspace` in the authored place** — verified 0 on
      2026-08-09. Re-check after any edit near the templates: a tag left live ships an auto-fire magnet
      into ordinary matches and nothing errors
- [ ] The three appear **on entering step 3** and are gone when step 6's bots walk in, and a touch
      player sweeping the crosshair over their spots during steps 1–2 does not fire
- [ ] The director **clones** the templates rather than reparenting them — run two tutorials back to
      back in one server and confirm the second one still has targets
- [ ] `ModelStreamingMode = Persistent` survives the clone — join on a throttled connection and confirm
      the target is there when step 3 opens, not a streamed-out gap
- [x] Each prop faces the player (0.00° error) and stands on the terrain (sink ≤ 0.006 studs), levelled
      rather than inheriting the source prop's slope tilt — measured 2026-08-09 (§4.2)
- [ ] **Steps 4 and 5 advance on PC**, on Q and E, with no mobile cluster on screen. This is the check
      that would have caught the `DashRequested` / `Skill2Requested` defect (§5.4) — both fire only from
      the touch tiles, so a client-side gate times out for every PC player while the dash and the fan
      visibly happen
- [ ] Step 5 still advances for a player who let step 4 time out with an empty cylinder: the first E
      press starts a reload rather than a fan, and the second one fans six (§4.2)
- [ ] With `AutoFireEnabled = false` on a touch device, step 3 shows the fire-button copy and still passes
- [ ] **No banner names a button by a label that is not on it** (decision 19, §4.6). Read every touch
      line on a real handset with the cluster visible: **all five buttons are glyphs, not words**
- [ ] **Step 2 glows SPRINT and not JUMP.** The two sit adjacent and both glyphs are human figures, so
      this is the cue most likely to be attached to the wrong button — and a mis-cue makes the player
      jump, which never satisfies the step. Confirm by tapping exactly what is lit
- [ ] **All five cluster buttons are on screen for the whole lesson** on a touch device — FIRE, SPRINT,
      JUMP, RELOAD, and SCOPE if the player is Vesper. Their authored default is `Enabled = false` and
      tutorial mode skips the round lifecycle that normally restores them (§4.6, point 6)
- [ ] Step 1's look-drag instruction does not send the thumb onto a button — dragging where the copy
      says to drag must rotate the camera, not fire a shot or jump
- [ ] **The glow renders BEHIND its target on both hosts** (§4.7) — screenshot it lit on a cluster
      button (`ZIndexBehavior = Global`) and on an ability tile (`Sibling`). The failure mode is the
      light appearing to sit in front of the glyph, which is the authored translucency showing it
      through, **not** a ZIndex mistake — do not "fix" it by raising ZIndex
- [ ] The glow **follows its button** through a rotation and a windowed resize —
      `HunterMobileClusterLayout` rewrites cluster positions on every `AbsoluteSize` change
- [ ] The lit button's authored `BackgroundTransparency` (0.35 on FIRE, 0.5 elsewhere) is **restored**
      when the step advances, on timeout, and on EXIT TRAINING mid-step
- [ ] A step whose target is absent shows no cue and no error — SCOPE on a non-Vesper player, the whole
      cluster on PC, the HUD clone before the hunter runtime has started
- [ ] The PC keycap pulses on steps 2, 9 and 10 and is **hidden on touch**; it is not shown on 4/5/7,
      which glow the ability tile on both platforms
- [ ] **Step 10 opens the panel and advances**, on M (PC) and the STATS button (touch); it does **not**
      advance on an M press that the panel ignored
- [ ] Step 10's panel shows `THIS MATCH` kills of 3, not 0 and not a previous round's figures — both
      the My Stats tiles and the Scoreboard row
- [ ] The panel is closed on the way into step 11 — no dim backdrop over "they shoot back now"
- [ ] The tutorial banner is readable **through** the stats backdrop (`DisplayOrder` 45 vs 20)
- [ ] **Sprint works at all in tutorial mode** — `State.roundActive` is true, so `SetCanSprintCheck`
      passes. Step 2 advances on hold-LeftShift (PC) and on the SPRINT toggle (touch), and does
      **not** advance on walking alone
- [x] `HoldFire` bots never fire — **confirmed in a playtest 2026-08-08**; step 11 bots do
- [ ] `StandDown` bots hold position completely: they do not walk, do not turn to face the player, and
      do not react to being shot. Check the step 7 line (the step 3 dummies are anchored props now and
      are covered by their own items above)
- [ ] The step 7 line: **all five lock and all five die to one High Noon**. Placement is the risk, not
      the code — 180 studs, 45° half-cone, and depth is cheaper than width (§4.5, positions in §4.9)
- [ ] **Fire the ultimate from where step 6 actually left you.** Under decision 23 that should be at or
      near `TutorialSpawn`, where all five lock. **The real check is where the player is standing**, not
      the lock itself: if step 6 has drawn them forward past ~33 studs the line starts dropping bots,
      and past ~22 studs step 8's cover is already gone (§4.1). If it reads as 2 of 5, the line or step
      6's arrival has to move — not `ConeAngle`
- [ ] **Measure the actual drift.** Log the player's distance from `TutorialSpawn` as each of steps 7
      and 8 opens, across a few real playthroughs including a deliberately restless one. Decision 23 is
      a claim about behaviour and this is the only thing that tests it; ~22 studs is the number that
      matters (§4.1), and steps 2 and 3 are where the drift would come from
- [ ] None of the five stands with its shins in the ground: the line drops 3.87 studs and bows 1.44
      studs off a straight lerp, so each y is raycast (§4.9)
- [ ] **Step 8's gold outline is actually seen through cover**, from where step 7 leaves the player.
      Under decision 23 that is at or near `TutorialSpawn`, where the ray HITS the lumber — but the
      cover dies between **+20 and +25 studs** of drift (§4.1), so check where they are standing before
      concluding the anchor is wrong. Drift is the first suspect; the anchor is the second
- [ ] **Step 11's bots reach the player inside the step.** Half the spawn pool is 120+ studs out and one
      draw is 412 (§4.10). If the step keeps ending before contact, lengthen it or filter the pool —
      do not author positions
- [ ] A step 11 bot that draws a spawn inside the fire walks **out** of it rather than standing in it,
      and takes no zone damage on the way (§4.10)
- [ ] Step 11 bots at `Training` cannot kill in fewer than three hits. Stand still and let a Vesper
      and a Bram shoot you; if either takes more than half the bar in one hit, `DamageMultiplier` is
      not being applied
- [ ] A despawned bot is **not replaced** — `SetPopulationLocked(true)` is in effect — and credits no
      kill or death to anyone
- [ ] Bots stay within ~60 studs of `TutorialSpawn` and do not path off across the canyon. Test a
      **Dust** bot specifically: its combat strafe bypasses `RequestMove` and is clamped separately
- [ ] A routed bot walks its waypoints in order and stands down where the route ends
- [ ] **Step 6's two bots are never seen appearing.** Stand at `TutorialSpawn` as step 6 opens: the
      lumber pile hides the entry, and the first sight of them is ~30 studs out and already walking
      (§4.8). A bot popping into view at range means the entry point moved
- [ ] **Both bots keep moving after they arrive** — `HoldAtEnd = false`. If either freezes on the
      middle dummy's old spot, step 6 has become target practice on statues (§4.8)
- [ ] The two do not spawn inside each other, and neither paths into a surviving target dummy
- [ ] **The step 8 Vesper walks to the player and waits there** (decision 18) — she never perches,
      never grapples, and above all **never backs off toward her `DesiredRange` of 150**, which is
      the specific thing `SetApproach` overrides and the reason a leash or a route would not do.
      Verify with the player standing still at `TutorialSpawn` doing nothing, then again with the
      player walking away: she should follow rather than stop where they used to be
- [ ] No bot fires an **ultimate** at any point in the tutorial — `TryUltimate` runs inside
      `ThinkAbility`, so this is the check that the veto sits high enough in it
- [ ] All four hunters appear across the lesson, and **no Dust bot is alive during step 11** — so the
      only Dust card on the bounty panel is the player's own
- [ ] Step 6's two kills are achievable inside 30s: Dust and Fortuna at 150 HP are 5 body shots each
- [ ] `UltimateChargeService:Set` fills the HUD ring at step 7
- [ ] Step 8: three `registerBotKill` calls mark the bot, and the gold `BountyHighlight` reads
      **through** the cover between `TutorialSpawn` and `TutorialBountySpawn` — stand at the spawn and
      look; if the outline is only visible in the open, the anchor is wrong, not the code. **This is
      still required under decision 18**: the bot spawns behind cover and only then walks out, so a
      spawn point with no cover deletes the through-wall lesson even though the step still completes
- [ ] The bot's **card** appears in the top-centre bounty row with a live value and a rendered
      portrait, and reads CLAIMED on the kill
- [ ] The banner clears the card row by 8px with a card up, at every swept viewport — not on an
      empty screen (§5.5)
- [ ] Claiming pays **nothing**: wallet, `data.XP`, quest progress and battle-pass progress all
      unchanged across the whole tutorial (snapshot the profile before and after, not just the wallet)
- [ ] **The player is never marked, at any point in the whole lesson.** Play it through killing
      everything available — 2 bots in step 6, 5 in step 7, the bounty bot in step 8, three more in
      step 11 — and confirm no gold outline on the player, no "BOUNTY ON YOU!" popup, no bounty music
      switch, and no second card in the row after the claim. This is the check for the `registerKill`
      guard (§4.1); without it the player is marked partway through step 7
- [ ] Timing out with the bot alive clears its bounty and leaves no stranded row on the panel
- [ ] EXIT TRAINING is reachable and ≥44×44px on a small phone, tablet, and windowed desktop
      (`capture_device_matrix`)
- [ ] Banner collides with neither the top-right pinned cluster nor the top-left chat at any size
- [ ] Ability tags are forced on even with `AbilityDescriptions = Off`

**Live (first publish):**
- [ ] **A tutorial server never appears in the match directory.** Check the sorted map while one is
      running. This is the gate — everything else is cosmetic next to it.
- [ ] A normal reserved server still publishes after the added mode-resolution read
- [ ] An existing veteran account is grandfathered and sees no card
- [ ] **The welcome card is actually seen.** Join on a fast connection with a warm cache — the case
      where profile load most beats the intro — and confirm the card appears *after* the camera lands
      on the lobby, never behind the veil or mid-pan, and that its 4s sliver starts from the moment it
      became visible rather than from when the remote arrived (§5.1)
- [ ] The card covers the main menu, which `LoadingScreen` re-enables at handoff
- [ ] **The tutorial funnel records all eleven steps for a fast player.** Someone who clears steps 1-10
      in ~50s fires the whole funnel inside one rate-limit window (`MAX_PER_PLAYER_PER_MIN = 30`), and
      a drop is silent. Budgeted at ~17 in the worst window (§7), so this should pass — a funnel that
      cliffs at the same step for every fast player is the limiter, not the lesson
- [ ] **The aggregates are one event, not eleven.** This is the single thing the rate-limit headroom
      depends on (§7); confirm it in the director rather than trusting the spec
- [ ] **A tutorial does not appear in the `MatchLoop` funnel** — no "Match Requested", no "Round
      Started" and above all no "Reached Buzzer" for a tutorial session. `RoundController` fires those
      four steps outside `tryLogFunnelStep`, so they need their own suppression (§5.3)
- [ ] Step 9's funnel number is read **filtered to PC**. Roblox backfills skipped steps, so every touch
      player who reaches step 10 is counted as having completed the ALT step they were never shown (§7)
- [ ] The tutorial funnel's step 1 carries Platform in `CF01` — without it the per-platform splits for
      steps 3 and 10 cannot be read at all, since breakdowns use the first step's fields only (§7)
- [ ] The `MatchLoop` funnel is unaffected: a tutorial player's *first real match* still fires steps 4-7
- [ ] A brand-new account is dispatched, completes, returns, and is paid once
- [ ] Rejoining does not re-trigger it
- [ ] `skip for now` never asks again
- [ ] Exiting mid-tutorial pays nothing and does not re-trigger on the next join

---

## 12. Release notes

- **Data-affecting.** Adds a profile field and pays currency. Reverting the places does not undo
  either — mark the release accordingly in `CHANGELOG.md`.
- Both places ship together, always — `Wallet` and the `DataService` template are mirrored, and a
  half-published experience is a live drift bug.
- Run `/preflight` before publishing.
