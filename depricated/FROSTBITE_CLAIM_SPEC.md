# Frostbite Claim — Second Map Transition Spec

**Status:** **Phases 1 and 2 COMPLETE and PLAYTESTED 2026-08-13.** Phase 1 built
`ReplicatedStorage.MapConfig` in Redwater (§5). Phase 2 generalised the zone shape (§6): six
scripts rewritten, Redwater's behaviour verified unchanged numerically and confirmed by playtest,
the radial path verified against §6.3/§6.4 through the real code. **Awaiting publish.**
**Phase 3 TOOLING BUILT 2026-08-13** — `/mirror` exists and is validated against the known-good
17-module state; `/preflight` Step 1 delegates to it. See the block at §7 and the findings in §7a.
**Phase 4 BRING-UP DONE the same day** — Frostbite carries the full shared codebase; see the block at
§8 for what that did and did not cover, and **§8b for the current parity figure and the four things
synced after the bring-up** (the bring-up's own `ffa5db7a` is historical — the live number is
**`TOTAL 110572d4`**, 272 scripts / 9,707 instances / 3,786,476 bytes, every mirrored root matching).
**Frostbite has now been playtested once** — a full round with bots; the zone, spawns and bot
behaviour worked, and the one Vesper perch warn is open item 111.
**§7.4 is SUPERSEDED** — the dev places were built as a **separate universe**, which measurement
showed is strictly better than the same-universe plan: store isolation is free *and* developer
products still work cross-experience (both verified live). The 8-name `storeName` chokepoint is
**not needed and should be dropped**; §7.4 has not yet been rewritten.
**Dev rows landed in `GameEnvironment` 2026-08-14** — DEV universe GameId `10696738139`: Bounty
`79122344034586`, Redwater `95375045711422`, Frostbite `90764829045032`. A dev place resolves
`env = "Dev"`, `isLive = false`, dev siblings, and tags builds `[DEV]`. Content reaches the dev
places by publishing each live place AS its dev twin.
Design agreed 2026-08-07.
**Owner:** unassigned — written for a cold session to execute.
**Audited 2026-08-13 (post-Phase-1)** — §2's Frostbite table re-measured live and largely rewritten
(§3a authoring turned out to be essentially complete, not "not yet authored"); `WallMap` audited,
one walk-under breach found and fixed; **every line number in §6.5 re-derived** after Phase 1 shifted
them, and a fourth `getSafeZBounds` consumer added that the earlier draft missed
(`BotPathing.GetFirewallEscapePosition`); §3d, §3.1, §8 step 3 and §10 item 3 corrected.
**Last audited:** 2026-08-11 — §2 re-measured, §3 rewritten (it was materially incomplete),
§3.1 added (tutorial is Redwater-only), §6 Phase 2 unblocked and specified (radial zone, measured),
open questions 2 and 4 resolved. Phase 3's subsections renumbered 6.x → 7.x to end a numbering
collision.
**Amended 2026-08-12** — three decisions landed. (1) A gamemode is **no longer a place**: maps and
gamemodes are independent axes, gamemode is runtime-selected (§1 corollary, §5
`MapConfig.Gamemodes`, §9); `CLAUDE.md` carried the old claim and has been corrected too.
(2) **Sync mechanism resolved: Option B for everything** (§7). (3) **Dev places share the live
universe**, isolated by an 8-name store suffix through a new `GameEnvironment.storeName` (§7.4).
**Amended 2026-08-13** — the **footstep system and `DestructibleService` were removed from Redwater**
at the user's request. Two Frostbite blockers died with them: §3b-ii item 2 (footsteps ~95% silent on
snow) and §3c (`Window`-named parts). Both sections are struck rather than deleted, so the analysis
is not re-derived from scratch later. §2 counts re-measured live the same day — see the note there,
the drop is larger than these two removals explain.
**Phase 5 SPECIFIED 2026-08-13, not built** — the selection UX is decided (matchmaking assigns match
1's map, an end-of-match vote picks every one after), and §9 was rewritten around it. Two of its
findings matter outside Phase 5: **§9.1 is a publish blocker** — Frostbite's mirrored
`MatchDirectoryService` publishes into Redwater's match directory with no field distinguishing them,
so the two maps' servers are indistinguishable to Bounty's matchmaking — and **§9.0 corrects a false
premise this spec carried**: there is no gamemode picker in Bounty and never was.
**Place:** Frostbite Claim, PlaceId `134041618959520` (universe sibling of Bounty + Redwater Canyon).

---

## 1. What this is

Frostbite Claim is a **second map running the existing Redwater deathmatch gamemode**, not a new
gamemode. Its geometry is already built (492 `workspace` children as of 2026-08-07); every service
other than `Workspace` and `StarterPlayer` is empty, and its `dataModelName` is still `Place1`.

The problem this spec solves: how Frostbite gets the ~294 scripts that run a match **without**
becoming a third hand-maintained copy of the codebase.

### Decision: separate places, shared code — do NOT merge the maps into one place

Two options were weighed.

**Rejected — one place holding both maps.** On code coupling alone this wins easily (see §3: the
map contract is 6 instance names and 2 numbers). It was rejected on **art authoring**, measured
against the live places:

- Roblox allows exactly **one** `Terrain.MaterialColors` palette per place, and the two maps repaint
  the *same* material enums to incompatible values (§4). Redwater has repainted **Snow to
  (149,100,68) brown**. Frostbite needs Snow at (235,253,255) white.
- Same for `Lighting` — one saved state per place, and the two are far apart (§4).
- Terrain is a `workspace` singleton and cannot be parked in `ServerStorage`, so a merged place must
  hold **both terrain volumes spatially, permanently**, in the place file and in server memory.
  Terrain voxels are the heaviest thing in a place; this compounds with every future map.
- Runtime is solvable (`Terrain:SetMaterialColor` and every Lighting property are script-writable,
  and one server only ever runs one map). **Studio authoring is not.** One saved palette means
  whoever builds Frostbite's snow is looking at brown snow through a warm desert LUT, every session,
  permanently.

**Accepted — Frostbite stays its own place; the shared code stops being hand-copied.** Terrain
palette, Lighting, water and MaterialVariants stay per-place and are authored naturally with zero
runtime application code. The duplication problem is solved once, mechanically, by §7 — and the same
mechanism retires the existing 17-module manual mirror, which is a standing liability regardless of
Frostbite.

**Corollary — maps and gamemodes are independent axes (corrected 2026-08-12).** A new *map* is a
new place under this same mechanism. A new *gamemode* is **not** a place. Most gamemodes are meant
to run on most maps, so gamemode is **runtime-selected code that every match place carries**,
chosen from `TeleportData` at boot.

Gamemode-as-place would multiply *maps x gamemodes x environments* and force identical gamemode
code to be maintained in every combination — the exact hand-maintained divergence this document
exists to prevent. Carrying every gamemode in every map place costs almost nothing instead, because
§7 already makes that code byte-identical everywhere, and `ServerScriptService.Main` is already
shaped for the split: its Start list runs universal player services, then combat/hunter services,
then exactly two gamemode-specific entries (`MatchDirectoryService`, `RoundController`). Only that
last pair varies by gamemode; everything above it is unconditional.

Which maps support which gamemodes is therefore **data**, declared per map in `MapConfig.Gamemodes`
(§5) and routed through the existing `TeleportData` channel (§9) — not a PlaceId decision.

---

## 2. Current state (re-measured 2026-08-13 — supersedes the 2026-08-11 figures)

Redwater Canyon, PlaceId `98517073248449` — **291 scripts total** as of 2026-08-13 post-Phase-1
(290 before, +1 for `ReplicatedStorage.MapConfig`; 2026-08-11 recorded 303).

> **The 13-script drop is only 2 explained.** `FootstepClient` and `RoundSystem.DestructibleService`
> were deleted 2026-08-13; the other ~11 predate that session and are **unattributed** — either peer
> work since 2026-08-11 or a miscount in the earlier figure. Flagged rather than reconciled, because
> a script count is a sanity check for the §7.1 sync boundary and a silently-wrong one is worse than
> a known-uncertain one. Re-derive it before trusting it as a mirror gate.

| Service | Top-level children | Notes |
|---|---|---|
| `ServerScriptService` | `Main`, `HunterImplementationGuide`, `SoftShutdown` + folders `Combat` `Testing` `VFX` `UI` `Networking` `PlayerServices`(22) `RoundSystem`(**6**) `AntiCheat` `Hunters` `Bots` **`Onboarding`(1)** | `RoundSystem` was 7 — `DestructibleService` removed 2026-08-13 |
| `ReplicatedStorage` | **40** — incl. **10 loose root ModuleScripts** (see §7.1) | loose count unchanged |
| `StarterPlayerScripts` | **44** = 40 LocalScripts + hunter folders `Dust` `Fortuna` `Vesper` `Bram` | was 47 then 43; `FootstepClient` removed 2026-08-13, `RbxCharacterSounds` added same day, rest unattributed (see note above). **`RbxCharacterSounds` is an empty LocalScript and must be copied** — its name is what suppresses Roblox's nine stock character sounds; an empty-looking script is not junk here |
| `StarterCharacterScripts` | 1 — `Health` | was 2 (`DefaultFootStepRemover`, `DefaultDeathSoundRemover`) — both deleted 2026-08-13, replaced by the empty `StarterPlayerScripts.RbxCharacterSounds` override (see the `StarterPlayerScripts` row) |
| `StarterGui` | **19** (was 15) | incl. `TutorialGui`, `HealingVignetteGui` |
| `ReplicatedFirst` | 1 (`EarlyShotRemoteDrain`) | |
| `ServerStorage` | **3** — `Brushtool2_Plugin_Storage`, `RBX_ANIMSAVES`, `TutorialDummies` | first two are **plugin junk, do not copy**. `TutorialDummies` (699 descendants) is **Redwater-only** — see §3.1 |

**`Config.ROUND_TIME` reads `360`.** The §5 guard inherited from `Config.md` §2d-i is clear; it is not
still `10` from the retirement test.

Frostbite Claim, PlaceId `134041618959520`: `Workspace` populated, every other service still
**empty (0 children)**, and `dataModelName` is **still `Place1`** (§8.1).

**Re-measured live 2026-08-13 — §3a map authoring is essentially COMPLETE.** The 2026-08-11 row
saying "everything else not yet authored" was badly stale; almost the whole contract landed since.

| Instance | Frostbite | Redwater ref | Status |
|---|---|---|---|
| `SpawnPoints` | **37 BaseParts** | 44 | done, verified against every zone phase (§6.4) |
| `WallMap` | **Folder, 16 Parts** | Folder, 72 | done — see the audit note below |
| `JailSpawn` | Part | Part | done |
| `FinishSpawns` | Folder, 7 — incl. `BoxPlayerSpawns` (12, with `VictoryScreenBoxModel`), `Pillars`, `Player1/2/3`, `PlayerLocal`, `VictoryScreenRigSpawn` | same | done |
| `VesperHookSpotsBot` | **Folder, 40** | 33 | done |
| `CameraSpawn` / `CameraFolder` | 1 / 2 | 1 / 2 | done |
| `HealthPack` tag | **35** | 25 | done |
| `Penetrable` tag | **1** | 8 | fine while cover is wooden (§3b-ii); tag any ice/metal/rock cover added later |
| `CorpseFolder` | absent | — | **correct** — it is not a contract (§3a) |
| `ReplicatedStorage.MapConfig` | **MISSING** | present | Phase 4 step 5 |
| `workspace.ZoneRef` | 9 rim parts + `zoneCenter` | — | **scaffolding for §6, not runtime content.** `zoneCenter` (-9.7, 37.3) is the authored centre Phase 2 reads; keep it as documentation, delete the 9 rim parts once `MapConfig` carries the radius |

> **`WallMap` audit, 2026-08-13.** All 16 parts measured `Transparency 1, CanCollide true,
> CanQuery false, Anchored true` — `CanQuery = false` is the load-bearing one (see §3a). 15 are ring
> segments spanning Y 4.0–316.1; the 16th is rotated 90° on X and is a **ceiling** at Y 316–364
> capping the arena, which Redwater has no equivalent of. Verified sealed: 720 sampled bearings give
> 100% angular coverage and 0 walk-under breaches.
>
> **One breach was found and FIXED in the same pass:** a single segment had its base at Y 62.7 while
> the other 14 sat at Y 4.0, and terrain under it fell to Y 8.4 — a ~54-stud gap over ~18.5° of arc
> (~99 studs of walkable opening). Corrected to `Size.Y` 312.1 / `Position.Y` 160.0, matching its
> siblings. `CastShadow` also cleared on all 16 (they are invisible). Re-scan: 0 breaches, tightest
> clearance 216.6 studs.

---

## 3. The map contract

**Rewritten 2026-08-11.** The previous version listed 6 items and claimed "nothing else touches map
geometry by name". That was wrong — it missed 7 more, including one that refuted its own headline
conclusion. Re-derived by grepping `[Ww]orkspace[%.:]%a` plus every `CollectionService` call across
all 303 scripts.

### 3a. Named `workspace` instances — every one must exist in Frostbite

| Contract | Redwater | Consumed at |
|---|---|---|
| `SpawnPoints` — Folder of BaseParts, round spawns | 44 parts | `SpawnService:73` (`WaitForChild`), `BotService:115`, `BotPathing:1001` |
| `JailSpawn` — BasePart, intermission/summary cage | Part | `SpawnService:256` |
| ~~`CorpseFolder` — Folder~~ | empty | **NOT A CONTRACT — 0 references, struck 2026-08-13.** Grepped `Corpse` across all 290 scripts during Phase 1: every hit is a comment or an unrelated local. Its last consumer is gone. **Do not author it in Frostbite.** |
| `FinishSpawns` — Folder, victory podium | 7 children | `RoundController:509,571`, `VictoryShowcaseClient:597,2066,2099` |
| ├ `FinishSpawns.Pillars` | Model, 4 | `RoundController:579` |
| ├ **`FinishSpawns.BoxPlayerSpawns`** | Model, 12 | `VictoryShowcaseClient:601` |
| │  └ `VictoryScreenBoxModel`, `Player1/2/3`, `PlayerLocal`, `SpotlightPartVictory1/2/3`, `SpotlightPartVictoryLocal`, `CameraPartStadium`, `CameraPartLocal`, `CameraPartAnimation` | Parts + 1 Model | `RoundController:511` resolves `VictoryScreenBoxModel` by name |
| └ `Player1/2/3`, `PlayerLocal`, `VictoryScreenRigSpawn` | Parts | podium placement |
| `WallMap` — invisible arena boundary, excluded from raycast filters | Folder, **72** (was recorded 64) | `GrappleHookService:53`, `BreachChargeService:352`, **`GrudgekeeperClient:698` (client)**, + 12 shared raycast-filter sites |
| **`VesperHookSpotsBot`** — Vesper bot perch pads | **Folder, 33** | `BotCombat:1081`, + the same 12 raycast-filter sites |
| **`CameraSpawn`** → `CameraIdlePart` | Folder, 1 | `RoundClientController:354` — intermission idle camera |
| **`CameraFolder`** → `CameraPartLocalPlayer`, `CameraPartVictory` | Folder, 2 | `VictoryShowcaseClient:581` — victory showcase camera |

**Not all of §3a is fresh authoring.** The contract splits two ways, and noticing this removes most
of the work:

- **Must fit this map's geometry — author fresh:** `SpawnPoints` (done), `WallMap`,
  `VesperHookSpotsBot`, `CameraSpawn`, and the `HealthPack`-tagged props.
- **Map-agnostic rigs — COPY from Redwater and reposition:** the whole `FinishSpawns` tree (podium,
  `VictoryScreenBoxModel`, the three spotlights, the three showcase cameras), `CameraFolder` and
  `JailSpawn`. These are a summary/podium set dressed for a
  cutscene, not arena geometry — their internal layout is what `VictoryShowcaseClient` and
  `RoundController` drive, and rebuilding it by hand would be error-prone for no gain.

### 3b. CollectionService tags — authored onto map content

| Tag | Redwater | Consumed at |
|---|---|---|
| **`HealthPack`** | **25 tagged instances** | **15 scripts** — every hunter's damage service, `HealthPackSystem`, `AimAssistController`, `RevolverLagCompensation`, `BotPathing`, `BotCombat`, … |
| **`Penetrable`** | 8 tagged instances | `BulletPenetration:95` (tag on the part *or any ancestor*) |

### 3b-ii. MATERIAL contract — the one that could break silently on a snow map

**Was two; footsteps left the codebase 2026-08-13 (item 2 below).** What remains is not a name
lookup, so it did not show up in the original §3 grep — it is a **core mechanic that simply stops
existing** in Frostbite unless the map is authored against it. Measured 2026-08-11 by sampling 1,200
downward rays inside each map's zone.

**1. Bullet penetration — VERIFIED WORKING in Frostbite. No action needed.**

> Measured 2026-08-11: Frostbite carries **3,027 Wood + 19 WoodPlanks + 17 Fabric** BaseParts of
> 4,762 total — *more* penetrable material than Redwater's 2,605. Its wooden structures satisfy
> rule 3 exactly as Redwater's do. An earlier draft of this section predicted penetration would be
> absent on a snow map; that was reasoning from Redwater's palette without measuring Frostbite's,
> and it was wrong. The rules below are retained as the contract for **future** maps, where a map
> built from ice/rock/metal genuinely would match none of them.

`BulletPenetration` (`ReplicatedStorage.Hunters.Shared`) tests, highest priority first:
1. `Penetrable` **attribute** on the part or any ancestor (explicit override, **0 users today**)
2. `Penetrable` **CollectionService tag** on the part or any ancestor
3. **Material is `Wood`, `WoodPlanks` or `Fabric`**. Terrain never penetrates.

Redwater carries **2,605 Wood + 29 WoodPlanks + 40 Fabric** BaseParts — its cover is overwhelmingly
wooden, so rule 3 does nearly all the work for free. The 8 tag carriers are *containers*, not parts
(`WoodPanels`, `Caravan` x3, `Barrels`, `Fence`, `Crates`, `Cacti`) — the tag is ancestor-inherited,
so tagging a folder covers everything in it.

A map built from ice, rock, snow and metal would match **none** of the three rules, and shooting
through cover would quietly not happen with no error. Frostbite avoids this by being built largely
in wood. **Frostbite carries only 1 `Penetrable` tag (`Caravan`) against Redwater's 8** — that is
fine while the cover is wooden, but any non-wood cover added later (ice walls, metal sheeting, rock
barricades) needs the tag on its container, or it will read as solid.

**2. ~~Footsteps would be ~95% silent.~~ — MOOT 2026-08-13, the feature was removed.**

`StarterPlayerScripts.FootstepClient` was **deleted** at the user's request. There is no
material→folder resolution left, so Frostbite's snow palette has nothing to resolve against and
this is **not a bring-up task**. Roblox's stock "Running" sound is suppressed by the empty
`StarterPlayerScripts.RbxCharacterSounds` override (which superseded `DefaultFootStepRemover` later
the same day), so characters make **no footstep sound at all** in either map — silence is the
intended behaviour, not a Frostbite content gap.

`ReplicatedStorage.SFX.Footsteps` (9 material folders) was **left in place, dormant** — nothing
references it. It still sits inside the §7.1 synced tree, so it will replicate to Frostbite
harmlessly. Do not treat its presence as evidence the feature exists.

> **Retained for a future map only:** the original trap was that a **missing** folder fell back to
> `Default` (audible) while a folder that **existed and was empty** returned `nil` and played
> nothing — an empty folder was *worse* than no folder. `Snow`, `Ground` and `Stone` were the empty
> ones, which is exactly where Frostbite's palette landed (Snow 77.1%, Slate 9.5%, Ground 8.4% →
> 5.0% audible ground, against Redwater's 98.7%). If footsteps are ever reintroduced, that asymmetry
> is the thing to design against, and Frostbite is the map that exposes it.

### 3c. ~~Name conventions~~ — MOOT 2026-08-13

- ~~**BaseParts literally named `Window`**~~ — `DestructibleService` was **deleted** at the user's
  request. It was already dead code: `breakWindow()` had no callers anywhere in the place, and the
  only Part named `Window` is `Workspace.Assets.Window`, an unplaced asset template. **Frostbite has
  no `Window` naming requirement.** No name conventions remain in the map contract.

### 3d. Config numbers

| Contract | Consumed at |
|---|---|
| ~~`Config.ZONE_START_Z` / `ZONE_END_Z`~~ — **moved to `MapConfig.Zone.Start` / `.End` in Phase 1, 2026-08-13.** No zone geometry remains in `Config`. | `ZoneService:144,145,580,585,589,714,715`, `SpawnService:85` — all now read `MapConfig` |

### 3e. Two failure modes to design against

- **`VesperHookSpotsBot` is hand-authored per-map nav data, and the old §3 said there was none.**
  The claim "bots use `PathfindingService` with live-computed waypoints … there is no hand-authored
  nav data per map — this is the single biggest reason this transition is cheap" is **false**.
  `BotCombat.resolvePerchPad` resolves *within* this authored folder of 33 pads. Frostbite needs its
  own set or Vesper bots have nowhere to perch. Worse, the folder is also in the raycast-ignore list
  of 12 combat scripts, so an absent folder silently changes what bullets collide with.
- **Both tag contracts fail silently.** A Frostbite with no `HealthPack`-tagged parts has no healing
  anywhere and throws no error — all 15 consumers just iterate an empty `GetTagged` result. Same
  shape as the `EmoteConfig` drift. Author these before first playtest, not after.
- **The MATERIAL contract in §3b-ii fails silently too**, because nothing in `workspace` is missing —
  the map looks complete. Penetration measured **fine** in Frostbite (3,027 Wood parts). The footstep
  half of this warning is gone with the feature (2026-08-13). **Measure, do not predict** — that
  lesson stands: this bullet originally predicted penetration would fail on a snow map, and measuring
  proved it wrong.

### 3f. Genuinely not part of the contract

- `workspace.ArenaBots`, `ClientBotVisuals`, `RewindHitboxes`, `Chrono_EntityStorage`,
  `ZoneFire_North` / `ZoneFire_South` are **created at runtime**. Not authored map content.
- `workspace.WorldCards` is created at runtime by `CardsServer:111` **if absent**.
- `workspace.Terrain` appears in `ZoneService` only as a raycast filter — map-agnostic.

Everything else — all four hunters, the combat pipeline, HUD, progression, telemetry, ranked, bots,
economy — is already map-agnostic and needs no change.

---

## 3.1 The onboarding tutorial is Redwater-only (decided 2026-08-11)

**Product decision: Frostbite never runs the tutorial.** It postdates the original spec entirely and
does not appear anywhere in §2–§9 as first written.

The trap: you **cannot** deliver this by carving the tutorial out of the sync. Tutorial branches live
in **17 scripts**, and 15 of them are core shared gamemode code — `RoundController`, `ZoneService`,
`Config`, `State`, `MatchDirectoryService`, `DataService`, `BountyService`, `HunterSelectionService`,
`BattlePassService`, `QuestEvents`, `KillCamClient`, `KillFeedClient`, `CombatFeedClient`,
`BountyMusicClient`, `HunterAbilityIntroClient`. Forking those to strip the tutorial recreates
exactly the hand-maintained divergence this whole document exists to prevent.

**The split is: code syncs, content does not.**

| | Frostbite |
|---|---|
| Tutorial **code** (all 17 scripts, incl. `TutorialDirector`, `TutorialClient`, `TutorialGui`) | **Syncs, and stays inert** |
| `workspace.TutorialSpawn`, `workspace.TutorialBountySpawn` | **Never authored** |
| `ServerStorage.TutorialDummies` (699 descendants) | **Never copied** |

This is safe because tutorial mode **fails closed**. `MatchDirectoryService.setTutorialMode` only
resolves true from (1) Bounty's `RedwaterAccessCodes_v1` reservation entry for this
`PrivateServerId`, or (2) the first arrival's `TeleportData.tutorial`. Bounty dispatches tutorials
against Redwater's PlaceId, so Frostbite receives neither signal and `State.tutorialMode` resolves
`false` on every server. `Config.TUTORIAL_FORCE_MODE` is honoured only in Studio or when
`GameEnvironment.isLive ~= true`, so it cannot convert a live Frostbite server either.

**Two things to fix before Frostbite ships — BOTH DONE 2026-08-13:**

1. ~~**`Config.TUTORIAL_ZONE_CENTER_OFFSET = -7.437` is a §7.3 violation.**~~ **FIXED in Phase 1.**
   Moved to `MapConfig.Zone.TutorialCenterOffset`; `ZoneService:122` reads it there and the resolved
   centre was verified at -257.437 = TutorialSpawn's Z. `Config` no longer holds any map coordinate.
2. ~~**Verify the absent-spawn path degrades safely.**~~ **VERIFIED.** All three sites guard and fall
   back without erroring: `RoundController:933` (`IsA("BasePart")` check → warns → falls back to
   `SpawnService.sendPlayerToRoundSpawn`), `TutorialDirector:182` (guard → fallback Vector3), and
   `TutorialDirector:257` (`anchorPart or Vector3.new(...)`). Inert code stays inert.

**Residual, knowingly accepted:** those two `TutorialDirector` fallbacks are hardcoded *Redwater*
coordinates (`-69.444, 9.0, -257.437` and `41.243, 11.496, -249.344`) sitting inside the synced
`ServerScriptService.Onboarding` tree — technically the same §7.3 violation class as item 1. They are
**deliberately not moved**: they can only execute when the tutorial runs, which is Redwater-only, and
giving every future map's `MapConfig` tutorial fields it never reads is worse than leaving them.
Recorded so a future audit does not "discover" them and move them.

---

## 4. Measured art conflicts (why the merge was rejected — kept as reference)

`Terrain` material colours, both places, 2026-08-07:

| Material | Redwater | Frostbite |
|---|---|---|
| Grass | (126,109,59) | (111,126,62) |
| Sand | (202,113,58) | (207,203,167) |
| Sandstone | (100,57,40) | (58,69,134) |
| **Snow** | **(149,100,68)** | **(235,253,255)** |
| Ground | (230,130,87) | (58,69,134) |
| Mud | (98,67,57) | (121,112,98) |
| LeafyGrass | (126,109,59) | (106,134,64) |
| Ice | (204,210,223) | (165,223,204) |
| Glacier | (221,228,229) | (165,223,204) |
| Rock / Slate | identical | identical |
| Water | (0.51,0.45,0.30), T 0.75, waves 0 | (0.05,0.33,0.36), T 0.30, waves 0.15 |

`Lighting`:

| | Redwater | Frostbite |
|---|---|---|
| Ambient | (0.60,0.43,0.23) warm | (0.27,0.27,0.27) neutral |
| Brightness | 3.5 | 3 |
| SunRays Intensity | 0.12 | 0.01 |
| Atmosphere | Color (1,0.93,0.79), Haze 2.17, Glare 0.20, Offset 0.67 | Color (0.78,0.78,0.78), Haze 0, Glare 0, Offset 0.25, bluish Decay |
| Post FX | Sky, SunRays, Atmosphere, Bloom, DoF, **ColorCorrection**, **ColorGrading** | Sky, SunRays, Atmosphere, Bloom, DoF |

`MaterialService` — **name collision hazard if these are ever merged:** both places contain variants
named `MaterialVariant` and `MaterialVariant1` (Redwater lists `MaterialVariant1` twice). Frostbite
adds `Racing_Buttes_A`, `Racing_Buttes_B`, `grass`.

Under the accepted design none of this needs resolving. Recorded so the merge option is not
re-litigated from scratch.

---

## 5. Phase 1 — Extract `MapConfig` (Redwater only, ships standalone)

> **DONE and PLAYTESTED 2026-08-13.** Built as specified below with two deliberate deviations,
> recorded at the end of this section. Every derived constant re-measured identical:
> `FIRE_WALL_SPEED` 1.875, `SPAWN_ZONE_MARGIN` 27, span 900, match centre -250, tutorial centre
> -257.437. All six touched scripts recompile. Three rounds plus a tutorial run passed — see
> "Verification for Phase 1" at the end of this section.

**Do this first. It touches only Redwater, is independently valuable, and can publish on its own.**

Create `ReplicatedStorage.MapConfig` — a root-level ModuleScript, deliberately **not** inside any
folder that will become a shared package (§7.3).

It declares, per place:

```lua
return {
    Id = "redwater",              -- stable key for telemetry / directory / lobby
    DisplayName = "Redwater Canyon",

    -- Which gamemodes this map supports (§1 corollary). Gamemode is runtime-selected,
    -- not a place, so "most gamemodes on most maps" is a data statement here rather
    -- than a combinatorial explosion of PlaceIds. Bounty reads this to build the
    -- map/gamemode picker; the match place reads it to reject a mode it cannot run.
    Gamemodes = { "deathmatch" },

    -- Zone geometry. Replaces Config.ZONE_START_Z / ZONE_END_Z.
    -- Shape drives the fraction -> geometry mapping in ZoneService (§6.2).
    Zone = {
        Shape = "linear",
        Axis  = "Z",
        Start = -700,
        End   = 200,
    },

    -- Named workspace instances (§3). Values are names, resolved by the consumer,
    -- so a map may rename its own geometry without touching shared code.
    --
    -- WARNING: this block is the ORIGINAL PLAN. What shipped drops CorpseFolder and
    -- WallMap -- see "What was actually built" below before copying it for a new map.
    Instances = {
        SpawnPoints  = "SpawnPoints",
        JailSpawn    = "JailSpawn",
        CorpseFolder = "CorpseFolder",   -- NOT SHIPPED: zero consumers
        FinishSpawns = "FinishSpawns",
        WallMap      = "WallMap",        -- NOT SHIPPED: literal in 15 scripts
    },
}
```

Then rewrite the six consumers in §3 to read `MapConfig` instead of hardcoding. Specifically:

- `SpawnService:66` — `FIRE_WALL_SPEED` derives from the zone range. Re-derive from `MapConfig.Zone`.
  **`SPAWN_ZONE_MARGIN` (27) is derived from Config on purpose** so retuning the zone cannot silently
  invalidate it — preserve that derivation, do not inline the number.
- `ZoneService:95,96,511,516`.
- `SpawnService:73,74,256`, `RoundController:463,525`, `BotService:115`.
- `GrappleHookService` / `BreachChargeService` `WallMap` raycast exclusions.

Delete `ZONE_START_Z` / `ZONE_END_Z` from `RoundSystem.Config`. Everything else in `Config` is
gamemode tuning and stays shared.

**Guard:** `Config.ROUND_TIME` is noted in the vault as possibly still `10` from a retirement test
(`Config.md` §2d-i). Check it reads `360` before any publish — unrelated to this work, but this spec
touches that file.

### What was actually built (2026-08-13) — two deviations from the plan above

**1. `WallMap` was NOT put in `Instances`.** The example above lists it; the code does not. It is
resolved by a **string literal in 15 scripts** — `GrappleHookService:53`, `BreachChargeService:352`,
`GrudgekeeperClient:698`, and 12 more sharing a `{ "VesperHookSpotsBot", "WallMap" }` raycast-filter
idiom. Wiring only the two sites this section names would leave 13 ignoring the table, and a config
that is authoritative for some callers but not others is worse than no config at all.

**The follow-up is not "wire the other 13" — it is to extract the shared idiom into one helper** in
`Hunters.Shared` that owns both folder names, then point that single helper at `MapConfig`. Doing it
per-site means 13 new requires threaded through hot combat modules for zero behaviour change.

Note this also applies to **`VesperHookSpotsBot`**, which §3a marks as fresh per-map authoring and
which travels with `WallMap` in every one of those 12 sites. Both names are still literals today.

**2. `CorpseFolder` was NOT put in `Instances`** — it has no consumers (see §3a).

`BotService:115` needed no change either: it is a warn string, and the folder itself is reached
through `SpawnService.getSpawnParts()`.

### Verification for Phase 1
Redwater plays a full round loop identically to before. No behaviour change is intended.

**Done:** all six scripts recompile via `loadstring`; `ZONE_START_Z` / `ZONE_END_Z` /
`TUTORIAL_ZONE_CENTER_OFFSET` return **0 hits** across all 291 scripts; every derived constant
re-measured bit-identical; graph rebuilt with 4 forward edges into `mapconfig` and 0 out of it.

**Playtested 2026-08-13 — Phase 1 is COMPLETE.** Three rounds at `ROUND_TIME` 80 /
`ZONE_PHASE_DURATION` 20 (12 phase transitions, 4x wall speed, 72-stud margin vs production's 27,
6 worst-case Final spawns vs 13) plus one tutorial run. Config restored to 360 / 80 and
re-verified.

**Method note worth reusing:** compressing the phase timer is a *harder* test, not just a faster
one, because `SPAWN_ZONE_MARGIN` is derived from it — 20s inflates the margin to 72 and halves the
usable spawn pool. Retuning the phase duration is the cheapest way to stress the spawn filter.

**And what a playtest could NOT verify:** the tutorial centre offset. A missing field falls back
to 0 and moves the zone 7.4 studs — imperceptible in play. That one was closed statically
(ZoneService reads the field, MapConfig supplies -7.437, centre resolves to -257.437). When a
config value's failure mode is *small*, observation is not evidence; read the resolved value.

---

## 6. Phase 2 — Zone shape generalisation

> **DONE and PLAYTESTED 2026-08-13.** Built as specified below with one API deviation, recorded in
> §6.5a. Redwater plays identically: bounds, the phase walk, `FIRE_WALL_SPEED` (1.875) and
> `SPAWN_ZONE_MARGIN` (27) all re-measured bit-identical, and a full round loop plus the checklist
> in §6.5b passed by hand. The radial path reproduces §6.3 exactly — radii 384 / 332.55 / 271.53 /
> 192, closing speeds 1.02 and 1.33 studs/s, margin 22.60 — and §6.4's spawn eligibility
> (**33 / 25 / 12**, zero spawns outside the start ring) measured *through the shipped code* against
> Frostbite's live 37 spawn points rather than by hand. **Ring RENDERING is unverified** — see §6.5c.

**UNBLOCKED 2026-08-11. Frostbite is a circle; the zone is RADIAL.** Measured against 9 reference
parts the map author placed at the intended wall line (`workspace.ZoneRef`) plus an authored
`ZoneRef.zoneCenter`.

### 6.1 The measurement

A least-squares circle fit to the 9 rim parts gives centre (13.71, 27.81), radius 386.4, **RMS
residual 9.65 studs = 2.50% of radius**. That is round. Radial is correct; no ellipse or polygon
test is needed.

**Use the authored `zoneCenter` (−9.7, 37.3), not the fitted centre.** They disagree by 25.3 studs,
which sounds like a reason to prefer the fit — it is not. `Config.ZONE_CENTER_RANDOM_RANGE = 40`
jitters the zone centre further than that **every single round**, so the disagreement is already
inside noise the design deliberately accepts. An authored part is self-documenting and survives
someone nudging a rim part later; a fitted constant silently goes stale. Cost of choosing the
authored centre, measured: **one** spawn in the worst-case Final circle.

### 6.2 Keep the phase fractions — change only the fraction → geometry mapping

This is the load-bearing decision, and it is what keeps Redwater untouched.

Redwater removes **25% of the total span per phase**: phase 1 open, then span fraction `f` =
0.75 → 0.50 → 0.25. (Verified: this reproduces `FIRE_WALL_SPEED = 1.875` and `SPAWN_ZONE_MARGIN = 27`
exactly, so the model is right, and it matches `TUTORIAL_ZONE_START_FRACTION = 0.75` /
`TUTORIAL_ZONE_END_FRACTION = 0.25`.)

**Do NOT apply those fractions to a radius.** Radius shrinks area *quadratically*; span shrinks it
*linearly*. A naive port gives a final radius of 96.6 and a final zone **4.7x smaller in area** than
Redwater's. Instead:

| Shape | mapping |
|---|---|
| `linear` | `halfSpan = 450 * f` |
| `radial` | `radius = StartRadius * math.sqrt(f)` |

The same `f` values drive both, so every phase constant, both tutorial fractions and all of
Redwater's behaviour are literally unchanged. One branch, in one place.

### 6.3 Frostbite's numbers

> **Superseded 2026-08-13 by the `EndRadius` change — see §6.7.** The table below is the
> sqrt-only mapping as originally shipped. It is kept because it is what the "same area fraction
> as Redwater" argument rests on, and because §6.4's spawn measurements were taken against it.

| Phase | `f` | Radius | Usable (−22.6 margin) | Worst-case eligible spawns |
|---|---|---|---|---|
| 1 | — | open | — | 37 |
| 2 | 0.75 | 332.6 | 309.9 | 33 |
| 3 | 0.50 | 271.5 | 248.8 | 25 |
| Final | 0.25 | 192.0 | 169.3 | **12** |

```lua
-- Frostbite MapConfig.Zone -- ORIGINAL. What shipped adds EndRadius = 150; see §6.7.
Zone = {
    Shape       = "radial",
    Center      = Vector2.new(-9.7, 37.3),  -- authored at workspace.ZoneRef.zoneCenter
    StartRadius = 384,
}

-- Redwater MapConfig.Zone — unchanged behaviour
Zone = {
    Shape = "linear",
    Axis  = "Z",
    Start = -700,
    End   = 200,
}
```

Radial closing speed is **1.02 then 1.33 studs/s** (accelerating, because equal area steps take
bigger radial bites late — this is a feature, the zone bites harder at the end). Sizing the margin
off the *fastest* transition: `SPAWN_ZONE_MARGIN = 12 + 1.33 * 8 = 22.6`, comfortably under
Redwater's 27. **Margins get safer on this map, not tighter.**

### 6.4 Spawn eligibility — already satisfied, no re-authoring needed

`workspace.SpawnPoints` exists in Frostbite with **37 parts** (Redwater runs 44). Checked against 108
sampled centre offsets (36 directions x 3 magnitudes up to the full ±40 jitter):

- **Zero spawns fall outside the start radius** — furthest is 286.1 of 384, so nobody spawns in fire
  at round start.
- Nearest spawn is 11.1 studs from centre, so the Final circle is genuinely populated rather than
  depending on stragglers.
- Worst case in Final is **12 eligible spawns. Redwater guarantees 3.** Four times the headroom.

This is also why the centre choice in §6.1 is safe: the layout absorbs a 25-stud centre shift without
approaching the limit.

### 6.5 What Phase 2 actually has to change

Contained, but wider than "ZoneService" — there is a **client-side** copy of the linear test.

> **All line numbers below re-derived live 2026-08-13, after Phase 1.** The previous set was written
> pre-Phase-1 and every ZoneService number was ~8-11 lines low, because Phase 1 added a require block
> at the top of the file. Re-derive again before trusting them; the function names are stable, the
> numbers are not.

**Signature change (the risky one).** `ZoneService.isPositionInSafeZone(zPos, extraMargin)` (**:338**)
takes a **scalar Z**. Radial needs X and Z, so it must take a `Vector3`, and all six callers change
with it: `ZoneService:242`, `RoundController:1108`, `BotPathing:524, 573, 1008, 1056`. A missed caller
passes a number where a Vector3 is indexed, which **errors loudly** rather than silently misbehaving —
the good failure mode. Do not "helpfully" accept both types; that converts it into a silent one.

**`getSafeZBounds` returns live geometry, not a computed value.** `ZoneService:302-305` reads the
actual fire-wall parts (`fireEffects[1].Position.Z + halfThickness`) — that is *why* it returns the
wall's inner **face**. The radial form must read the live ring radius minus half thickness the same
way. Recomputing the radius from `f` instead would drift from the rendered wall and quietly break the
face contract.

**It has FOUR consumers, not one — the earlier draft named only `SpawnService`.** Every one
destructures `local minZ, maxZ`, so all four break the moment the return shape changes:

| Consumer | What it does with the pair |
|---|---|
| `SpawnService:138` | `getSafeZBounds(0)` for the spawn-clearance filter |
| `ZoneService:319` | inside `clampPositionToSafeZone` |
| `ZoneService:339` | inside `isPositionInSafeZone` |
| **`BotPathing:576-586` `GetFirewallEscapePosition`** | **the one the earlier draft missed.** Compares `position.Z < minZ - tolerance` with hysteresis and picks an escape Z. This is Z-axis logic end to end, not just a destructure — under radial it becomes "move inward along the radius". Miss it and bots cannot escape a closing ring |

**Other sites:**

| Site | Change |
|---|---|
| `ZoneService.clampPositionToSafeZone` (**:317-322**) | already takes a `Vector3`, but clamps **only Z** and depends on the return shape above. Radial form: `center + (pos-center).Unit * math.min(dist, r - margin)`. Callers `BotPathing:302, 1035, 1074` unchanged |
| `ZoneService.getSafeZBounds` (**:297**) | returns `(minZ, maxZ)`. Radial needs `(centre, radius)` — either a second function or a shape-tagged return. See the four-consumer table above |
| `createFireWall` (defined **:733**, called **:807-808**) | 2 walls (`ZoneFire_South` / `_North`) become N ring segments. Runtime-created, so **no map authoring** — a loop, not content. Use 10-12 segments for the look |
| `ZoneBurnedSmoke_South` / `_North` (**:574-596**), `ZoneFireGroundEffects` (**:612**) | same segmentation. `updateBurnedSmokeVolumes` now reads `ZONE_START` / `ZONE_END` upvalues from MapConfig |
| `randomCenterOffset` (declared **:21**; set **:56** round, **:122** tutorial, **:853** reset) | scalar → 2D offset. Better on a round map than Redwater's 1D jitter. Note the tutorial path now reads `MapConfig.Zone.TutorialCenterOffset` |
| `lastFireTrailZ`, `lastTerrainAlignmentZ` (**:37-38**; written :707-708, :816-820, :835-844, :865-866) | Z-keyed state tables, need re-keying per segment |
| **`ZoneAtmosphere:110-111, 116-117, 140` (CLIENT)** | independently finds `ZoneFire_South` / `_North` and does its own `posZ < innerSouthZ or posZ > innerNorthZ` test. **Easy to miss** — it is not in `RoundSystem` and does not call `ZoneService` at all |
| `SpawnService:85-88` | `FIRE_WALL_SPEED` / `SPAWN_ZONE_MARGIN` derivation, now `MapConfig.Zone` span over `Config` schedule. **Keep it derived** (§5) — re-derive from the radial schedule's fastest transition, do not inline 22.6 |
| `BotConfig.FirewallAvoidanceMargin = 26` | scalar margin, works unchanged under radial |

**Phase 1 gives you a free test lever.** Compressing `Config.ZONE_PHASE_DURATION` inflates
`SPAWN_ZONE_MARGIN` through the derivation (20s → margin 72 vs production 27, halving the usable
spawn pool), so a short round is a *harder* test of the spawn filter, not merely a faster one. That
is how Phase 1 was validated; use it for the radial spawn filter too.

### 6.5a What was actually built — one API deviation

**`getSafeZBounds` was DELETED, not given a radial twin.** §6.5 above assumed it survived in some
form. It is replaced by **`ZoneService.getSafeClearance(position) -> studs inside the boundary`**,
because three of its four consumers were already deriving exactly that number from the `(minZ,
maxZ)` pair, and a shape-tagged return would have put a `Shape` branch in all four instead of one.
`clampPositionToSafeZone` covers the fourth (`BotPathing.GetFirewallEscapePosition`), which now
reads clearance for its hysteresis and clamps for its destination.

Consequences worth knowing before Phase 3:

- **The Shape branch exists in exactly two files.** `ZoneService` owns it; `ZoneAtmosphere` carries
  the client's unavoidable second copy (a LocalScript cannot require a server module, and finding
  two walls by name does not generalise to N segments). It requires `MapConfig` as of this phase.
