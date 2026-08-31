# Redwater Canyon — Infinite Match Loop + Combined Summary Screen

**Status:** specified, not implemented. Written 2026-08-06.
**Scope:** Redwater Canyon only. **No Bounty code change is required** (verified — see §7).

---

## 1. Goal

Redwater currently plays **one** match and then kills the server: `closeServer()` teleports
everyone back to Bounty and drains. This changes it to loop matches indefinitely, and collapses
the three-step match-end sequence into two.

**Before**

| Step | What | Duration |
|---|---|---|
| 1 | Dust cinematic + "MATCH COMPLETED" | ~8.15s |
| 2 | Top-3 podium reveal, CONTINUE button | until clicked |
| 3 | Match stats + RETURN TO BOUNTY button | remainder of 30s |
| — | `closeServer()` → everyone teleported to Bounty | — |

**After**

| Step | What | Duration |
|---|---|---|
| 1 | Dust cinematic + "MATCH COMPLETED" | ~4.08s (halved) |
| 2 | Podium (screen-right) **+** match stats (screen-left) **+** countdown (bottom-centre) **+** RETURN TO BOUNTY (bottom-right) | ~12.4s |
| — | intermission countdown → next match | 5s |

Nobody is auto-teleported to Bounty. The only ways out of Redwater are the RETURN TO BOUNTY
button during step 2, and the settings panel's leave button — both already fire
`LeaveToLobbyRequest`, handled by `LeaveToLobbyService`. Neither needs changing.

---

## 2. Decisions already taken

These were settled with the project owner. Do not re-litigate them.

1. **Podium moves right via a runtime camera offset** — nothing in the world moves.
2. **The local player's own podium dummy is dropped entirely.** `PlayerLocal`,
   `SpotlightPartVictoryLocal` and `CameraPartLocal` become unused; the camera holds the
   stadium shot for all of step 2. The player's own result is fully covered by the stats panel.
3. **The 10s countdown starts after the #1 reveal lands**, not at the start of step 2.
4. **Late joiners are held for the next round**, not bounced to Bounty.
5. **`CanvasContinue` is deleted** from the data model along with its wiring.
6. **Server retirement policy:**
   - after **5 completed rounds** (~32 min) the server stops accepting *matchmade* players;
     **friend joins continue to work**;
   - once retired **and** empty of humans, it closes;
   - **1 hour** wall-clock cap — the round in progress plays to the buzzer, then it closes
     (worst case ~66 min).

---

## 3. Measured facts the design rests on

Verified live against the Studio data model, 2026-08-06. Re-verify if these drift.

- Cinematic clip `rbxassetid://138087029355149` is **exactly 2.000s**, played at
  `AdjustSpeed(0.35)` ⇒ `cutTime = (2.000 - 0.12) / 0.35 = 5.371s`.
- `VictoryShowcase.Canvas` (the stats panel) is already `Size (0.3, 1)` at `Position X = 0.15`
  — **it already occupies the left 30%.** Nothing needs moving there.
- `VictoryShowcase.TimerCanvas` → `TimerLabel` **already exists**, authored at
  `Position (0.5, 0.927)`, `Size (0.2, 0.063)`, text `"RETURNING TO LOBBY IN: 00:20"`, and is
  referenced by **no script in the place**. This is the step-2 countdown; it only needs driving
  and new copy.
- `VictoryShowcase.CanvasReturnToBounty` is at `Position (0.875, 0.900)` — already bottom-right.
- Podium geometry: `CameraPartStadium` sits **21.25 studs** from the mean of Player1/2/3.
  In camera space the slots are at `x = +0.10 (P1, z −16.3)`, `−10.41 (P2, z −23.2)`,
  `+10.65 (P3, z −23.8)` — a ~21-stud span. `VictoryScreenBoxModel` is 150 × 117.8 × 150,
  so there is ample room to dolly back inside it.
