# Preflight — after the publish (Steps 9–11)

Read this only once the user has published all three places and reported the new place versions.
Steps 10 and 11 are skipped in `check` mode.

## Step 9 — Record the place versions

Replace `rTBD` in the release file's **Published** field with the reported numbers — e.g.
`` `Bounty r2768 · Redwater r3168 · Frostbite r756` — published 2026-09-13. `` — then run
`.\.claude\scripts\changelog-capture.ps1 -SyncIndex`, which copies it into the index row. The release
file is the one home; never edit the index cell by hand. This is the rollback index: an entry without
versions cannot be reverted to, and `-Roll` refuses to roll the next release on top of it.

**Take the numbers as given.** `game.PlaceVersion` in a Studio edit session is frozen at the moment the
file was opened, so it is not a cross-check. A version that looks like it moved backwards is far more
likely a typo in the message: ask the user to re-read it.

Commit and push the release file + `CHANGELOG.md` (explicit paths).

## Step 10 — Cut the GitHub release

Runs after Step 9, because the body carries the place versions. Internal, like the changelog: the repo
is private, so the body may name place versions and describe a security fix plainly. **If the repo is
ever made public, every past release becomes public with it** — the exploit rule would then apply to
these bodies retroactively.

- **Tag:** the dated filename without the date — `2026-08-29-update-2.md` → `update-2`. The human version
  string has a space and cannot be a git ref. Tags are never reused.
- **Target the commit that carries the dated release file**, not whatever `main` is by now — other
  sessions may have pushed since.

```bash
gh release create <tag> --repo Rasmus-Bondo/Bounty --title "<human version string, e.g. Hotfix 1.3>" --target <sha> --latest --notes-file <file in the scratchpad>
```

**Body — five to ten lines, never the entry itself:**

```
**Published 2026-09-05** · Bounty r2481 · Redwater Canyon r2733 · Frostbite Claim r410
**Rollback lands on:** Bounty r2475 · Redwater r2726 · Frostbite r406
**Data-affecting:** no

- <one line per change, lifted from the entry's own bolded summaries>

Full entry: https://github.com/Rasmus-Bondo/Bounty/blob/main/changelog/<release>.md
```

Lift the bullets from the entry's bolded one-line summaries; do not rewrite them. **Verify** with
`gh release view <tag> --repo Rasmus-Bondo/Bounty` that the versions match `CHANGELOG.md` — a release
whose numbers disagree with the index is worse than none.

## Step 11 — Draft the public Discord post

**Deliberately last:** the user posts only after walking the live places and saying the release looks
right. Drafting earlier produces a message that waits through the part most likely to send everything
back to Step 1.

A player-facing announcement for the public `#changelog` channel, **2000 characters maximum** —
Discord's hard per-message limit; a longer post fails to send rather than truncating. Count the
characters and state the count with the draft.

**Derive it from the release entry, never paste it** — the entry carries place versions, rollback
targets, schema notes and security fixes, none of which go in front of players.

- **Never name an exploit fix.** Duplication bugs, anti-cheat changes and permission holes are
  *"backend improvements"* and nothing else.
- **No internal identifiers** — no script, module, remote or service names, no place versions or ids.
  *"The Collection menu now loads properly when you join"*, not *"CollectionClient re-requests on join"*.
- **Lead with what a player will notice** — new content first, then annoyances now fixed. Refactors,
  vault and graph work and anything invisible in-game are left out, however long they took.
- **The release name is the title**, matching the in-game version tag.

Discord formatting: `##` title, `###` sections, `-` bullets; tables, HTML and nested indentation do not
render. One line per bullet, the changed thing in bold, at most a couple of emoji as section markers.

```
## Update 1

### 🆕 New
- **<feature>** — one line on what it does for the player.

### ⚙️ Improved
- **<thing>** — what is better now.

### 🐛 Fixed
- <the annoying thing, described as the player experienced it>
```

Present it in a fenced block with the character count underneath. If it is awkward to copy from the
terminal, write it to the scratchpad and give the path. Never write it into `changelog/`, and **do not
post it yourself.**
