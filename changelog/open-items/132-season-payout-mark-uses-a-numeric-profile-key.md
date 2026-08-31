# 132 — The season payout's idempotency mark uses a numeric profile key, so a winner is paid again on every rejoin

[Open items index](../OPEN-ITEMS.md) · [Conventions](../CONVENTIONS.md)

---

**Symptom.** `RankSeasonRewardService` records a paid season as `data.RankRewards[season] = rank`
(line 155, checked at line 133) with a **number** key. DataStore serialises the profile through
JSON, which turns a numeric key into a string one — written as `[4]`, read back as `["4"]`. The
mark therefore holds for the rest of the session and is invisible on the next load: the join path
re-pays the same season. Tokens through the Wallet, the season titles, and the `GiftNotice` card,
once per rejoin, for as long as that season stays inside `MAX_SEASON_LOOKBACK` (6 seasons, roughly
three months).

**Deadline: Saturday 2026-09-12, 20:00 CEST.** Nothing has ever been paid on live —
`FIRST_REWARDED_SEASON = 4` and season 4 does not close until then, so `payableSeasons()` is empty
until that boundary. Until then this is unreachable in production. After it, it is uncapped Token
inflation across the top 100 that only manual profile surgery can undo.

**Repro.** Seen on DEV during the 2026-08-29 payout dry run: the reward kept landing. Bank RP into
a DEV season, cross the boundary, collect the payout, rejoin — paid again, same season. Note the
DEV mock schedule (see [129](129-dev-only-mock-season-schedule-must-be-removed.md)) also closes
**two** seasons on 2026-08-29, at 18:00 and 20:00 CEST, so a second card for a *different* season
that evening is correct behaviour and not this bug.

**Mechanism, confirmed in Studio.** `HttpService:JSONEncode({[4] = 12})` → `{"4":12}`; after
decode, `t[4]` is `nil` and `t["4"]` is `12`. The rest of the profile already stringifies for
exactly this reason — `DataService`'s template documents `[tostring(step)]` and
`[tostring(level)]`, and offline gifts key on `tostring(updateId)`.

**Fix.** Stringify the season at both sites, the read at line 133 and the write at line 155.
Bounty-only; `RankSeasonRewardService` is not mirrored. No migration is owed: live carries neither
key form, because it has never paid.

**Closing test.** On DEV, finish inside the top 100 of a season, cross its boundary, take the
payout, then rejoin twice: the card must appear exactly once and the Token balance must not move
on either rejoin. Then read the profile back and confirm `RankRewards` carries a string key.
*(raised: ranked season rewards, 2026-08-29)*
