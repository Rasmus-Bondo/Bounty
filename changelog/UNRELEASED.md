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
  Also: `BattlePassConfig` (time-gated season blocks, Season 2), `TitlesConfig` (pass titles tagged by season).
- **Data-affecting:** yes — ranked season Token awards and title grants.
  Also: yes — Bounty Pass Season 2 (`S7`) resets every player's pass level, XP, quests, claims and Full Pass at 2026-09-19 18:00 UTC, and pass rewards now bank lootbox chests.

---

## Added

- **Bounty Pass Season 2 titles, hidden until the season flips.** Seven fire-themed ids across the four hunters at pass levels 2/7/12/17/22/27: CINDERKIN, HOT STREAK, HEAT HAZE, FORGEBORN, SUNSCORCH, EMBERLINE, ASHBORNE. One per hunter across the latest four slots, no reserved style used.

  All seven carry `hiddenUntilOwned`, which is what makes them safe to publish ahead of the season; the flag comes off in the same commit that bumps `SEASON_ID`, alongside re-badging the Season 1 seven off `pass(n)`. Reverting changes nothing player-visible — nobody owns these yet. Catalog-verified (all seven resolve through `IsValid(hunter, id)`, no duplicate ids); not playtested. The rest of the season — 21 quests, 30-row reward track, art manifest — is specced in `SEASON2_PASS_SPEC.md` and still blocked on hunter-skin and emote art.