- `DailyRewardService.registerPlay` is **idempotent per UTC day** — safe to call once per
  looped round. (`RankedService.awardRound` is deliberately per-round and *should* fire each time.)

---

## 4. Client — `StarterPlayer.StarterPlayerScripts.VictoryShowcaseClient` (2831 lines)

### 4.1 Halve step 1

All in `runVictoryCinematic` unless noted. Target total **4.08s** (exactly half of 8.15s).

| Where | From | To |
|---|---|---|
| `spawnCinematicAvatar` → `track:AdjustSpeed(...)` | `0.35` | `0.70` |
| bars close — `tweenCinematicBars(0.5, 0.28)` | `0.28` | `0.14` |
| bars open — `tweenCinematicBars(0.11, 0.5)` | `0.5` | `0.25` |
| fade to black — `tweenCinematicFade(0, 0.35)` | `0.35` | `0.18` |
| hold on the stadium set — `task.wait(1.65)` | `1.65` | `0.82` |
| fade up — `tweenCinematicFade(1, 0.5)` | `0.5` | `0.25` |

`getCinematicCutTime` needs no edit — it divides by the playback speed, so doubling the speed
halves `cutTime` to **2.686s** on its own. **But make the `0.35` there a shared constant** with
the `AdjustSpeed` call rather than two literals that must agree; they are the same number and
silently desync otherwise.

**The muzzle flash constant must change.** It is currently
`math.max(0, math.min(3, cutTime * 0.62) - elapsed)`. At the old speed the `min(3, …)` cap
*binds* (0.62 × 5.371 = 3.33 → clamped to 3.0), putting the flash at clip-time
3.0 × 0.35 = **1.05s of the 2.000s clip**. At the new speed the cap no longer binds and `0.62`
would drift the flash to clip-time 1.166s. Replace the whole expression with a clip-time
constant so it lands on the same animation frame regardless of playback speed:

```lua
local MUZZLE_CLIP_TIME = 1.05 -- seconds INTO the 2.0s clip, where the shot actually fires
local muzzleDelay = math.max(0, (MUZZLE_CLIP_TIME / CINEMATIC_PLAYBACK_SPEED) - elapsed)
```

### 4.2 Collapse steps 2 and 3 into one screen

In `startVictoryShowcase`'s `runVictoryCinematic` completion callback:

- Keep the three staggered `revealRank` calls (3rd at t=0, 2nd at 0.95, 1st at 1.90).
  Each reveal is `REVEAL_FADE_DELAY` 0.05 + `REVEAL_FADE_INFO` 0.4, so **#1 is fully in at
  t = 2.35s**. Call this `REVEAL_SEQUENCE_TIME = 2.35`.
- **Delete** the `setupVictoryShowcaseGui(currentStats, 3.0, onContinue)` callback body
  entirely — the local-dummy spawn, `setSpotlightEnabled(scene.Spotlights.Local, true)`,
  the `playVictorySound("Spotlight", …)` on the local spotlight, and
  `tweenCameraToLocalPlayerPart()`. Per decision 2 none of that survives.
- Rewrite `setupVictoryShowcaseGui(stats, revealDelay, countdownSeconds)` so that at
  `t = REVEAL_SEQUENCE_TIME` it does what the CONTINUE handler used to do inline:
  `populateVictoryCanvas`, the position slide-in tween, `tweenGuiToState` on `canvas`,
  **plus** `canvasReturnToBounty` **plus** the new `timerCanvas` — all three fading in together
  on the same curve.

**Delete** `continueButtonConnection` and every reference to `canvasContinue` /
`ContinueBackground` / its `TextButton` (~50 lines). Keep `returnButtonConnection` exactly as
it is — it already fires `leaveToLobbyRequest:FireServer()` and hides its own canvas.

