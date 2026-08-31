## Project
**Bullets and Bounty**

A western-themed FPS built in Roblox as a multi-place experience. Designed to play well on both PC and mobile.

The experience is **three places**: one lobby and two match maps. Everything below that says "both
places" means the lobby plus the match place you are working in — but mirrored code and publishing
cover all three.

- **Bounty** (start place) — Menu-based lobby where players group up with friends, customize skins, and queue for a match before teleporting in via TeleportService. **There IS a gamemode picker** — `StarterGui.GameModeGui`, opened from the HOME sign's CHANGE MODE button, publishing a `SelectedMode` attribute that `ReworkedUIPlay` reads. **There is no map picker**: matchmaking assigns the map and players vote for the next one at the end of each match.
- **Redwater Canyon** (match place) — Free-for-all deathmatch in a canyon map. Players spawn with revolvers and fight in timed rounds with intermission for stats and map reset between them.
- **Frostbite Claim** (match place) — the second map, shipped in Update 1. Runs the same gamemode code as Redwater; the two are kept in sync by `/mirror`, not by Packages.

**Maps and gamemodes are independent axes.** A new **map** is a new place. A new **gamemode** is
**not** — most gamemodes are meant to run on most maps, so gamemode is runtime-selected code that
every match place carries and picks from `TeleportData` at boot. Making each gamemode its own place
would multiply maps x gamemodes and force the same code to be maintained in every combination.

**Core Value:** Gunplay feels satisfying and rounds are fun to play with friends — solid shooting mechanics, fair spawning, and a smooth round loop that keeps players in the action.

## Response Style
Default to the shortest answer that does the job. Lead with the answer or the action taken.

- **Diagnosis:** cause in 1-2 sentences, then the fix. No timelines, tables, or replayed reasoning.
- **Completed work:** what changed, whether it's verified, what's left. 3-5 lines.
- **Expand only** when asked, or when a decision genuinely needs a tradeoff spelled out.

**Every fact gets ONE home.** The recurring failure is explaining the same mechanism in the code
comment, the vault `.md` *and* the changelog entry — three copies that drift apart, and two of them
are read by nobody. Rationale lives in the **code comment**, next to the line someone will edit.
The vault says what the script does. The changelog says what changed and what breaks if you revert
it. This applies to changelog entries too: they are internal and detailed, not long. An entry needs
the change, the rollback risk, and whether it is verified — not the diagnosis that is already
sitting in the source.

## Concurrent Sessions
**Up to five Claude sessions work this project at once — same folder, same working tree, same Studio instance.** Treat every shared resource as potentially modified by a peer session since you last read it.

- **`changelog/UNRELEASED.md`** — never `Write` it whole; always `Edit` anchored on a section heading and re-read immediately before editing, because another session may have appended since. Same for the root `CHANGELOG.md` index. See Changelog & Release Rules.
- **Vault `.md` files** — re-read before editing; a peer may have updated the summary or connections section.
- **Shared mirror modules** — if you edit one copy, check the other copy for peer edits before writing so you don't clobber concurrent changes.
- **`.changelog/pending/`** — each session writes its own `<session>.jsonl`; never touch another session's file. `/changelog all` is the only sweep and belongs to a release.
- **Studio data model** — MCP reads reflect the live state; a peer session may have created, moved, or deleted instances between your tool calls. Re-fetch before assuming structure.

### Git with five agents in one working tree

**One clone, one working tree, one branch.** Every session commits to `main` in the same folder, so
each commit is a child of the last and **pushes cannot diverge — merge conflicts are structurally
impossible.** Keep it that way. The hazard here is not merging; it is that four peers' half-finished
edits are sitting in the same tree as yours, and git cannot tell them from your own.

- **Stage explicit paths. `git add <path>` — never `git add -A`, `git add .`, or `git commit -a`.**
  Those sweep every peer's in-progress work into your commit, and the peer has no way to notice. This
  is the rule that matters most, and it is *denied* in `.claude/settings.json` so it fails outright
  rather than prompting.
