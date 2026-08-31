# Tutorial Relocation Spec

**Move the Redwater onboarding lesson out of the canyon floor and into the purpose-built walled
tutorial bowl.** Authored 2026-08-16. Every number below was measured against live Studio geometry
on that date — re-measure before trusting any of it if the builder has moved parts since.

Status: **specified, not started.** No instance has been created, moved or anchored; no script has
been edited.

---

## 0. What exists today

The lesson runs on the canyon floor around `workspace.TutorialSpawn` (a Part at
`-69.4, 9.0, -257.4`), with all bot choreography hardcoded as canyon `Vector3`s inside
`TutorialDirector`. A new walled tutorial bowl has been built roughly 1500 studs west and is
currently **inert** — nothing in either place's code references a single one of its parts.

The bowl sits at **X −1446…−1809, Z +58…−289**, floor y 0–50, perimeter walls to y 200. For scale,
the playable canyon (`WallMap`) spans X −237…290, so the two do not overlap on any axis.

### Instance inventory (26 root instances, all at `workspace` root today)

| Group | Instance | Count | Position / extent |
|---|---|---|---|
| Areas | `TutorialSpawn` **(Model)** | 1 | pad at −1538.7, 6.1, −26.1 · `Union` + `Checkpoint` |
| | `CheckPointTutorial1` | 1 | −1576.1, 8.3, −40.5 |
| | `CheckPointTutorial2` | 1 | −1637.3, 38.1, −118.7 |
| | `CheckPointTutorial3` | 1 | −1728.0, 22.8, −199.6 |
| Walls | `WallTutorial` (14 × `WallPartTutorial`) | 1 | perimeter, 30 thick, y to 200, transp 0.70 |
| | `TutorialWallStep1` (4 × `Step1Walls`) | 1 | X[−1678…−1547] Y[10…85] Z[−139…−66], transp 0.65 |
| | `TutorialWallStep2` (5 × `Step2Walls`) | 1 | X[−1737…−1634] Y[14…135] Z[−234…−73], transp 0.65 |
| | `SurfaceGuiTutorialPart1` | 1 | −1646.3, 35.2, −75.2 · on wall 1's face |
| | `SurfaceGuiTutorialPart2` | 1 | −1682.7, 38.8, −164.7 · on wall 2's face |
| BotSpawns | `PassiveBotSpawn` | 2 | −1643.9, 50.5, −188.3 · −1703.6, 49.9, −100.7 |
| | `UltimateBotSpawn` | 6 | see §4 |
| | `BountyBotSpawn` | 1 | −1639.6, 50.4, −183.1 |
| | `FreeRoamBotSpawn` | 8 | see §5 |

Both SurfaceGui parts carry a `SurfaceGui` (Top face) → `TextLabel` reading
**"FINISH THE PREVIOUS TASK"**, and each sits inside its gate wall's footprint.

None of these carry a tag, an attribute or a script. All wiring is to be written.

### Step → area binding

The bowl's three areas map onto the existing `STEPS` table with no step reordering:

| Area | Runtime steps | Anchor pad | Gate out |
|---|---|---|---|
| 1 | 1 `Move` · 2 `Shoot` · 3 `Dash` · 4 `Fan` | `TutorialSpawn`, `CheckPointTutorial1` | `TutorialWallStep1` |
| 2 | 5 `FirstBlood` · 6 `Ult` · 7 `Bounty` | `CheckPointTutorial2` | `TutorialWallStep2` |
| 3 | 8 `FreeMouse` · 9 `Stats` · 10 `LiveFire` | `CheckPointTutorial3` | — |

Marker counts corroborate the binding: `PassiveBotSpawn` ×2 = `STEP6_BOTS` ×2, `BountyBotSpawn` ×1,
and `UltimateBotSpawn` ×6 = High Noon's `MaxTargets` (§4).

---

## 1. The four things that break

Fix all four or the lesson does not run. Two of them fail **silently**, which is what makes this
list the most important section in the document.

