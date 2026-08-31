---
name: changelog
description: Turn this session's raw Studio-mutation capture in .changelog/pending/ into prose entries in changelog/UNRELEASED.md. Use after a work session, or whenever the user asks to update the changelog. Pass "all" to sweep every session's capture before a release.
---

# Update the changelog

Reads the mechanical capture and writes human prose. The capture cannot be forgotten (it is a
`PostToolUse` hook); the curation needs judgement, which is why it is a skill and not a script.

**You write into `changelog/UNRELEASED.md` and nothing else.** The root `CHANGELOG.md` is an index —
one table row per release, no prose — and it only changes when `/preflight` rolls a release. Shipped
releases live in `changelog/YYYY-MM-DD-<release>.md` and are never edited after publishing. Standing
concerns that outlive a release become **an issue on the project board**
(<https://github.com/users/Rasmus-Bondo/projects/1>) — not a file in `changelog/open-items/`, which
is redirect stubs only since 2026-08-31. Conventions are in `changelog/CONVENTIONS.md`.

**Several agents work this project at once, so this skill never deletes anything and never touches
another session's capture.** The capture is partitioned per session at write time —
`.changelog/pending/<session>.jsonl`, one file per pane, shared with that pane's own subagents.
Curating a file *retires* it into `.changelog/consumed/`, where `/preflight` can still read it for
release scope. The old single shared `pending.jsonl` failed twice over: whichever agent curated
first deleted the capture of everyone still mid-work, and two panes appending at the same instant
could collide on a file lock that the hook silently swallows.

## Steps

**1. Find your capture.**

```
.\.claude\scripts\changelog-capture.ps1
```

Prints your session id, every pending file with its line count and whether it is `MINE`, and the
consumed count. **Curate the `MINE` file and no other.** If there is no file for your session, say
so and stop — do not curate another pane's lines, and do not invent entries from memory of the
conversation. Read the file itself with `Read`, not a shell command.

Each line is one Studio mutation: `ts`, `tool`, `target`, `place`, sometimes `name`, and `origin`
when the mutation came from a subagent. Place ids map as: `place:131701626847012` = Bounty,
`place:98517073248449` = Redwater Canyon, `place:134041618959520` = Frostbite Claim.

**A mutation in one match place usually implies its twin.** Redwater and Frostbite carry the same
codebase byte-identical, so a capture showing an edit in only one of them is either a per-place file
(`MapConfig`, map geometry) or a mirror that has not been finished — worth a look before you write
the entry, not after `/preflight` catches it.

> **`all`** — invoked as `/changelog all`. Curates every pending file, plus the unowned
> pre-partition `pending.jsonl` if one is still lying around. This is the pre-release sweep and
> what `/preflight` calls. Before writing, list which sessions you are about to absorb and say
> plainly that another agent may still be working in one of them, so the user can hold off. Prose
> for work you did not do is necessarily vaguer — that is the cost of the sweep, and the reason it
> is not the default.

**2. Collapse it.**

The raw log is far too granular to publish. Group by subsystem, not by tool call:

- Many `set_property` / `mass_set_property` on one GUI subtree → **one** line about that panel.
- Repeated `set_script_source` on the same script → **one** line about that script's change.
- `create_object` + `set_script_source` on the same path → a single "added X" line.
- Ignore pure scaffolding churn (an object created then deleted in the same session).

**3. Describe the change, not the edit.**

Bad: *"Set source of ServerScriptService.SoftShutdown."*
Good: *"Servers now evacuate players to the lobby on shutdown instead of disconnecting them."*

The reader wants to know what is different about the game, not which tool ran.

**Then keep it short.** An entry answers three things and stops: what changed, what breaks if you
revert it, and whether it was verified. A bolded one-liner plus one to three short paragraphs.
**Do not re-explain in the entry a mechanism you have just commented in the source** — that is a
second copy which will drift, and the source is where the next person reads it. See
[Entries are precise, not long](../../../changelog/CONVENTIONS.md) for the full rule, including the
one case that does carry diagnosis: an entry cited by an issue on the board.

**4. Write into `changelog/UNRELEASED.md` — by anchored `Edit` only.**

Another agent may append to this file between your read and your write, so:

- **`Read` `changelog/UNRELEASED.md` immediately before editing.** A read from earlier in the
  session is stale.
- **Use `Edit`, anchored on a `## Added` / `## Changed` / `## Fixed` heading** or on a distinctive
  line of an existing bullet. Splitting the prose out of the root index made these anchors unique
  within the file — a bare `## Fixed` no longer collides with every past release, because past
  releases are separate files now.
- **Never `Write` the whole file.** A whole-file write is the one operation that silently destroys
  a concurrent agent's entry; a failed `Edit` only errors.
- **If the `Edit` fails, re-`Read` and retry.** The anchor moving means someone else just wrote —
  that is the mechanism working, not a problem to route around.
- **Never edit a dated release file** in `changelog/`. Those are published history. If something
  shipped and was described wrong, the correction is a new entry in `UNRELEASED.md`, not a rewrite
  of the record.

Use `## Added` / `## Changed` / `## Fixed` sections. Append to existing sections rather than
duplicating them. One bullet per change, so two panes interleaving stays legible. Leave the header
block and nav links at the top of the file alone — the coverage check treats everything above the
first `---` rule as boilerplate.

Then confirm your entries actually cover what you changed:

```
.\.claude\scripts\changelog-capture.ps1 -Coverage -Mine
```

`-Mine` restricts this to your own capture — without it every other pane's uncurated work is
reported as your suspect. A `SUSPECT` is a name from your capture that appears nowhere in
`changelog/UNRELEASED.md`. Often that is correct: an entry written in player terms will not contain the
script's name. Read each one and decide. **Do not add script names to the prose to clear the
list** — the check exists to find work you forgot to describe, not to make the changelog name
files. `/preflight` Step 4 runs the same check unrestricted, so anything you leave surfaces again
at release time.

**5. Flag the two things that carry release risk.**

While grouping, watch for and call out explicitly:

Record both in the metadata bullets at the top of `UNRELEASED.md`, above the section headings —
`/preflight` reads them when it converts the file into the release entry.

- **Shared modules touched.** The mirrored set is 20 files: `Wallet`, `Telemetry`,
  `TelemetryClient`, `ProfileService`, `GameEnvironment`, `MapCatalog`, `GamemodeConfig`,
  `SoftShutdown`, `VersionTagController`, `BattlePassConfig`, `BoostConfig`, `EmoteConfig`,
  `QuestConfig`, `TitlesConfig`, `DailyRewardConfig`, `FriendBonusConfig`, `TitleStyles`,
  `TitleRenderer`, `AnimationLoader`, `TesterGrantService`. If any appear,
  note them so `/preflight` knows to verify the mirrors. If a module starts being mirrored and
  is not on this list, say so — an untracked mirror is how `QuestConfig` drifted unnoticed.
  **`MapCatalog` is not `MapConfig`** — the catalog is universe-wide and mirrored; `MapConfig` is
  per-place and must never be.
- **Data-affecting changes.** Anything touching Wallet reasons, the XP curve, RP awards,
  battle-pass grants or the profile shape. These cannot be undone by reverting a place, so
  they must be marked in the release entry.

**6. Retire the capture — never delete it.**

```
.\.claude\scripts\changelog-capture.ps1 -Retire
```

Moves **your** file to `.changelog/consumed/<session>-<utc stamp>.jsonl`. Add `-All` only in `all`
mode. Nothing is removed from disk: `/preflight` reads `pending/` **and** `consumed/` together to
get the full list of scripts a release touched, and archives them under the release name once it
rolls. A retired file is also how a wrong entry gets rewritten instead of reconstructed.

Do not delete, empty, or edit a file in `pending/` by hand, and do not retire a file that is not
yours — an agent that is still working has no way to notice its capture disappeared.

## Security note

Never write an exploit, duplication bug or anti-cheat change into player-facing wording.
The changelog is internal and records the full detail; the curated public note says
"backend improvements". Naming an exploit publicly advertises that it existed.