- **Never rewrite the shared tree.** No `git checkout`, `git switch`, `git reset --hard`,
  `git stash`, `git clean`. Each silently destroys uncommitted work belonging to sessions you cannot
  see, and there is no reflog for a file that was never staged. These prompt — treat the prompt as a
  stop sign, not a speed bump.
- **No branches, no worktrees.** Studio is the authority and cannot be branched, so a doc branch
  describes a place that has already moved on. And `graphs/` is regenerated wholesale from the
  *entire* vault: on a branch it would be built from a partial one, and a 386 KB generated JSON is a
  file nobody can merge or review. Isolation would manufacture the conflicts it claims to prevent.
- **Commit small and often.** The window where your work sits unstaged is exactly the window a peer's
  careless `add` can take it.
- **Scope your status:** `git status --short -- <your paths>`, not a bare `git status` showing four
  other people's work.
- **`index.lock` means a peer is mid-commit.** Wait a moment and retry. **Never delete the lock
  file** — that corrupts their commit without unblocking yours.
- **A rejected push means someone edited on github.com or another machine.** That is the only way
  this repo can diverge. `git pull --rebase`, then push.
- **`graphs/` regenerates, never merges.** Run the update script and commit the regenerated graph in
  the same commit as the vault edits that caused it. If two sessions both touched the vault, the last
  run is the correct one — never hand-edit or hand-merge a generated graph.

## Codebase Location
**The codebase does NOT live in this project folder.** All game code (Luau scripts, instances, properties) lives exclusively in **Roblox Studio**. This folder only contains planning documents, an Obsidian documentation vault, and generated knowledge graphs.

To read or modify the codebase, you **MUST** use the **Roblox MCP server** tools (`mcp__robloxstudio__*`). Do NOT attempt to read game code from local files — they are documentation, not source.

This folder **is** a git repo, pushed to private `Rasmus-Bondo/Bounty`. It versions the docs, vaults, graphs and changelog only. `git log` will never tell you what changed in the game — the changelog and the Roblox place versions do that.

### Constraints
- **Platform**: Roblox Studio — all game code is Luau scripts within the Roblox data model
- **Architecture**: Client-server model enforced by Roblox (LocalScripts on client, Scripts on server, RemoteEvents for communication)
- **Storage**: Roblox DataStore API for persistence (rate limits, key size limits apply)
- **Performance**: Must run smoothly on mobile devices — the majority of Roblox's player base is on phones
- **Input**: Must support both keyboard/mouse and touchscreen input methods
- **Streaming**: All three places run `workspace.StreamingEnabled = true`. A Model can replicate to a client as an **empty container** — `FindFirstChild` on the model succeeds while its BaseParts (and the Sounds/Attachments inside them) are streamed out. Never assume descendants exist client-side, and put menu-critical instances inside a Model with `ModelStreamingMode = Persistent`.

## Technology Rules
- **Networking**: RemoteEvents only. `FireServer` for client actions, `FireClient`/`FireAllClients` for server broadcasts. Never use RemoteFunction for combat.
- **Persistence**: ProfileService (DataStore wrapper) with session locking.
- **Shared modules are mirrored VERBATIM across all three places** — 20 files: `Wallet`, `Telemetry`, `TelemetryClient`, `ProfileService`, `GameEnvironment`, `MapCatalog`, `GamemodeConfig`, `SoftShutdown`, `VersionTagController`, `BattlePassConfig`, `BoostConfig`, `EmoteConfig`, `QuestConfig`, `TitlesConfig`, `DailyRewardConfig`, `FriendBonusConfig`, `TitleStyles`, `TitleRenderer`, `AnimationLoader`, `TesterGrantService`. **`MapCatalog` is not `MapConfig`** — the catalog is universe-wide and lists every map; `MapConfig` is per-place, describes only that map, and must NEVER be mirrored. Edit both copies in the same pass and verify with a byte-length + checksum compare — `/preflight` does this as a hard gate. Drift here fails **silently**: Redwater's `EmoteConfig` once fell to 5 of 18 ids, which collapsed 13 emotes to the default at match end with no error, and `QuestConfig` drifted to 2777 vs 3337 bytes because it was not on this list at all.
- **UI**: ScreenGui/Frame hierarchy, authored as instances. See **UI Rules** below.
- **Input**: UserInputService + ContextActionService. Detect mobile via `UserInputService.TouchEnabled`. Touch gets aim assist and dedicated buttons.
- **Combat**: Server-authoritative. Hitscan weapons call `BulletPenetration.Pierce` (`ReplicatedStorage.Hunters.Shared`) rather than a bare `workspace:Raycast`, and feed `GetDamageMultiplier(layers)` into their damage service. Never treat a stopped pierce as a miss — return a result, or the shot falls through to the forgiveness sphere and hits someone behind the wall. Server still validates ray origin and does lag compensation; client-side FX projectile sims must mirror the server's raycast filter exactly.
- **Audio**: Positional sounds on Attachments. InverseTapered rolloff, 10-200 stud range. **Every Sound must carry a SoundGroup** (`SFX` / `HitSound` / `Music`) — there is no `SoundService.Volume`, "Master" is faked by multiplying into each group, so an ungrouped Sound escapes **all four** settings sliders. `:Clone()` inherits the group; every `Instance.new("Sound")` site must set `.SoundGroup` explicitly.
- **Avoid**: Roact/React-lua, BodyVelocity/BodyForce (deprecated), Mouse object (deprecated), client-side hit detection, RemoteFunction for combat.

