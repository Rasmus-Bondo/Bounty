# Changelog conventions

[Index](../CHANGELOG.md) · [Unreleased](UNRELEASED.md) · [Issues](https://github.com/users/Rasmus-Bondo/projects/1)

How release entries are named, structured and written. Read this before rolling a release
or writing an entry; you do not need it to look up what a past release did.

---

## The metadata block

Every release entry opens with these fields:

| Field | Meaning |
|---|---|
| **Published** | Roblox place version for each place, e.g. `Bounty r42 · Redwater r67`. This is your rollback target — record it right after publishing. |
| **Rollback target** | The *previous* release's place versions — where a revert of this release lands. Under fire nobody wants to derive that from the file. |
| **Shared modules** | Which of the 21 mirrored modules were touched, and whether the byte-length + checksum compare passed. A touched module with no ✅ is a live drift bug. |
| **Profile schema** | ProfileService data shape version. Bumps are **one-way** — you cannot safely revert a place past one. |
| **Data-affecting** | `yes` if the release mutates stored player data (Wallet reasons, XP curve, RP awards, pass grants, migrations). Reverting the place does **not** undo these. |

## Entries are precise, not long

An entry answers three questions and stops: **what changed**, **what breaks if you revert it**, and
**whether it was verified**. Length is not thoroughness. An entry that re-explains a mechanism
already commented in the source is a second copy of that explanation, and the two will drift.

- **Rationale belongs in the code comment**, next to the line someone will actually edit. The entry
  ties the change to a release; the source explains itself.
- **Name the revert hazard explicitly** when there is one — a flag that restores the old behaviour,
  a companion place that must ship with it, a constant that must stay larger than another. This is
  the part nobody can reconstruct at 2am, and it is the reason the file exists.
- **State the verification basis, not a transcript.** "Playtested by the owner", "harness-verified,
  not playtested", "recompile only" each carry real information. Three paragraphs of harness output
  do not.
- **One exception: an entry cited by an issue carries that issue's diagnosis** — see rule 2
  above. The issue deliberately holds only symptom, repro and closing test, so the forensics
  have to live somewhere, and this is that somewhere. Absent an issue, a fix explained in its
  own source does not need re-explaining here.

Rough shape: a bolded one-line summary, then one to three short paragraphs. Anything longer is
usually several changes that want separate bullets, or diagnosis that belongs in the source.

## File layout

One file per release, in this folder, named `YYYY-MM-DD-<release-slug>.md` — date first so the
folder sorts chronologically, since `Hotfix 10` would otherwise sort before `Hotfix 2`.

- `../CHANGELOG.md` — the index. One table row per release, nothing else. It is the entry point.
- `UNRELEASED.md` — work that has shipped to no one yet. `/changelog` writes here.
- `OPEN-ITEMS.md` — signpost to the project board plus the old-id → issue mapping. Open items are
  **not** tracked here any more.
- `open-items/<id>-<slug>.md` — redirect stubs, so the published release entries' links still
  resolve. `open-items/archive/` + `ARCHIVE.md` hold the 99 items closed before 2026-08-31.
- `CONVENTIONS.md` — this file.

**Rolling a release renames `UNRELEASED.md`** to the dated file and creates a fresh empty one.
Nothing is cut and pasted between files, which is the whole reason the in-flight prose does not
live in the index.

## Issues live on the project board

Since 2026-08-31 a known problem or a deferred piece of work is an **issue** on
<https://github.com/users/Rasmus-Bondo/projects/1>. The board is its only home: you drag it between
columns there, and nothing about it is tracked in this folder. The term *open item* is retired — it
is an issue, and its id is its issue number.

`OPEN-ITEMS.md` was a single 2,755-line / 217 KB document until 2026-08-11, then an index of rows
over `open-items/` until the migration. Both shapes drifted, and the migration audit caught three
at once: the index listed 18 rows under a heading that said 16, item 125 had a file and no row at
all, and a cross-reference pointed at a path that had been archived out from under it. **A board
cannot drift from itself** — the status you see is the status there is.

Three rules carry over unchanged:

1. **The issue holds symptom, repro and the test that closes it. Diagnosis lives in the release
   entry.** The forensics that explain *why* a fix worked are written once, in the entry that
   shipped it. The old document's bulk was items restating what already existed one folder up.
2. **`Testing` is not closed.** Code sitting in Studio still owes a human playtest; MCP playtesting
   is unavailable, so closure is always a manual run-through. That was the entire point of the old
   `FIXED (unverified)` status, and it is now a column you can see without opening anything.
3. **A closure records its basis.** An owner may close on **elapsed time without recurrence**
   rather than a playtest — that is how the last ten launch issues closed on 2026-08-11. Say which
   in the closing comment: "shipped and tested" and "shipped and nothing broke" are different
   claims, and only that comment distinguishes them later. A resurfaced problem becomes a **new
   issue**, never a reopened one.

**Old ids still resolve, and do not match issue numbers.** Release entries published before the
migration cite items by their old number — 1–32 are the launch report (no #2), 33+ from the
2026-08-11 split — and old 132 is issue #1. `OPEN-ITEMS.md` carries the mapping table, and the
stubs under `open-items/` keep those citations clicking through. New work takes an issue number and
no old id at all.

## The 21 mirrored shared modules

`Wallet`, `Telemetry`, `TelemetryClient`, `ProfileService`, `GameEnvironment`, `MapCatalog`,
`GamemodeConfig`, `SoftShutdown`, `VersionTagController`, `BattlePassConfig`, `BoostConfig`,
`EmoteConfig`, `QuestConfig`, `TitlesConfig`, `DailyRewardConfig`, `FriendBonusConfig`,
`TitleStyles`, `TitleRenderer`, `AnimationLoader`, `TesterGrantService`, `BountyPlusConfig`.

**`MapCatalog` is not `MapConfig`.** The catalog is universe-wide and lists every map; `MapConfig`
is per-place, describes only that map, and must never be mirrored. The two agree on exactly one
value (`MapConfig.Id` equals the catalog row's `id`) and nothing checks it.

**When a module starts being mirrored, add it here and to the gate module's list in the same pass.** An
untracked mirror is worse than an untracked file, because it looks covered — it has gone wrong on
each of the last three additions.

The list lives in **three** prose files that must be updated together: this file, `CLAUDE.md` and
`.claude/skills/changelog/SKILL.md`. The fourth copy is **executable code** —
`rootsFor("universe")` in `.claude/skills/preflight/PreflightGates.luau`, installed in all three places
as `ServerStorage.PreflightGates`, which both `/preflight` and `/mirror` run. It is the one that
actually compares, so when the count disagrees, the module is right and the prose is stale. `CLAUDE.md`
names the count twice (the module rule and the changelog-folder table); grep for the number, not
just the list.

## Versioning scheme

Human-readable, not semver. Feature rolls are `Launch`, then `Update 1`, `Update 2`… Patches are
`Hotfix`, `Hotfix 2`, `Hotfix 3`… — a flat ascending counter that ran from Launch up to
`Hotfix 17`, because `Hotfix N.1` presumed an `Update N` to sit on top of and none had shipped.

**`Update 1` shipped 2026-08-14, so the flat counter is retired.** The next patch is **`Hotfix 1.1`**,
then `Hotfix 1.2`… and patches on `Update 2` restart at `Hotfix 2.1`.

Do **not** retro-rename the shipped flat hotfixes to `Hotfix 1.1` / `1.2` / `1.3`. The string
is baked into `GameEnvironment.version` in both places and appears in every player's on-screen
version tag, so a rename desyncs the tag from these files — which is the one thing the tag exists
to prevent.

Roblox's own place version number is internal and meaningless to players; it appears only in
the **Published** field.

## Never patch-note an exploit fix

Duplication bugs, anti-cheat changes and permission holes get full detail here and the words
*"backend improvements"* in anything a player reads. Naming the exploit publicly advertises that
it existed and invites probing for the next one.
