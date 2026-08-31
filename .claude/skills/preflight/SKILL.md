---
name: preflight
description: Run the pre-publish gates before shipping to Roblox - verify shared-module mirrors, syntax-check changed scripts, sync vault and graphs, confirm release scope, roll the changelog, bump the version, hand over the DEV soak and manual publish checklists, record the place versions, and draft the public Discord announcement last. Pass "check" to run the read-only gates only. Use whenever the user is about to publish, or wants a health check on the mirrors.
---

# Preflight

**This skill does not publish anything.** Publishing is manual, in Studio, by the user — that is
why it is not called `/publish`. Preflight runs the gates beforehand and hands over a checklist.

Two minutes of checks here beats an evening of archaeology later. With no git repository, the
changelog is the project's only version history and the Roblox place version is the only rollback
index — both have to be correct *before* the publish, not after.

**Changelog layout:** the root `CHANGELOG.md` is an index — one table row per release. Prose lives
in `changelog/`: `UNRELEASED.md` for in-flight work, `YYYY-MM-DD-<release>.md` for shipped ones,
`CONVENTIONS.md` for the rules. Rolling a release **renames** `UNRELEASED.md` and adds a row to the
index; nothing is cut and pasted between files.

**Open items are a folder too.** `changelog/OPEN-ITEMS.md` is an index of one row per open item;
each item lives in `changelog/open-items/<id>-<slug>.md`, and closed ones move to
`open-items/archive/` with a row in `open-items/ARCHIVE.md`. Never write prose into the index.

Run the steps in order. **Steps 1, 2 and 4 are hard gates:** if any fails, stop and report.
Do not proceed because the failure looks cosmetic.

**There is one flow, for every release.** A hotfix does not get a lighter path — it gets the same
gates, because the rushed release is exactly the one that skips things. The only argument is:

> **`check`** — invoked as `/preflight check` (or any argument starting with `check`). Stop after
> Step 4 and report. This is a stopping point, not a different procedure: steps 1–4 are read-only
> apart from regenerating the graph files, so it is always safe to run. Do not roll the changelog,
> do not bump the version, do not print the publish checklist. Also the right choice any time the
> user asks for a health check rather than a release.

---

## Step 1 — Mirror check (HARD GATE)

The mirrored module set is maintained byte-identically across all three places — `/mirror` owns the
list, so this step deliberately does not restate a count that goes stale. Drift here fails *silently*:
Redwater's `EmoteConfig` once fell to 5 of 18 ids and collapsed 13 emotes to the default at
match end, with no error anywhere. `QuestConfig` later drifted to 2777 vs 3337 bytes — Redwater
missing an entire `BONUS` table and carrying stale XP values — purely because it was not on
the list. **When a new module starts being mirrored, add it to `/mirror`'s `universe` tier in the
same pass** — that skill holds the list now, so a module added here instead is a module nobody
checks.

**Run `/mirror universe`.** It owns the module list and the walk; this step owns the verdict.
Run it against **every place in the release scope** — Bounty + Redwater **+ Frostbite Claim**.
Frostbite shipped with `Update 1` and carries the full module set, so a `<MISSING>` row there is
now a real drift bug, not the empty-place state this step used to expect.

The gate is the single `TOTAL` fold. **Every place in scope must print the same one** — matching
totals mean every mirrored module agrees on byte length, content, name and class, with nothing
left to eyeball.
Any difference → **stop**, drill into the differing rows, report which module drifted, and offer
to reconcile. Only continue past a mismatch if the user explicitly overrides.

`/mirror` is also the reconcile tool, but reconciling is **not** part of preflight: fixing drift
mid-publish means publishing a build nobody has run. Stop, fix, re-run the gate.

## Step 2 — Syntax check (HARD GATE)

`loadstring` every script changed for this release. The capture is partitioned per agent session,
so read `.changelog/pending/` **and** `.changelog/consumed/` together — a pane that has already
run `/changelog` retired its file into `consumed/`, and its scripts are still going out in this
release. `.\.claude\scripts\changelog-capture.ps1` lists both with line counts.

Never rely on `require` — the plugin's require cache is stale and will report errors from a
previous version of a module.

```lua
local fn, err = loadstring(obj.Source)
print(obj.Name, fn and "SYNTAX OK" or ("FAIL: " .. tostring(err)))
```

Any failure → **stop**.

### BotConfig sanity check — Redwater only (HARD GATE)

