---
name: preflight
description: Run the pre-publish gates before shipping to Roblox - verify shared-module mirrors, syntax-check changed scripts, sync vault and graphs, confirm release scope, roll the changelog, bump the version, hand over the DEV soak and manual publish checklists, record the place versions, cut the GitHub release, and draft the public Discord announcement last. Pass "check" to run the read-only gates only. Use whenever the user is about to publish, or wants a health check on the mirrors.
---

# Preflight

**This skill does not publish anything.** Publishing is manual, in Studio, by the user — that is why
it is not called `/publish`. Preflight runs the gates beforehand and hands over a checklist. The
changelog is the game's only version history and the Roblox place version its only rollback index,
so both have to be right *before* the publish.

**One flow for every release.** A hotfix gets the same gates, because the rushed release is the one
that skips things. The only argument is **`check`** (any argument starting with `check`): stop after
Step 4 and report. Steps 1–4 are read-only apart from regenerating the graph files, so `check` is
always safe, and it is the right choice for a health check rather than a release.

**Steps 1 and 4 are hard gates.** On a failure, stop and report — never continue because it looks
cosmetic, only on the user's explicit override. Reconciling is not part of preflight either: fixing
drift mid-publish ships a build nobody has run. Stop, fix, re-run.

**Work fast — the cost here is what you write, not the tools.** Every tool call in this flow returns in
about a second; the Hotfix 3.2 run spent its ten minutes generating retyped Luau and waiting on one
call at a time. So: **never paste gate Luau** (it lives in Studio, one line runs it), **batch every
independent call into one message**, and **never Read raw capture files** (`-Coverage` prints the scope).