- **`workspace.ZoneCenter`** is a new attribute, written once per round, so that client copy can
  locate a ring. New replication surface, and a second home for the zone's centre.
- **`MapConfig.Zone.Axis` now hard-asserts at require time.** It was declared and read by nothing.
  A linear map declaring a non-Z axis fails on load rather than rendering its zone 90 degrees out.
- **`randomCenterOffset` is a `Vector2`.** Linear reads only `.Y` and still draws exactly one number
  from the seeded stream, so a given round start lands on the centre it always did.
- **§10 item 3's gate wording is stale** — it names `getSafeZBounds`. Re-scope it when that check is
  next run.

### 6.5b The checklist that closed this phase

No MCP playtest (`start_playtest` hangs the plugin), so Phase 1's lever was reused: `ROUND_TIME` 80
/ `ZONE_PHASE_DURATION` 20, which inflates `SPAWN_ZONE_MARGIN` to 72 and halves the usable spawn
pool — a *harder* test of the spawn filter, not merely a faster one. Restored to 360 / 80 after, and
re-verified.

Walls build and close with columns sitting on the terrain (this is what covers the
`alignWallColumnsToTerrain` change from `Position + offset` to `CFrame:PointToWorldSpace`); ground
trail and burned-smoke volumes follow; the burn ramp and its grade behave; respawns never land in
the flames; bots turn inward without jittering on the boundary; reset clears everything; the
tutorial runs with its pinned centre. All passed.

