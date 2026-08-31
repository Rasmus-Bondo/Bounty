# Ranked System Design (Alternative) — Rank Points, No-Punishment

An alternative to [[ranked_system_design]] (Elo-vs-the-field). Written for a young player base: **you never lose points for playing badly, and grinding always pays off** — only the Elo-based design's "loss" mechanic is removed; everything else about scope carries over.

## Scope

- Every Redwater Canyon round is ranked — no separate casual/ranked queue.
- Rating is **tracking + leaderboard only** — it does not affect matchmaking or lobby assignment.
- Kept separate from [[ProgressionService]]'s XP/Cash/Level economy — that's progression-through-playing, this is a skill/performance score.

---

## Core Idea

Instead of comparing your performance to an "expected" value (which requires the possibility of falling short and losing points, as in the Elo design), Rank Points (RP) are **strictly additive** — computed directly from what you did in the round, floored at 0. No comparison to opponents' ratings, no Elo machinery, no way to go negative.

## Rank Points Formula (per round)

```
RP = Kills * 3
   + Assists * 1
   + Headshots * 1
   + PlacementBonus   (1st = +15, 2nd = +10, 3rd = +6, top half of lobby = +3, rest = 0)
   + StreakBonus      (max(0, bestKillStreak - 2) * 2)
```

Every term is ≥ 0, so RP for a round can never be negative — worst case is exactly **0**, never a loss. Deaths are not part of the formula at all; punishing deaths is exactly what this design avoids.

A truly empty-handed round (0 kills, 0 assists, 0 headshots, last place) awards **exactly 0 RP** — no participation floor. Bad play gains nothing; it never costs anything.

---

## Worked Example

| Game quality | Kills | Assists | Headshots | Placement | Best streak | RP breakdown | Total RP |
|---|---|---|---|---|---|---|---|
| Great game | 15 | 5 | 8 | 1st (+15) | 6 (+8) | 45+5+8+15+8 | **81** |
| Average game | 4 | 1 | 1 | mid-table (+3) | 2 (+0) | 12+1+1+3+0 | **17** |
| Bad game | 0 | 0 | 0 | last (+0) | 0 (+0) | 0+0+0+0+0 | **0** |

A great game is worth roughly **4-5x** an average one. A bad round costs nothing — the player simply doesn't move.

---

## Why Grinding Still Pays Off

RP never decays and never resets, so total RP is a running sum across every round ever played. An average player earning ~17 RP/round who plays constantly will out-accumulate a skilled player who only plays occasionally — volume compounds the same way skill does, just on a longer timescale. That's the built-in reward for players who like to grind, with no separate mechanic required.

---

## Tiers

Tiers are **one-way milestones** rather than something a player can fall out of — a natural fit here since RP only ever increases. Rough thresholds using the average-game rate (~17 RP/round) as a guide:

| Tier | RP threshold | ~Games to reach |
|------|--------------|-----------------|
| Drifter | 0 | — |
| Gunslinger | 500 | ~30 |
| Outlaw | 2,000 | ~120 |
| Legend | 6,000 | ~350 |

Once reached, a tier is permanent — no demotion.

---

## Leaderboard

Same mechanism as the Elo design:
- A dedicated **OrderedDataStore**, written once per player per round end.
- Displayed in the **Bounty lobby** (top ~100 + "your rank" nearby-lookup).
- Sorted by total RP instead of Elo rating.

---

## Honest Tradeoff

Since nothing ever goes down, this is no longer a live "how good are you right now" estimate — it's a permanent performance score, closer to a second XP bar than a competitive rating. A dedicated grinder will eventually out-rank a newer, more skilled player. That's an acceptable tradeoff here since rating already doesn't drive matchmaking in either design — but worth naming explicitly since it's the key difference from the Elo-based approach.

---

## Status

This design has **not** replaced [[ranked_system_design]] — both are being kept as options until a direction is chosen. Decided so far:
- Bad rounds award exactly 0 RP (no participation floor).
- This system stays separate from Elo design for comparison, not yet adopted.

## Open Questions

- Whether to formally choose this over the Elo-based design, combine ideas from both, or keep exploring further alternatives.
- Exact RP-per-action weights and tier thresholds — the numbers above are a reasonable starting point, not tuned/playtested.
- Whether a season reset ever makes sense given RP is designed to be permanent (may be moot if the whole point is "no punishment, ever").
