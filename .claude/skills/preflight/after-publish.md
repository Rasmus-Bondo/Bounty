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

Runs once Step 9 is committed **and pushed**, because the body carries the place versions. One call:

```
.\.claude\scripts\changelog-capture.ps1 -GitHubRelease
```

It builds the release from the newest index row and its release file: tag, title, target commit and a
short body made of the Published/rollback/Data-affecting lines, the entry's bolded one-liners and a link
to the full entry. Afterwards it reads the release back to check the versions. It refuses on `rTBD`, an
unpushed commit or a tag that already exists. The comments in the script explain each rule. Add
`-Preview` to print the release without creating it.

The body is internal, like the changelog: the repo is private, so it may name place versions and
security fixes plainly. **If the repo is ever made public, every past release becomes public with it.**

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