### 6.5c What a playtest could NOT verify, and what closes it

**The ring's rendering.** Redwater is linear, Frostbite has no code yet, so `_createFireRing`,
`resizeRingSegment`, the smoke annulus and the arc trail have never drawn a frame. The maths they
feed is verified; the visuals are first-playtest work in Phase 4. A temporary radial `MapConfig` on
Redwater was offered as a smoke test and **declined** — the geometry would have been nonsense and a
MapConfig that must not be published mid-test is its own hazard.

Two sizing decisions to check when it first runs, both deliberate:

- **Segments resize as the ring closes.** A fixed-width chord bows outward at its ends, which at the
  final radius would put flames ~34 studs *outside* the boundary the damage tick uses.
- **Emitter columns are budgeted at the arena radius, not the spawn radius.** `ZONE_FIRE_SPAWN_FRACTION`
  is 2.0, so the fire spawns on a circle 1.4x the arena; counting columns there would over-provision
  every later phase permanently. 96 columns for a boundary 1.5x longer than Redwater's two walls
  (62), rather than 144. Ground-fire patches are likewise budgeted per *ring*, not per segment.

### 6.7 `EndRadius` — tightening the endgame (2026-08-13, after the first playtest)

The first Frostbite playtest confirmed §6.6's prediction from the other direction: the final zone
was **the same 25% of arena area as Redwater's**, and on a circle that reads as far too open.
`radius = StartRadius * sqrt(f)` makes area linear in `f` exactly as the canyon's span does, so
Frostbite inherited Redwater's endgame *size* precisely — the problem was never a bug.