Run this in **Redwater** immediately after the syntax pass. It catches accidental tuning edits
that would ship a match with only one hunter type — which publishes silently with no error.
Uses `loadstring` rather than `require` because the plugin's require cache is stale.

**`Enabled` and `Debug` are the two that cost the most and announce themselves the least.**
`Enabled = false` ships a deathmatch with **no bots at all** — a solo player lands in an empty
canyon, and nothing errors, because a disabled bot system is a legitimate configuration. `Debug =
true` ships whatever the debug path draws or prints to every live player and floods the server
log, which then buries the diagnostic warnings the rest of this flow depends on reading. Both get
flipped by hand while testing and are exactly the kind of edit that never makes it into a
changelog entry — the hook does not capture a value someone toggled in the Properties pane.

```lua
local src = game.ServerScriptService.Bots.BotConfig.Source
local fn, err = loadstring(src)
if not fn then print("FAIL: BotConfig parse: " .. tostring(err)) return end
local ok, cfg = pcall(fn)
if not ok then print("FAIL: BotConfig exec: " .. tostring(cfg)) return end

local ALL = {"Dust", "Fortuna", "Vesper", "Bram"}
local enabled = {}
for _, h in ipairs(cfg.EnabledHunters or {}) do enabled[h] = true end

local errs = {}

-- Identity-compared, not truthiness-compared: `Enabled = nil` is falsy and would pass a
-- `if not cfg.Enabled` test only by accident, while `Debug = "false"` (a string) is truthy
-- and would slip past a bare `if cfg.Debug`. Both must be the actual booleans.
if cfg.Enabled ~= true then
	table.insert(errs, "Enabled=" .. tostring(cfg.Enabled) .. " (" .. typeof(cfg.Enabled) .. "), expected boolean true -- bots would not spawn at all")
end
if cfg.Debug ~= false then
	table.insert(errs, "Debug=" .. tostring(cfg.Debug) .. " (" .. typeof(cfg.Debug) .. "), expected boolean false -- debug output would ship to live players")
end

for _, h in ipairs(ALL) do
	if not enabled[h] then table.insert(errs, h .. " missing from EnabledHunters") end
	local w = (cfg.HunterWeights or {})[h]
	if not w or w <= 0 then table.insert(errs, h .. " weight=" .. tostring(w)) end
end
if #(cfg.EnabledHunters or {}) ~= #ALL then
	table.insert(errs, "#EnabledHunters=" .. #(cfg.EnabledHunters or {}) .. ", expected " .. #ALL)
end
-- The three fill knobs, asserted together because they are only correct relative to each other:
-- MaxBots is DesiredRoundParticipants - 1 (a solo player's fill), and a MaxBots below that
-- silently re-shrinks the quiet games the fill exists to populate. 8/10 until 2026-08-18, when
-- the "more fighters per game" pass took the target to 14 (visitor cap 10 -> 14, matchmaking
-- ceilings to 11/12/2). Update all three here together or the gate fails on a correct config.
if cfg.DesiredRoundParticipants ~= 14 then table.insert(errs, "DesiredRoundParticipants=" .. tostring(cfg.DesiredRoundParticipants) .. ", expected 14") end
if cfg.MaxBots ~= 13 then table.insert(errs, "MaxBots=" .. tostring(cfg.MaxBots) .. ", expected 13") end
if cfg.MinBots ~= 4 then table.insert(errs, "MinBots=" .. tostring(cfg.MinBots) .. ", expected 4") end

if #errs == 0 then
	print("BotConfig OK — " .. table.concat(cfg.EnabledHunters, ", "))
	for _, h in ipairs(ALL) do print("  " .. h .. " weight=" .. tostring((cfg.HunterWeights or {})[h])) end
	print("  DesiredRoundParticipants=" .. tostring(cfg.DesiredRoundParticipants) .. "  MaxBots=" .. cfg.MaxBots .. "  MinBots=" .. cfg.MinBots)
	print("  Enabled=" .. tostring(cfg.Enabled) .. "  Debug=" .. tostring(cfg.Debug))
else
	for _, e in ipairs(errs) do print("FAIL: " .. e) end
end
```

Any `FAIL:` line, any missing hunter, any `weight=0` or `weight=nil` → **stop**.

