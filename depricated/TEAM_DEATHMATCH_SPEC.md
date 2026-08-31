# Team Deathmatch — Gamemode Spec

**Status:** DESIGNED, NOT BUILT. Written 2026-08-18 for a cold session to execute.
**Owner:** unassigned.
**Places affected:** Redwater Canyon (`98517073248449`), Frostbite Claim (`134041618959520`),
Bounty (`131701626847012`).
**Every product decision below was made by the user on 2026-08-18 and is not open for
reinterpretation.** Where a decision has a consequence the user accepted explicitly, the acceptance
is recorded next to it so a later session does not "fix" it.

---

## 1. What this is

Team Deathmatch is the **second gamemode**, and the first thing that makes gamemode a real axis in
this codebase. Two teams of five, six minutes, most enemy kills wins. No firewall, no phases.

`FROSTBITE_CLAIM_SPEC.md` §1 already decided the shape this must take, and that decision stands:

> A new *map* is a new place. A new *gamemode* is **not**. Most gamemodes are meant to run on most
> maps, so gamemode is **runtime-selected code that every match place carries**, chosen at boot.

`FROSTBITE_CLAIM_SPEC.md` §9.7 deferred the whole gamemode axis with the words *"Build it with the
second gamemode, not before."* **This is that build.** When it ships, go back and mark §9.7 done.

### The one-paragraph version of the refactor

`RoundController` is 2,603 lines and every one of them assumes free-for-all. Do **not** fork it —
a second 2,603-line copy is the exact hand-maintained divergence this project has spent three specs
avoiding. Instead, extract the handful of decisions that actually differ between FFA and TDM into a
**rules module per gamemode**, and leave the round loop, the payout block, the analytics block, the
retirement policy, the late-join handling and the teleport paths exactly where they are. The
measured difference between the two modes is about **nine decisions** (§4.2), not two thousand lines.

---

## 2. Decisions (all made 2026-08-18)

| # | Question | Decision |
|---|---|---|
| 1 | How does a player reach TDM? | **Lobby gamemode picker.** `GameModeGui` already exists and already works — TDM is a third button (§11). |
| 2 | Spawning | **The team bases are the only spawns, always** — every spawn and respawn puts you at your team's base. The pads are placeholders for spawn houses being built on them, so spawns come from authored markers with a pad-surface fallback (§7, §7.1). |
| 3 | Team identity | **Team-colored outline on the rig** (Highlight, fill fully transparent) **+ team-colored kill feed and scoreboard.** No nameplate recolor, no through-wall marker (§10). |
| 4 | Friendly fire | **Nothing crosses.** No damage, no knockback, no slow, no status — and teammate bodies do **not** block bullets (§8). |
| 5 | Bot fill | Fill to **5v5**, with a floor of **1 bot per team** that holds even at 10 humans, so a full lobby is 6v6 / 12 fighters (§9). |
| 6 | Match end | **Team banner over the existing individual podium.** Podium still ranks all 10-12 fighters by kills regardless of team (§12). |
| 7 | RP | **Unchanged.** `RankedService.awardRound` keeps paying by individual placement. TDM and FFA stay on one ladder (§12.3). |
| 8 | Friend join into a full team | **Friend's team wins. 6v4 humans is allowed**, total goes to 11+. Friends are never split (§6.4). |
| 9 | Play area | **Full map, no boundary.** No firewall, no replacement boundary (§13). |
| 10 | Bounties | **Kept, unchanged.** Streaks mark and pay exactly as in FFA (§14). |
| 11 | End-of-match vote | **Map vote as today, plus a separate second ballot for mode** (§15). |
| 12 | Team assignment | **Parties seated whole first, then solos at random.** No skill or level balancing (§6). |
| 13 | Tie at the buzzer | **DRAW.** No sudden death, no tiebreaker. Podium and payouts run normally (§12.2). |

---

## 3. Current state — what already exists

Measured live 2026-08-18. Do not re-derive; do re-verify anything you are about to edit.

### 3.1 Already built and reusable

| Thing | Where | Why it matters |
|---|---|---|
| **The mode picker** | `Bounty.StarterGui.GameModeGui` + `GameModeClient` (330 lines) | A working modal with `DeathmatchButton` / `TutorialButton`, publishing a `SelectedMode` string attribute on the ScreenGui. `ReworkedUIPlay` reads it to pick which remote to fire. **TDM is a third button, not a new system.** |
| **Mode-at-boot resolution** | `MatchDirectoryService` lines ~219-330 | `State.tutorialMode` is a tri-state (nil → false/true) resolved from the reservation's MemoryStore record (`{ code = …, tutorial = true }`) with the first arrival's `TeleportData.tutorial` as backup, then mirrored to `workspace:SetAttribute("TutorialMode", …)`. **This is the exact template for gamemode resolution — copy its shape, including fail-closed.** |
| **Per-map data hole** | `ReplicatedStorage.MapConfig` | Already carries `Gamemodes = { "deathmatch" }`. Declared, read by nothing. |
| **Universe-wide map rows** | `ReplicatedStorage.MapCatalog` (mirrored) | Already carries a `gamemodes` field per row. Declared, read by nothing. |
| **Directory entry mode field precedent** | `MatchDirectoryService.writeEntry` line 347, `map = MapConfig.Id` | Including the absent-means-default rule and the comment explaining why. `mode` follows it exactly. |
| **Bot slot retirement on next death** | `BotService.Reconcile` + `_onBotDied` | **Already does precisely what the user asked for.** A player joining flags the oldest bot `Retiring = true`; it keeps fighting and leaves on its next death. It only needs a team dimension. |
| **Authored bot control** | `BotService.SpawnBot(spec)`, `SetPopulationLocked`, `Despawn` | The levers for owning a roster explicitly, built for the tutorial. |
| **Pluggable aim-assist filter** | `AimAssistController:SetCanAimAssistCheck(fn)` | The clean insertion point for "never assist onto a teammate". No changes inside the controller needed. |
| **Hitscan chokepoint** | `ReplicatedStorage.Hunters.Shared.BulletPenetration.Pierce(origin, direction, params, overrides)` | Every hitscan weapon goes through it (CLAUDE.md, Combat). The single best place to make teammates non-blocking. |
| **Party grouping server-side** | `RoundController.playerGroupData[userId]` → `.groupId`, `.members` | Already populated from `GetJoinData().TeleportData` on join, already used by the two teleport paths. **Team assignment reads this; it does not need a new channel.** |
| **Timer HUD** | `StarterGui.RoundStatusGui` — `Container` at `Position (0.5, 0, 0, 0)`, `Size (0.35, 0, 0, 58)` | The two score UIs flank this. |