**1a — `workspace.TutorialSpawn` is ambiguous.** The new pad is a *Model*; the old canyon marker is
a *Part*, both at workspace root. Four sites resolve the name at root:

| Site | Code | Failure mode |
|---|---|---|
| `RoundController:1027` | `workspace:FindFirstChild(Config.TUTORIAL_SPAWN_NAME or "TutorialSpawn")` then `:IsA("BasePart")` | warns, falls back to `SpawnService.sendPlayerToRoundSpawn` — **player spawns in the canyon** |
| `TutorialDirector:181-186` | `getTutorialSpawnPosition()` | **silent** — returns `Vector3.new(-69.444, 9.0, -257.437)` |
| `TutorialDirector:257-261` | bounty anchor lookup | **silent** — returns `Vector3.new(41.243, 11.496, -249.344)` |
| `TutorialClient:1878` | `workspace:WaitForChild("TutorialSpawn", 5)` then `:IsA("BasePart")` | returns; camera never pointed |

Moving the geometry into `workspace.Tutorial` (§2) resolves the ambiguity — the bare root lookup can
then only mean the old Part — but it also breaks all four sites outright. **Phase 0 and Phase 1
ship together or not at all.**

**1b — 25 parts are unanchored with `CanCollide` on.** All 14 `WallPartTutorial`, all 4
`Step1Walls`, all 5 `Step2Walls`, and both SurfaceGui parts. They fall out of the world on the
first physics step of a live server. Edit mode hides this completely.

**1c — the tutorial fire zone burns invisibly out here.** `ZoneService.getSafeClearance` on a linear
map tests **Z only** (`math.min(position.Z - area.min, area.max - position.Z)`), while the fire wall
is a part 800 studs wide positioned at **X = 0**. At X −1600 there is no fire on screen and the
damage still applies. The zone pins to Z −257 closing to ±112.5, so a player on the new spawn pad
(Z −26) is outside the safe band from the first frame.

**1d — 16 canyon `Vector3` literals in `TutorialDirector`,** plus three `ServerStorage.TutorialDummies`
authored at canyon CFrames. `TutorialDirector` is mirrored **byte-identical into Frostbite Claim**,
so those Redwater coordinates ride in shared gamemode code today. Phase 1 is as much a mirror fix as
a relocation.

---

## 2. Phase 0 — Geometry (Studio only, no code)

Build the folder and reparent all 26 root instances:

```
workspace.Tutorial
├── Areas/       TutorialSpawn, CheckPointTutorial1..3   (each gains a Stand — below)
├── Walls/       WallTutorial, TutorialWallStep1, TutorialWallStep2,
│                SurfaceGuiTutorialPart1, SurfaceGuiTutorialPart2
└── BotSpawns/   PassiveBotSpawn x2, UltimateBotSpawn x6,
                 BountyBotSpawn x1, FreeRoamBotSpawn x8
```

Use a plain `Folder`, not a `Model` — no pivot, no `ModelStreamingMode` surprises, and the contents
stream by position, which is correct because the player is physically there.

Then:

- **Anchor the 25 parts** listed in §1b.
- **Hide the 17 bot markers** — they are `Transparency = 0` today and would render as floating
  boxes. Set `Transparency = 1`, `CanQuery = false`, `CanCollide = false`, `CastShadow = false`.
- **Retire the old canyon markers** — `workspace.TutorialSpawn` (Part, −69.4, 9.0, −257.4) and
  `workspace.TutorialBountySpawn` (Part, 41.2, 11.5, −249.3). These stay **out** of the folder.
- **Add a `Stand` part inside each of the four pad Models.**

### The `Stand` convention

The pads are flat Unions with no meaningful orientation, and four separate features need "a place to
put the player, facing a particular way". One authored part per pad serves all of them: the initial
spawn, the travel backstop teleport (§6), the respawn point (§7) and the ult setup (§4).