**`StartRadius` is not the lever.** It is a measurement of the authored rim (fit 386.4, declared
384), and lowering it drags every phase inward and pushes spawns outside the *opening* ring — at
320 two of the 37 spawn in fire. Measured floor is ~350, which only reaches a 175 final.

So the radial branch gained an optional **`EndRadius`**, with area interpolating linearly between
the two radii:

```lua
radius(f) = sqrt( End² + (Start² - End²) * (f - 0.25) / (1 - 0.25) )
```

Each phase still removes an equal slice of area, so the shared `Config` schedule is untouched.
**Omitting `EndRadius` defaults it to `StartRadius * sqrt(0.25)`, which collapses the formula back
to the old one exactly** — the previous behaviour is the special case, not a separate branch.
Redwater is linear and re-derived bit-identical (`FIRE_WALL_SPEED` 1.8750, `SPAWN_ZONE_MARGIN`
27.00).

Frostbite ships `EndRadius = 150`:

| Phase | `f` | Radius | Usable (−25.77 margin) | Worst-case eligible spawns |
|---|---|---|---|---|
| 1 | 1.00 | 384.0 | 358.2 | 37 |
| 2 | 0.75 | 325.3 | 299.5 | 31 |
| 3 | 0.50 | 253.3 | 227.5 | 18 |
| Final | 0.25 | **150.0** | 124.2 | **7** |