### 3.2 Authored but broken — fix before anything else

**Both `TeamDeathmatch` spawn pads are `Anchored = false`, in both places.** A 30 × 1 × 37.4 stud
unanchored Part falls the moment the server starts. Anchor all four. This is Phase 0 and takes a
minute.

| Place | Part | Position | Separation |
|---|---|---|---|
| Redwater | `RedTeamSpawn` | (96.2, 1.2, −542.1) | **~437 studs** |
| Redwater | `BlueTeamSpawn` | (−36.5, 19.8, −125.2) | |
| Frostbite | `RedTeamSpawn` | (−221.7, 7.2, −53.9) | **~497 studs** |
| Frostbite | `BlueTeamSpawn` | (256.2, 24.8, 81.6) | |

**Decided 2026-08-18: the pads stay opaque, visible, collidable props.** They are the floor players
stand on, not invisible markers — so they need real surfaces and real materials, and they must never
be set `Transparency = 1`.

**They are placeholders for a building.** The user's collaborator is authoring a proper spawn house
on each pad. That has a hard consequence for the spawn logic (§7.1) and it is far easier to honour
now than to retrofit once the houses are standing.

### 3.3 Does not exist at all

- No `Teams` service usage anywhere in any place. Zero results across 299 scripts.
- Nothing reads `MapConfig.Gamemodes` or `MapCatalog.gamemodes`.
- No team concept, no team score, no friendly-fire check, no ally test.
- **No damage chokepoint.** Damage is applied at **eight** independent `Humanoid:TakeDamage` sites
  (§8.1). There is no single place to add a friendly-fire gate; one must be threaded.

### 3.4 One correction to an existing document

`FROSTBITE_CLAIM_SPEC.md` §9.0 states, in bold, *"there is no gamemode picker in Bounty and there
never was."* **That is now false** — `GameModeGui` was built for the tutorial relocation (shipped in
Hotfix 1.2). It is a real picker with a real `SelectedMode` attribute. Correct §9.0 when this ships,
and correct the claim in `CLAUDE.md`'s project blurb in the same pass. Do not delete the old text —
strike it, the way that spec strikes its own superseded sections.

---

## 4. The refactor — making gamemode an axis

This is Phase 1 and **it ships standalone with FFA behaviour byte-identical**. Nothing about TDM
lands until Phase 2. Resist the urge to combine them: if the round loop regresses, you want to know
whether it was the extraction or the new mode.

### 4.1 New modules

| Module | Where | Mirrored? | What it is |
|---|---|---|---|
| `GamemodeConfig` | `ReplicatedStorage.GamemodeConfig` | **YES — 19th universe-tier module** | The registry: one row per mode (`id`, `displayName`, `blurb`, `roundTime`, `usesZone`, `teamCount`, `targetParticipants`). Read by the match places *and* by Bounty's picker, which is exactly why it is universe tier and not per-place. |
| `Deathmatch` (rules) | `ServerScriptService.RoundSystem.Gamemodes.Deathmatch` | Match tier | FFA rules. Every function is the code lifted out of `RoundController`, unchanged. |
| `TeamDeathmatch` (rules) | `ServerScriptService.RoundSystem.Gamemodes.TeamDeathmatch` | Match tier | TDM rules. Phase 2 onward. |
| `TeamService` | `ServerScriptService.RoundSystem.TeamService` | Match tier | Team membership, assignment, score, and the authoritative `areAllies`. Inert when `teamCount == 0`. |
| `TeamAffinity` | `ReplicatedStorage.TeamAffinity` | Match tier | The **shared client+server** ally test. Tiny on purpose — it reads attributes and answers one question. The client needs it for aim assist and FX raycasts; the server needs it for damage. One implementation, two consumers. |

**Add `GamemodeConfig` to `/mirror`'s universe tier and to `CLAUDE.md`'s mirrored-module list in the
same commit you create it.** This is not optional bookkeeping. `QuestConfig` drifted to 2777 vs 3337
bytes for exactly one reason: it was created and never added to that list.

### 4.2 The rules interface

These are the **nine** decisions that differ. Everything else in `RoundController` stays put.

```lua
-- ServerScriptService.RoundSystem.Gamemodes.<Mode>
return {
    Id = "deathmatch",            -- matches GamemodeConfig row id
    TeamCount = 0,                -- 0 = FFA, 2 = TDM
    UsesZone = true,              -- false suppresses ZoneService entirely

    -- 1. Called once at boot, after mode resolves, before the round loop starts.
    Init = function(ctx) end,

    -- 2. Called at the top of each round, before players are placed.
    PrepareRound = function(ctx) end,

    -- 3. Where does this player spawn? Returns a CFrame, or nil to fall through to
    --    SpawnService's normal pool. FFA returns nil. TDM returns a point on the pad.
    ResolveSpawn = function(player) return nil end,

    -- 4. A player or bot died. This is the ONLY scoring hook.
    --    RoundController still does kill credit, XP, bounty and stats itself.
    OnDeath = function(victim, killerPlayer, killerBotId) end,

    -- 5. Who won? Returns { kind = "player"|"team"|"draw", ... }.
    GetOutcome = function() end,

    -- 6. Extra fields for the VictoryShowcase "Start" payload (the team banner).
    DecorateVictoryPayload = function(payload) end,

    -- 7. May this attacker damage this victim? The friendly-fire gate.
    CanDamage = function(attackerCharacter, victimCharacter) return true end,

    -- 8. How many bots does each side want? Returns a map of team -> count,
    --    or a single number for FFA.
    DesiredBots = function(humanCount) end,

    -- 9. Called at the loop tail, after the showcase clears.
    EndRound = function() end,
}
```

### 4.3 How mode reaches the match place

**Copy the tutorial's resolution path exactly.** It is already proven, already fails closed, and
already handles the reserved-server case, the first-arrival backup and the unresolved window.

1. **`State.gamemode`** — tri-state: `nil` until resolved, then a mode id string. Mirrored to
   `workspace:SetAttribute("Gamemode", id)` the moment it resolves, because the client needs it and
   because it is inspectable in the Explorer during a playtest.
