# Unreleased

Work that has shipped to no one yet. `/changelog` writes here; `/preflight` renames this file to
`YYYY-MM-DD-<release>.md` when the release rolls and drops a fresh empty one in its place.

**Concurrency:** several agents work this project at once. **Never `Write` this file whole.** Add
entries with `.\.claude\scripts\changelog-capture.ps1 -Add <file>` (what `/changelog` does); amend one
with an `Edit` anchored on its text after a fresh re-read. A whole-file write is the one operation that
destroys a concurrent entry without complaining.

[Index](../CHANGELOG.md) · [Conventions](CONVENTIONS.md) · Previous release: [Hotfix 3.3](2026-09-14-hotfix-3-3.md)

---

- **Shared modules:** `GameEnvironment` (RANK_SEASONS row), `TitlesConfig` (Season 2 podium titles + 7 Bounty Pass titles), `BattlePassConfig` (cadence comment).
- **Data-affecting:** yes — ranked season Token awards and title grants.

---

## Added

- **Bounty Pass Season 2 titles, hidden until the season flips.** Seven fire-themed ids across the four hunters at pass levels 2/7/12/17/22/27: CINDERKIN, HOT STREAK, HEAT HAZE, FORGEBORN, SUNSCORCH, EMBERLINE, ASHBORNE. One per hunter across the latest four slots, no reserved style used.

  All seven carry `hiddenUntilOwned`, which is what makes them safe to publish ahead of the season; the flag comes off in the same commit that bumps `SEASON_ID`, alongside re-badging the Season 1 seven off `pass(n)`. Reverting changes nothing player-visible — nobody owns these yet. Catalog-verified (all seven resolve through `IsValid(hunter, id)`, no duplicate ids); not playtested. The rest of the season — 21 quests, 30-row reward track, art manifest — is specced in `SEASON2_PASS_SPEC.md` and still blocked on hunter-skin and emote art.

## Changed

- **`HunterViewmodelContract` header comment (both match places), comment only.** It said
  "/preflight Step 2 runs it"; since the Hotfix 3.3 preflight rework the contract gate runs in Step 1
  through `ServerStorage.PreflightGates`. No behaviour change, no data. Byte-identical in Redwater and
  Frostbite (26206 B, `c737f84b`), compiles, `Hunters.Shared` match-tier fold equal.
- **Tooling: cheaper `/changelog` and a scripted GitHub release (not game code).** `/changelog` is
  now three calls and never reads a capture file or `UNRELEASED.md`. `changelog-capture.ps1` with no
  arguments prints a grouped digest, flagging `[mirrored]` modules (read from `PreflightGates.luau`),
  `[one-sided]` Redwater/Frostbite edits and names already `[in UNRELEASED]`. `-Add <file> [-Retire]`
  merges entries and metadata into `UNRELEASED.md`, then prints suspects. `-GitHubRelease [-Preview]`
  builds, creates and verifies `/preflight` Step 10's release. The skill drops from 154 to 61 lines and
  no longer carries the mirrored-module list. The capture hook runs `async` (it blocked every Studio
  mutation for ~460 ms) with a longer append retry. `gh api graphql`, `gh issue close` and
  `gh release create` are allowlisted. Rollback: revert the commit; no data, no Studio change. Verified
  on a sandbox copy of `changelog/`: the digest (mine, `-All`, no capture); `-Add` into existing,
  empty and new sections, including the metadata merge; `-Add -Retire`; `-Roll` over the merged file;
  and `-GitHubRelease -Preview`, which reproduces the Hotfix 3.3 release's tag and target. 10
  concurrent hook appends lost no lines. `-GitHubRelease` has not yet created a real release.
- **The Bounty Pass and the ranked leaderboard no longer turn over together.** Ranked resets every 2 weeks, the pass every 3, so the two boundaries coincide once every 6 weeks and sit apart the rest of the time. They shared an instant at launch and `BattlePassConfig` documented that as an invariant, which it no longer is.

  Comments only, no behaviour change. `GameEnvironment`'s `RANK_SEASONS` comment also lost the line "Nothing else changes", which was how a season came to be scheduled with no titles behind it. What this guards against is a future edit dragging `SEASON_START` back onto a `RANK_SEASONS` row, which would stretch or truncate a quest week for every player mid-season.

## Fixed

- **Ranked Season 2 now closes and pays, on Sat 26 Sep 20:00 CEST.** It was the last row of `RANK_SEASONS`, so it had no end at all: no countdown on the leaderboard flyout, never counted as closed, and the top 100 would never have been paid. Appending the row closes it and rolls the board to `RankPoints_v6`.

  `TITLE_SEASONS` gained the season in the same change, and the two must always ship together — the `RANK_SEASONS` row alone pays the top 3 their Tokens, stamps the profile as paid, and silently grants no title.

  Revert risk: reverting a place after 26 Sep un-pays nothing, and re-publishing an older place re-opens a season that has already paid out. Verified in edit mode — all 12 Season 2 title ids mint and validate, the ladder pays 17,100 Tokens with titles at ranks 1-3 and nothing past 100, and both RP boards hold a full 100 players. Not playtested.

- **The ranked payout could pay a winner twice.** `paySeason` cleared its per-season idempotency guard, then yielded inside `fetchStandings` before writing the mark, so two `resolveFor` coroutines for the same player could both reach `Wallet.award` — 2,000 Tokens twice for the season winner. Reachable at a boundary specifically, where a join still inside its profile-wait poll overlaps the rollover sweep. Now re-checked after the yield.

  **This was live for the Season 1 payout on 12 Sep** — worth auditing the economy analytics for duplicate `TimedReward` Token grants around 20:00 CEST that day. Revert and the race returns. Verified by inspection only; reproducing it needs two concurrent joins at a season boundary, so it was not playtested.