Final area **70,686** sq studs against 115,812 — **39% tighter**. The last transition is the
fastest at 1.721 studs/s (vs 1.325), so the margin rises 22.60 → 25.77, still under Redwater's 27.
Seven eligible Final spawns against Redwater's guaranteed 3.

**The mapping now lives in two places, deliberately.** `ZoneService.radiusForFraction` is canonical;
`SpawnService.zoneBoundaryAt` carries a copy because it runs at *module load* to derive the margin,
and calling ZoneService there would add a load-order dependency on a much larger module for three
lines of arithmetic (`SpawnService` requires ZoneService lazily today, and ZoneService does not
reference SpawnService at all). Both carry a comment pointing at the other. Change them together.

**Not yet playtested.** The numbers are verified through the shipped code; the ring at 150 has not
been seen.

### 6.6 One genuine design consequence

Redwater's Final zone is a 225 x 617 **strip** — wide and shallow, with a long axis to retreat down.
Frostbite's is a 384-diameter **circle** with no long axis. Comparable area (117,300 vs 138,800 sq
studs), meaningfully different endgame: more forced contact, less kiting. Recorded as a deliberate
choice, not an accident of the maths.

---

## 7. Phase 3 — The sync mechanism

> **TOOLING BUILT and VALIDATED 2026-08-13.** The mechanism is `/mirror`
> (`.claude/skills/mirror/SKILL.md`), which owns the allowlist, the walk and the repair procedure —
> read it for *how to run it*; this section stays the *why*. `/preflight` Step 1 now delegates to
> `/mirror universe` and its 17-row eyeball compare collapsed to a single `TOTAL` fold. **Validated
> against the known-good state:** Bounty and Redwater print byte-identical universe manifests down
> to the rollup (`6f17c98a`), all 17 in sync. **§7.4's store-name chokepoint is NOT built** — it is
> independent of the mirror and waits for dev places to exist.
>
> **One measured reversal, recorded in §7a.** Option B below assumes scripts sync naturally via
> `set_script_source` and that non-script instances are the hard part. Both halves are wrong.

**DECIDED 2026-08-12: Option B, for everything. Option A is rejected outright** — see §7.4 for the
dev/live topology that decides it.

Two mechanisms were weighed. Both eliminate hand-copying; they differ in who performs the sync.

### Option A — Roblox Packages
Convert each shared tree to a Package in Redwater, insert into Frostbite, use *Update All*.

- **Pro:** native, atomic per package, no custom tooling.
- **Con:** publish and update are **Studio UI operations**. The MCP toolset has no package
  publish/update verb, so the sync step becomes a **manual action the user performs**, not something
  an agent can do or `/preflight` can gate. Given this project is almost entirely agent-driven, that
  is a significant regression in workflow.
- **Con:** a package update **replaces the whole packaged instance and its descendants**. Anything
  map-specific inside a packaged folder is destroyed on every update — this is why `MapConfig` must
  live outside them (§5, §7.3).

### Option B — Scripted mirror sync over MCP *(recommended)*
Both places connect to MCP simultaneously (confirmed — three instances were connected while writing
this). An agent can `get_script_source` from Redwater and `set_script_source` into Frostbite for
every script in the shared trees, then byte-compare to verify.

- **Pro:** agents can run it. It becomes a `/mirror` skill and a hard `/preflight` gate, exactly like
  the existing byte-length + checksum compare.
- **Pro:** **retires the 17-module manual mirror** in the same stroke, and generalises to any number
  of places.
- **Pro:** verification is the same mechanism as the sync, so drift is detectable, not just avoidable.
- **Con:** custom tooling to write and maintain. Handles *scripts* naturally; non-script instances
  (GUI trees under `StarterGui`, `ReplicatedStorage` models/folders of assets) need `export_rbxm` /
  `import_rbxm` or a recursive property copy — meaningfully harder than scripts.
- **Con:** `set_script_source` mangles `\n` escapes in Lua string literals
  (`reference_mcp_source_newline_escapes`). Any sync tool must round-trip-verify, not assume.

**DECIDED: Option B for everything.** An earlier draft recommended a hybrid (B for scripts, A for
the authored GUI and asset trees). That is superseded — once dev twins exist, **Packages have no
branching**: dev and live consuming the same package means publishing an update to test in dev
simultaneously offers it to live, with no way to express "this version is dev." Packages also
replace the whole packaged instance and its descendants on update, and the sharing tiers cut
*through* existing folders (`PlayerServices` mixes universal and deathmatch services) while Packages
are per-tree. None of that is fixable, so A is out even for the trees it suited.

**Two things keep B's cost down:**

1. **The one-time bring-up is not the sync tool's job.** Export the §7.1 trees from Redwater as
   `.rbxm` and import them into Frostbite — roughly 8 operations, not 300 script writes. Push code
   *into* Frostbite rather than rebuilding Frostbite from a Redwater copy, specifically because
   **terrain transfers badly** and this direction never moves it. The two places then start
   identical and the ongoing tool only has to catch **drift**, which is the scripts-only easy case.
   `export_rbxm` / `import_rbxm` stays the escape hatch for later GUI changes.
2. **The mirror only ever runs between DEV places** (§7.4), so a mirror bug is a dev-only accident
   fixed by not promoting. It does not need to be transactional.

### 7a. What was actually built (2026-08-13) — one reversal and three missing roots

**1. `set_script_source` is the WRONG repair tool, and `.rbxm` handles scripts too.** Option B's
pro/con pair reads "handles *scripts* naturally; non-script instances … meaningfully harder than
scripts." Measured, it is the other way round:

- `set_script_source` **interprets** `\n`, `\r` and `\t` in the source text. A probe carrying them
  came back with a real newline inside a string literal and an injected CR byte — a *different
  file* than the one read. This is `reference_mcp_source_newline_escapes`, reproduced deliberately.
- `export_rbxm` → `import_rbxm` is binary. `ProfileService` (83,513 bytes, the codebase's heaviest
  escape carrier) round-tripped Redwater → Frostbite **byte-identical**, `ClassName` preserved,
  compiling. It creates missing instances and whole subtrees in one call, so it subsumes
  `create_object` + `set_script_source` rather than being a fallback for the awkward cases.

So the con that made Option B look expensive was backwards: **one mechanism covers both**, and the
scripts-only "easy case" is the one with the corruption hazard. The blast radius is small — **2 of
269 synced scripts** carry such escapes — but a mangled `\t` compiles silently, so it is not
self-announcing.

**2. §7.1's root list omits three real ones**, found by walking the live tree instead of the prose:

| Root | Redwater | Frostbite | Why it matters |
|---|---|---|---|
| **`SoundService`** | 3 SoundGroups — `SFX`, `HitSound`, `Music` | **none** | Every Sound must carry a group and "Master" is faked by multiplying into each (`CLAUDE.md`, Audio). A Frostbite without them puts every sound outside **all four** settings sliders — silently. Author or import before first playtest. |
| `TextChatService` | 4 config instances | 4, **already identical** (`b317e447`) | Roblox defaults, never edited. In the allowlist so an edit to one place surfaces. |
| `StarterPlayer.Folder` | 3 `StarterCharacter` rigs, 3 scripts | absent | Map-agnostic parked storage. A `StarterCharacter` only applies as a *direct* child of `StarterPlayer`, so this is inert content, not live config. |

**3. §7.1's counts are stale.** Live 2026-08-13: `ServerScriptService` 13 children (the `Testing`
folder is **gone**, taking §12's `BotSpawner2` item with it), `ReplicatedStorage` 36 (not 40),
`StarterGui` 18 (not 19). The synced boundary is **272 scripts / 3.78 MB** across 9,586 instances,
against 291 scripts in the place — the other 19 are Workspace dummy `Animate` scripts (11) and
`ServerStorage` (7), neither of which syncs, plus `MapConfig`.

**4. The allowlist is services, with one exclusion inside.** §12 says "allowlist the synced trees;
never denylist" — that governs *services*, and Workspace/Terrain/Lighting/MaterialService/
ServerStorage are simply absent. **Within** an allowlisted service the walk is unfiltered, so a new
top-level folder syncs by default; a hand-maintained list of trees would silently un-mirror
anything added to it. `ReplicatedStorage.MapConfig` is the single exclusion, which is exactly why
§7.3 keeps it a root-level sibling.

**5. Structure is compared, properties are not.** The fold covers every instance's path and class
plus source bytes and hash, so an edit, a rename, a reclass and a missing GUI child all move it —
each verified by deliberate injection. A recoloured Frame does not. Authored GUI is checked
**structurally, not visually**, by design (v1 decision).

### 7.1 Shared boundary — what syncs

Everything below is gamemode code and must be identical in both places:

| Service | Trees |
|---|---|
| `ServerScriptService` | `Main`, `SoftShutdown`, `HunterImplementationGuide`, `Combat`, `VFX`, `UI`, `Networking`, `PlayerServices` (22), `AntiCheat`, `Hunters`, `Bots`, **`Onboarding`** (see §3.1 — syncs inert). **13 children; `Testing` is gone (§7a).** |
| `ServerScriptService.RoundSystem` | all **6** (was 7; `DestructibleService` removed 2026-08-13) — **minus** the map constants removed in Phase 1 |
| `ReplicatedStorage` | `Hunters`, `Revolver`, `Modules`, `Events`, `ExternalLibrary`, `Characters`, `CharacterScripts`, `SFX`, `VFX`, `KillFeed`, `Grudgekeeper`, viewmodel + asset folders, `BotRig`, `BotAnimate`, the BillboardGui templates, the Round value objects |
| `ReplicatedStorage` root modules | `BattlePassConfig` `BoostConfig` `DailyRewardConfig` `EmoteConfig` `FriendBonusConfig` `GameEnvironment` `QuestConfig` `TitlesConfig` `TitleStyles` `TitleRenderer` |
| `StarterPlayerScripts` | all **44** incl. `Dust` `Fortuna` `Vesper` `Bram` and the empty `RbxCharacterSounds`, which is load-bearing (§2, §3b-ii) |
| `StarterCharacterScripts` | `Health` |
| `StarterGui` | all **18** (§7a — the 19 was stale) |
| `ReplicatedFirst` | `EarlyShotRemoteDrain` |
| **`SoundService`** | the 3 SoundGroups — `SFX`, `HitSound`, `Music`. **Missing in Frostbite** (§7a) |
| **`TextChatService`** | its 4 config instances — already identical everywhere (§7a) |
| **`StarterPlayer.Folder`** | 3 `StarterCharacter` rigs, map-agnostic parked storage (§7a) |

**Loose root modules are a packaging problem.** The 10 ModuleScripts sitting directly under
`ReplicatedStorage` cannot form one Package without wrapping them in a folder — and wrapping changes
every `ReplicatedStorage.X` require path across both places. Under Option A, make each its own
package (10 packages, zero path churn). Under Option B this is a non-issue.

### 7.2 Never syncs (map-specific, authored per place)

- All of `Workspace` — geometry, terrain, and the full §3a contract (`SpawnPoints`, `JailSpawn`,
  `FinishSpawns`, `WallMap`, **`VesperHookSpotsBot`**, **`CameraSpawn`**, **`CameraFolder`**) plus
  the §3b tags (**`HealthPack`**, **`Penetrable`**)
- `Terrain` material colours + water properties
- `Lighting` and all its children
- `MaterialService` variants
- `ReplicatedStorage.MapConfig`
- `ServerStorage` — plugin junk (`Brushtool2_Plugin_Storage`, `RBX_ANIMSAVES`) **and**
  `TutorialDummies`, which is Redwater-only per §3.1

### 7.3 The load-bearing rule

> **Nothing map-specific may live inside a synced tree.**

Under Option A a package update silently destroys it. Under Option B a mirror sync overwrites it.
Either way the failure is **silent** — same class of bug as the `EmoteConfig` drift (18 ids → 5, 13
emotes collapsed to default with no error) and the `QuestConfig` drift (2777 vs 3337 bytes). This is
why `MapConfig` is a root-level sibling and not `RoundSystem.MapConfig`.

### 7.4 Dev places, and the store-name chokepoint (DECIDED 2026-08-12)

Private dev copies of Bounty, Redwater and Frostbite are coming. **They live in the SAME universe as
live**, as extra places — not a separate experience. That keeps product and gamepass IDs shared, so
purchase flows test normally with no per-environment ID table.

**This splits the sync graph into two edge types that must not share a mechanism:**

| Edge | Mechanism |
|---|---|
| **Vertical, dev → live** (promotion) | Whole-place publish from Studio. Carries Workspace, Terrain and Lighting. Native, manual, no tooling. |
| **Lateral, Redwater ↔ Frostbite** (drift) | The Option B mirror — and **only ever between dev places**, because each live place is downstream of its own dev twin. |

#### The cost of one universe: 8 shared state names

DataStores and MemoryStores are **universe-scoped**, so same-universe dev places share live state by
default. Measured across both places 2026-08-12 — this is the complete surface, and there is **no
`MessagingService` anywhere in either place**, so no cross-server broadcast leak:

| # | Name | Site |
|---|---|---|
| 1 | `PlayerData_v2` | `DataService:215-216` (`DATA_VERSION`), both places |
| 2 | `RankPoints_v<season>` | `GameEnvironment.getRankStoreName()` → Redwater `RankedService:44`, Bounty `RankLeaderboardService:54` |
| 3 | `STORE_NAME` | Bounty `LimitedStockService:40` |
| 4-6 | `DIRECTORY_MAP`, `PENDING_MAP`, `ACCESS_CODE_MAP` | Bounty `MatchmakingService:74-76` (MemoryStore) |
| 7-8 | `MAP_NAME`, `ACCESS_CODE_MAP` | Redwater `MatchDirectoryService:71-72` (MemoryStore) |

**The MemoryStores are the sharper risk, not the profiles.** The match directory is how Bounty finds
Redwater servers. An unsuffixed dev Bounty reads live directory entries and hands out live access
codes; `GameEnvironment` resolves the PlaceId to dev so the teleport *fails* rather than landing in a
live match, but dev players occupy slots in the live pending map and matchmaking breaks confusingly.

#### The fix is ONE chokepoint, not 8 branches

`GameEnvironment` is already mirrored and already knows the environment, and already owns name 2:

```lua
function GameEnvironment.storeName(base)
    return GameEnvironment.isLive and base or (base .. "_" .. GameEnvironment.env)
end
```

Every name above routes through it and `getRankStoreName` wraps it. **Live names are unchanged, so
no existing data moves.** Same shape as `Wallet` being the sole currency mutator — and it makes the
real failure mode (someone adds a 9th store later and forgets) a mechanical `/preflight` grep for
`GetDataStore` / `GetOrderedDataStore` / `GetSortedMap` / `GetHashMap` call sites not routed through
the helper. Promote this to a `CLAUDE.md` rule when it ships, not before.

Suffixing name 3 also means dev testing stops burning live Prestige Card units
(`project_limited_stock`).

#### The residual cost, which has no fix

**Analytics blend, permanently.** Open item 084 records that Creator Hub's `Place` filter does not
split custom events by emitting place, so dev `MatchStart` events land in live charts with no way to
filter them out. Store suffixing does not help — different system. One universe means one analytics
stream. Accepted knowingly.

---

## 8. Phase 4 — Frostbite bring-up

> **STEPS 1, 3, 4 and 5 DONE 2026-08-13.** Frostbite now carries the whole shared codebase and is
> **provably identical to Redwater**: every synced root's fold matches and the match-tier `TOTAL` is
> **`ffa5db7a`** in both places — 272 scripts, 9,587 instances, 3,782,989 source bytes. All 273
> scripts (272 + `MapConfig`) compile via `loadstring`, 0 failures. `MapConfig` authored radial per
> §6.3. SoundGroups reconciled to 87 SFX + 5 HitSound + the same 7 deliberately ungrouped.
>
> **Steps 2 and 6 also DONE.** Access page copied from Redwater (Maximum Visitor Count 10, Social
> Slots Customize/3, Direct Access Control **Limited to same Universe** — that last one is per-place
> and carries a "you've made an exception" flag, so Frostbite would **not** have inherited it;
> left at the default, players could deep-link straight into a match and bypass the lobby entirely).
> `GameEnvironment` now carries a Frostbite row — see §8a.
>
> **Phase 4 is COMPLETE. The remaining gap is that nothing here has ever been playtested**, including
> §6.5c's ring rendering, which has still never drawn a frame. Routing (§9) is the next phase and is
> still blocked on the map-picker product question.
>
> **Two `.rbxm` losses were found and repaired — see the `/mirror` skill for the general rule.**
> 92 `Sound.SoundGroup` refs were dropped (targets outside the exported set — a serialize-time loss
> no import order fixes), and **3 of 6 `AccessoryWeld`s under `Characters` vanished despite valid
> intra-set `Part0`/`Part1`**, recreated by hand with `C0`/`C1` copied at full precision. Neither
> raised an error, and `import_rbxm`'s `instance_count` reported success because **it counts
> top-level instances only** — it said 35 while the subtree was 3 short. The fold caught both.
>
> **Pre-existing Redwater bug, carried across deliberately:** 7 Sounds under
> `RevolverDefaultViewmodel.Skins.HellFire.Revolver.Base` have **no SoundGroup**, so the HellFire
> skin's audio escapes all four settings sliders. Grouping them in Frostbite alone would have made
> the two places differ, so they were carried faithfully. Fix in **both** places or neither.

1. Rename the DataModel — it is still `Place1`.
2. Confirm place settings on the **Creator Hub**, not from the DataModel
   (`feedback_place_settings_source`): `StreamingEnabled = true`, and **Maximum Visitor Count = 10**
   to match `SOLO_PLAYER_CAP + FRIEND_SLOTS` (`Config.md` §2b — mismatching this makes the friend
   slots fiction and produces `GameFull` rejections).