2. **Primary source: the reservation record.** Bounty's `MatchmakingService` already writes
   `{ code = …, tutorial = true }` into `RedwaterAccessCodes_v1` for a tutorial reservation. Add
   `mode = "tdm"` to the record it writes for a TDM reservation. `MatchDirectoryService` reads it at
   boot, same call site.
3. **Backup source: `TeleportData.gamemode`** from the first arrival, exactly as
   `TeleportData.tutorial` backs up the tutorial marker today.
4. **Absent means `"deathmatch"`.** Non-negotiable, and for the reason `map` already documents at
   `writeEntry` line 343: publishing does not update running servers, so for one server generation
   the stores hold records written before this field existed. Treating absent as "unknown" takes
   matchmaking down for as long as those servers take to empty.
5. **`writeEntry` gains `mode = State.gamemode`,** next to `map`. Same absent-means-default contract,
   documented in the same comment style.
6. **`RoundController.Start` waits for `State.gamemode` to resolve** in the same spawned thread that
   already waits for `State.tutorialMode`, then requires the matching rules module once and holds it.
7. **Assert `GamemodeConfig` has a row for the resolved id, and that `MapConfig.Gamemodes` contains
   it, at boot.** Same reasoning as `FROSTBITE_CLAIM_SPEC.md` §9.2's `MapConfig.Id == catalog row id`
   assert: two files have to agree and nothing checks it.

**`tutorialMode` stays a separate flag.** Do **not** fold the tutorial into `GamemodeConfig` as a
third mode. The picker calls it a mode because that is how it reads to a player, but in the code a
tutorial server is a server that publishes no directory entry and runs `runTutorialSession()`
instead of the round loop — a different axis entirely, and one whose fail-closed publishing rule the
whole tutorial design rests on. Merging them puts a "never publish" special case inside the
gamemode registry, where the next mode will inherit it by accident.

### 4.4 Where `RoundController` changes

Keep the edits surgical and keep them findable. Each one is a call out to `rules`, and every FFA
path must produce byte-identical behaviour when `rules.Id == "deathmatch"`.

- The round-length read becomes `GamemodeConfig[mode].roundTime`. **Both modes are 360.**
  `Config.ROUND_TIME` stays as the FFA row's value; do not delete it without checking
  `MatchDirectoryService.secondsLeftFor`, which reads it to advertise time remaining.
- `ZoneService.startZone()` / `resetZone()` are gated on `rules.UsesZone` (§13).
- `getWinner` delegates to `rules.GetOutcome`.
- The `VictoryShowcase "Start"` payload passes through `rules.DecorateVictoryPayload`.
- The player-death handler and `BotService`'s bot-death handler each call `rules.OnDeath` — **after**
  the existing kill credit, bounty and `RoundStatsService.ResolveDeath` calls, not instead of them.
- `SpawnService` consults `rules.ResolveSpawn` before its own pool.

---

## 5. Phase plan

Each phase is independently verifiable. Do not skip ahead; Phase 1 in particular is the one that can
break live FFA, so it gets its own playtest.

| Phase | What | Verified by |
|---|---|---|
| **0** | Anchor the four pads. Decide visible-vs-invisible. | Explorer; run the place and confirm nothing falls. |
| **1** | The gamemode axis (§4). FFA behaviour unchanged; `GamemodeConfig` exists; mode resolves at boot; `mode` on the directory entry. **No TDM yet.** | A full FFA round plays identically. `workspace.Gamemode` reads `deathmatch`. Directory entry carries `mode`. |
| **2** | `TeamService` + `TeamAffinity`. Assignment, parties, spawns on the pads (§6, §7). | 2 humans + bots split 5/5; a party of 2 lands on one team; everyone spawns on their pad. |
| **3** | Friendly fire off, all eight sites + raycast pass-through + aim assist (§8). | Every hunter's every ability tested against a teammate. See §8.4 — this is a checklist, not a spot-check. |
| **4** | Scoring + the two score UIs (§10.1). | Kills increment the right side. Screenshot-verified at phone / tablet / ultrawide. |
| **5** | Bots on teams, 1-per-team floor, join-retires-a-bot on the right side (§9). | Join and leave repeatedly; teams stay 5/5 and the retiring bot is always on the joiner's team. |
| **6** | Match end — team banner, draw, podium (§12). | Win, lose and draw all reached. |
| **7** | Team outline + kill feed + scoreboard coloring (§10). | Screenshot at range and in a fight; skins still readable. |
| **8** | Bounty lobby: third picker button, matchmaking, teleport data (§11). | Queue from the lobby into a TDM server. Party of 4 arrives together on one team. |
| **9** | End-of-match mode vote (§15). | Vote TDM → FFA and back on the same server. |
| **10** | Mirror, vault, graph, changelog (§17). | `/mirror` clean, `/preflight check` clean. |

---

## 6. Teams

### 6.1 Representation — attributes, not the `Teams` service

Use attributes. Roblox's `Teams` service is rejected deliberately:

- It drives the **default Roblox player list**, splitting it into team sections. This game has its
  own scoreboard and its own leaderstats sync, and the stock list is not what players read.
- It auto-colors nameplates, which is **decision 3's rejected option** — the user chose a rig
  outline and explicitly did not choose nameplate recolor.
- Bots are not `Player` objects, so half the roster cannot join a `Team` anyway and the ally test
  would need a second path regardless. One path is better than one-and-a-half.

The representation:

| Attribute | On | Value |
|---|---|---|
| `Team` | the `Player` | `"red"` / `"blue"` |
| `Team` | the character `Model` | same, restamped on every `CharacterAdded` |
| `Team` | the bot rig `Model` | same |
| `Team` | the `BotService` record | same — **the record, not just the rig** |

**The record matters as much as the rig.** `BotService._spawnController` clones a brand-new
character on every respawn, so a rig-only team stamp comes back blank the first time a player kills
that bot. This is the same trap `BotHoldFire` / `BotStandDown` already document at
`BotService` item 14 — re-stamp from the record on every spawn, exactly as those two do.

**The character stamp must land before the character is parented to `workspace`,** or there is a
window where a rig exists with no team and every ally test involving it returns "enemy".

### 6.2 `TeamAffinity` — the shared ally test

```lua
-- ReplicatedStorage.TeamAffinity
-- The one answer to "are these two on the same side", asked by the friendly-fire gate on the
-- server and by aim assist / FX raycasts on the client. Attribute-driven so it needs no
-- require of anything mode-specific and works identically for players and bots.
TeamAffinity.teamOf(characterOrPlayer) -> string?    -- nil in FFA, and nil for an unstamped rig
TeamAffinity.areAllies(a, b)          -> boolean     -- FALSE when either side is nil
TeamAffinity.isTeamMode()             -> boolean     -- reads workspace:GetAttribute("Gamemode")
```