`tweenCameraToLocalPlayerPart`, `getLocalCameraPart`, `LOCAL_PLAYER_CAMERA_FOV` and
`LOCAL_CAMERA_TWEEN_TIME` become dead. Remove them, and drop `PlayerLocal` /
`Spotlights.Local` from `getFinishSpawns`'s required-parts validation so a future cleanup of
those parts cannot fail the whole scene lookup.

### 4.3 Move the podium to screen-right — camera offset

Where the cinematic cuts to the stadium shot (`camera.CFrame = scene.StadiumCamera.CFrame`),
apply an offset in **camera object space**.

Do **not** hardcode a stud offset. The podium spans ~21 studs and the visible width at that
distance is only ~41.6 studs at 16:9 — a naive strafe pushes rank 3 off the right edge, and
the framing changes completely on a narrow viewport. This is the same trap documented for
`getPodiumPlateScale` in the vault: a fixed number picked at one viewport is wrong at every
other one. Compute it from the live aspect ratio:

```lua
local PODIUM_SHIFT_FRACTION = 0.15  -- fraction of SCREEN WIDTH to push the podium right
local PODIUM_DOLLY_BACK     = 9     -- studs, to buy horizontal room for the shift

local function stadiumCameraCFrame(scene)
	local base = scene.StadiumCamera.CFrame
	local cam  = workspace.CurrentCamera
	local vp   = cam.ViewportSize
	local aspect = math.max(0.1, vp.X / math.max(1, vp.Y))

	-- Distance to the podium AFTER dollying back, since that is where it will be framed.
	local distance = 21.25 + PODIUM_DOLLY_BACK
	local halfWidth = distance * math.tan(math.rad(VICTORY_CAMERA_FOV / 2)) * aspect
	local strafe = PODIUM_SHIFT_FRACTION * 2 * halfWidth

	return base * CFrame.new(-strafe, 0, PODIUM_DOLLY_BACK)
end
```

Reasoning for the two constants, so they can be re-derived rather than re-guessed:
at 16:9 the podium already fills ~50% of the frame, leaving no room to shift it 15% without
clipping rank 3. Dollying back 9 studs (to d ≈ 30) narrows it to ~36% of the frame; the
0.15 shift then puts the podium's drawn span at roughly **0.33 → 0.87** of screen width —
clear of the stats panel's right edge at 0.30, and clear of the screen edge. The ~0.09
screen-width the BillboardGui plates add on each side is included in those figures.

Apply the same CFrame everywhere the stadium shot is set (there is one site today; make it a
single helper so a second site cannot drift).

`VictoryScreenBoxModel` is 150 studs across, so a 9-stud dolly stays well inside the set.
**Verify anyway** — see §8.

### 4.4 Drive the countdown

`TimerCanvas` / `TimerLabel` already exist and are unwired. Fade `TimerCanvas` in with the
stats canvas at `REVEAL_SEQUENCE_TIME`, then tick it down once per second from
`countdownSeconds` (from the server payload — see §5.3; never a client-side literal, or the
client and server drift and the intermission starts while the panel is still up).

Copy changes from `"RETURNING TO LOBBY IN: 00:20"` to **`"NEXT MATCH IN: 10"`**, counting down
to `"NEXT MATCH IN: 1"`. No `mm:ss` — the value is always single digits.

`TimerLabel` styling must follow `UI_STYLE_GUIDE.md`; read it before touching the label. It is
authored already, so prefer leaving its visual properties alone and only writing `.Text`.

---

## 5. Server — `ServerScriptService.RoundSystem`

### 5.1 `Config`

```lua
-- Match summary, in three parts so the client and server cannot drift.
SUMMARY_CINEMATIC_TIME = 4.1,   -- step 1, halved
SUMMARY_REVEAL_TIME    = 2.4,   -- podium 3rd -> 2nd -> 1st
SUMMARY_COUNTDOWN_TIME = 10,    -- the on-screen counter
-- Derived: the server must outlast the client's whole sequence, never the reverse.
POST_GAME_VICTORY_TIME = 4.1 + 2.4 + 10 + 0.5,  -- 17.0

-- Server retirement. See MATCH_LOOP_SPEC.md section 2.6.
SERVER_RETIRE_AFTER_ROUNDS = 5,
SERVER_MAX_LIFETIME = 3600,
```