```lua
-- RoundSystem.Config sanity check (run in Redwater)
-- loadstring inherits real globals so require(GameEnvironment) resolves normally.
-- The stale require cache is fine here: ROUND_TIME and ZONE_PHASE_DURATION are
-- hardcoded numbers that don't touch GameEnvironment at all.
local src = game.ServerScriptService.RoundSystem.Config.Source
local fn, err = loadstring(src)
if not fn then print("FAIL: Config parse: " .. tostring(err)) return end
local ok, cfg = pcall(fn)
if not ok then print("FAIL: Config exec: " .. tostring(cfg)) return end

local errs = {}
if cfg.ROUND_TIME ~= 360 then table.insert(errs, "ROUND_TIME=" .. tostring(cfg.ROUND_TIME) .. ", expected 360") end
if cfg.ZONE_PHASE_DURATION ~= 80 then table.insert(errs, "ZONE_PHASE_DURATION=" .. tostring(cfg.ZONE_PHASE_DURATION) .. ", expected 80") end

if #errs == 0 then
	print("RoundSystem.Config OK — ROUND_TIME=" .. cfg.ROUND_TIME .. "  ZONE_PHASE_DURATION=" .. cfg.ZONE_PHASE_DURATION)
else
	for _, e in ipairs(errs) do print("FAIL: " .. e) end
end
```

Any `FAIL:` line → **stop**.

### Weapon-skin contract check — both match places (HARD GATE)

Run this in **Redwater and Frostbite**. A gun skin is a fork of the whole first-person rig, so
adding one can silently rename the weapon model, drop an animation clip, or park a Folder in a
`Skins` folder — none of which errors, and all of which reach a player as a dead ultimate or a
gun that does not animate. Icefang shipped with two of those at once. Uses `loadstring` rather
than `require` because the plugin's require cache is stale.

```lua
local src = game.ReplicatedStorage.Hunters.Shared.HunterViewmodelContract.Source
local fn, err = loadstring(src)
if not fn then print("FAIL: HunterViewmodelContract parse: " .. tostring(err)) return end
local ok, mod = pcall(fn)
if not ok then print("FAIL: HunterViewmodelContract exec: " .. tostring(mod)) return end

for _, line in ipairs(mod.Report()) do print(line) end
```

Any `FAIL:` line → **stop**. A FAIL is something `Normalize` cannot repair at runtime.

`WARN` and `NOTE` are read-and-judge, not gates. **Four are standing as of 2026-08-29, all
deliberate** — if the count or the text differs from this list, a skin changed and the difference
is the thing to look at:

```
NOTE: Bram ViewmodelAnimations holds 1 clip(s) no manifest entry names (Ability)
NOTE: Fortuna Viewmodel.Skins.BackupPrestigeCard is a Folder, not a Model
NOTE: Fortuna skin 'PrestigeCard': no Weapon.WorldModel.Skins entry of the same name
NOTE: Vesper ViewmodelAnimations holds 2 clip(s) no manifest entry names (BasicShootReload, Run)
-- 7 skin viewmodels checked: 0 fail, 0 warn, 4 note
```

`BackupPrestigeCard` is knowingly kept — it is inert, because every resolver type-checks
`IsA("Model")`. `PrestigeCard`'s world twin is mapped explicitly by `CardsWorldVisualServer`'s
`TemplateResolver`. **Any WARN at all is new**, since the authored art was brought onto the
contract on 2026-08-24.

### Animation clip parity — Redwater vs Frostbite (HARD GATE)

`Audit()` above runs inside one place and cannot see the other, so it passes on a rig whose clips
are merely **stale**. A clip id that differs from the default is by design a legitimate override,
and nothing else compares property *values* across the match places — Step 1 diffs scripts, and the
asset-parity copy that seeds Frostbite compares descendant count and tree signature, neither of
which sees an `AnimationId`. Frostbite's Icefang sat on the superseded July default clips for three
weeks through that hole (fixed 2026-08-27). Run in **both** match places:

```lua
local src = game.ReplicatedStorage.Hunters.Shared.HunterViewmodelContract.Source
local fn, err = loadstring(src)
if not fn then print("FAIL: HunterViewmodelContract parse: " .. tostring(err)) return end
for _, line in ipairs(fn().ClipManifest()) do print(line) end
```

The gate is the `TOTAL` line — the **manifests**, which is what plays. As of 2026-08-29 both
places print:

```
TOTAL 40 clips, 2033 chars, sum=169085011
TOTAL-INSTANCES 620 clips, 62584 chars, sum=890517719
```