**`areAllies` returns `false` when either team is `nil`.** Fail *open* for damage, not closed. An
unstamped rig — one that streamed in oddly, or spawned in the window described above — must be
shootable. A gate that fails closed turns a stamping bug into an invulnerable player, which is far
worse than one stray friendly-fire hit and much harder to diagnose from a bug report.

### 6.3 Assignment

Runs at round start, and again for every mid-round arrival.

1. **Parties first, whole.** Read `RoundController.playerGroupData[userId].groupId`. Every member of
   a group goes to the same team. Party max is 4 (`Bounty.PartyService.MAX_PARTY_SIZE`), so a party
   always fits a team of five. Seat the largest party first, onto the team with more room.
2. **Solos fill at random** into whichever side has room, then whichever side is smaller.
3. **A mid-round arrival joins the smaller team,** unless rule 4 applies.
4. **A friend join always joins their friend's team** (§6.4), overriding rule 3.
5. **Teams persist for the whole round and reset at the top of the next one.** A player who dies
   does not get reassigned; reassignment mid-round is the thing decision 12 rejected.

### 6.4 Friend joins and the accepted imbalance

Seats 9-10 are friend-join slots that ignore the matchmaking lock (`Config.FRIEND_SLOTS = 2`), so a
friend can arrive when their friend's team already holds five humans.

**Decision 8: the friend's team wins. 6v4 humans is allowed.** "Friends always join the same team"
is absolute and beats team evenness.

The short team keeps its bots, so both sides still field at least five fighters — a 6v4 human split
is a 6v5 or 6v6 fight, not a 6v4 one. Total headcount can reach 12-13.

**This is accepted, not overlooked. Do not add a rebalancer.** The two alternatives were offered and
declined: splitting friends (breaks the rule exactly when it matters) and swapping a solo player
across mid-match (a player gets moved through no fault of their own).

### 6.5 Leavers

A leaver is **not** replaced by reassigning anyone. `BotService` fills the empty slot on that team
through the normal reconcile path, which is what it already does for FFA. Teams can end a round
uneven in humans; the bot fill keeps them even in fighters.

---

## 7. Spawning

**Decision 2: the pads are the only spawns, for the whole match.**

- `TeamDeathmatch.ResolveSpawn(player)` returns a random point on that player's pad, and
  `SpawnService` uses it instead of consulting `getSafeSpawnPool`. The existing 44 (Redwater) /
  37 (Frostbite) `SpawnPoints` are **not used at all** in TDM.
- `ResolveSpawn` picks from that team's **authored marker folder**, and falls back to scattering
  across the pad's top surface while no markers exist (§7.1). The three bullets below describe the
  fallback; the marker path gets position and facing from the marker itself.
- Apply the same **+4 stud lift** `SpawnService` and `BotService._spawnPosition` already use, on both
  paths. **Do not pivot a rig exactly onto the floor** — `project_rig_pivot_foot_offset`: `PivotTo`
  buries Bram 0.3 studs and the offset differs per hunter.
- **De-conflict simultaneous spawns.** Five players landing at round start must not stack. Assign one
  marker each (or one pad cell each on the fallback), the same way `teleportAllToRoundSpawns` shuffles
  unique spawns today. **There must be at least as many markers as a team can have fighters** — six
  under the friend-join case in §6.4, not five.
- **Face the enemy on the fallback only.** Derive the look-vector from the pad toward the other pad,
  so nobody spawns staring at a rock wall. Do not hardcode a facing, and do not apply this to a
  marker — a marker's own rotation is authored and wins.
- **Everything else in `SpawnService` stays.** The `ACImmuneUntil` stamp, the
  `SpawnProtectionService.grant` bubble, the 0.35 s `verifyTeleport` settle, the per-player ticket,
  the network-ownership repair — all of it is orthogonal to which CFrame was chosen and all of it is
  still needed. `ResolveSpawn` supplies a target; it does not replace the placement machinery.
- **`resetPlayerFireTime` becomes a no-op** in TDM because no zone runs. Leave the call; it is cheap
  and removing it would make `SpawnService` mode-aware for no benefit.

### 7.1 A house is being built on each pad — spawn from markers, not from the slab

**The pad is a placeholder.** A proper spawn house is being authored on top of each one (§3.2). A
scatter that samples the pad's flat top surface works today and **breaks the day the house lands**:
cells fall inside walls, under stairs, or on the roof, and the failure looks like a player spawning
stuck in geometry rather than like a spawn bug.

Build the spawn resolution against **authored markers from the start**, so the house changes nothing:

- Each team's spawn is a **`Folder` of marker BaseParts** inside the `TeamDeathmatch` tree —
  `TeamDeathmatch.RedTeamSpawn.Points`, or a sibling folder, whichever reads better once the house
  exists. `ResolveSpawn` picks from that folder, exactly as `SpawnService` picks from `SpawnPoints`
  in FFA. Nothing in the code ever measures the slab.
- **Fall back to the pad's surface when the folder is missing or empty.** That is what makes this
  shippable before the houses are built: today the fallback *is* the behaviour, and the day the
  markers appear the code switches over with no edit. Warn once when the fallback is taken, so a
  house that ships without markers is loud rather than silent.
- **Folder order is the part name, compared numerically** so `Point10` follows `Point9`. Explorer
  child order is not stable — `BotService.SetRoute` already learned this and documents it.
- Each marker's **rotation carries the spawn facing**, which retires the "point at the other pad"
  rule below the moment markers exist. This is the same contract the onboarding tutorial's `Stand`
  parts already use (`MapConfig.Instances.Tutorial`), so it is a pattern this codebase has shipped.
- **`MapConfig.Instances` gains the team-spawn names** (`TeamSpawnRed` / `TeamSpawnBlue` or a single
  `TeamSpawns` folder name), so a future map may call its own geometry whatever it likes and so the
  names are resolved through the one table that exists for it. Per-place, never mirrored — edit both
  match places by hand.

**Tell whoever builds the houses two things:** every spawn marker goes in the folder with its
rotation set to the direction a player should face, and the markers must sit on walkable floor with
headroom — not flush against a wall, and not on a surface the +4 stud spawn lift would push through
a ceiling.