Each `Stand` is an invisible `BasePart` — `Transparency = 1`, `CanCollide = false`,
**`CanQuery = false`** (load-bearing, per the existing `Config` note at line 198), `Anchored = true`
— positioned on the pad surface with its `CFrame` carrying the look direction.

Starting facings, measured today. The first three are level looks toward the next pad; verify each
in Studio before committing, and note that **`CheckPointTutorial2.Stand`'s pitch is deliberate and
must not be levelled** (§4).

| Stand | Look vector | Note |
|---|---|---|
| `TutorialSpawn.Stand` | `(−0.933, 0, −0.360)` | toward CP1, 40 studs |
| `CheckPointTutorial1.Stand` | `(−0.616, 0, −0.788)` | toward CP2, 99 studs, +29 climb |
| `CheckPointTutorial2.Stand` | **`(−0.748, 0.218, −0.627)`** | the ult facing — see §4 |
| `CheckPointTutorial3.Stand` | author toward the live-fire spread | see §5 |

---

## 3. Phase 1 — Coordinates become data

Replace every literal with a by-name lookup under the folder, so the builder can move a marker
without a code edit and the mirrored module stops carrying map coordinates.

- `MapConfig.Instances` gains `Tutorial = "Tutorial"`. **Frostbite omits the entry**, exactly the
  way it already omits `Zone.TutorialCenterOffset` — `MapConfig` is per-place and must never be
  mirrored.
- `Config.TUTORIAL_SPAWN_NAME` and `Config.TUTORIAL_BOUNTY_SPAWN_NAME` (lines 200-201) come out of
  the mirrored `Config` and are resolved through `MapConfig` instead.
- `TutorialDirector` literals:

| Lines | Table | Becomes |
|---|---|---|
| 43-46 | `STEP6_BOTS` (2) | the 2 `PassiveBotSpawn` parts |
| 51-57 | `STEP7_LINE` (5) | **all 6** `UltimateBotSpawn` parts (§4) |
| 67-73 | `STEP11_BOTS` (5) | 5 of the 8 `FreeRoamBotSpawn` parts (§5) |
| 186 | spawn fallback | `TutorialSpawn.Stand` |
| 261 | bounty fallback | `BountyBotSpawn` |

`StopDistance` (12 / 20 on the step-6 pair) is behaviour, not geometry — keep it in code, staggered,
so the two do not stand shoulder to shoulder on one side of the player.

The `lookTarget` computations at lines 459 and 515 derive a facing from the player anchor and stay as
they are, **except** that a `StandDown` bot's spawn rotation is permanent, so where a marker already
carries a sensible facing, prefer the marker's `CFrame` over a recomputed look.

- **Re-author the three `ServerStorage.TutorialDummies`** into area 1. Current authored positions are
  canyon coordinates (−76.3/13.4/−220.6, −30.3/12.7/−234.4, −37.3/9.6/−283.7). They are cloned with
  their stored CFrame, so either move the models in `ServerStorage` or add three markers to
  `BotSpawns/` and place them at spawn time. Prefer markers, for consistency with everything else.

---

## 4. The ultimate step — teleport and face

Step 6 (`Ult`) is the one step that cannot tolerate the player standing wherever the previous fight
left them. The player is **placed on `CheckPointTutorial2.Stand` and pointed at the firing line** so
the lock-on has a full set of targets.

### Why the numbers work

`HighNoonServerConfig.Targeting` is `{ Range = 180, ConeAngle = 45, MaxTargets = 6 }`, and
**`ConeAngle` is a half-angle** — `HighNoonTargeting:~50` computes
`angle = deg(acos(dot(aimDirection.Unit, toTarget.Unit)))` and returns `angle <= self.ConeAngle`.
So the usable cone is 90° wide, and `MaxTargets = 6` is exactly the marker count.

From eye height on the CP2 pad (`Checkpoint.Position + (0, 4.5, 0)`), facing
**`(−0.748, 0.218, −0.627)`** — the centroid of the six markers:

| Marker | Distance | Off-axis |
|---|---|---|
| −1690.3, 52.9, −148.1 | 62 | 11.2° |
| −1707.6, 79.2, −153.0 | 86 | 18.2° |
| −1680.4, 53.0, −125.6 | 45 | 30.1° |
| −1657.8, 51.5, −172.7 | 58 | 29.0° |
| −1674.0, 51.9, −162.3 | 58 | 10.3° |
| −1657.8, 38.2, −155.3 | 42 | 27.8° |

Worst case 30.1° against a 45° cone — **14.9° of margin**, all six well inside `Range = 180`, and
all six have **clear line of sight** (raycast-verified, ignoring the pads and markers themselves).
A brute-force search for the axis that minimises the worst angle lands on `(−0.765, 0.174, −0.620)`
and buys only 0.3°, so the centroid is the value to author. `HighNoonTargeting`'s sight test excludes
every rig in the arena, so the six cannot body-block each other.

### Why it splits across server and client

**The server can place the player but cannot face them.** Under `LockFirstPerson` the PlayerModule
camera owns the yaw and turns the character to match the camera every frame, so a server-written
rotation is gone by the first render. This is already documented at `TutorialClient:1863-1872` and is
the entire reason `faceLessonSpawn` exists client-side.

- **Server** — `SpawnService.teleportPlayerToSpawn(player, stand)`. Signature is
  `(player, spawnPart) -> boolean`, and the boolean means the write was **issued**, not that it
  survived; `verifyTeleport` settles that asynchronously 0.35s later. Never write `root.CFrame`
  directly — a server CFrame write on a player-owned character is silently discarded.
- **Client** — a new `face` field on the `TutorialStep` payload carrying the look vector.
  `TutorialClient` reuses `point()` (lines 1903-1911) and its **twice, a frame apart** write
  (1916-1918); a single write landing on the frame the camera is initialising for a fresh character
  is discarded.

**Do not reuse `faceLessonSpawn`'s pitch handling.** Line 1910 flattens the look to
`Vector3.new(look.X, 0, look.Z).Unit` because "a spawn marker's tilt is a modelling accident". Here
the tilt is not an accident — the firing line sits ~16 studs above the pad, and a levelled camera
puts the whole line above the crosshair. The ult facing carries the full 3D vector.

### Ordering

Existing rule (`TutorialDirector` item 4a): nothing spawns on a step boundary, everything goes
through `afterBeat`, and the ultimate charge is granted **last**, inside step 6's `afterBeat`
callback after the firing line has spawned — because a full charge ring is the loudest thing on the
HUD and reading it as the cue is what sent Dead Eye into an empty canyon in the 2026-08-09 playtest.

The teleport and facing go **at the step boundary, before the beat**: player planted and looking at
empty ground, then the line pops into exactly their view, then the charge fills. Teleporting after
the line spawns would yank the player mid-read. This ordering is the one item worth eyeballing in a
playtest rather than reasoning about.

---

## 5. The live-fire spread — a decision that needs a playtest read

`STEP11_BOTS` currently spawns five bots **100–125 studs out**, and the rule behind that number is
emphatic in `TutorialDirector`: *"THE DISTANCE IS THE WARNING"*. Nothing in this game tells a player
a bot is about to exist, so the only thing standing between a spawn and an ambush is enough ground to
watch it walk in. Two earlier passes got this wrong — a 35–45 stud ring and then a 60–90 one — and
both read as *being jumped by five bots that appeared out of nothing*.

The eight authored markers, measured from CP3, do not sit in that band:

| Position | Distance | LOS from CP3 |
|---|---|---|
| −1750.6, 25.4, −230.4 | 38 | clear |
| −1687.4, 27.0, −218.5 | 45 | clear |
| −1739.6, 50.0, −131.8 | 69 | blocked (cactus) |
| −1649.0, 50.4, −190.4 | 80 | clear |
| −1689.8, 56.0, −122.3 | 86 | blocked (rock) |
| −1635.7, 39.6, −139.8 | 110 | clear |
| −1670.6, 41.5, −103.3 | 112 | blocked (terrain) |
| −1614.7, 38.5, −117.1 | 140 | blocked (terrain) |

