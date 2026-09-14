---
name: changelog
description: Turn this session's raw Studio-mutation capture in .changelog/pending/ into prose entries in changelog/UNRELEASED.md. Use after a work session, or whenever the user asks to update the changelog. Pass "all" to sweep every session's capture before a release.
---

# Update the changelog

A `PostToolUse` hook logs every Studio mutation to `.changelog/pending/<session>.jsonl`, one file per
pane. This skill turns yours into entries in `changelog/UNRELEASED.md`, in three calls. **Never `Read`
a capture file or `UNRELEASED.md` for it** — the script digests the one and writes into the other.

## 1. Digest

```
.\.claude\scripts\changelog-capture.ps1
```

Your capture grouped by place and script with tool counts, flags explained at the bottom, and the
current section counts of `UNRELEASED.md`. **Curate only your own capture.** With none, say so; work
the hook cannot see (`execute_luau`, hand edits in Studio) is still written up from what you did.

**`all`** (`/changelog all`, the pre-release sweep): add `-All` to the digest and to step 3. Called by
`/preflight`, just sweep. Called on its own, first name the sessions you are about to absorb.

## 2. Write the entries to a scratchpad file

```markdown
- **Shared modules:** `Wallet` (new `ChestRefund` reason).
- **Data-affecting:** yes — new Wallet reason.

## Fixed

- **One bolded line saying what is different in the game.** Then what breaks if you revert it and
  the verification basis, in one to three short paragraphs.
```

- The two metadata bullets are optional: include **Shared modules** only when a `[mirrored]` module
  was touched, **Data-affecting** only when it is yes (Wallet reasons, XP curve, RP awards,
  battle-pass grants, profile shape — reverting a place does not undo those).
- Sections are `## Added` / `## Changed` / `## Fixed`. One bullet per change, grouped by subsystem,
  not by tool call. Describe the change, not the edit: *"Servers evacuate players to the lobby on
  shutdown"*, not *"Set source of SoftShutdown"*.
- Don't re-explain a mechanism already commented in the source. The exception is an entry cited by
  a board issue, which carries the diagnosis (`changelog/CONVENTIONS.md`).
- Exploit, duplication and anti-cheat fixes get full detail here, because this file is internal. Only
  player-facing text says "backend improvements".

## 3. Add and retire

```
.\.claude\scripts\changelog-capture.ps1 -Add <file> -Retire
```

Appends each section under its heading, merges the metadata (a `no` never overwrites a peer's `yes`),
prints your SUSPECTS and moves your capture to `.changelog/consumed/`. A SUSPECT is a captured name
that no entry mentions. Often that is correct, because entries are written in player terms. If one
turns out to be forgotten work, run `-Add` again with just that entry. **Don't add script names only
to clear the list.**

To amend an existing entry, `Grep` for it and `Edit` it. Never delete, empty or hand-edit a capture
file, and never retire another pane's (without `-All`, `-Retire` only takes yours).