### 7.2 Spawn camping is a known, accepted risk

Five players respawning on one known 30 × 37 pad for six minutes is the classic version of this
problem, and the user chose this option over the two alternatives that mitigate it. **Do not
unilaterally add a boundary, a spawn-picker or a camp detector.** If a playtest shows it is a real
problem, raise it as an open item with what you observed and let the user decide. Three levers exist
without writing any code: the pads' positions (§3.2), `Config.SPAWN_PROTECTION_DURATION`, and — once
the spawn houses are built — **the house interior itself**, which gives defenders cover and sightline
breaks that an open slab cannot. Reassess camping after the houses land, not before.

---

## 8. Friendly fire — nothing crosses

**Decision 4.** This is the largest and most error-prone phase, because there is no chokepoint.

### 8.1 The eight damage sites

Every one of these calls `Humanoid:TakeDamage` directly. All eight need the gate.

| # | Script | Line(s) | Hunter |
|---|---|---|---|
| 1 | `ReplicatedStorage.Revolver.Modules.RevolverServer.RevolverDamageService` | — | Dust (revolver — **the default weapon everyone carries**) |
| 2 | `ReplicatedStorage.Revolver.Modules.HighNoonDamage` | — | Dust ultimate |
| 3 | `ServerScriptService.Hunters.FortunaServer.CardsServer` | 241 | Fortuna |
| 4 | `ServerScriptService.Hunters.VesperServer.SunspikeDamageService` | 74 | Vesper |
| 5 | `ServerScriptService.Hunters.VesperServer.StarfallSightModule` | 135 | Vesper ultimate (ring damage) |
| 6 | `ServerScriptService.Hunters.BramServer.GrudgekeeperDamageService` | 76 | Bram |
| 7 | `ServerScriptService.Hunters.BramServer.GrudgekeeperModule` | 172 | Bram (breach charge / shrapnel shell) |
| 8 | `ServerScriptService.Bots.BotCombat` | 358, 628, 643 | every bot |

`ServerScriptService.RoundSystem.ZoneService` (251, 255, 298) is a ninth site and is **out of
scope** — the zone never runs in TDM (§13). Do not gate it; do not delete it.

**Line numbers are from 2026-08-18 and will drift.** Re-grep `:TakeDamage(` across the place before
you start and reconcile the count. If you find a ninth combat site, something shipped since this was
written and it needs the gate too.

### 8.2 Where the gate goes

At each site, immediately before `TakeDamage`, and **after** the existing spawn-protection and
`LastCall` checks so the ordering comments already at those sites stay true:

```lua
if not rules.CanDamage(attackerCharacter, victimCharacter) then return end
```

For TDM, `CanDamage` is `not TeamAffinity.areAllies(a, b)`. For FFA it is `return true`, so the FFA
path pays one function call and changes nothing.

**Return, do not deal zero.** Zero damage still fires hit markers, hit sounds, damage-direction
indicators, health-bar reveals and ultimate charge through `HunterHitPipeline`. A refused hit must
be refused before any of that.

### 8.3 The four things that are not `TakeDamage`

Decision 4 is "nothing crosses", which is broader than damage.

1. **Bullets pass through teammates.** Add an allies-are-transparent rule inside
   `BulletPenetration.Pierce` — it is the single hitscan chokepoint and the shooter is already known
   there. **A teammate must not count as a penetration layer**, or shooting past an ally would apply
   the 50% wall falloff (`project_bullet_penetration`). Skip them entirely; do not pierce them.
2. **Client FX must mirror the server filter exactly.** `project_visual_raycast_parity` is explicit
   about this and there are 18+ `RaycastParams` construction sites. The client-side projectile sims
   and impact FX must use the same ally-skip, or tracers visibly stop in a teammate's chest while the
   server's shot carries on to the enemy behind them.
3. **Status effects and knockback.** `ReplicatedStorage.Hunters.Shared.HunterStatusEffects` is where
   slows and similar land — gate application there. Bram's charge knockback and Vesper's slow are the
   two known cases; sweep the four hunters' server folders for anything that writes to a victim it
   did not damage.
4. **Aim assist and mobile auto-fire must never target a teammate.** Use
   `AimAssistController:SetCanAimAssistCheck(fn)` — the hook already exists, so this is one predicate,
   not a controller change. `project_mobile_auto_fire` warns that auto-fire keys off `GetLock()` and
   never off a raycast, so fixing the lock predicate fixes auto-fire for free. Do this or mobile
   players will be *steered onto* their own teammates.

### 8.4 Phase 3 verification checklist

Not a spot-check. Every row, against a teammate, in a live playtest:

- [ ] Dust revolver body shot / headshot
- [ ] Dust High Noon ultimate
- [ ] Fortuna cards
- [ ] Fortuna dash (contact damage, if any)
- [ ] Vesper Sunspike
- [ ] Vesper Starfall ultimate ring
- [ ] Bram Grudgekeeper
- [ ] Bram breach charge / shrapnel shell
- [ ] Bram charge — **no knockback on a teammate**
- [ ] Any slow / status from any hunter
- [ ] Shooting *through* a teammate hits the enemy behind them, at full damage
- [ ] Client tracer and impact FX agree with the server on all of the above
- [ ] Mobile aim assist refuses to lock a teammate; auto-fire does not fire at one
- [ ] Bots do not damage bots or players on their own team
- [ ] **An unstamped rig is still damageable** (§6.2, fail-open)

---

## 9. Bots

`BotService.Reconcile` already retires a bot on its next death when a player joins. It needs a team
dimension and a new target function; the retirement mechanic itself is untouched.

### 9.1 Counts

**Decision 5.** Target 5 per side. Floor of **1 bot per team**, held even at a full human lobby.

| Humans | Split | Bots | Fighters |
|---|---|---|---|
| 0 | 0/0 | 5 + 5 | 10 |
| 1 | 1/0 | 4 + 5 | 10 |
| 4 | 2/2 | 3 + 3 | 10 |
| 8 | 4/4 | 1 + 1 | 10 |
| **10** | 5/5 | **1 + 1** | **12** |
| 11 (friend join, §6.4) | 6/5 | 1 + 1 | 13 |

`TeamDeathmatch.DesiredBots(humanCount)` returns `{ red = n, blue = m }` where each is
`max(1, 5 - humansOnThatTeam)`. **This overrides `BotConfig.MinBots` entirely in TDM** — the
per-team floor replaces the global one. `BotConfig.MinBots` and `DesiredRoundParticipants` keep
their current values and keep governing FFA; do not retune them.

