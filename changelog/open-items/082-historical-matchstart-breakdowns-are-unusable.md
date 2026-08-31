# 82 — Historical `MatchStart` breakdowns are unusable for hunter pick rate, and cannot be repaired

[Open items index](../OPEN-ITEMS.md) · [Conventions](../CONVENTIONS.md)

---

**Historical `MatchStart` breakdowns are unusable for hunter pick rate, and cannot be repaired.**
Until the fix in `UNRELEASED.md` ships, ~65% of rows carry `Unknown|Unknown` (2,604 of 3,977 over
the 7 days to 2026-08-05), and the surviving third is biased toward the player who seeded each
server rather than merely being a smaller sample. Custom events do not backfill, so this window is
gone — **date-bound any pick-rate chart to after the fix publishes.** `HunterSwitch` is unaffected
throughout (it fires on a mid-round respawn, when both fields have long resolved), and
`MatchDeaths` broken down by CustomField03 is the correct proxy for the historical window since its
hunter comes from `stats.hunterLabel` at the buzzer. *(raised: MatchStart Unknown fields,
2026-08-05)*