`TOTAL-INSTANCES` folds the rig `Animation` instances, which no loader has read since the clip ids
moved into the manifests. They are the Phase 1 revert path, so they still have to match across the
places — but a difference there cannot reach a live match, so it is a **read-and-judge**, not a
stop. Phase 2 deletes them and that line goes with them.

**A changed total is not itself a failure** — installing a clip legitimately moves it — but it must
move **identically in both places**. Differing totals → **stop**.

**Compare the sum, not the count.** The Icefang drift left the count at 609 in *both* places: it
moved the char figure by 1 and the sum by 3,727,187. A count-only comparison is exactly what let it
through for three weeks, and it is the tempting thing to eyeball.

On a mismatch, the per-group rows above the total name the subtree — `Dust.Weapon` read 170221126
against a drifted 170273780. Pass that group back to get one row per clip and read off the id:

```lua
local src = game.ReplicatedStorage.Hunters.Shared.HunterViewmodelContract.Source
for _, line in ipairs(loadstring(src)().ClipManifest("Dust.Weapon")) do print(line) end
```

Then make the two places agree and re-run — reconciling is not part of preflight, same as Step 1.
Bounty is not in this check: it has no `ReplicatedStorage.Hunters` folder.

## Step 3 — Vault and graph sync

Per the Vault Rules in `CLAUDE.md`, every Studio script has a matching `.md` at the mirrored
path. Verify:

- Every script created this session has a `.md` in `LocalBounty/` or `LocalRedwaterCanyon/`.
- Every deleted script has had its `.md` removed.
- Connections were updated on **both** sides of any new `require()` / RemoteEvent / BindableEvent.

Then rebuild:

```
python update_bounty_graph.py
python update_redwater_canyon_graph.py
```

Remember `[[wikilinks]]` are extracted from the **entire** file including prose — a name written
casually in a sentence becomes a real graph edge and invents a dependency that does not exist.
Verify a new script's edges landed correctly by grepping `graph.json` for its lowercased id;
every `_tgt` must map to a real code-level connection.

## Step 4 — Scope confirmation (HARD GATE)

Read every capture file — `.changelog/pending/*.jsonl` plus `.changelog/consumed/*.jsonl` — and
list every script they touched, grouped by place. Then walk the list with the user and confirm
**each entry belongs in this release**.

A release sweeps every agent's capture, so this is also where you find out that another pane is
mid-feature. If a pending file is still growing, or its session is not the user's, ask before
absorbing it: an unfinished edit from another agent is exactly the half-finished feature this gate
exists to catch, and it will not look unfinished in the log.

Then cross-check the capture against what the changelog actually says:

```
.\.claude\scripts\changelog-capture.ps1 -Coverage
```

Each `SUSPECT` is a name from the capture that appears nowhere in `changelog/UNRELEASED.md` — either
a session that never ran `/changelog`, or one that ran it and wrote too little. **Nothing else in
this flow can see the second case:** retiring a capture file is what marks it "described", and no
other gate reads the prose at all.

Treat suspects as questions, not failures. A change written in player terms — *"the Collection
menu no longer stays deaf on join"* — will not contain the word `CollectionClient`, and that is
the better entry. **Never clear a suspect by adding the script name to the prose**; that trades a
readable changelog for a green check. A genuine miss goes back through `/changelog` (or
`/changelog all`) before Step 5 rolls anything.

This is the gate that catches the thing no automated check can: a half-finished feature edit
riding along on an urgent push. The mirror and syntax gates prove the build is *consistent* and
*compiles* — neither has any opinion on whether it should be going out. An unrelated script in
this list is not automatically wrong, but it must be a deliberate answer, not a discovery made
after publishing.

If anything does not belong → **stop** and resolve it before continuing. Reverting one script now
is trivial; identifying it later from a changelog entry that never mentioned it is not.

Note that `execute_luau` mutations and instance edits made by hand in Studio are **not** captured
by the hook, so this list is a floor, not a complete inventory. Ask what else changed.

**One capture is not work at all.** A file whose *only* lines are one or two script edits on
`game.ReplicatedStorage.GameEnvironment`, one per place, is a stranded version bump from the
**previous** release — Step 6 made it after that release archived. Do not curate it and do not
count it as scope: archive it under the release it came from
(`changelog-capture.ps1 -Archive "<that release>"` after retiring it) and carry on. Step 6 now
closes its own capture, so this should only ever be a leftover from before that change.

**In `check` mode, stop here and report.**