The floor exists for the same reason `MinBots` does and the reason is worth keeping in the code
comment: the bots are deliberately weak, and a new player on a phone should always have something
they can reliably kill.

### 9.2 Team-aware retirement

The user's rule, restated: *when a player joins, a bot on the team that player joined is retired on
its next death.*

`Reconcile` already implements retire-on-next-death. The changes are:

- Count and target **per team**, not globally.
- The surplus pass picks its retiree **from the over-target team only**.
- The under-target pass un-retires **from the under-target team only**, newest flag first.
- `_chooseHunter`'s `HunterCaps` counting — decide whether caps are per-team or per-arena. **Per
  arena** keeps the existing behaviour and the existing numbers; per-team would silently double
  every cap. Take per-arena unless a playtest argues otherwise, and say so in the comment.
- `_spawnController` re-stamps `Team` from the record alongside `BotHoldFire` / `BotStandDown`
  (§6.1).
- `_spawnPosition` calls `rules.ResolveSpawn` for the bot's team pad instead of sampling
  `getSafeSpawnPool`.

### 9.3 Bot targeting

`BotBrain`'s target pool must drop allies. There is already a precedent for exactly this shape:
`BotTargetPlayersOnly` (added 2026-08-09 for the tutorial) drops other bots from the pool via a rig
attribute. Team filtering is the same mechanism with a different predicate — reuse the shape, and
route it through `TeamAffinity` so there is still only one ally test in the codebase.

**`project_fix_every_implementation` applies with full force here.** Bots reimplement services
rather than calling them (`project_bram_bot_abilities`). For every friendly-fire gate you add to a
hunter's server module, ask whether `BotCombat` has its own copy of that damage path — for three
sites it does.

---

## 10. UI

Read `UI_STYLE_GUIDE.md` before touching any of this. Screenshot-verify per
`feedback_ui_screenshot_verify` and `feedback_responsive_breakpoints`.

### 10.1 The two team score readouts