Keep the name `POST_GAME_VICTORY_TIME` — `startVictoryShowcase` and the round-end
`task.wait` both read it, and so do comments in `hookCharacter`. Write it as the sum above
rather than a bare `17` so the relationship is visible at the definition.

### 5.2 `RoundController.Start` — the loop

Wrap the body of the `task.spawn` (currently lines ~1408–1632) in `while true do … end`.

**Per-iteration reset.** These already happen inside the body and are correct as-is:
`State.playerKills/playerDeaths/botKills/botDeaths`, `RoundStatsService.Reset()`,
`QuestEvents.reset()`, `BountyService.resetAll()`, `ZoneService.resetZone()`,
`DestructibleService.resetDestructibles()`, `BotService.PrepareRound/ActivateRound/EndRound`.

**Replace the tail.** Currently:

```lua
task.wait(Config.POST_GAME_VICTORY_TIME or 15)
setStatus("Returning to lobby...", 0)
closeServer()
```

becomes: wait the summary out, then **tear the summary down and loop** —

1. `VictoryShowcase:FireAllClients("Clear")`
2. `unfreezeAllPlayers()` — this currently only ever runs inside `closeServer`. If it is not
   moved here, every player stays anchored with `VictoryFreeze`, `ACImmune` and their
   `VictoryImmunityField` for the whole of the next round. **This is the single most
   load-bearing line in the whole change.**
3. `setFinishPillarsVisible(false)`, `setVictoryBoxVisible(false)`
4. evaluate retirement (§5.4); `break` if it fires
5. loop — the top of the body already re-runs `setStatus("Waiting for players…")`, the
   `MIN_PLAYERS` wait, the jail teleport and the 5s intermission countdown.

`State.roundActive`, `roundActive.Value` and `workspace:SetAttribute("RoundTimeLeft", 0)` are
already reset in the body's opening lines.

**The `"Not enough players!"` branch** (~line 1441) currently calls `closeServer()` and
`return`s. Under the loop it must **`continue`** instead — fall back to waiting for players.
Only the retirement path may close the server now.

### 5.3 Phase rename: `"Ended"` → `"Summary"`

`State.roundPhase = "Ended"` at the buzzer becomes `"Summary"`. Reserve `"Ended"` for the
retirement path only (set it in `closeServer`).

This is what lets Bounty distinguish "wrapping up a round, back in 17s" from "this server is
going away" **with no Bounty code change at all** (§7).

Every existing `"Ended"` comparison in `RoundController` must move to `"Summary"`:
`hookCharacter` (~947, ~989, ~1055) and the `setupPlayer` late-arrival flag (~989).

`startVictoryShowcase` gains `countdownSeconds = Config.SUMMARY_COUNTDOWN_TIME` in the payload
alongside the existing `duration`.

### 5.4 Retirement

Module-level: `local roundsPlayed = 0` and `local serverStartClock = os.clock()`.

Increment `roundsPlayed` at the buzzer. Then at the point marked (4) in §5.2:

```lua
-- Stop matchmaking filling this server once its code is getting old. Friend joins are
-- deliberately still allowed: they gate on `hardCap`, not on `open`.
if roundsPlayed >= Config.SERVER_RETIRE_AFTER_ROUNDS and not matchmakingRetired then
	matchmakingRetired = true
	MatchDirectoryService.setMatchmakingClosed()
end

-- Retired and nobody left: nothing to keep the loop alive for.
if matchmakingRetired and #Players:GetPlayers() == 0 then
	closeServer()
	break
end

-- Wall-clock cap. Checked HERE, after the buzzer, which is what makes it
-- "finish the round in progress, then retire".
if os.clock() - serverStartClock >= Config.SERVER_MAX_LIFETIME then
	closeServer()
	break
end
```

