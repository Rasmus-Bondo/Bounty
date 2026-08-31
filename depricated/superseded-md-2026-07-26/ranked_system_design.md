# Ranked System Design

## Scope

- Every Redwater Canyon round is ranked — no separate casual/ranked queue.
- Rating is **tracking + leaderboard only** — it does not affect matchmaking or lobby assignment. Server/lobby fill works exactly as it does today.
- Kept separate from [[ProgressionService]]'s XP/Cash/Level economy — that's progression-through-playing, this is skill rating.

---

## Rating Algorithm — "Elo vs. the Field"

Standard Elo assumes 1v1. Redwater Canyon is FFA with a variable player count per round, so instead of running pairwise Elo across every pair in the lobby (O(n²)), each player gets **one update per round** by comparing their placement to an expected placement derived from their rating vs. the lobby average (O(n)).

### Step 1 — Placement score

Where you finished, normalized to 0–1:

```
placementScore = (N - placement) / (N - 1)
```

1st place = 1.0, last place = 0.0, evenly spread between.

### Step 2 — Expected score

Standard Elo win-probability formula, using the average rating of everyone *else* in the lobby as the "opponent":

```
expected = 1 / (1 + 10^((avgOpponentRating - myRating) / 400))
```

Rating above the lobby average → expected pushes toward 1 (you're supposed to do well). Below average → expected pushes toward 0.

### Step 3 — Delta

```
delta = K * (placementScore - expected)
```

You gain when you outperform your rating's expectation, lose when you underperform it. Your placement alone doesn't determine gain/loss — only how it compares to what your rating predicted.

### K-factor

- **K = 32** for a player's first 5 games (provisional) — rating moves fast to find its true level.
- **K = 16** after — swings settle down so one bad round doesn't tank a stable rating.

### Other mechanics

- **Ties** (equal kills): average the placement scores across tied ranks — e.g. two players tied for 2nd/3rd both use placement 2.5.
- **Rounding**: delta rounds to the nearest whole number before applying.
- **Floor**: rating can't drop below 0.
- **Early leavers**: players who leave before round end get no rating change (avoids punishing/rewarding disconnects).
- **Minimum lobby size**: rounds with fewer than 3 players don't award rating changes — not enough signal, avoids weird 1v1-style edge cases.

---

## Worked Example

6-player round, ratings before the game: A=1200, B=1100, C=1000, D=1000, E=900, F=800. Finish order by kills: C, A, E, D, B, F.

| Player | Rating | Placement | placementScore | avg opponent rating | expected | delta (K=32) |
|--------|--------|-----------|-----------------|----------------------|----------|--------------|
| C | 1000 | 1st | 1.00 | 1000 | 0.50 | **+16** |
| A | 1200 | 2nd | 0.80 | 960  | 0.80 | **~0**  |
| E | 900  | 3rd | 0.60 | 1020 | 0.33 | **+9**  |
| D | 1000 | 4th | 0.40 | 1000 | 0.50 | **-3**  |
| B | 1100 | 5th | 0.20 | 980  | 0.67 | **-15** |
| F | 800  | 6th | 0.00 | 1040 | 0.20 | **-6**  |

**Reading the results:**

- **C** won and was only expected to perform "average" (rating equal to the lobby), so the win is worth a big gain.
- **A** placed 2nd, which is almost exactly what the highest rating in the lobby predicted — expectation met, so almost no change.
- **E** placed 3rd despite being one of the lower-rated players in the lobby — outperformed expectation, solid gain.
- **B** was the 2nd-highest rated player but placed 5th — badly underperformed expectation, the biggest loss in the round.
- **F** placed dead last but was already the lowest-rated player, so the system half-expected it — a small loss, not a crater.
- Deltas roughly cancel out across the lobby (+16 + 0 + 9 - 3 - 15 - 6 ≈ 0), keeping the overall rating pool stable instead of inflating over time.

---

## Data & Persistence

New fields on the player profile (added to [[DataService]]'s profile template, backfilled via the existing `Reconcile()` pattern used for RedeemedCodes/Settings):

| Field | Purpose |
|-------|---------|
| `Rating` | Current skill rating, starts at 1000 |
| `GamesPlayed` | Drives the provisional K=32 window (first 5 games) |
| `PeakRating` | Career-high rating, for profile/leaderboard flex |
| `Wins` | Total 1st-place finishes |

### Global leaderboard

- A dedicated **OrderedDataStore** (separate from the ProfileService store, which only holds sorted numeric keys).
- Written once per player per round end — not per-kill — to stay well under DataStore write limits.
- Displayed in the **Bounty lobby** (top ~100 + "your rank" nearby-lookup), since it's the persistent hub and Redwater Canyon servers are transient.

---

## Round-End Flow

1. [[RoundController]] determines final placements by kill count (already does this for winner selection).
2. New `RankedService` (peer to [[ProgressionService]], depends on [[DataService]]) computes each player's delta and applies it to their profile.
3. The rating delta rides along in the existing `VictoryShowcase` payload built by `buildPostGameStats()` — no new remote needed. VictoryShowcaseClient can show something like `1000 → 1018 (+18)` next to the existing XP bar animation.
4. Leaderboard OrderedDataStore is updated with the new rating.

---

## Display

- Western-flavored tiers, purely cosmetic on top of the numeric rating: **Drifter → Gunslinger → Outlaw → Legend**.
- Shown in the Bounty lobby and on the leaderboard.
- Tier rating bands and season/reset policy are still open — TBD before implementation.

---

## Open Questions

- Exact rating bands for each tier.
- Whether to add a season reset / decay mechanism, or let rating run indefinitely (simplest for v1).