## Step 5 — Roll the changelog

### First check whether the game has shipped at all

Read `changelog/2026-07-31-launch.md`. **If its `Published` field still reads `rTBD`, the first
public release has not happened yet.**

In that case, do **not** mint a new release. Before the first public release there is no prior
published version for anyone to diff against, so every change is simply part of the initial
release, not a change *to* it. Instead:

- Fold anything noteworthy from `changelog/UNRELEASED.md` (and from any capture no one has curated
  yet — run `/changelog all`) into the **existing Launch file**, as a description of the shipped
  game rather than a log of edits.
- Leave `changelog/UNRELEASED.md` empty of entries (keep its header block).
- Archive the captures anyway: `.\.claude\scripts\changelog-capture.ps1 -Archive "Launch"`.
- Leave `GameEnvironment.version` at `"Launch"` — **skip Step 6 entirely.**
- Then continue to Step 8. Step 7's DEV soak and Step 10's announcement are both moot before the
  first release — nothing has shipped, so there is no live build to protect and nothing to announce.

Pure polish and bugfixing on features that have never shipped needs no entry at all. Only
change the Launch entry when what the game *contains* changes.

### Otherwise, roll it normally

1. If anything is still in `.changelog/pending/`, run `/changelog all` first so nothing is lost —
   the sweep absorbs every agent's capture, not just this session's.
2. Ask the user for the release name. The scheme is in `changelog/CONVENTIONS.md`: `Update N` for
   features, `Hotfix N` for patches on top of the current release. Read the top row of the index
   table and propose the next name rather than asking cold.
3. **Rename** `changelog/UNRELEASED.md` to `changelog/YYYY-MM-DD-<release-slug>.md` — e.g.
   `changelog/2026-08-10-update-1.md`. Date first so the folder sorts chronologically; the slug is
   the release name lowercased with hyphens. Then rewrite its header:

```markdown
# Update 1 — YYYY-MM-DD

**Summary:** <one sentence — this is what the index row says>

[Index](../CHANGELOG.md) · [Conventions](CONVENTIONS.md) · Previous: [Hotfix 4](2026-08-03-hotfix-4.md)

---

- **Published:** `Bounty rTBD · Redwater rTBD · Frostbite rTBD`
- **Rollback target:** `Bounty rNNNN · Redwater rNNNN · Frostbite rNNNN` (<previous release>) — revert **all three** places.
- **Shared modules:** <which were touched> — mirror verified ✅
- **Profile schema:** vN (unchanged | bumped, one-way)
- **Data-affecting:** yes | no
```

   Keep the `## Added` / `## Changed` / `## Fixed` sections and their prose exactly as curated —
   this is a rename plus a header swap, not a rewrite. Fix the previous release file's `Next:` link
   to point at the new file.

4. Create a fresh `changelog/UNRELEASED.md` with the standard header (copy it from the file you
   just renamed) and no entries.
5. Add a row to the top of the release table in `CHANGELOG.md`, by **anchored `Edit`** — never a
   whole-file write, another agent may be reading it. Carry over the `Summary` line as the
   *What it was* cell.
6. Move anything from this release that is knowingly unfinished, deferred or still broken into
   `changelog/open-items/` — **one file per item**, taking the next free id from the top of
   `changelog/OPEN-ITEMS.md`, tagged `(raised: <release name>)`, plus one row in that index. A
   release file is history and stops being edited the moment it ships; a live concern buried in one
   is a concern nobody finds. While you are there, move any item this release **verified** into
   `open-items/archive/` and shift its row to `open-items/ARCHIVE.md` — an open list that never
   loses rows is the thing that made the old file unreadable.
7. **Do not archive the captures yet.** Archiving is the closing action of *Step 6*, after the
   version bump, because the bump is itself a captured Studio edit. Archiving here strands it —
   see Step 6.

**Step 6 edits `GameEnvironment`, which is one of the 17.** Whatever the fixes touched, the
release always touches at least that one — so the **Shared modules** field is never `none`, and
its ✅ has to come from a compare run *after* the version bump, not the Step 1 baseline.

## Step 6 — Bump the version

**Skipped in `check` mode, and in the pre-first-release case from Step 5.**

Update `GameEnvironment.version` in **all three** places to the new release name, then re-run
`/mirror universe` to confirm the three edits are identical — the `RS/GameEnvironment` row and the
`TOTAL` fold must both agree again. The bump moves the fold, so the ✅ recorded in the release entry
has to be the **post-bump** number; a fold quoted from the Step 1 baseline is already stale.