The empty check must sit **before** the `MIN_PLAYERS` wait at the top of the body, otherwise a
retired empty server blocks there forever instead of closing.

`closeServer()` is otherwise unchanged and still does the right thing — `setClosing()`,
fade, `VictoryShowcase "Clear"`, `unfreezeAllPlayers`, re-grant `ACImmune`,
`teleportAllToLobby`, 12s drain, kick.

> `ServerScriptService.SoftShutdown` **cannot** be used for this. It is a `BindToClose`
> handler — it only runs when Roblox kills the server and is not callable. `closeServer()` is
> the self-retirement path.

### 5.5 Late joiners

`forwardLateJoiner` stays, but is now only reachable when `serverClosing` is true.

In `setupPlayer`, **stop setting `lateArrivals[player] = true`** when the phase is `"Summary"`
— that flag exists solely to feed `forwardLateJoiner`. In `hookCharacter`'s summary branch,
drop the `if lateArrivals[player] then forwardLateJoiner(player) return end` block. The
surviving behaviour — `GameplayVisibility:FireClient(player, false)` +
`sendPlayerToJailSpawn` — is exactly "hold them for the next round".

**Do not freeze them.** `freezePlayerForVictory` in that branch is for players who *played* the
round and are watching their own podium. A joiner who arrives during the summary should stand
in the cage unfrozen and be picked up by the next round's countdown.

`lateArrivals` is still needed for the `serverClosing` path — keep it.

### 5.6 Analytics under looping

- `logMatchStart` / `logMatchCompletion` now fire **once per round per player**, which is
  correct: a player who stays 5 rounds genuinely played 5 matches, and `MatchesPlayed` /
  `SittingMatchIndex` should advance 5 times.
- **`matchFunnelIdByUserId` must be re-minted per round** for players already present.
  `Telemetry.logFunnelStep(player, 5, …)` at the buzzer would otherwise fire step 5 repeatedly
  against one session id and double-count the `MatchLoop` funnel. Mint a fresh id at round
  start for anyone whose funnel already completed.
- `DataService.tryLogFunnelStep` (the onboarding funnel) is persist-deduped once-ever, so it
  needs nothing.

---

## 6. Authored UI — `StarterGui.VictoryShowcase`

1. **Delete** `CanvasContinue` (and its `ContinueBackground` → `TextButton` subtree).
2. **`TimerCanvas`** — keep the authored geometry. Change `TimerLabel.Text` to
   `"NEXT MATCH IN: 10"` as the authored default. Add it to the `applyVictoryCanvasScale`
   calls alongside `Canvas` and `CanvasReturnToBounty` so it takes the same
   `getVictoryEndScreenScale()` ladder.
3. `Canvas` and `CanvasReturnToBounty` — **no geometry change.** Both are already positioned
   correctly for the new layout.

Read `UI_STYLE_GUIDE.md` before editing any of these. Nothing here should need a new component
recipe — the frames already exist and are authored.

---

## 7. Bounty — verified, no change required

Both consumers of the directory entry were read at spec time:

- `MatchmakingService.acceptsMatchmaking` — `if entry.closing or not entry.open then return
  false end`, then special-cases **only** `phase == "Fight"` for the join lock and otherwise
  `return true`. A `"Summary"` entry is therefore governed purely by Redwater's `open` flag.
- `FriendJoinService.evaluateEntry` — refuses on `entry.closing or entry.phase == "Ended"`.
  `"Summary"` passes; `"Ended"` (now only ever published by a retiring server) still refuses,
  with the correct "wrapping up" message.

Had the summary kept publishing `"Ended"`, a friend pressing Join during the podium would have
been told *"Your friend's match has already ended."* — which is precisely why §5.3 exists.

**`MatchDirectoryService` (Redwater) does need two edits:**