**One on each side of the match timer** (user's words).

- Author them as **children of `StarterGui.RoundStatusGui`**, siblings of `Container` — not as a new
  ScreenGui. Two ScreenGuis cannot be kept in alignment through inset changes and device rotation,
  and `project_lobby_screen_insets` plus `project_absoluteposition_topbar_shift` are both about
  exactly this class of drift. One ScreenGui, one inset behaviour.
- `Container` is `Position (0.5, 0, 0, 0)`, `Size (0.35, 0, 0, 58)`. **Read its live `AnchorPoint`
  before positioning anything** — it was not in the property dump and the layout depends on it.
- **In TDM the container is effectively 45px, not 58.** `ZoneLabel` is the phase timer and there are
  no phases, so it is hidden and the negative-9px `UIListLayout` padding no longer applies. Do not
  vertically center the score chips against 58.
- Red left, blue right, or match the pads' geography if that reads better. Colors come from the pads
  (`Crimson` / `Navy blue`) adjusted to the style guide's palette — a navy that dark will not pass
  contrast against the HUD.
- Both hidden entirely in FFA. Gate on `workspace:GetAttribute("Gamemode")`, and **register them in
  `RoundClientController`'s `SWEEP_EXEMPT_GUI_NAMES` or verify the round sweep cannot force them
  visible** — `project_round_sweep_settings_trap` is that the sweep's default for an unknown GUI is
  *visible*, which is how `MapVoteGui` nearly shipped rendering during matches.
- Mobile: `RoundStatusClient` fades its labels to `TextTransparency = 0.3` on touch. Match it, or the
  new chips will be the brightest thing on a phone screen.
- **`AutomaticSize` will not do what you want here** (`feedback_automaticsize_defeats_textwrapped`).
  Reserve a fixed two-digit width; a score chip that resizes as the score climbs jitters the whole
  top bar.

### 10.2 Team identity on the rig

**Decision 3: a colored outline only.** A `Highlight` with `FillTransparency = 1` and
`OutlineColor` set to the team color. The skin's own colors survive intact — this was chosen
specifically so purchased cosmetics stay visible.

Two collisions to resolve, both real:

1. **`BountyService` already puts a `Highlight` on bounty targets** and bounties are kept (§14). Two
   `Highlight` instances on one rig do not blend; one wins. Decide the precedence explicitly and
   comment it — **bounty should win**, because it is the transient, high-information state and the
   team outline is ambient. Restore the team outline when the bounty clears.
2. **Transparencies multiply** (`project_ultimate_ready_fx`). The ultimate-ready glow, the
   spawn-protection ForceField and this outline all stack on the same rig. Check the combination on
   mobile specifically — that memory records the mobile path needing a mask rather than a ZIndex fix.

Add the outline in one place — wherever `SkinService.loadCharacter` finishes — not per hunter.

### 10.3 Kill feed and scoreboard

- `KillFeedClient` colors each entry's names by the team of the killer and the victim, read from
  `TeamAffinity`. The remote payload needs the two teams added; do not have the client infer them
  from a character that may have already been destroyed.
- The TAB scoreboard (`RoundStatsService` → the stats panel) colors each row by team. It stays a
  **single kill-ranked list**, not two columns — decision 6 keeps the leaderboard individual.
- `project_killfeed_weapon_icons`: the icon lookup is an exact-name key with a silent Revolver
  fallback. Nothing here changes weapons, but if you touch that payload, do not disturb the key.

---

## 11. Bounty (lobby) changes

### 11.1 The picker

`GameModeGui.Scrim.Dialog` currently holds two buttons. Add `TeamDeathmatchButton`.

- `GameModeClient` hardcodes its two-entry `BUTTONS` and `READOUT` tables — extend both. Better:
  drive them off `GamemodeConfig` so a fourth mode is data, with `tutorial` kept as the one
  hand-written non-`GamemodeConfig` entry (§4.3).
- `Dialog` carries a `UIAspectRatioConstraint` and a `UISizeConstraint` sized for two buttons. A
  third needs the dialog re-proportioned. `project_uiaspectratio_geometry`: `FitWithinMaxSize`
  clamps both axes, so this will not simply grow.
- **The 3D sign readout already handles this.** `GameModeClient` lines 69-125: DEATHMATCH is 3D mesh
  letters, and any other mode hides them with `LocalTransparencyModifier` and enables a `SurfaceGui`
  on the same plates. TDM takes the SurfaceGui path automatically — **no new mesh letters, and none
  are possible** (the letter set has no U, O, R, I or L). Check that "TEAM DEATHMATCH" fits
  `ModeTitle`; `feedback_device_only_text_metrics` says never script-sync the label, mirror
  `TextScaled` instead.
- Selection stays **session-only, never persisted** — `GameModeClient` line 310 explains why for
  tutorial and the same argument holds for TDM, though more weakly. Keep the existing behaviour: every
  join starts on DEATHMATCH.

### 11.2 Matchmaking

- `ReworkedUIPlay` passes the selected mode to whichever remote it fires.
- `MatchmakingService` filters candidate servers on `entry.mode`, **treating absent as
  `"deathmatch"`** (§4.3 item 4).
- `reserveFreshServer` writes `mode` into the access-code record so the new server can resolve
  itself at boot.
- `chooseDestination` already returns `(…, placeId, mapId)` after the Frostbite work; it gains
  `modeId` alongside. `PartyService`'s destination handling follows it, exactly as it had to follow
  `mapId`.
- **This splits the matchmaking pool in two.** Accepted as the cost of decision 1 — a picker that
  cannot actually route you to your pick is not a picker. Watch server fill rates after launch; if
  TDM servers seed empty and stay empty, that is an open item and a product decision, not a bug.

### 11.3 Friend and follow joins

`FriendJoinService` and `FollowJoinService` route by place and access code and do not care about
mode — a friend join lands you in your friend's server whatever it is running. **No filtering.** The
one thing to confirm is that the arrival path resolves the server's mode from the server rather than
from the joiner's own `SelectedMode`, or a player who had DEATHMATCH selected in the lobby would
arrive at a TDM match believing it is FFA. The server is authoritative; the attribute is advisory —
`GameModeClient` line 10 already says so.

---

## 12. Match end

### 12.1 Winner and banner

**Decision 6.** `GetOutcome` returns the winning team and both scores.
`DecorateVictoryPayload` adds them to the existing `VictoryShowcase "Start"` payload, and
`VictoryShowcaseClient` renders a banner above the podium — `RED TEAM WINS 47-41`.

**The podium itself does not change.** It still ranks every fighter by kills across both teams, with
the existing sort (kills desc → real player before bot → deaths asc). A player who topped the server
on the losing team still stands on it. The banner carries the team result; the podium carries the
individual one.

### 12.2 Draws

**Decision 13.** Equal kills at the buzzer is a `DRAW`. Banner reads DRAW, podium runs normally,
`flushPendingRewards` / `awardRoundCompletion` / `DailyRewardService.registerPlay` /
`RankedService.awardRound` all run exactly as they do for a win. No extra time, no tiebreaker, no
new round-loop state.

`GetOutcome` returning `{ kind = "draw" }` must be handled in `VictoryShowcaseClient` — do not let it
fall through to the "X wins" string with an empty name.

### 12.3 Rewards and RP

**Decision 7: nothing changes.** `RankedService.awardRound` pays by individual placement across all
fighters. No win bonus, no team-driven RP. TDM and FFA stay comparable on one ladder.

Everything else in the round-end block — the XP/Cash flush, round completion, daily play credit,
quests, battle-pass XP, the `MatchEnd` telemetry and the `NewPlayer` funnel step 7 — is untouched and
**must stay untouched**. If you find yourself editing the payout loop, you have gone past the scope
of this spec.

### 12.4 Analytics

Add `mode` as a dimension to `MatchStart` / `MatchEnd` so the two gamemodes can be told apart in the
existing charts. **Do not add new events** — `RoundController` item 20 records that logging from
combat paths tripped the AnalyticsService event cap once already. A dimension on an event that
already fires is free; a new event is not.

---

## 13. No zone, no phases

`rules.UsesZone = false` for TDM. `ZoneService.startZone()` is never called and `resetZone()` runs
at round start for cleanliness.

Consequences to handle, each of which is a place something assumes the zone exists:

- **`ZoneService.getSafeClearance`** is consulted by `SpawnService.getSafeSpawnPool`, which TDM does
  not use (§7). No change needed, but do not delete the call path.
- **`BotPathing.GetFirewallEscapePosition`** and `BotConfig.FirewallAvoidanceMargin` must no-op
  rather than reading a zone that never started. A bot pathing away from a firewall at infinity is
  a bot walking off the map.
- **`ZonePhaseName` / `ZonePhaseTimeLeft` / `ZonePhase`** workspace attributes stay at 0/empty, which
  `RoundStatusClient` already reads as "hide the zone label" and "do not announce a phase". Verify
  rather than assume — the announcer seeds a baseline on first call and only fires on forward
  transitions into phase 2+, so it should stay silent naturally.
- **`ZoneAtmosphere`** must not render fire walls. Check it gates on the zone being active.
- **`KilledByZone`** is never set, so the `_creditPlayerKill` skip for zone deaths is simply never
  taken. No change.
- **The full map is live for six minutes** (decision 9). Redwater's canyon normally squeezes to 25%.
  The pads are 437 / 497 studs apart, which is the only pacing lever, and moving them is the
  intended tuning method. Expect the first playtest to be about this.

---

## 14. Bounties stay

**Decision 10: unchanged.** `BountyService` keeps marking streaks and paying out, for players and
bots, in TDM exactly as in FFA. No per-team visibility, no changes to the payout.

The one interaction to resolve is the `Highlight` collision in §10.2. Bounty wins.

A teammate cannot claim your bounty simply because they cannot damage you — no extra rule needed.

---

## 15. The end-of-match mode vote

**Decision 11: the map vote stays exactly as it is, and a separate mode ballot is added.**

`FROSTBITE_CLAIM_SPEC.md` §9.3/§9.4 built the map vote and `RoundController.runMapVoteDuringSummary`
already rides the summary window. The mode ballot is a second, sequential ballot.

- Reuse `MapVoteClient` / `MapVoteGui`'s machinery — it was already generalised to N tiles from a
  hidden `TileTemplate` (§9.6 item 5), so a two-tile mode ballot needs no new tile authoring.
- **Same tie rule: a tie keeps the current mode.** Staying is free; moving is not.
- **A mode change is a server-local reconfigure, not a teleport.** This is the crucial difference
  from a map change. Map = place, so a map change teleports (§9.4). Mode is runtime-selected code the
  server already carries, so a mode change just picks a different rules module at the top of the next
  round. **Do not route it through `moveToMap`.**
- If a mode change and a map change both win, the map teleport carries the new mode in its
  `TeleportData` and in the access-code record. The destination server resolves it at boot like any
  other arrival.
- **The summary window is already tight.** `POST_GAME_VICTORY_TIME` is a sum of named parts
  (`4.1 + 2.4 + 10 + 0.5 = 17.0`) and `runMapVoteDuringSummary` yields the whole window on every path
  including the no-vote one. Adding a second ballot means re-budgeting that sum, not stealing from the
  map vote's `MAP_VOTE_TIME = 10`.
- The tutorial server never votes (`FROSTBITE_CLAIM_SPEC.md` §9.5) and that stays true.

---

## 16. Things that will bite

1. **Someone will fork `RoundController`.** 2,603 lines is intimidating and copying it feels faster
   for an afternoon. It is the single worst outcome available here. Nine hooks (§4.2).
2. **The friendly-fire gate will be added to seven of the eight sites.** The revolver is the one
   everybody remembers and Bram's `GrudgekeeperModule` (as distinct from its `DamageService`) is the
   one everybody misses — they are two different scripts with two different `TakeDamage` calls.
3. **Bots will be forgotten.** `BotCombat` has three `TakeDamage` calls and reimplements hunter
   abilities rather than calling them. `feedback_fix_every_implementation`: always ask "is there a
   bot version?"
4. **Client raycast parity will be forgotten.** The server will correctly shoot past a teammate while
   the client's tracer stops dead in their chest, and it will be reported as "shots not registering".
   `project_visual_raycast_parity`.
5. **Mobile aim assist will steer players onto teammates.** One predicate through
   `SetCanAimAssistCheck`, and it also fixes auto-fire because auto-fire reads `GetLock()`.
6. **The team stamp will race the character.** Stamp before parenting to `workspace`, and re-stamp
   bots from the record on every respawn (§6.1).
7. **`GamemodeConfig` will drift.** It is universe tier and must be in `/mirror` and in `CLAUDE.md`'s
   list from the day it is created. This is how `QuestConfig` went to 2777 vs 3337 bytes.
8. **Frostbite will be forgotten.** Everything in the match tier goes into **both** match places,
   byte-identical. Both places publish together, always — a half-published experience is a live drift
   bug.
9. **The pads will fall.** They are unanchored right now (§3.2).
9a. **Spawns will be written against the pad slab**, because that is what exists on the day someone
    builds this, and it works perfectly until the spawn houses land — at which point players spawn
    inside walls and on roofs. Write the marker-folder path *and* the fallback together (§7.1);
    writing the fallback alone is the trap.
10. **The round sweep will resurrect the score UIs in FFA.** Its default for an unknown GUI is
    visible. `project_round_sweep_settings_trap`.
11. **`Highlight` collision with bounties** will look like the team outline randomly vanishing
    (§10.2). It is not random; it is the bounty highlight winning.
12. **`FROSTBITE_CLAIM_SPEC.md` §9.0 and `CLAUDE.md` both currently claim there is no gamemode
    picker.** Both are wrong (§3.4) and one of them will be used as evidence that the picker needs
    building from scratch.

---

## 17. Obligations before publish

- **Mirror.** `GamemodeConfig` → universe tier, all three places. `Gamemodes/`, `TeamService`,
  `TeamAffinity` and every edited match-tier script → both match places, byte-identical. Run
  `/mirror` and add `GamemodeConfig` to `CLAUDE.md`'s mirrored list and to the skill's universe tier.
- **`MapConfig.Gamemodes`** gains `"tdm"` in **both** match places. It is per-place and never
  mirrored — edit both by hand.
- **`MapCatalog.gamemodes`** gains `"tdm"` on both rows. It **is** mirrored — edit all three copies.
- **Vault.** A `.md` per new script in `LocalRedwaterCanyon/` (and the Frostbite mirror follows
  whatever convention that place's vault uses). Update the Connections and Dependencies sections on
  every script you touch — `RoundController`, `SpawnService`, `BotService`, `MatchDirectoryService`,
  `RoundStatusClient`, `KillFeedClient`, and Bounty's `GameModeClient`, `ReworkedUIPlay`,
  `MatchmakingService`.
- **Wikilink discipline.** `[[Links]]` only for real `require()` / Remote / Bindable / tag edges.
  `Required by:` is **plain text**. Prose comparisons are plain text. Then verify against the graph,
  because the graph is the only proof:
  `Grep "\"_src\": \"teamservice\"" graphs/RedwaterCanyonGraph/graph.json -A 1`
- **Graphs.** `python update_redwater_canyon_graph.py` and `python update_bounty_graph.py` — bare
  commands, one per tool call, both issued in one message so they run in parallel. Watch the
  `Extracted N nodes, M edges` line, not `Done:`. A node-count drop needs `--force`
  (`reference_graph_script_force_flag`).
- **Changelog.** `/changelog` for this session's capture. Mark it **data-affecting** if anything
  touches Wallet reasons, the XP curve or RP awards — as specced it does not, and if it starts to,
  that is a scope change worth surfacing.
- **`/preflight`** before publishing, not after. Both places publish together.
- **Open items** for anything left `FIXED (unverified)` — one file per item in
  `changelog/open-items/`, one row in `OPEN-ITEMS.md`.

---

## 18. Open questions

Genuinely undecided. Raise these with the user rather than choosing.

1. ~~**Do the pads stay visible?**~~ **RESOLVED 2026-08-18 — yes, opaque props.** A spawn house is
   being built on each pad by the user's collaborator, which is why §7.1 spawns from authored markers
   with a pad-surface fallback rather than measuring the slab.
2. **Per-team or per-arena `HunterCaps`?** (§9.2) Per-arena is the conservative default and this spec
   takes it, but a 5-stack of one hunter on one side is possible under it.
3. **`Config.SPAWN_PROTECTION_DURATION` in TDM.** Pad spawning concentrates arrivals in one known
   place, which argues for longer. Left at the FFA value until a playtest says otherwise (§7.1).
4. **Mode-ballot timing budget.** §15 says re-budget `POST_GAME_VICTORY_TIME` rather than stealing
   from the map vote, but does not pick the number. Pick it with a stopwatch on a real summary.
5. **What happens to a TDM server that empties to one human?** FFA is fine with this — `MIN_PLAYERS`
   is 1 and bots fill the arena. TDM technically works too (1v0 humans, bots either side), but "your
   team" of four bots against five bots may read as pointless. No decision needed to ship; worth
   watching.