## UI Rules

**Read `UI_STYLE_GUIDE.md` in the project root before creating or changing any GUI instance.** It is
the single home for everything UI — how it is authored (as real instances, never built in code), the
colour and type tokens, the corner and stroke rules, component recipes, motion, the `DisplayOrder`
registry, device scaling, and the build-and-verify order. It was derived by scanning every
`ScreenGui` in both places, so it describes what the UI **is**, not what someone once intended.

**Nothing about UI is duplicated here on purpose.** A UI fact repeated in this file is a second copy
that will drift — put it in the guide instead, and link to the section from the code comment that
needs it.

**Two sections are about speed rather than style, and are why the guide is worth opening even for a
small tweak.** §1.1 — *a property read-back is not verification*, and a value read off an existing
instance is not necessarily reproducible by assigning it, so **clone UI that already looks right
rather than re-typing its property values**. §9 — the build-and-verify order, whose headline is *run
`capture_device_matrix` on the FIRST draft, not the last*, plus a copy-paste geometry assertion
snippet. Both exist because rebuilding one dialog took nine build-screenshot-fix cycles, about six of
them avoidable: three defects were present in the very first build and were found one at a time
because each round checked a single viewport.

**It is a living document and you may edit it.** When you establish a new pattern, add it; when you
find a rule that is wrong, correct it rather than working around it. `.claude/settings.json` grants
read + edit on it.

## Economy
The two currencies and account XP are governed by **opposite** rules. Do not generalise from one to the other.

- **Cash / Tokens — single chokepoint.** Every change goes through the shared `Wallet` module (`ServerScriptService.PlayerServices.Wallet`) via `Wallet.award` / `Wallet.spend`. **NEVER write `data.Cash` / `data.Tokens` directly** — it skips the economy analytics event and usually the leaderstat sync. Wallet is the sole currency mutator and the only place `AnalyticsService:LogEconomyEvent` is called. Sites that already mutated can log after the fact with `Wallet.logSource` / `logSink`.
- **Every mutation needs a `reason`,** and an unmapped reason silently falls back to the "Gameplay" transaction type rather than erroring — so a new spend/award that isn't added to Wallet's reason map will mislabel itself in analytics instead of failing loudly. Add the reason to **both** copies.
- **Account XP — no chokepoint.** It is written in three places across both places, and only Redwater's `ProgressionService` applies boost multipliers, recomputes Level and fires `LevelUp`. When auditing XP writers, grep for `data%.XP` — the lobby assigns rather than increments, so a `+=` search finds only one of the three. Battle-pass season XP is a separate track again and never touches `data.XP`.