- add `setMatchmakingClosed()` setting a `matchmakingClosed` flag, and make `isOpen` return
  false when it is set — **without** touching `closing`, which must stay false so friend joins
  and the directory entry itself survive;
- add `phase == "Summary"` to the `isOpen` allow-list next to `Waiting`/`Countdown`/`Starting`
  (a player matchmade into a summary waits for the next round, per decision 4).

Note this is **not** one of the 16 mirrored modules — `MatchDirectoryService` is Redwater-only.
No mirror work in this change. Both places still publish together regardless; that rule is
unconditional.

---

## 8. Verification

Playtesting over MCP is unavailable (`start_playtest` hangs the plugin connection), so:

**Syntax** — recompile every edited script with `loadstring(script.Source)` via `execute_luau`
before reporting done.

**Camera framing** — park the Studio edit camera on the computed CFrame and
`capture_screenshot`. Check across `set_device_simulator` at minimum a small phone, a tablet
and a **windowed** desktop (a windowed PC is near-square and is the aspect the strafe maths is
most sensitive to). Confirm on each:
- no podium dummy or its plate crosses `x = 0.30` into the stats panel;
- rank 3's plate does not clip the right edge;
- the `VictoryScreenBoxModel` backdrop edge is not visible after the 9-stud dolly.

Studio's default viewport is the one size no player has — it does not count as a check.

**Timing** — assert the client sequence total (4.08 + 2.35 + 10 = 16.43) stays under
`POST_GAME_VICTORY_TIME` (17.0). If step 1 is retuned, retune the Config sum with it.

**Manual checklist for a real playtest** (cannot be automated here):
1. Round 2 starts and players can move — proves `unfreezeAllPlayers` moved correctly (§5.2.2).
2. A player who joins during the summary spawns into the next round rather than bouncing.
3. The countdown reads 10 → 1 and the intermission begins as it hits 0.
4. RETURN TO BOUNTY still teleports out mid-summary, with party data intact.
5. Round 6 onward: a friend can still join; matchmaking sends new players elsewhere.

---

## 9. Documentation obligations

Per `CLAUDE.md`:

- **Vault** — update `LocalRedwaterCanyon/StarterPlayer/StarterPlayerScripts/VictoryShowcaseClient.md`
  (steps 2/3 merged, local dummy dropped, camera offset, countdown), and
  `LocalRedwaterCanyon/ServerScriptService/RoundSystem/RoundController.md` (the loop, the
  `"Summary"` phase, retirement, late joiners). Also `MatchDirectoryService.md` and `Config.md`.
  Then run `python update_redwater_canyon_graph.py` as a bare command.
  **No new `[[wikilinks]]` unless a real `require()`/Remote/Bindable was added** — this change
  adds none, so the edge count must not move. Verify with a grep of `graph.json`.
- **Changelog** — an entry in `changelog/UNRELEASED.md`, appended with an `Edit` anchored on a
  section heading, never a whole-file `Write`. Flag it clearly: this changes the round loop and
  the server lifecycle, and it is **not** data-affecting (no profile shape, Wallet reason, XP
  curve or RP change).
- Run `/preflight` before publishing. Both places go out together.

---

## 10. Open questions / things deliberately not done

- **`ROUND_TIME` is untouched at 360s.** A looping server may want shorter rounds; not in scope.
- **`COUNTDOWN_TIME` stays 5s.** Total between-match downtime is ~22s (4.1 cinematic + 12.4
  summary + ~1 wind-down + 5 intermission). Worth watching once it is playable.
- **`PlayerLocal`, `SpotlightPartVictoryLocal`, `CameraPartLocal` are left in the world**
  after decision 2 makes them unused. Deleting authored world parts was not authorised here;
  raise it separately if the clutter matters.
- **The muzzle-flash clip time (1.05s) preserves today's framing exactly**, but today's framing
  was tuned against a 3.0s cap that happened to bind. If the flash reads early or late at the
  new speed, that constant is the knob — not the playback speed.
