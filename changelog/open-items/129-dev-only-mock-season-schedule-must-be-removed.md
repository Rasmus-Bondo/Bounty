# 129 — The DEV-only mock ranked-season schedule is a test fixture and must be removed after 2026-08-29

[Open items index](../OPEN-ITEMS.md) · [Conventions](../CONVENTIONS.md)

---

**`GameEnvironment.DEV_RANK_SEASONS` exists only to dry-run the ranked season payout before it
first pays for real on 2026-09-12.** It adds two rows the live table does not have — season 4
opening at `1787788800` (2026-08-27 02:00 CEST, already past) and season 5 at `1788019200`
(2026-08-29 18:00 CEST), the boundary that closes season 4 and makes `RankSeasonRewardService`
pay it out roughly two to three minutes later.

**It cannot affect live.** `seasonTable()` branches on `GameEnvironment.env == "Dev"`
explicitly — never on `not isLive` — so an unpublished Studio place, which resolves to `"Unknown"`
via the `ENVIRONMENTS` fallback, gets the LIVE schedule. Verified by forcing all three env values:
`Live` and `Unknown` both enumerate the unchanged four live boundaries and have nothing payable
either now or on Saturday; only `Dev` sees the mock rows.

**Why it still has to go.** DEV season numbers are shifted **+2** against live from here on, so
DEV writes `RankPoints_v4` for a different window than live's. That is harmless while it lasts —
DEV is a separate experience with its own DataStores — but it is a permanent divergence in a
mirrored module, and a stale mock schedule is exactly the kind of thing that gets read as
intentional a month later.

**Closing test:** delete `DEV_RANK_SEASONS` and `seasonTable()`, restore `getRankSeason` and
`getRankSeasonEnd` to read `RANK_SEASONS` directly, mirror across all three places and verify
byte-identical. Then confirm a DEV server reports the same season number as live.

**Note if the mock payout is not observed on Saturday:** the most likely cause is not the
schedule but an empty store — `RankPoints_v4` on DEV starts empty and an empty season correctly
pays nobody, so someone has to play at least one DEV Redwater round before 18:00 CEST to bank RP
into it.
*(raised: ranked season rewards, 2026-08-27)*