3. ~~Author every map contract instance in `workspace` (§3a), and both tag sets (§3b).~~
   **ESSENTIALLY DONE as of 2026-08-13 — see the §2 Frostbite table for the live measurement.**
   `SpawnPoints` (37), `WallMap` (16, audited and sealed), `JailSpawn`, `FinishSpawns` (full tree),
   `VesperHookSpotsBot` (40), `CameraSpawn`, `CameraFolder`, `HealthPack` (35) all exist.
   Remaining on this step: **nothing blocking.** Consider tagging `Penetrable` on any non-wood cover
   (currently 1 vs Redwater's 8 — fine while the cover is wooden, §3b-ii).
   Do **not** author `TutorialSpawn` / `TutorialBountySpawn` (§3.1), and do **not** author
   `CorpseFolder` (§3a — not a contract).
4. Sync the shared trees (§7.1) by the chosen mechanism.
5. Author `ReplicatedStorage.MapConfig` for Frostbite.
6. ~~Add Frostbite to `GameEnvironment`'s `ENVIRONMENTS` table.~~ **DONE 2026-08-13 — see §8a.**
   **Never hardcode a PlaceId anywhere else** — every place resolves siblings from its own
   `game.PlaceId`, which is what keeps DEV servers out of live matches.

### 8a. The `GameEnvironment` third-place change (2026-08-13)

Frostbite resolved `env = "Unknown"` / `isLive = false` until this landed, and that was doing more
damage than a wrong label: `Telemetry:57` gates on `GameEnvironment.isLive`, so **Frostbite emitted
no telemetry at all**, and `Wallet` + `Telemetry` tagged every economy and match event with place
`"Unknown"`. The version tag also rendered `[UNKNOWN]` to players, and the live-server guard on
`TUTORIAL_FORCE_MODE` was unarmed (harmless only because the flag reads `false`).

**The sibling ids were factored out of the rows.** Each row used to repeat
`bounty = …, redwater = …`; a third place would have made that three copies per row, and a fourth
map four. They now point at one shared `LIVE_SIBLINGS` table, so a new map is one constant, one
line in that table and one row — and a sibling can no longer be present on one row and missing from
another, which would resolve `nil` and teleport nowhere. `GameEnvironment.frostbitePlaceId` is the
new field; the five existing ones are byte-for-byte unchanged in behaviour and were regression-checked.

Propagated by `.rbxm` rather than three source writes, so the copies are identical by construction.
Verified: all three places report `17/17, 295683 bytes, fold a50c52df` on the universe tier, and
Redwater/Frostbite still match on the match tier at `7d50c6f1` — its byte count moved by exactly
708, `GameEnvironment`'s growth.

**Bounty resolves `redwaterPlaceId` in four services** — `MatchmakingService`, `FriendJoinService`,
`FollowJoinService`, `TutorialDispatchService`. Adding `frostbitePlaceId` does not route anything on
its own; making those map-aware is §9, which lists exactly what each one does with it. (An earlier
draft named `PartyService` here; it does not read the id — `FollowJoinService` does.)

### 8b. State at end of 2026-08-13 — what was synced after bring-up

The bring-up fold in the header (`ffa5db7a`) is a **historical** figure. Four things landed after it,
and the current parity figure is below.

| Synced after bring-up | Why it was not in the bring-up |
|---|---|
| `RevolverDefaultViewmodel.Skins.BetaRevolver` (47 desc) | Authored in Redwater *after* the bring-up pass |
| `SniperDefaultViewmodel.Skin.Frostpiercer` (44 desc) | Same |
| `StarterGui.MapVoteGui` (26 desc) | Same — see §9.6 |
| `HunterSelectionService.STUDIO_TEST_HUNTER` → `nil` | Testing knob, set during the first Frostbite playtest |

**Current parity, both match places: `TOTAL 110572d4` — 272 scripts / 9,707 instances / 3,786,476
bytes, every one of the nine mirrored roots matching.** That number is the one to re-derive before a
publish, not `ffa5db7a`.

Two notes for whoever picks this up:

- **`MapVoteGui` is deliberately left `Enabled = true`** with no visibility gate, at the owner's
  instruction, because Phase 5 is being built against it. It therefore renders mid-screen in a
  playtest in **both** match places and overlaps the podium, the intermission timer and RETURN TO
  BOUNTY. **This is not a bug to fix in passing** — the vote code turns it off and on. It must not
  ship enabled.
- **The non-script drift was invisible to every other check.** All three of the syncs above had
  identical script counts and identical source bytes; only the instance census moved. That is the
  case `/mirror` exists for, and the reason its fold covers instances rather than just scripts.

---

## 9. Phase 5 — Lobby and routing

**Product decisions, made 2026-08-13. These close open question §11.3.**

1. **Match 1's map is assigned by Bounty's `MatchmakingService`.** No lobby UI, no player choice, no
   party-conflict rule.
2. **Every subsequent map is chosen by an end-of-match vote in the match place**, run at *every*
   round end, through the already-authored `StarterGui.MapVoteGui`.
3. There is **no gamemode picker** and there never was — see §9.0. Map is the only new axis.

### 9.0. Two corrections to what this section used to say

> **SUPERSEDED 2026-08-17.** The "no gamemode picker" finding below was true when measured and is
> now false: `Bounty.StarterGui.GameModeGui` shipped with the tutorial relocation in Hotfix 1.2 and
> is a live, working picker. Every "there is no gamemode picker and never was" line in this spec
> (§9, §12) inherits this stamp. Current behaviour: `TEAM_DEATHMATCH_SPEC.md` §3.4. The rest of
> §9.0 — the clean `GameEnvironment` destination resolution — still holds.

**"The lobby already has a gamemode choice" was false.** Measured 2026-08-13: `gamemode` appears in
exactly one Bounty script (`GameEnvironment`), and `Deathmatch` / `selectedMode` / `MatchMode` appear
in none of the 171. `CLAUDE.md`'s "choose a gamemode before teleporting in" overstates it the same
way. So the old "two pickers that might conflict" paragraph described a problem that does not exist,
and every `gamemode` field below is **deferred, not built** — there is nothing yet to carry.

**Bounty's Redwater destination is already clean.** All four call sites resolve from
`GameEnvironment`; no PlaceId is hardcoded anywhere:

| Script | Use |
|---|---|
| `FriendJoinService` | `REDWATER_PLACE_ID = GameEnvironment.redwaterPlaceId`; 2 `TeleportAsync`; re-exported as `FriendJoinService.REDWATER_PLACE_ID` |
| `MatchmakingService` | 2 × `ReserveServer(REDWATER_PLACE_ID)` |
| `FollowJoinService` | `entry.placeId == FriendJoinService.REDWATER_PLACE_ID` → `"Match"` vs `"Lobby"` |
| `TutorialDispatchService` | 1 × `TeleportAsync` — **stays Redwater-only** (§3.1) |

### 9.1. The publish blocker — the match directory cannot tell the maps apart

**BUILT 2026-08-14.** `map = MapConfig.Id` on every entry; the absent-means-redwater default lives in
Bounty `MatchmakingService.readServers` and nowhere else; the stores keep their prefix. One addition
beyond the list below: `FollowJoinService`'s two `REDWATER_PLACE_ID` comparisons became
`FriendJoinService.isMatchPlace(entry.placeId)` — a Frostbite PlaceId falling to the lobby-hop
else-branch would have sent a plain jobId at a reserved-only place.

**This is independent of the vote and must land before Frostbite goes live at all.**

`MatchDirectoryService` is in the match tier, so Frostbite carries it **byte-identical**. Its four
MemoryStore names are hardcoded with a `Redwater` prefix:

```
RedwaterMatchDirectory_v1     SortedMap   MatchDirectoryService (match) + MatchmakingService (Bounty)
RedwaterAccessCodes_v1        HashMap     both
RedwaterPendingJoins_v1       HashMap     Bounty only
RedwaterTutorialServers_v1    HashMap     both
```

A live Frostbite server therefore publishes itself into the same directory Bounty queries to route
Redwater players, and **nothing in the entry says which map it is**.

**Keep one shared store; add the field.** One query returning every map, filtered client-side, is
better than one query per map — and it is what makes "find me any server on the map that won the
vote" a single lookup. The work is:

- `MatchDirectoryService.writeEntry` adds `map = MapConfig.Id` to the entry.
- Bounty's `MatchmakingService` and `FriendJoinService` filter candidates on it.
- **A missing `map` field means `"redwater"`.** Publishing does not update servers already running
  (`CLAUDE.md`, Environments), so for one server generation the directory holds entries written by
  old code. A filter that treats absent as "unknown, skip" sees zero servers and takes matchmaking
  down for ~30–60 minutes.
- **Do not rename the stores in the same change.** The names are misleading, but a rename is a
  coordinated three-place cutover and the entries are TTL'd anyway. Defer it to a `_v2` bump and
  leave a comment saying why.

### 9.2. Bounty assigns match 1's map

**BUILT 2026-08-14, with one deliberate deviation and one addition.** The uniform roll happens
**only when reserving a fresh server** (`reserveFreshServer` → `MapCatalog.randomLiveId()`), not as
a filter on candidates — rolling first and then filtering to the roll would walk past a busy
Redwater match to seed an empty Frostbite one, and the live population is uniform anyway because
every server was created by the roll. The catalog rows also gained a `live` flag (in rotation is a
separate fact from existing; both maps ship `live = true` — user decision 2026-08-13), and
`chooseDestination` returns `(…, placeId, mapId)` because an access code is only valid against the
place it was reserved on, so `PartyService`'s constant destination had to go with it.

`MatchmakingService`'s two `ReserveServer(REDWATER_PLACE_ID)` calls reserve against the **selected
map's** PlaceId instead. `FollowJoinService`'s `"Match"` test becomes "is this *any* match place".

Selection rule: **uniform random across live maps**. Not rotation — rotation is per-server state and
Bounty has many servers, so it would not actually rotate. Revisit if one map proves unpopular.

**Bounty has no `MapConfig`** — it is per-place and never syncs (§7.2). So the map list needs a new
home, and it is needed in all three places at once: Bounty to assign, Redwater and Frostbite to
render the vote tiles.

**New module `ReplicatedStorage.MapCatalog` — the 18th mirrored module (universe tier).** One row
per map: `{ id, displayName, thumbnail, siblingKey, gamemodes }`. `siblingKey` indexes
`GameEnvironment`'s sibling table (`redwater` / `frostbite`) rather than storing a PlaceId, so the
no-hardcoded-PlaceId rule survives and dev/live resolution keeps working. Add it to `/mirror`'s
universe tier and to `CLAUDE.md`'s mirrored-module list in the same pass, or it drifts silently —
that is exactly how `QuestConfig` went to 2777 vs 3337 bytes.

`MapConfig.Id` stays the per-place identity and must equal the catalog row's `id`. That is the one
value the two files share, and nothing checks it — assert it at boot in the match place.

### 9.3. The vote

**BUILT 2026-08-14.** Its own beat after `VictoryShowcase "Clear"`, under the loop-tail curtain —
which is what resolved §9.6's collision. `Config.MAP_VOTE_TIME = 10` / `MAP_VOTE_RESULT_TIME = 2.5`
(tunable, picked without asking). The tie rule shipped stricter than written: move only on exactly
one leader that is not the current map. Server module `RoundController.runMapVote` + new
`MapVoteClient`; screenshot-verified at phone/tablet/ultrawide.

Runs at **every** round end. `RoundController` already loops up to
`SERVER_RETIRE_AFTER_ROUNDS = 5` rounds, so most votes will land on the current map and cost nothing.

- Server tallies; **a tie keeps the current map**, because staying is free and moving is not.
- **Winner == current map** → the existing loop continues, entirely unchanged. This is the common case.
- **Winner != current map** → §9.4.

### 9.4. The move path — a map change is a teleport, not a round transition

**BUILT 2026-08-14** as `RoundController.moveToMap`, in the ordering below, mirrored to Frostbite
(match-tier fold `e934626c` both places). The access-code write is
`MatchDirectoryService.registerAccessCode`, noted at both copies per step 3. Two details beyond the
steps: each group payload's `redwaterAccessCode` is **overridden** to the new code (passed through
unchanged, the destination server would adopt the abandoned server's code as its own at boot), and a
`ReserveServer` failure after `setClosing` degrades into `closeServer` — the entry cannot be
un-withdrawn, so playing on would leave the server invisible to matchmaking for life.
**VERIFIED on live DEV-universe servers 2026-08-14** — vote-to-move teleported the server
Redwater → Frostbite, stay stayed, party state survived Bounty → Redwater → Frostbite → Bounty,
and an app follow-join landed in the moved server (the duplicated access-code write working).

Map = place (§1). This is the part with no existing analogue, and the part most likely to be
underestimated.

1. `MatchDirectoryService.setClosing()` **first**, before anything else — it withdraws the entry so
   Bounty stops routing joiners into a server that is evacuating. `RoundController.closeServer`
   already establishes this ordering (its item 15a); the same reasoning applies here and for the same
   reason.
2. `TeleportService:ReserveServer(targetPlaceId)` → `(accessCode, privateServerId)`.
3. Write the access code to `RedwaterAccessCodes_v1` keyed by that `privateServerId`, exactly as
   Bounty's `MatchmakingService` does today, so friend joins can still follow the party into the new
   match. **The match server is doing Bounty's job here** — there is no cross-place RPC, so this
   logic is duplicated rather than shared. Note it in both copies.
4. Teleport. **`TeleportAsync` takes one `TeleportData` for the whole roster**, so a single call
   cannot preserve per-player party payloads. Group players by their original `groupId` from
   `RoundController`'s `playerGroupData` and issue **one call per group, plus one for the solos** —
   the same split `teleportAllToLobby` already makes (its item 16a), for the same reason: a solo
   must not arrive carrying a `groupId`, or Bounty rebuilds a party of one around them.
5. This server retires.

**Retirement stays exactly as it is — decided 2026-08-13.** `SERVER_RETIRE_AFTER_ROUNDS` does
**not** carry across a move. The destination server starts its own count of 5, exactly as if the
party had arrived from the lobby, and `TeleportData` gains no retirement field. Nothing in the
shutdown path changes.

The consequence is accepted, not overlooked: a group that keeps voting to move can play
indefinitely, because every move resets the counter. That is fine because retirement exists to stop
a *server* outliving its code, not to cap a session — and `SERVER_MAX_LIFETIME` (3600 s) still binds
on every individual server regardless of how it was reached, so no running server is ever more than
an hour behind a publish (`CLAUDE.md`, Environments: publishing does not update running servers).

### 9.5. What must not break

- **Friend joins and follow-joins mid-vote** (`project_friends_list_join`). Step 1 above is the whole
  defence; a joiner already in flight still lands in an evacuating server, same as today.
- `RoundController.getReturnTeleportData` and `LeaveToLobbyService` return to Bounty regardless —
  unchanged. RETURN TO BOUNTY stays the opt-out for anyone who does not want to move.
- The onboarding tutorial stays Redwater-only (§3.1) and never votes.

### 9.6. `MapVoteGui` — authored, unwired, and currently in the way

It exists in Redwater's `StarterGui` (26 descendants) with two `ImageButton` tiles, real thumbnails,
`VOTES: 0` counters and a `VOTE FOR NEXT MAP` header. **Zero script references in either place.**
Six things it needs before it can ship:

**All six closed as of 2026-08-14.**

| # | Problem | Measured |
|---|---|---|
| 1 | ~~Collides with the whole summary screen~~ | **DONE 2026-08-14** — the vote got its own beat after the showcase clears (see §9.3), so nothing shares the screen; the canvas moved to centre (`Position (0.5, 0, 0.5, 0)`, `Size (0.62, 0, 0.6, 0)`) |
| 2 | ~~Renders right now~~ | **DONE 2026-08-14** — authored `Enabled = false`; only `MapVoteClient` shows it, and it is in `RoundClientController`'s `SWEEP_EXEMPT_GUI_NAMES` so the round sweep's "unknown gui → visible" default cannot resurrect it |
| 3 | ~~Z-order undefined~~ | **DONE 2026-08-14** — `DisplayOrder = 1000000`: above the 999999 fade curtain it renders against, below MatchCompleteGui's 1000001 |
| 4 | ~~Will distort across devices~~ | **DONE 2026-08-14** — `UIAspectRatioConstraint` on the **canvas** (ratio set at runtime from the map count, keeping every grid cell square); a tile-level constraint was tried first and collided the two labels, which anchor to different boxes |
| 5 | ~~Hardcoded to exactly two maps~~ | **DONE 2026-08-14** — one hidden `TileTemplate` cloned per server-sent option; `CellSize` and the canvas aspect computed from the count; the second authored tile deleted |
| 6 | ~~Not in Frostbite~~ | **DONE 2026-08-13** — mirrored via `.rbxm`, property-level fold `98f4bb93` over 27 entries identical in both places. Frostbite gets the same vote feature by construction; both places now match on every mirror root (`TOTAL 110572d4`) |

**Give the vote its own beat rather than sharing the band.** The podium is the reward moment and the
vote is the decision moment; both are right-of-centre by nature, and problem 1 is what that collision
looks like. `POST_GAME_VICTORY_TIME` is already a sum of named parts
(`4.1 + 2.4 + 10 + 0.5 = 17.0`), so adding one is clean — and the move branch needs a further beat on
top for the reserve + teleport, which the stay branch must not pay.

### 9.7. Deferred

`gamemode` on the directory entry and in `TeleportData`, and filtering candidate maps by
`MapConfig.Gamemodes`. All of it is correct and none of it is reachable: there is one gamemode, no
picker, and `MapConfig.Gamemodes` is `{ "deathmatch" }` in both places. Build it with the second
gamemode, not before.

---

## 10. Verification

Nothing here is optional. Reporting done without these is reporting done falsely.

1. **Syntax** — every edited script recompiles via `loadstring(script.Source)`
   (`feedback_verify_code`). `execute_luau`'s `require()` cache is stale; recompile before trusting
   a module error (`feedback_plugin_require_cache`).
2. **Mirror parity** — byte-length + checksum compare across every synced tree, both directions.
   This is the gate that catches the failure mode that has already bitten this project twice.
3. **`MapConfig` completeness** — grep both places for the §3 names. **A surviving literal is a bug
   only for names `MapConfig.Instances` actually declares** (`SpawnPoints`, `JailSpawn`,
   `FinishSpawns`). `WallMap` and `VesperHookSpotsBot` are *deliberately* still literals in 15 and 12
   scripts respectively (§5, "What was actually built") — flagging those would be a false positive,
   which is how a gate gets ignored. Re-scope this check if that follow-up ever lands.
4. **No playtesting over MCP** (`feedback_no_mcp_playtest` — `start_playtest` hangs the plugin
   connection). Verify by `loadstring` plus a manual in-Studio checklist.
5. **Vault + graph** — new/changed scripts get `.md` files under `LocalRedwaterCanyon/`, and
   Frostbite needs its own vault folder + graph + update script if it is to be navigable at all.
   Wikilinks are for real code connections only.
6. **Publish both places together, always.** With three places this becomes a three-way lockstep —
   `/preflight` must be taught the third place before the first joint publish.
7. **Store-name chokepoint** (§7.4) — grep both places for `GetDataStore` / `GetOrderedDataStore` /
   `GetSortedMap` / `GetHashMap` and confirm every call site resolves its name through
   `GameEnvironment.storeName`. A missed one silently shares live state with a dev place. This is a
   `/preflight` gate, not a one-time check.

---

## 11. Open questions

1. ~~**Sync mechanism**~~ — **RESOLVED 2026-08-12: Option B (scripted mirror over MCP) for
   everything;** Packages rejected, they cannot express a dev/live branch. Dev places share the live
   universe, with an 8-name store suffix through `GameEnvironment.storeName`. See §7 and §7.4.
2. ~~**Frostbite's zone shape**~~ — **RESOLVED 2026-08-11: radial.** Measured circular (RMS residual
   2.50% of radius). Phase 2 is unblocked and fully specified in §6.