Blocked line of sight at spawn is fine, arguably good — a bot walking out from behind cover is the
intent. The distances are the problem.

**Recommendation: use the five furthest — 80, 86, 110, 112, 140** — which respects the distance rule
as closely as the authored markers allow, and leave the 38 and 45 stud markers unused rather than
repeat a mistake that has already been made twice. Expect the 140 to cost ~10s of a 30s step in
walking; if that reads as dead time in playtest, the lever is already named in the module's own
comment: start the clock at the bots' arrival rather than at the instruction, rather than moving
them closer.

`CheckPointTutorial3.Stand`'s facing should then be authored toward the centroid of whichever five
are chosen, by the same method as §4.

---

## 6. Phase 3 — Area gating

Bind step blocks to areas per §0. Two gates, each opening on the completion of its area's last step:

- `TutorialWallStep1` opens when `Fan` (step 4) completes
- `TutorialWallStep2` opens when `Bounty` (step 7) completes

Each gate's `SurfaceGuiTutorialPart` leaves with its wall — the "FINISH THE PREVIOUS TASK" sign must
not outlive the barrier it explains.

### The arrival gate

The next block's first step — its line, its bot choreography, everything — is **held until the player
stands on the destination pad**, with a **20-second backstop** after which they are teleported to
that area's `Stand`.

Walk distances are 99 studs (CP1→CP2, +29 climb) and 122 studs (CP2→CP3, −15), so roughly 7–10
seconds each at normal walk speed. 20s is 2–3× that: it fires on a player who is genuinely lost, not
one who is merely slow.

Three constraints:

- **The window sits on top of `STEP_BEAT`,** like every other deadline in the module. Otherwise the
  clock starts while the previous step's line is still on screen and the player is reading, not
  walking.
- **The backstop teleport goes through `SpawnService.teleportPlayerToSpawn`,** for the reasons in §4.
- **The arrival gate must not add a step.** `Telemetry.logTutorialFunnelStep` fires per step and the
  completion step is `#STEPS + 1` (currently 11). Adding steps shifts every index and makes live
  funnel data before and after the change incomparable. The gate lives inside the existing step's
  lead-in.

### Budget

`TUTORIAL_HARD_CEILING` goes **300 → 330** (`Config:185`). A full-timeout run is ~230s today; two
travel windows at worst case add ~44s for ~274s, leaving only 26s of headroom against 300. Busting
the ceiling flips the run's funnel outcome from `Completed` to `Ceiling`, which is exactly why the
ceiling was raised 260 → 300 last time.

Add a **`travelTeleports`** count to the existing `TutorialRun` aggregate event — it reports whether
the backstop is firing at all, without touching the funnel indices the previous paragraph protects.

---

## 7. Phase 2 & 4 — Zone, respawn, client, mirror

### Zone (mandatory)

Remove the `ZoneService.startTutorialZone(tick())` call at **`RoundController:2145`**. This is the
line that causes 1c, and removing it is not optional.

Recommended cleanup in the same pass, since an entry nothing consumes rots: delete
`ZoneService.startTutorialZone` and its `tutorialZone` branches (the local at :92, the `spawnFraction`
branch at :1074-1078, the fraction interpolation at :251-252), `Config.TUTORIAL_ZONE_CLOSE_TIME` /
`_START_FRACTION` / `_END_FRACTION` (:194-196), and `MapConfig.Zone.TutorialCenterOffset` (:43-50).
This is the most invasive deletion in the plan — do it last, syntax-check after, and it is the one
item safe to defer if the pass needs time-boxing. Removing the *call* is not.