## Hunter Architecture (Redwater Canyon)
Hunters are **data-driven**, not hand-wired. Each one declares a `Manifest` under `ReplicatedStorage.Hunters.<Name>.Config` (remotes, bindables, ultimate-charge sources, viewmodel), which is consumed by `HunterServerRuntime.Start(manifest)` and `HunterClientRuntime.Start(manifest)`. Everything hero-agnostic lives in `ReplicatedStorage.Hunters.Shared` — hit pipeline, ultimate charge, position history/lag comp, world model, viewmodel motion, status effects, bullet penetration, aim assist, client teardown registry.

Hero-specific server code goes in `ServerScriptService.Hunters.<Name>Server/`, hero-specific client code in `StarterPlayerScripts.<Name>/`. Code that serves all viewers stays at the root and is left ungated.

**Before adding or changing a hunter, read `ServerScriptService.HunterImplementationGuide`** (ModuleScript, docs-only) — it is the canonical spec for the manifest schema, runtime APIs, shared-module catalog and wiring recipe. Dust and Fortuna are the reference implementations.

## Context Navigation
When you need to understand or navigate the codebase, follow this two-step process:

1. **Query the knowledge graph first** — Use `/graphify query "your question"` to search the relevant graph for scripts, connections, and relationships. Browse the place-specific vault folders for detailed summaries of individual scripts.
   - **Redwater Canyon**: `graphs/RedwaterCanyonGraph/graph.json` · vault at `LocalRedwaterCanyon/`
   - **Bounty (Lobby)**: `graphs/BountyGraph/graph.json` · vault at `LocalBounty/`
   - **Frostbite Claim** has no vault or graph of its own, by design — it mirrors Redwater's gamemode code, so Redwater's vault describes it. Read Redwater's, then check the live Frostbite source via MCP for anything map-specific.
2. **Then fetch live source via MCP** — Once you've identified the scripts you need, use the Roblox MCP tools (`get_script_source`, `grep_scripts`, etc.) to read the actual current code. The graph tells you *where to look*; MCP gives you *what's actually there*.

The vault folders and `graphs/` knowledge graphs are documentation aids — NOT the source of truth. The Roblox Studio data model (accessed via MCP) is always authoritative.

### Reading graph.json directly
`graph.json` is pretty-printed one key per line, so **read it with `Grep`/`Read` — never shell out to `python -c` or PowerShell to parse it.** To check whether a `[[wikilink]]` became a real edge, grep the place's graph for the lowercased script name:

```
Grep "\"_src\": \"titlebuycontroller\"" graphs/BountyGraph/graph.json -B 5 -A 3
```

Three things that otherwise cost a round-trip each to rediscover: the edge array is **`links`**, not `edges`; node ids are the **lowercased** label (`titlebuycontroller`); and each link carries two id pairs, of which **`_src`/`_tgt` is the correct directed one** — `source`/`target` are reordered by the graph library and read backwards. `GRAPH_REPORT.md` is a summary (stats, god nodes, communities) and does not list every edge, so it can't confirm a specific one. Shell is only for running the update scripts below.

## Vault Rules
Each place has its own Obsidian vault folder that mirrors the Roblox Studio script hierarchy. Every script has a corresponding `.md` summary file at the matching path (e.g. `game.ServerScriptService.Combat.RevolverModule` → `LocalRedwaterCanyon/ServerScriptService/Combat/RevolverModule.md`). You MUST keep these vaults in sync with the codebase.

| Place | Vault folder | Graph directory | Update script |
|-------|-------------|-----------------|---------------|
| Redwater Canyon | `LocalRedwaterCanyon/` | `graphs/RedwaterCanyonGraph/` | `python update_redwater_canyon_graph.py` |
| Bounty (Lobby) | `LocalBounty/` | `graphs/BountyGraph/` | `python update_bounty_graph.py` |

### When to update
- **New script created** → Create a matching `.md` file with the standard template (see below).
- **Script deleted** → Delete the corresponding `.md` file.
- **Script renamed or moved** → Move/rename the `.md` file to match.
- **New RemoteEvent, BindableEvent, or require() connection added** → Update the Connections section in both the source and target `.md` files.
- **Connection removed** → Remove it from both sides.
- **Script behavior changes significantly** → Update the "What it does" section.