`execute_luau`'s `require` cache is stale and will report the *old* version string even after a
successful edit. Confirm with a fresh compile instead:

```lua
local m = loadstring(game.ReplicatedStorage.GameEnvironment.Source)()
print(m.version)
```

### Then close out the capture — the bump logs itself (do not skip)

The bump is two script edits on a mirrored module, so the `PostToolUse` hook records it like any
other change — into a **fresh** `.changelog/pending/<session>.jsonl`, created seconds after Step 5
swept `pending/` empty. Left there it outlives the release and surfaces at the *next* preflight as a
two-line capture naming only `GameEnvironment`: Step 2 syntax-checks it for no reason and Step 4
reports it as a `SUSPECT` from a session nobody recognises, belonging to a release that already
shipped. **This is why the archive moved out of Step 5.** It has stranded at least twice —
`.changelog/archive/Hotfix-10/1c100411-…-stranded-pending.jsonl` was renamed by hand after someone
reconstructed where it came from; Hotfix 11's was not caught at all.

So archive **here**, once the bump is verified and nothing else will touch Studio this release:

```
.\.claude\scripts\changelog-capture.ps1 -Retire
.\.claude\scripts\changelog-capture.ps1 -Archive "Update 1"
```

`-Retire` **without `-All`** claims only this session's file — the one the bump just created — and
leaves any other pane's pending work untouched. `-Archive` then moves everything in `consumed/` to
`.changelog/archive/<release>/`, bump included, so the release keeps the full evidence of what it
touched and the next one starts from an empty `pending/`. It is still the only step that empties
`consumed/`; Steps 2 and 4 read `consumed/` before it runs, so they are unaffected by the move.

Nothing after this point touches the Studio data model through a captured tool — Steps 9 and 10
write markdown, and Steps 7 and 8 are the user publishing by hand — so this is the last moment the
capture can be closed cleanly. The one thing that reopens it is a **bug found during the Step 7 DEV
soak**: fixing it is a Studio edit, so it starts a fresh capture that has to be curated and archived
under this same release name.

**Do not write a changelog entry for the bump.** It is mechanical, implied by the release name, and
the archived capture is its record. Archiving before the bump, or skipping the `-Retire`, is what
strands it.

## Step 7 — DEV soak (conditional)

**Skipped in `check` mode**, and in the pre-first-release case from Step 5.

The DEV universe (GameId `10696738139`) is a **separate experience**, so its DataStores and
MemoryStores are isolated from live for free, with no store-name suffixing anywhere. It exists for
the one class of thing Studio cannot test at all: **published-server behaviour**. Studio has no
`game.JobId`, so `MatchDirectoryService` never publishes there — reserved servers, access codes,
friend-join forwarding and real profile round-trips are all unreachable from a solo playtest.

### The live file is master

DEV is a **publish target, never a branch.** Edits happen in the live place file — the one this
session is connected to — and reach DEV only via *File > Publish to Roblox As…*. **Never edit a dev
place:** there is no merge path back, and every tool here (the MCP sessions, the capture hook,
`/mirror`, the graph scripts) is wired to the live place ids. `/mirror` scope stays at **three**
places, not six.

What this buys is the property that makes the soak worth anything: what you tested in DEV and what
you ship to live are the same file, byte for byte. Promoting the other way — editing in dev and
publishing *As* live — makes every release a Publish-As into production, one mis-click from shipping
an untested build.

**A dev twin is not a backup.** Content reaches it only on an explicit publish, so it is routinely
older than live and nothing flags the difference: checked 2026-08-14, dev Redwater still held the
vote-testing leftover `ROUND_TIME = 10` and version `Hotfix 17`. It has the features and not the
fixes. Rollback always comes from the live place's **Versions** tab, never from the dev copy.

### When to run it

Not every release. Three extra publishes and a client join on every hotfix is ceremony that gets
skipped under pressure, which is worse than not having it at all. Run the soak when the release
touches:

- teleport routing, reserved servers or access codes
- MemoryStore matchmaking / the match directory
- profile shape, or anything flagged **data-affecting**
- Robux products or receipt handling
- a mirrored module's **behaviour** — not merely its version string

Skip it for UI, FX and tuning. Same gate as the route smoke test in Step 8, and for the same reason.

### The soak