`RoundController:1020-1025`'s comment justifies routing through `teleportPlayerToSpawn` on the
grounds that "under the compressed zone the respawn origin sits INSIDE the fire from ~32s onward, so
all four are load-bearing". With the zone gone that justification lapses, but `verifyTeleport`,
`ACImmuneUntil` and the spawn-protection grant are still worth having — correct the comment, keep
the routing.

### Respawn

`TUTORIAL_RESPAWN_DELAY` stays 0. Track the player's current area and respawn them on **that area's
`Stand`** instead of always the start pad. Without this, dying in area 3 after both walls are open
means a 200-stud walk back with an instruction on screen they cannot act on. A death during a travel
window respawns at the *previous* area's Stand (they have not arrived yet) and should restart the
20s clock.

### Client

`TutorialClient` needs the folder-aware lookup (`WaitForChild` through `Tutorial` → `Areas` →
`TutorialSpawn` → `Stand`, each with a timeout) and the generalised facing from §4. Note that a
`WaitForChild` timeout suppresses the infinite-yield warning without ending the wait, so a missing
part fails quietly — check the return.

### Mirror

`TutorialDirector`, `TutorialClient`, `Config`, `ZoneService` and `RoundController` are all part of
the gamemode codebase mirrored between Redwater Canyon and Frostbite Claim. **`MapConfig` is
per-place and must not be mirrored.** Run `/mirror` after the code edits and before publishing.

Frostbite has no vault folder — only Redwater and Bounty do — so there is no doc work on that side.

---

## 8. Verification

Nothing here requires a playtest through MCP; a playtest hangs the plugin connection. Verify by
read-back and a manual checklist.

1. **Syntax** — after each `set_script_source`, recompile with `loadstring(script.Source)`. Do not
   trust a stale `require()` cache.
2. **The four lookup sites resolve** (§1a) — read each back and confirm a `BasePart`, not a Model
   and not `nil`.
3. **Nothing unanchored remains** in `workspace.Tutorial` — re-run the audit that produced §1b.
4. **The ult cone still holds** — recompute §4's off-axis table from
   `CheckPointTutorial2.Stand`. Any marker move invalidates the 14.9° margin.
5. **Bot paths** — `PathfindingService:ComputeAsync` works in edit mode; verify a path from each
   spawn set back to its checkpoint (Success, no jump waypoints) before committing the marker
   selection.
6. **Vault + graph** — update `TutorialDirector.md`, `TutorialClient.md`, `Config.md`,
   `ZoneService.md`, `RoundController.md`, `MapConfig.md` under `LocalRedwaterCanyon/`, then run
   `python update_redwater_canyon_graph.py` as a bare command.
7. **Changelog** — `/changelog` for this session's capture. Not data-affecting: no Wallet reason, XP
   curve, RP award or profile-shape change. The funnel indices are deliberately unchanged (§6).

### Manual playtest checklist

- Player spawns on the pad in area 1, facing down the course.
- Steps 1-4 complete; wall 1 and its sign disappear together.
- Standing on CP2 starts step 5; loitering triggers the 20s teleport instead.
- **Step 6: player is planted on CP2 facing the line, the six bots are all on screen, the charge
  fills after the line has spawned, and a lock takes all six.**
- Steps 5-7 complete; wall 2 and its sign disappear together.
- Death in area 2 or 3 respawns on that area's pad, not the start.
- Live-fire bots are visible walking in, not appearing.
- Run completes under the 330s ceiling with no fire damage anywhere.

---

## 9. Not in scope

- The bowl's art pass — the gate walls are `Cool yellow` at 0.65 transparency and the perimeter is
  red at 0.70, both plainly placeholder. Not this change.
- Retuning the lesson's step copy for the new geography (`TutorialClient` owns the strings). Flag
  any line that now describes the canyon, but changing them is a separate pass.
- Frostbite ever running the tutorial. It does not, and Phase 1 exists partly to make that
  structurally true rather than incidentally true.