After any of the above changes, run the corresponding update script (see table above) to sync the knowledge graph with the updated vault. These scripts parse vault markdown deterministically (no LLM needed) and regenerate `graph.json`, `graph.html`, and `GRAPH_REPORT.md`. Append `--full` to force a complete rebuild.

**Run them as the bare command, one per tool call** — `python update_bounty_graph.py`, nothing before it and nothing chained after it. Both places need rebuilding? That is two calls, issued together in one message so they run in parallel — never `a.py; b.py` (a chained string matches neither rule, and in Windows PowerShell 5.1 `&&` is a parser error and `&` is the call operator, not a chain). They are allowlisted in `.claude/settings.json`, and permission rules match on the command **prefix**: a leading `Set-Location`/`cd` or a wrapping `2>&1 | Select-Object …` makes it a different command and re-prompts every single time. The working directory is already the project root, so the prefix buys nothing. Read the output with `Read`/`Grep` rather than piping — the same rule is why `cat`/`head`/`tail`/`grep`/`Select-String` should go through the `Read`/`Grep`/`Glob` tools instead of a shell: those need no approval at all, and a one-off shell command can never be usefully allowlisted, so it just adds a permission rule nobody will ever match again.

### File template
Every summary file must follow this structure:
```markdown
---
tags: [server/client, script/localscript/modulescript, ...]
path: game.ServiceName.Path.To.Script
type: Script | LocalScript | ModuleScript
lines: <line count>
---

# ScriptName

One-line description.

## What it does
<numbered list of key behaviors>

## Dependencies
- **Requires:** <modules via require(), each a `[[Wikilink]]` — this is the ONE field the graph
  reads for the forward edge, so a plain-text name here is a MISSING edge> or Nothing
- **Required by:** <who requires this, as PLAIN TEXT — never `[[wikilinks]]`> or Nobody

## Connections
### RemoteEvents
| Remote | Direction | Other script |
|--------|-----------|-------------|
| `EventName` | ← Client / → Client | [[OtherScript]] context |

### BindableEvents
| Bindable | Direction | Other script |
|----------|-----------|-------------|
| `EventName` | ← / → | [[OtherScript]] context |

### Direct require()
| Target | Function | Purpose |
|--------|----------|---------|
| [[Module]] | `Module.func()` | Why |
```

### Wikilink rules
- `[[Wikilinks]]` are ONLY for direct code-level connections: `require()`, `RemoteEvent`, `RemoteFunction`, `BindableEvent`, `BindableFunction`, or `CollectionService` tags.
- Do NOT wikilink scripts that only interact implicitly (reading attributes, reading UI instances, destroying instances created by another script, render priority ordering, etc.). Use plain text for those references.
- **Why this matters:** the update scripts extract wikilinks from the **entire file, including prose** — not just the Dependencies and Connections sections. A `[[Name]]` written casually in a sentence becomes a real edge in the graph and quietly invents a dependency that does not exist in code.
- **Prose comparisons are how this rule actually gets broken.** Not carelessness — sentences that read as obviously correct: *"parented at the root, like `[[HunterSwitchClient]]`"*, *"overloaded the same way `[[HunterSwitchService]]`'s remote is"*, *"`[[HunterClientLoader]]` tears down per-hunter folders"*. Each invented an edge. Naming a script to explain a **convention it copies**, a **contrast**, or **another script's behaviour** is plain text. A wikilink asserts that *this* script's code names that one — nothing weaker.
- **Docs-only files never wikilink anything.** `HunterImplementationGuide` requires nothing and is never executed, so every `[[Name]]` in it is fabricated by definition. Same for any `.md` describing a script that only reads attributes or instances.
- **A shared module's `Required by:` list is plain text, not wikilinks.** An edge's `_src` is the node of the **file the wikilink was written in**, so a `Required by:` wikilink points *dependency → dependent* — backwards. When the dependent's own `.md` also declares the `require()`, the two form a reciprocal pair and the graph keeps whichever direction it parsed first. **A `--full` rebuild does not fix it; it was never a cache problem.** The caller's own file supplies the edge the graph needs, so writing it on both sides only creates a race.
  - Both vaults were swept clean of backwards and prose links on 2026-08-07, so **any `Required by:` or prose wikilink you find now is new debt, not historical backlog** — fix it rather than assuming it is known. (Prose links that merely repeat a dependency the file already declares structurally were deliberately left; they assert nothing false.)
