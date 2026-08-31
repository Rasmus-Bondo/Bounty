# Open items — moved to the project board

[Index](../CHANGELOG.md) · [Conventions](CONVENTIONS.md) · [Unreleased](UNRELEASED.md) · [Archive](open-items/ARCHIVE.md)

**This file is no longer the open-items index.** Since 2026-08-31 open items live as GitHub Issues
on the project board:

### → https://github.com/users/Rasmus-Bondo/projects/1

The board is the **only** home for an open item's status, severity and detail. Do not re-add rows
here, and do not put prose in the stubs under `open-items/` — they exist solely so the links in the
published release entries keep resolving.

## How the board maps onto the old vocabulary

The `Status` column replaces the old status words. The distinction that mattered most — *fixed in
Studio is not the same as verified* — is now a column you can see at a glance:

| Board column | Old status | Means |
|---|---|---|
| **Deferred** | `DEFERRED` | Deliberately not now |
| **Open** | `OPEN` | Not started |
| **In Progress** | `INVESTIGATING` | Actively being worked |
| **Testing** | `FIXED (unverified)`, `BUILT (unverified)`, `DONE (unverified)` | Code is in Studio; **owes a human playtest**. MCP playtesting is unavailable, so closure is always a manual run-through |
| **Done** | `VERIFIED`, `WONTFIX` | Closed |

`Severity` is a separate field: **P1** breaks a match or loses player value, **P2** is visibly wrong
in normal play, **P3** is polish. Items carry `standing` or `internal` as a label.

**Closing an item** is now closing the issue. The `open-items/archive/` folder and
[ARCHIVE.md](open-items/ARCHIVE.md) keep the 99 items closed before the migration; nothing new goes
there.

**Ids were not reused.** Issue numbers are new and independent; the old item id is preserved in
each issue title's source file and in the table below. Release entries cite the **old** id.

## Old item id → issue

Severity and column are **not** recorded here — they are board state and would go stale the moment a
card moves. Read them from the board with `/issues`.

| Old id | Issue | Class |
|---|---|---|
| 132 | [#1](https://github.com/Rasmus-Bondo/Bounty/issues/1) | standing |
| 131 | [#2](https://github.com/Rasmus-Bondo/Bounty/issues/2) | standing |
| 130 | [#3](https://github.com/Rasmus-Bondo/Bounty/issues/3) | standing |
| 128 | [#4](https://github.com/Rasmus-Bondo/Bounty/issues/4) | standing |
| 127 | [#5](https://github.com/Rasmus-Bondo/Bounty/issues/5) | standing |
| 126 | [#6](https://github.com/Rasmus-Bondo/Bounty/issues/6) | standing |
| 125 | [#7](https://github.com/Rasmus-Bondo/Bounty/issues/7) | standing |
| 124 | [#8](https://github.com/Rasmus-Bondo/Bounty/issues/8) | standing |
| 123 | [#9](https://github.com/Rasmus-Bondo/Bounty/issues/9) | standing |
| 122 | [#10](https://github.com/Rasmus-Bondo/Bounty/issues/10) | standing |
| 121 | [#11](https://github.com/Rasmus-Bondo/Bounty/issues/11) | standing |
| 118 | [#12](https://github.com/Rasmus-Bondo/Bounty/issues/12) | standing |
| 117 | [#13](https://github.com/Rasmus-Bondo/Bounty/issues/13) | standing |
| 113 | [#14](https://github.com/Rasmus-Bondo/Bounty/issues/14) | standing |
| 112 | [#15](https://github.com/Rasmus-Bondo/Bounty/issues/15) | standing |
| 35 | [#16](https://github.com/Rasmus-Bondo/Bounty/issues/16) | standing |
| 50 | [#17](https://github.com/Rasmus-Bondo/Bounty/issues/17) | standing |
| 51 | [#18](https://github.com/Rasmus-Bondo/Bounty/issues/18) | standing |
| 70 | [#19](https://github.com/Rasmus-Bondo/Bounty/issues/19) | standing |
| 129 | [#20](https://github.com/Rasmus-Bondo/Bounty/issues/20) | internal |
| 109 | [#21](https://github.com/Rasmus-Bondo/Bounty/issues/21) | internal |
| 106 | [#22](https://github.com/Rasmus-Bondo/Bounty/issues/22) | internal |
| 92 | [#23](https://github.com/Rasmus-Bondo/Bounty/issues/23) | internal |
| 91 | [#24](https://github.com/Rasmus-Bondo/Bounty/issues/24) | internal |
| 90 | [#25](https://github.com/Rasmus-Bondo/Bounty/issues/25) | internal |
| 89 | [#26](https://github.com/Rasmus-Bondo/Bounty/issues/26) | internal |
| 88 | [#27](https://github.com/Rasmus-Bondo/Bounty/issues/27) | internal |
| 86 | [#28](https://github.com/Rasmus-Bondo/Bounty/issues/28) | internal |
| 85 | [#29](https://github.com/Rasmus-Bondo/Bounty/issues/29) | internal |
| 84 | [#30](https://github.com/Rasmus-Bondo/Bounty/issues/30) | internal |
| 83 | [#31](https://github.com/Rasmus-Bondo/Bounty/issues/31) | internal |
| 82 | [#32](https://github.com/Rasmus-Bondo/Bounty/issues/32) | internal |
| 81 | [#33](https://github.com/Rasmus-Bondo/Bounty/issues/33) | internal |

## Three defects this migration surfaced

Recorded because they explain discrepancies between the old file and the board:

1. **Item 125 had a file but no row** in this index — it was invisible to anyone reading the index.
   It is on the board as [#7](https://github.com/Rasmus-Bondo/Bounty/issues/7).
2. **The "Standing concerns (16)" heading listed 18 rows.** The board's count is authoritative: 33
   items migrated, 19 `standing` and 14 `internal`.
3. **Item 113 linked to item 111 at the wrong path** — 111 had been archived, so the link had been
   dead since. The issue points at the archive copy.

## Provenance of the launch numbering

Kept because it explains gaps and duplicates that otherwise look like mistakes. There is no **#2**.
Ids 1–32 are the original launch report and are all closed; 33+ were assigned when the standing
concerns became items on 2026-08-11. Ids are never reused and never renumbered — release entries
cite them by number. The full provenance note is in git history, in this file before 2026-08-31.