**Changelog layout:** `CHANGELOG.md` is an index, one row per release. Prose lives in `changelog/`:
`UNRELEASED.md` in flight, `YYYY-MM-DD-<release>.md` shipped, `CONVENTIONS.md` for naming and the
metadata fields. **Issues** live on the [project board](https://github.com/users/Rasmus-Bondo/projects/1)
(`/issues`), never in `changelog/`.

---

## Step 0 — Connect

`get_connected_instances`. **All three places must be connected** — Bounty, Redwater Canyon, Frostbite
Claim — because a one-sided run proves nothing and reads like a pass. Missing one → stop and ask the
user to open it. Pass each `id` verbatim as `instance_id` below.

## Steps 1–3 — one message, six calls in parallel

| Call | What it covers |
|---|---|
| `execute_luau` in **each** place: `loadstring(game.ServerStorage.PreflightGates.Source)().run(print)` | Step 1 universe mirror · Step 2 syntax of every script · BotConfig · RoundSystem.Config · weapon-skin contract · clip parity · current version line |
| `.\.claude\scripts\changelog-capture.ps1 -Coverage` | Step 4's scope list |
| `python update_bounty_graph.py` | Step 3 |
| `python update_redwater_canyon_graph.py` | Step 3 |

**Pass `print` exactly as shown.** `execute_luau` captures only its own chunk's `print`; without the
argument the gates run, print into Studio's Output window, and the tool returns nothing. **Never
`require` the module** either — the plugin's require cache is stale and reports old code.

If `run()` fails because `ServerStorage.PreflightGates` does not exist, install it — never retype it:
`import_rbxm` with `source.path` = `C:\Users\2000b\Documents\bulletsandbounty\.claude\skills\preflight\PreflightGates.rbxm`
and `parent_path` = `game.ServerStorage`, then re-run.

### Step 1 — Read the gate output (HARD GATE)

Each place prints one block and ends with:

```
VERDICT PASS | JUDGE | FAIL  -- reasons
COMPARE universe=<fold> clips=<sum | n/a> gates=<hash>
```

It passes when all of these hold:

1. **No `FAIL`.** A `JUDGE` means the contract printed `NEW:` lines — read them (below) before passing it.
2. **`universe=` and `gates=` are identical in all three places; `clips=` is identical in Redwater and
   Frostbite.** Nothing in one place can see another, so this comparison is yours and it is the whole
   cross-place gate. Compare the full strings, never a count.
3. **`role=`** reads `lobby` for Bounty and `match` for the other two. A match place printing `lobby`
   lost its `Hunters` folder and silently skipped its match gates.

`run()` already FAILs on anything it can judge alone: an unresolved universe root, a script that does
not compile, a BotConfig or RoundSystem.Config value off its expected value, a contract `FAIL`, a
missing clip total or version line. **The expected values and the list of accepted contract lines
live at the top of `PreflightGates.luau`, each with its reason** — read them there, not here.

**On a mismatch, drill in** — still one line per place:

| Differs | Run | Then |
|---|---|---|
| `universe=` | `…().mirror("universe", "", print)` | The row whose fold differs names the module. Offer `/mirror` to reconcile. |
| `clips=` | `…().clips(nil, print)` for the per-group sums, then `…().clips("Dust.Weapon", print)` | One row per clip; read off the id. |
| `gates=` | — | A place holds a stale copy of the gate module. Reinstall all three (below). |

`CLIPS-INSTANCES` differing is **read-and-judge**, not a stop: those rig `Animation` instances are read
by no loader since 2026-08-29 and only matter as the Phase 1 revert path.

**`NEW:` lines** are contract WARN/NOTE lines the module does not list as standing. A real problem →
stop. Deliberate → add it to `STANDING` in `PreflightGates.luau` with its reason, reinstall, re-run.
**Never edit an expected value to get past a failing gate**; change it only for a deliberate tuning
change, in the same pass as the tuning.

### Step 2 — Syntax

Covered by `run()`'s `SYNTAX` line: every script in the place compiles through `loadstring`, which is a
superset of the changed ones and also catches `execute_luau` and hand edits the capture never saw.

### Step 3 — Vault and graph sync

The graphs rebuilt in the batch. Check the vault against the scope list: every script created this
release has a `.md` at its mirrored path, every deleted one lost its `.md`, and connections are
updated on **both** sides. If you fix a vault file, re-run both update scripts. Verify a new script's
edges by grepping `graph.json` for its lowercased id — every `_tgt` must be a real code-level
connection (`CLAUDE.md`, Vault Rules).

## Step 4 — Scope confirmation (HARD GATE)

`-Coverage` already printed the scope: every capture file (pending and consumed, owner, age) and then
every touched script and instance subtree **grouped by place**, each marked `SUSPECT` or `named`. Walk
it with the user and confirm **each entry belongs in this release**. This is the gate no automated check
can replace — a half-finished feature riding along on an urgent push compiles and mirrors fine.

- **A file tagged `possibly still in progress`, or from a session that is not the user's** — ask before
  absorbing it. Another pane's unfinished edit does not look unfinished in the log.
- **`SUSPECT`** = the name appears nowhere in `UNRELEASED.md`. A question, not a failure: prose written
  in player terms often never names the script, and that is the better entry. **Never clear a suspect
  by adding the script name to the prose.** A genuine miss goes back through `/changelog` (or
  `/changelog all`) before Step 5.
- **A file tagged `version bump only`** is a stranded bump from the previous release, not scope. Do not
  curate it: retire it and archive it under the release it came from
  (`-Retire`, then `-Archive "<that release>"`).
- **A place group named `instance:xxx` or `(default)`** is a Studio process the hook never saw named;
  match the id against Step 0's output.
- **The list is a floor.** `execute_luau` mutations and hand edits in Studio are never captured. Ask what
  else changed.

Anything that does not belong → **stop** and resolve it. **In `check` mode, stop here and report.**

## Step 5 — Roll the changelog

1. `-Coverage` showed anything still in `pending/` → run `/changelog all` first.
2. Propose the next release name from the top index row (`Update N` for features, `Hotfix N.M` for
   patches — `CONVENTIONS.md`) and ask.
3. `.\.claude\scripts\changelog-capture.ps1 -Roll "<release name>"`. It renames `UNRELEASED.md` to the
   dated file, writes the header (Published `rTBD`, Rollback target from the previous row), links the
   previous release's `Next`, drops a fresh `UNRELEASED.md` and adds the index row. It refuses if the
   previous release has no recorded place versions.
4. **One `Edit`** filling the new file's `TBD`s: **Summary** (one sentence — it becomes the index row),
   **Profile schema** (`vN, unchanged`, or bumped — one-way), **Data-affecting** (`yes` whenever Wallet
   reasons, the XP curve, RP awards, battle-pass grants or the profile shape changed). Leave **Shared
   modules** for Step 6. The body stays exactly as curated. Then `-SyncIndex`.
5. **Board:** open an issue for anything this release knowingly leaves unfinished, deferred or broken
   (`gh issue create`, label `standing` or `internal`, set Status and Severity, body tagged
   `(raised: <release>)` with a link to the entry). Close any issue this release verified, saying in the
   closing comment whether the basis was a playtest or elapsed time without recurrence.
6. **Do not archive the captures yet** — Step 6 does, because the bump is itself a captured edit.

## Step 6 — Bump the version

**Skipped in `check` mode.**

1. **One message:** `edit_script_lines` on `game.ReplicatedStorage.Config.GameEnvironment` in all three
   places. `old_string` is the exact text in Step 1's `VERSION` line; `new_string` carries the new name.
2. **One message:** `run(print)` in all three places again. `VERSION` must read the new name and `universe=`
   must match across all three. Write that **post-bump** fold into **Shared modules** — the bump always
   touches `GameEnvironment`, so the field is never `none`, and a Step 1 fold is already stale:
   `` `GameEnvironment` (the version bump) only. Universe mirror verified ✅ post-bump — fold `xxxxxxxx`
   (21 scripts / N bytes, resolved 21 of 21, identical in all three places). `` — plus any other
   mirrored module the release touched. Then `-SyncIndex`.
3. **Close the capture.** The bump logged itself into a fresh `pending/` file, so:
   ```
   .\.claude\scripts\changelog-capture.ps1 -Retire
   .\.claude\scripts\changelog-capture.ps1 -Archive "<release name>"
   ```
   `-Retire` without `-All` claims only this session's file; skipping it strands the bump into the next
   release's scope. The bump gets no changelog entry — the archived capture is its record.
4. **Commit and push** the roll: explicit paths only (the release file, `UNRELEASED.md`, `CHANGELOG.md`,
   the previous release file, `.changelog/archive/<release>/`, regenerated `graphs/`).

A bug found in the Step 7 soak reopens all of this: the fix is a Studio edit, so re-run Steps 1–4 and
archive its capture under this same release name.

## Step 7 — DEV soak (conditional)

**Skipped in `check` mode.**

The DEV universe (GameId `10696738139`) is a separate experience with isolated DataStores and
MemoryStores. It exists for what Studio cannot test at all: **published-server behaviour** — Studio has
no `game.JobId`, so reserved servers, access codes, friend-join forwarding and real profile round-trips
are unreachable from a playtest.

**Run it when the release touches** teleport routing / reserved servers / access codes, MemoryStore
matchmaking or the match directory, the profile shape or anything data-affecting, Robux products or
receipt handling, or a mirrored module's **behaviour** (not just its version string). Skip it for UI,
FX and tuning — ceremony on every hotfix gets skipped under pressure, which is worse than not having it.

**The live file is master; DEV is a publish target, never a branch.** Edit only the live place files
(every tool here is wired to them) and reach DEV via *File > Publish to Roblox As…*. Never edit a dev
place — there is no merge path back. A dev twin is **not a backup**: it has the features and not the
fixes. Rollback always comes from the live place's Versions tab.

```
[ ] Publish As -> DEV Bounty            (File > Publish to Roblox As...)
[ ] Publish As -> DEV Redwater Canyon
[ ] Publish As -> DEV Frostbite Claim
[ ] Join the DEV experience from the Roblox CLIENT, not a Studio playtest
[ ] Version tag reads "<release> rN [DEV]" - the suffix is the proof you are not on live
[ ] Server log clean of "[GameEnvironment] PlaceId ... has no ENVIRONMENTS row"
[ ] Step 8's route smoke test, plus whatever this release changed
[ ] RETARGET THE SESSIONS BACK TO LIVE - check the title bar of every Studio window
```

- **The `ENVIRONMENTS` warning in DEV** means the place fell back to the *live* sibling ids, so a tester
  teleporting out of the dev lobby lands in a real match. Stop and fix first.
- **`Publish to Roblox As…` retargets the session.** A plain *Publish to Roblox* afterwards goes to DEV
  and reports success. Only the r-number and `[DEV]` tell them apart — check the title bar before Step 8.
- **Purchases in DEV spend real Robux** (products prompt cross-experience) and grant into the dev
  profile. It is also the only end-to-end test of a `ProcessReceipt` handler.

## Step 8 — Hand over the manual checklist

Never publish or start a playtest through MCP (it hangs the plugin). Print:

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
[ ] Tell me it looks right, and I will cut the GitHub release and draft the Discord post
```

The `ENVIRONMENTS` warning on live means a PlaceId changed: teleports fall back to hardcoded ids and
analytics goes silent. **Stop and fix before anything else.**

Add **only** when the release fixes an exploit or is data-affecting — never as an optional extra, since
servers churn on their own and a forced shutdown is disruption bought for nothing:

```
[ ] Creator Hub > Shut Down All Servers (SoftShutdown evacuates to the lobby)
```

**Route smoke test** — by hand, only when the release touches teleport routing, the economy or bot counts:

| # | Test | Expect |
|---|------|--------|
| 1 | Party → Play → Redwater | Lands in a match (`PartyService.DESTINATION_PLACE_ID`) |
| 2 | Leave match → lobby | Returns to Bounty (`Config.LOBBY_PLACE_ID`) |
| 3 | Join a friend already in a match | Forwards to their server (`FriendJoinService`) |
| 4 | Earn Cash in a match, check balance in lobby | Wallet awards and syncs |
| 5 | Solo match, count bots | `MaxBots` bots (`BOT_EXPECT` in `PreflightGates.luau`) |
| 6 | 11+ humans in a match | Bots never drop below `MinBots` |

The fill is `clamp(DesiredRoundParticipants - humans, MinBots, MaxBots)`, so the floor only starts
binding above `DesiredRoundParticipants - MinBots` humans — rarely testable on demand.

**Rollback:** Creator Hub → the place → Versions → the release's **Published** version, all three places.
**Reverting restores code, never player data** — check the entry's **Data-affecting** flag first.

---

**When the user reports the new place versions, read `after-publish.md` in this folder** — Steps 9–11:
record the versions, cut the GitHub release, draft the Discord post.

## Changing the gate module

`PreflightGates.luau` in this folder is the canonical, reviewable copy. After editing it:

1. `set_script_source` it into **one** place's `game.ServerStorage.PreflightGates` (create the
   ModuleScript first if needed) and `run(print)` there — it must compile and behave.
2. `export_rbxm` that instance to `PreflightGates.rbxm` in this folder (overwrite).
3. In the other two places, delete the old copy and `import_rbxm` the new one into `game.ServerStorage`.
4. `run(print)` in all three: `gates=` must agree.

The file must stay free of backslashes — the header says why. `/mirror` uses the same module, and the
universe module list is its `rootsFor("universe")`: a module that starts being mirrored is added there
in the same pass.
