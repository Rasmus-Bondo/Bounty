---
name: issues
description: Read and manage the project board - the single home for this project's issues (known problems, deferred work). Lists open issues with their board column and severity in one call, opens new ones, and moves or closes existing ones. Use whenever you need to know what is outstanding, when a release raises a concern that outlives it, or when work closes an issue.
---

# The project board

**https://github.com/users/Rasmus-Bondo/projects/1** — the only home for an issue. There is no
markdown list; `changelog/OPEN-ITEMS.md` and `changelog/open-items/*.md` are redirect stubs kept
alive only so links in published release entries still resolve. Never write to them.

**The board is authoritative, and the owner drags cards on it.** A card that moved is not a
discrepancy to query — it is the owner's decision, already made. In particular **`Done` means done:
never re-verify it, never ask whether it is really finished, never reopen it to check.** Read the
column, believe it, move on.

## Read the board

**One query, ~1s, no issue bodies.** Copy it as-is:

```bash
gh api graphql -f query='
{ node(id:"PVT_kwHOBK9TF84BiCdN"){ ... on ProjectV2 { items(first:100){ nodes{
  content{ ... on Issue { number title state } }
  fieldValues(first:20){ nodes{ ... on ProjectV2ItemFieldSingleSelectValue {
    name field{ ... on ProjectV2SingleSelectField{ name }}}}}
}}}}}' --jq '.data.node.items.nodes[]
  | select(.content.state=="OPEN")
  | "\([.fieldValues.nodes[]|select(.field.name=="Status")|.name][0])\t\([.fieldValues.nodes[]|select(.field.name=="Severity")|.name][0])\t#\(.content.number)\t\(.content.title)"' | sort
```

Filter in the `select(...)` rather than after — e.g. add
`| select([.fieldValues.nodes[]|select(.field.name=="Status")|.name][0]=="Testing")`.

**Do NOT use `gh project item-list --format json`.** It embeds every issue's full body — about
80 KB across the board — and will flood your context for what should be a one-line list.

`gh issue list` is fine and faster when you only need titles, labels or state, but **it cannot see
the board columns**: `Status` and `Severity` are project fields, not issue properties. If the
question is "what is in Testing", it must be the GraphQL query above.

## What the columns mean

| Column | Means |
|---|---|
| **Deferred** | Deliberately not now |
| **Open** | Not started |
| **In Progress** | Actively being worked |
| **Testing** | Code is in Studio and **owes a human playtest**. MCP playtesting is unavailable, so closure is always a manual run-through. Not closed |
| **Done** | Finished. Not a question |

`Severity`: **P1** breaks a match or loses player value · **P2** visibly wrong in normal play ·
**P3** polish. Every issue also carries `standing` (raised by a release) or `internal` (tooling,
data, infrastructure).

## Renaming or reordering a column

**Pass the existing option `id` for every option**, and pass *all* of them — `updateProjectV2Field`
replaces the whole option set. Omit the ids and every card silently loses its column; there is no
warning and no undo. Read the current ids first, change only what you mean to change, then re-read
the item counts to confirm nothing was dropped.

## Open an issue

The issue holds **symptom, repro, and the test that closes it**. Diagnosis does *not* go here — it
goes in the release entry that shipped the fix, once. Tag the body `(raised: <release name>)`.

```bash
gh issue create --repo Rasmus-Bondo/Bounty --title "..." --body-file <file> --label standing,P2
```

Then put it on the board and set its fields:

```bash
NID=$(gh issue view <n> --repo Rasmus-Bondo/Bounty --json id --jq .id)
IID=$(gh api graphql -f query="mutation{addProjectV2ItemById(input:{
  projectId:\"PVT_kwHOBK9TF84BiCdN\",contentId:\"$NID\"}){item{id}}}" \
  --jq '.data.addProjectV2ItemById.item.id')
gh api graphql -f query="mutation{updateProjectV2ItemFieldValue(input:{
  projectId:\"PVT_kwHOBK9TF84BiCdN\",itemId:\"$IID\",
  fieldId:\"PVTSSF_lAHOBK9TF84BiCdNzhg75wU\",
  value:{singleSelectOptionId:\"<status id>\"}}){projectV2Item{id}}}"
```

Same mutation with `fieldId` `PVTSSF_lAHOBK9TF84BiCdNzhg79YE` sets `Severity`.

**Ids** — Status: `Open` e7cc2fe9 · `In Progress` 9fac5fe2 · `Testing` 0caf8cf4 ·
`Deferred` dc65173a · `Done` 055ec7e3. Severity: `P1` aa1197c7 · `P2` 671d55ad · `P3` 78806ba8 ·
`Unset` c6025581. Project id `PVT_kwHOBK9TF84BiCdN`.

## Close an issue

`gh issue close <n> --repo Rasmus-Bondo/Bounty -c "<basis>"`. **The comment states the basis** —
*playtested* or *elapsed time without recurrence*. "Shipped and tested" and "shipped and nothing
broke" are different claims and the comment is the only thing that distinguishes them later. A
problem that resurfaces becomes a **new issue**, never a reopened one.

## Old ids

Release entries published before 2026-08-31 cite items by their **old** number, which does not
match the issue number — old item 132 is issue #1.

**This collides, and it fails silently.** Old ids and issue numbers occupy the same range: a
release entry saying "item 12" translates to issue #12 only by coincidence — issue #12 is actually
old item 118. `gh issue view 12` succeeds and hands you the wrong issue with no error. **Always
translate through the mapping table in `changelog/OPEN-ITEMS.md` before looking a cited number up.**
The overlap widens as the board grows past #33.

New work takes an issue number and no old id.
