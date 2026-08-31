# 105 — Ranked season 3 boundary is unverified on live

[Open items index](../OPEN-ITEMS.md) · [Conventions](../CONVENTIONS.md)

**Closed 2026-08-15 — owner decision. Never verified, and the moment has passed.** The season 3
boundary fired 2026-08-14 18:00 UTC / 20:00 CEST and nobody checked the rollover while it was
happening; the one-shot event cannot be re-run. No player complaint about lost RP followed. Closed
on elapsed time, not on evidence. If a boundary defect surfaces at season 4, raise a **new id**.

**Status:** CLOSED 2026-08-15 (never verified) · **Sev:** P1 · **Area:** both places — GameEnvironment, ranked
*(raised: Hotfix 16)*

---

**Symptom.** Not a defect — a scheduled event that has not happened yet. Ranked season 3 begins at
epoch `1786730400` = **2026-08-14 18:00 UTC / 20:00 CEST**, moving the leaderboard to `RankPoints_v3`
and zeroing each profile's `RankPoints` lazily on its first award past the boundary.

**Repro.** The rollover was exercised in an edit session by shimming `os.time` over the live source:
`17:59:59 → RankPoints_v2`, `18:00:00 → RankPoints_v3`. That proves the resolver, not the live
round-trip — the OrderedDataStore write is not exercisable in Studio without API services enabled.

**The test that closes it.** After 2026-08-14 18:00 UTC, on live:

1. Open the lobby leaderboard. **Expect it empty**, or near-empty — not the season 2 top 100. A stale
   board past the boundary would mean `RankLeaderboardService` did not flush its row caches.
2. Play a Redwater round and earn RP. **Expect** the post-game card to show the gain, and the player to
   appear on the board with only that round's total.
3. Confirm a player who had RP before the boundary now shows their **new** total, not the old one.

**Publish before the boundary, not after.** Servers resolve the season from `os.time()` per call and
roll over unattended, but only servers already running this build — so publish, then *Shut Down All
Servers*.

**The revert stops being clean the moment step 2 succeeds.** Deleting the season row restores the
season 2 board intact (`RankPoints_v2` is never written to or deleted) but never restores RP on a
profile already zeroed.

**Not aligned to the battle-pass boundary**, deliberately — `BattlePassConfig.SEASON_START` is
unchanged and that season runs to 2026-08-21 17:00 UTC. The first reset shared one instant with it;
this one does not.

**Shipped in:** [Hotfix 16](../2026-08-13-hotfix-16.md) — first entry under `## Changed`.