- **Bounty Pass Season 2, *Trial by Fire*, switches itself on at Sat 2026-09-19 20:00 CEST (18:00 UTC, epoch 1789840800).** `BattlePassConfig` now holds one block per season, and `Config.SEASON_ID` / `PAID` / `FREE` / `WEEKS` / `questById` resolve to the newest block whose start has passed, so running servers roll over without a second publish. A DEV-universe server always runs the newest block, so DEV has Season 2 now, with all 21 quests open through the preview window. Studio on the live place stays on Season 1 until the flip, because it writes the live DataStore. Season 2 content: 21 new `s3w*` quests, 30 paid rows and 13 free rows, 7 fire titles, 2 lava guns, and chests replacing the dullest Cash rows. **Eight rows are ART PENDING** (issue #42): hunter skins L10/L20/L30 and emotes L3/L13/L18/L24/L28 are commented out. `exclusiveSkins` is now built from every season block, so past and upcoming pass skins stay out of the shop and chest pools.
  Reverting after 18:00 UTC on 09-19 does not un-reset anyone: profiles already stamped `S7` would roll back to `S6` with 0 XP, a second reset. Verified by loadstring with `GameEnvironment` stubbed per env (Live, Dev, Unknown) at flip−1 and flip; the week clock, per-week XP (21,500), duplicate quest types, label length (≤34) and the S6→S7 profile rollover were checked. All three copies are byte-identical (41,456 B). Not playtested.
- **Pass rewards can be lootbox chests (`kind = "chest"`, `count`).** `BattlePassService.grantReward` banks them through `LootboxService`: the paid track uses the region-gated `grantChests`, the free track uses `grantFreeChests`. A region-restricted player banks 0 on the paid track, and the level still counts as claimed. The card icon is the daily-reward crate art (`BattlePassConfig.ICONS.chest`). Verified with stubbed services: paid L4, free L13, restricted paid L26, a pending level and a linked L1 claim.
- **Dust's CinderSix-Shooter (pass L15) and Bram's MoltenGrudgekeeper (pass L29) lava gun skins are wired end to end.**
  - **Redwater:** the inner `Lava` model is renamed to `Default` / `Shotgun`, to match the other skins; runtime `Normalize` already coped, so this is art hygiene. New third-person models in `WorldModel.Skins`, seated by measuring against the default gun (they match their siblings to about 0.05 studs).
  - **Frostbite:** both first-person skins and both third-person models copied from Redwater (checksum-matched).
  - **Bounty:** lobby models in `WeaponSkins`, the lobby dummy's gun in `WeaponSkinsWorld` plus `LobbySpawn` alias entries, and `SkinCatalog` rows with no price.
  - **`PreflightGates` (all three places, `gates=16db0750`):** the resolved "named Lava" and "no WorldModel.Skins entry" standing lines are removed. The rig-clip WARNs are kept, because rig clips are unread by design, so the lava guns play Dust's and Bram's manifest animations.

  Without these, a pass claim at L15/L29 is refused (no Bounty model) and other players see the default gun. Verified by render screenshots (world grip, lobby dummy, Trading Post, Collection, pass card) and the gate run (PASS, 0 new lines in all three places). **Needs a DEV playtest:** first-person fire/fan/reload/ultimate for Dust and blast/shrapnel/reload for Bram, the third-person view from a second client, and claiming both levels.

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
- **Pass titles are tagged with their season (`pass(season, level)`).** The badge reads `BOUNTY PASS L<n>` for the live season and `BOUNTY PASS S<n>` for a past one, and an upcoming season's titles are hidden, all resolved from `BattlePassConfig.activeSeasonNumber()`. This replaces the manual flip edits `TitlesConfig` used to ask for, and the seven Season 2 titles no longer carry `hiddenUntilOwned`. Reverting it alone after the flip would badge Season 1 and Season 2 titles at the same levels. Verified by loadstring with the live season stubbed to 1, 2 and 3. Byte-identical ×3 (24,142 B).
- **A pass level with no reward row shows a COMING SOON card instead of the authored `LOREM IPSUM` placeholder** (`BattlePassClient.markPending`). The card never becomes claimable. Screenshot-checked on a paid and a free card.
- **Gun skins on pass reward cards take their pose from `WeaponDisplayConfig`, as the Collection weapon tile does.** `renderGunArt` used to flip HellFire alone, which would have put CinderSix-Shooter upside down. Bram's guns get card-only `cardRoll = 32` and `cardDistanceScale = 1.38`, so the shotgun runs corner to corner instead of clipping as a flat strip. HellFire's card is unchanged. Screenshot-checked with the real `renderGunArt` on HellFire, CinderSix-Shooter, Icefang, MoltenGrudgekeeper and FrostbiteGrudgekeeper. The caption "MOLTEN GRUDGEKEEPER" wraps to two lines, which were both readable at 1658×678; check on a phone.

## Fixed

- **Ranked Season 2 now closes and pays, on Sat 26 Sep 20:00 CEST.** It was the last row of `RANK_SEASONS`, so it had no end at all: no countdown on the leaderboard flyout, never counted as closed, and the top 100 would never have been paid. Appending the row closes it and rolls the board to `RankPoints_v6`.

  `TITLE_SEASONS` gained the season in the same change, and the two must always ship together — the `RANK_SEASONS` row alone pays the top 3 their Tokens, stamps the profile as paid, and silently grants no title.

  Revert risk: reverting a place after 26 Sep un-pays nothing, and re-publishing an older place re-opens a season that has already paid out. Verified in edit mode — all 12 Season 2 title ids mint and validate, the ladder pays 17,100 Tokens with titles at ranks 1-3 and nothing past 100, and both RP boards hold a full 100 players. Not playtested.

- **The ranked payout could pay a winner twice.** `paySeason` cleared its per-season idempotency guard, then yielded inside `fetchStandings` before writing the mark, so two `resolveFor` coroutines for the same player could both reach `Wallet.award` — 2,000 Tokens twice for the season winner. Reachable at a boundary specifically, where a join still inside its profile-wait poll overlaps the rollover sweep. Now re-checked after the yield.

  **This was live for the Season 1 payout on 12 Sep** — worth auditing the economy analytics for duplicate `TimedReward` Token grants around 20:00 CEST that day. Revert and the race returns. Verified by inspection only; reproducing it needs two concurrent joins at a season boundary, so it was not playtested.