3. ~~**Map and gamemode selection UX**~~ — **RESOLVED 2026-08-13.** Matchmaking assigns match 1's
   map; every later map is chosen by an end-of-match vote in the match place, every round end. No
   lobby UI. The "two pickers" half of this question was **based on a false premise** — there is no
   gamemode picker in Bounty and never was (§9.0). See §9.
4. ~~**Mirror list accuracy**~~ — **RESOLVED 2026-08-11, see §11a.**
5. **Does Frostbite need its own knowledge-graph vault**, or does it inherit Redwater's given the
   code is identical by construction? Leaning: no separate vault for synced code; a small
   Frostbite-only vault for `MapConfig` and map notes.

### 11a. Resolved: the mirror list has TWO tiers, not one list of 17 or 18

Measured across both live places on 2026-08-11 (byte length + checksum of every file):

**Tier 1 — 17 fully-mirrored files. Byte-identical, and all 17 verified in sync today.**
`GameEnvironment` `BattlePassConfig` `BoostConfig` `EmoteConfig` `QuestConfig` `TitlesConfig`
`DailyRewardConfig` `FriendBonusConfig` `TitleStyles` `TitleRenderer` `AnimationLoader` `Wallet`
`Telemetry` `ProfileService` `SoftShutdown` `TelemetryClient` `VersionTagController`.
A whole-file checksum gate is correct for these.

**Tier 2 — 1 partial mirror: `CodeRedemptionService`.** Only the `CODES` table plus `resolveCode`
are shared (**1145 bytes, identical in both places today**). The award plumbing *deliberately*
differs: Redwater routes XP through `ProgressionService` because it owns the XP curve and the
`LevelUp` fire; Bounty has no such call. Whole files differ by design — 5341 bytes in Redwater vs
5010 in Bounty.

So both existing claims were imprecise. `project_code_redemption_mirror` calling it "a 17th mirror"
overstates it; `CLAUDE.md`'s list of 17 omits it entirely. **By location there are 18 files in scope,
but only 17 can be checksummed whole.** Adding `CodeRedemptionService` to a Tier-1 checksum gate
would false-positive permanently and train everyone to ignore the gate — the specific way a mirror
gate dies. It needs a region check (`local CODES = {` through the end of `resolveCode`), not a file
check.

**This matters more at three places than two:** every gate here becomes a three-way comparison, and
a Tier-2 file compared the Tier-1 way fails on every run.

---

## 12. Things that will bite

- **`set_script_source` mangles `\n` escapes** inside Lua string literals. Use a `[[long string]]`
  and verify with `loadstring` (`reference_mcp_source_newline_escapes`). Directly relevant to
  Option B.
- **`grep_scripts` matches literals by default.** Regex alternation silently returns 0 results —
  never conclude "no references" from a failed pattern search
  (`reference_grep_scripts_literal`).
- **Streaming is on in both places.** A Model can replicate as an empty container; never assume
  descendants exist client-side. Menu-critical instances need
  `ModelStreamingMode = Persistent` (`project_streaming_constraints`).
- **`Terrain` and `Lighting` are per-place and must NOT be synced.** A mirror tool that walks
  services indiscriminately will flatten Frostbite's art the first time it runs. Allowlist the
  synced trees; never denylist.
- **Redwater has no `SpawnLocation` anywhere.** `LoadCharacter` drops characters at world origin,
  and `hookCharacter` places them synchronously before anything yields to compensate. Frostbite
  inherits this and must have a valid origin *or* the same synchronous placement — a fresh character
  standing in the fire at origin is the failure this guards against
  (`RoundController.md` §4a).
- **Profile schema bumps are one-way.** Nothing in this spec should touch the profile shape; if it
  does, it is a data-affecting release and cannot be rolled back by reverting a place.
- **The two tag contracts fail silently and are invisible in code review.** `HealthPack` (25
  instances) and `Penetrable` (8) are properties of *authored parts*, not of any script. Nothing in
  291 scripts changes when they are missing; the consumers just iterate an empty set. A Frostbite
  playtest with no healing looks like a gameplay complaint, not a missing-content bug.
- **`workspace.WorldCards` is create-if-absent, so a stray instance of that name captures it.**
  `CardsServer:111` takes whatever `FindFirstChild("WorldCards")` returns and only builds a Folder
  when nothing is there. Redwater currently has a stray **Model** of 9 Fortuna card MeshParts sitting
  at `workspace` root, so the runtime cards are parented into that instead of a clean Folder. Do not
  reproduce it in Frostbite, and do not name anything `WorldCards` in the map.
- ~~**`Testing.BotSpawner2` is dead but still syncs.**~~ — **MOOT 2026-08-13.** The whole
  `ServerScriptService.Testing` folder is gone; the live service has 13 children and no `Testing`
  among them (§7a). Nothing to remove before the first sync. Struck rather than deleted so the
  concern is not re-derived: *anything* dead inside a synced root propagates to every future map,
  and the allowlist is by service, so a new dead folder would ride along the same way.