- **Verify after running the update script — the graph is the only proof.** The rule is easy to follow and still easy to violate, so check the result rather than your intent:
  ```
  Grep "\"_src\": \"yournewscript\"" graphs/RedwaterCanyonGraph/graph.json -A 1
  ```
  Every `_tgt` must map to a real `require()` / RemoteEvent / BindableEvent / CollectionService tag in that script. If one doesn't, the **wikilink** is wrong, not the graph.
  - **`graph.json` proves a bad edge exists; it does NOT prove a good edge is missing.** The builder prunes heavily on the way to the final graph — Redwater extracts 927 edges and writes 716 — and what it drops hangs off the god nodes. `RoundController.md` declares `[[SpawnService]]` in its `Requires:` line and there is still no `roundcontroller → spawnservice` pair in `graph.json`. Reading that absence as "the wikilink didn't register" is a false negative, and it will send you adding links that are already there.
  - **The authoritative number is `Extracted N nodes, M edges`, not `Done: … M edges`.** After demoting bad links to plain text the *extracted* `M` must drop by exactly the number you demoted (1153 → 883 for 270). The `Done:` figure moves by some other amount as pruning re-settles, and that difference is not a bug to chase.
- Only create `.md` files for actual Roblox Studio scripts. No overview files, index files, or hub files.

## Changelog & Release Rules

The changelog is the **only** version history of the game itself. The project folder is a git repo (private `Rasmus-Bondo/Bounty`), but git versions the *documentation* — the Luau code lives in Studio, so no commit records what shipped. Roblox place versions are the rollback index; the changelog is how you know *which* version to roll back to. It is **internal**: it carries place versions and security fixes and is never pasted anywhere a player can read.

**It is a folder, not a file.** `CHANGELOG.md` in the project root is an **index** — one table row per release and nothing else — so an agent looking up one release does not load five. Open only what you need:

| File | What it is |
|---|---|
| `CHANGELOG.md` | Index. Release table with dates, place versions, data-affecting flag, one-line summaries. Start here. |
| `changelog/UNRELEASED.md` | In-flight work. The **only** file `/changelog` writes. |
| `changelog/YYYY-MM-DD-<release>.md` | One shipped release. **Published history — never edited after publishing.** A correction to a shipped entry is a new entry in `UNRELEASED.md`. |
| `changelog/OPEN-ITEMS.md` | Signpost to the [project board](https://github.com/users/Rasmus-Bondo/projects/1) plus the old-id → issue mapping. **Issues are not tracked here any more.** |
| `changelog/open-items/<id>-<slug>.md` | Redirect stubs, so links in the published release entries still resolve. `open-items/archive/` + `ARCHIVE.md` hold the 99 items closed before 2026-08-31. |
| `changelog/CONVENTIONS.md` | Metadata-block fields, versioning scheme, the 20 mirrored modules, the exploit rule. |

Rolling a release **renames** `UNRELEASED.md` to the dated file and adds a row to the index — prose is never cut and pasted between files.

### Automation
| Piece | What it does |
|-------|--------------|
| `.claude/hooks/log-studio-change.ps1` | `PostToolUse` hook appending every Studio mutation to `.changelog/pending/<session>.jsonl` — **one file per agent session**, shared with that session's subagents. Mechanical — cannot be forgotten. |
| `.claude/scripts/changelog-capture.ps1` | Says which capture file is *yours*, retires a curated one into `.changelog/consumed/`, archives consumed files under a release name, and `-Coverage` lists touched names that appear nowhere in `changelog/UNRELEASED.md`. Moves files; never deletes them. **Keep it pure ASCII** — PowerShell 5.1 reads a BOM-less `.ps1` as CP1252, where an em-dash decodes into a smart quote the parser accepts as a string delimiter, breaking the file with errors that point at unrelated lines. |
| `/changelog` | Curates **your own session's** capture into prose in `changelog/UNRELEASED.md`, checks its own coverage, then retires it. `/changelog all` sweeps every session — the pre-release roll-up. |
| `/preflight` | The pre-publish gates. **Run it before every publish, not after.** It does not publish — publishing is manual in Studio, which is why it is not called `/publish`. `/preflight check` stops after the read-only gates. Its Step 4 reads `pending/` **and** `consumed/` together (a pane that already curated still ships its scripts) and runs the `-Coverage` cross-check; Step 5 sweeps anything uncurated and archives the captures under the release name. |

### Rules
- **Never publish one place alone.** The mirrored modules make a half-published experience a live drift bug. All three places go out together, always.
- **Curate your own capture, and retire it rather than deleting it.** Several agents work this project at once, which is the whole reason the capture is partitioned per session. Touching another pane's `pending/` file — curating it, emptying it, deleting it — silently destroys work that agent has not written up yet, and it cannot tell that anything went missing. `/changelog all` is the only sweep, and it belongs to a release, announced first.
- **Never `Write` `changelog/UNRELEASED.md` or `CHANGELOG.md` whole.** Append with an `Edit` anchored on a section heading, and re-read the file immediately before, because another agent may have written since. A whole-file write is the one operation that destroys a concurrent entry without complaining; a stale anchor merely errors, which is the point.
- **A shipped release file is history.** `changelog/YYYY-MM-DD-<release>.md` stops being edited the moment it publishes, except to fill in its `Published` versions. Corrections go in `UNRELEASED.md`; anything still broken or deferred becomes an issue on the project board, not something buried in a release entry where nobody will look.
- **A number in a release entry is an OLD item id, not an issue number — never pass it to `gh issue view`.** Release entries published before 2026-08-31 cite items by their old id, and the two numberings collide: old item 12 is issue #12, but issue #12 is old item 118. The lookup succeeds and returns the wrong issue, silently. Translate through the mapping table in `changelog/OPEN-ITEMS.md` first. The collision widens as the board grows past #33.
- **The board is authoritative, and the owner drags cards on it.** A card that moved is a decision already made, not a discrepancy to query. **`Done` means done — never re-verify it, never ask whether it is really finished.** Read the column, believe it, move on.
- **Read the board with `/issues`.** It wraps the one GraphQL call that returns number, title, column and severity. `gh issue list` cannot see the columns (`Status` and `Severity` are project fields, not issue properties), and `gh project item-list --format json` embeds every issue body — ~80 KB — so it floods your context for what should be a one-line list.
- **Issues live on the [project board](https://github.com/users/Rasmus-Bondo/projects/1) and nowhere else.** They are called *issues*, not "open items" — the old term is retired. You drag them between columns on the board; that is the interface. The issue carries symptom, repro and the test that closes it; **diagnosis stays in the release entry**. Closing the issue is how it closes, and the closing comment records whether the basis was a playtest or elapsed time without recurrence. The **`Testing` column is not closed** — it still owes a playtest, which is the distinction the old `FIXED (unverified)` status existed to make.
- **Never patch-note an exploit fix.** Duplication bugs, anti-cheat changes and permission holes get full detail in the changelog and the words *"backend improvements"* in anything player-facing. Naming an exploit advertises that it existed and invites probing for the next one.
- **Mark data-affecting releases.** Anything touching Wallet reasons, the XP curve, RP awards, battle-pass grants or the profile shape cannot be undone by reverting a place. Reverting restores code, never stored data.
- **Record the place versions** in the release's `Published` field immediately after publishing. An entry without them cannot be rolled back to.
- **Profile schema bumps are one-way.** You cannot safely revert a place past one.

### Environments
`ReplicatedStorage.GameEnvironment` (mirrored) is the single source of truth for place ids, the human version string and `isLive`. **Never hardcode a PlaceId anywhere else** — every place resolves its *siblings* from its own `game.PlaceId`, which is what stops a DEV server from teleporting players into live matches. Adding the staging universe means adding two rows to its `ENVIRONMENTS` table and nothing else.

Publishing does not update servers that are already running; they keep the old code until they empty out. `ServerScriptService.SoftShutdown` (mirrored) evacuates players to the lobby so *Shut Down All Servers* on the Creator Hub retires stale code without disconnecting anyone.