```
[ ] Publish As -> DEV Bounty            (File > Publish to Roblox As...)
[ ] Publish As -> DEV Redwater Canyon
[ ] Publish As -> DEV Frostbite Claim
[ ] All three - the mirrored modules make a half-published universe a drift bug in DEV too
[ ] Join the DEV experience from the Roblox CLIENT, not a Studio playtest
[ ] Version tag reads "<release> rN [DEV]" - the suffix is the proof you are not on live
[ ] Server log clean of "[GameEnvironment] PlaceId ... has no ENVIRONMENTS row"
[ ] Run Step 8's route smoke test here, plus whatever this release actually changed
[ ] RETARGET THE SESSIONS BACK TO LIVE - check the title bar of every Studio window
```

That `ENVIRONMENTS` warning means something worse here than on live. In DEV it means the place
resolved no row and **fell back to the live sibling ids**, so a tester teleporting out of the dev
lobby lands in a real match against real players. Stop and fix before anything else.

**`Publish to Roblox As…` re-targets the Studio session.** After the dev push the session points at
the dev place, and a plain *Publish to Roblox* then goes to DEV, not live — reporting success either
way. The version string is identical in both places, so the only things that distinguish them are
the r-number and the `[DEV]` suffix. This is the same trap as *Save to Roblox As*, which once left
Redwater's saved place armed with an unshipped `Update 1` for a day with nothing in the UI saying
so. **Check the title bar before Step 8, every time.**

**Purchases prompt cross-experience.** Developer Products are scoped to the live universe but were
verified to prompt from DEV, so a purchase test there spends **real Robux** and grants into the dev
profile. That is also the only remaining way to exercise a `ProcessReceipt` handler end to end —
Studio never charges the place owner, so a receipt path that has never seen a real purchase has
never run.

**If the soak finds a bug, you are back at Step 1.** The fix is a Studio edit, so it opens a fresh
capture and re-arms every gate: curate it, re-run Steps 1 and 2, and archive it under this same
release name. Do not patch and publish straight to live on the grounds that DEV already passed —
what DEV passed is no longer the build.

## Step 8 — Hand over the manual checklist

Publishing itself is manual — never attempt it via MCP, and never start a playtest via MCP
(`start_playtest` hangs the plugin connection). Print this for the user:

```
[ ] Title bar says LIVE, not the dev twin  (only after a Step 7 soak)
[ ] Publish Bounty                          (File > Publish to Roblox)
[ ] Publish Redwater Canyon
[ ] Publish Frostbite Claim
[ ] All three published together - never one alone
[ ] Read back the new place versions and tell me, so I can record them in the release entry
[ ] Update the game description on Creator Hub if this release changes the blurb
[ ] Join live: version tag top-right reads the new release name + version, with NO [DEV] suffix
[ ] Server log clean of "[GameEnvironment] PlaceId ... has no ENVIRONMENTS row"
[ ] Look around - the things this release changed actually work on live
[ ] Tell me it looks right, and I will draft the Discord post (Step 10)
```

That `ENVIRONMENTS` warning is the one that must not be ignored: it means a PlaceId changed, so
teleports have fallen back to hardcoded ids and analytics is silenced. **If it appears on live,
stop and fix before anything else.**

### Route smoke test

MCP cannot playtest, so this is by hand. Only needed when a release touches **teleport routing,
the economy, or bot counts** — skip it for a UI or FX change.

| # | Test | Expect |
|---|------|--------|
| 1 | Party → Play → Redwater | Lands in a match (`PartyService.DESTINATION_PLACE_ID`) |
| 2 | Leave match → lobby | Returns to Bounty (`Config.LOBBY_PLACE_ID`) |
| 3 | Join a friend already in a match | Forwards to their server (`FriendJoinService`) |
| 4 | Earn Cash in a match, check balance in lobby | Wallet awards and syncs |
| 5 | Solo match, count bots | 13 bots (14 target − 1 human, capped at `MaxBots`) |
| 6 | 11+ humans in a match | Bots never drop below 4 |

Row 6 only engages at 11+ concurrent players, so it is rarely testable on demand. The fill is
`clamp(DesiredRoundParticipants - humans, MinBots, MaxBots)`, so at 10 humans it lands on 4 on its
own and the floor only starts *binding* at 11. Both numbers move with
`DesiredRoundParticipants` — re-derive them from the gate above rather than trusting this row.

### Rollback

Creator Hub → the place → **Versions** tab → revert to the version in the release's **Published**
field. About 30 seconds. Revert **both** places, never one.

**Reverting restores code, never player data.** A release that paid out wrong currency, granted
wrong items or migrated the profile shape leaves every corrupted balance intact after a revert.
Check the release's **Data-affecting** flag before assuming a revert is sufficient.

### Shut Down All Servers — only when it actually matters

Add this line to the checklist **only** if the release fixes an **exploit** or is
**data-affecting**. Otherwise leave it out; do not offer it as an optional extra.

```
[ ] Creator Hub > Shut Down All Servers (SoftShutdown evacuates to the lobby)
```

Servers here churn on their own: players teleport Bounty → Redwater constantly, so instances
empty and retire the old build without intervention. A forced shutdown is disruption bought for
very little, and at low concurrency it buys nothing at all. The two exceptions are the cases
where old code running for another few minutes is genuinely harmful — an exploit still being
worked, or a data change where two builds writing different shapes to the same profile is the
whole problem. **Do not recommend it for a normal bugfix**, however tempting the "stale code"
argument sounds.

The DEV soak is **Step 7**, not an appendix to this one — it runs before the live publish, and its
last line is retargeting the sessions back to live. If you arrived here straight from a dev push,
check the title bar first: a plain *Publish to Roblox* from a still-retargeted session republishes
DEV and reports success.

## Step 9 — Record the place versions

When the user reports the new version numbers, write them into the release's **Published**
field, replacing `rTBD`, **in both places it appears** — `changelog/<release>.md` and the
`Published` column of the index table in `CHANGELOG.md`. This is the rollback index; an entry
without it cannot be reverted to.

**Take the numbers as given.** `game.PlaceVersion` in a Studio edit session is frozen at the
moment the file was opened and does not refresh on publish, so it is not a cross-check — offering
it as one presents a stale number as corroboration. If a reported version looks like it moved
*backwards*, that is far more likely a typo in the message than a real discrepancy: ask the user
to re-read it, and never reason from the Studio value.

Also state, in the entry itself, which versions a rollback of this release would land on — the
previous release's numbers. Under fire nobody wants to derive that from the file.

## Step 10 — Draft the public Discord post

**Skipped in `check` mode**, and in the pre-first-release case from Step 5 — nothing has shipped, so
there is nothing to announce.

**This is deliberately the last step.** The user posts the announcement only after walking the live
places and confirming the release looks right, so drafting it earlier just produces a message that
sits waiting through the part of the process most likely to send everything back to Step 1. Write it
when Step 9 has real version numbers in it and the user has said live is good — not before.

Write a player-facing announcement for the public `#changelog` Discord channel, **2000 characters
maximum**. That is Discord's hard per-message limit: a longer post does not truncate, it fails to
send. Count the characters and state the count when you present the draft.

**Derive it from the release entry — never paste the release entry.** `changelog/<release>.md` is
internal. It carries place versions, rollback targets, profile-schema notes and security fixes, none
of which go in front of players.

What goes in:

- **Never name an exploit fix.** Duplication bugs, anti-cheat changes and permission holes get the
  words *"backend improvements"* and nothing else. Naming one advertises that it existed and invites
  probing for the next.
- **No internal identifiers.** No script or module names, no place versions or PlaceIds, no remote
  or service names. *"The Collection menu now loads properly when you join"*, not *"CollectionClient
  re-requests on join"*.
- **Lead with what a player will actually notice** — new content first, then things that were
  annoying and are now fixed. Refactors, vault and graph work, and anything invisible in-game are
  left out entirely, however much of the session they took.
- **Keep the release name as the title.** It matches the in-game version tag, so a player can tell
  whether they are on the new build.

Format for Discord, not for a markdown file: `##` title, `###` section headings, `-` bullets. Tables,
HTML and nested indentation do not render. One line per bullet, bolding the thing that changed. A
couple of emoji as section markers at most — this is a changelog channel, not a hype post.

```
## Update 1

### 🆕 New
- **<feature>** — one line on what it does for the player.

### ⚙️ Improved
- **<thing>** — what is better now.

### 🐛 Fixed
- <the annoying thing, described as the player experienced it>
```

Present it in a fenced block so the user can copy it whole, with the character count underneath. Do
not write it into `changelog/` — a release file is history and this is a separate artefact; if it is
awkward to copy out of the terminal, put it in the scratchpad and give the path. **Do not post it
yourself.**
