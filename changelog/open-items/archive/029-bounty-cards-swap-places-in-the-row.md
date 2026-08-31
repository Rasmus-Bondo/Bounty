# 29 — Bounty cards swap places in the row

[Open items index](../../OPEN-ITEMS.md) · [Conventions](../../CONVENTIONS.md)

---

**Status:** **VERIFIED by the owner 2026-08-06**, on the owner's sign-off rather than a reported
playtest run · **Sev:** P3 · **Area:** Redwater — bounty list HUD · In Studio, **not yet published**

**Reported 2026-08-05** (owner's own play): when two bounties are registered at almost the same time,
their cards can trade positions in the row. They should hold their positions. The reporter's
suspicion that near-simultaneous registration is the trigger is **correct, and it is load-bearing** —
see the 2-second window below.

**Cause — diagnosed by reading, not reproduced.** The row is ranked purely on the scaled cash value,
and that value is quantised, so two bounties started close together spend most of their life exactly
**tied** and briefly untied, flipping the tiebreak each cycle.

`Config.BOUNTY_BASE_CASH` is a **constant** (10), so `getBountyReward` (`BountyService:148`) makes
cash a pure function of how long the bounty has been up: `10 + floor(duration * 0.5)` — one cash step
every **2 seconds**. For two bounties started Δ seconds apart with **Δ < 2**,
`floor(dA * 0.5) - floor(dB * 0.5)` alternates between **1 and 0**: it is 1 for Δ out of every
2-second window and 0 for the remaining 2 − Δ. The pair is therefore tied for most of every cycle and
untied for a short slice of it — and the snapshot republishes roughly once a second, so the client
sees both states.

The two states rank the pair **differently**, which is the bug:

| State | Comparator | Winner |
|---|---|---|
| untied | `a.cash > b.cash` (`BountyService:188`) | the **older** bounty |
| tied | `a.name < b.name` (`BountyService:186`) | the **alphabetically first** holder |

When the alphabetically-first holder is the *younger* bounty, those two answers disagree and the
cards swap back and forth about once per 2s cycle for as long as both are up. **Δ ≥ 2 never ties**,
so two bounties registered well apart are stable — which is exactly why the symptom needs them
registered at almost the same time.

**The client makes it worse by re-sorting with no tiebreak at all.** `applySnapshot`
(`BountyListClient:555`) runs its own `table.sort` over the server's already-sorted array using only
`(a.cash or 0) > (b.cash or 0)`, discarding the alphabetical resolution entirely. `table.sort` is not
stable, so a tied pair lands wherever the sort happens to leave it. Slot assignment is **positional**
— `entries[index]` into `slots[index]`, no `LayoutOrder` involved despite what `BountyListClient.md`
implies — so rank *is* screen position with nothing sticky in between.

**Fix (2026-08-06) — `BountyService` + `BountyListClient`, no authoring change, no remote change.**
Ranking by cash was ranking by start time with the resolution thrown away: cash is a pure function of
`startedAt`, so sorting on `startedAt` ascending yields the identical order with no ties left to
flip. `addSnapshotEntry` now carries the timestamp onto the entry (coerced once and shared with
`getBountyReward`, so the rank key cannot describe a different moment than the cash on the card), and
the client's competing re-sort is deleted.

- **The tiebreak became `userId`, not `name`.** This was not in the diagnosis and matters: Roblox
  **display names are not unique**, so two players sharing one would hit `a.name < b.name` false in
  both directions and land straight back on an unstable sort — the same bug by a second route. It now
  fires only on an exact float tie between two `tick()` reads.
- **The client comment is the actual guard against regression.** Deleting the re-sort is one line;
  the reason it must not come back is the general one, that any second comparator over the same data
  can disagree with the first.

⚠️ **Holds only while `BOUNTY_BASE_CASH` is a constant.** If base cash ever becomes per-target
(streak-scaled, say) age and value stop agreeing and the intended order has to be decided outright
rather than derived from either one. The warning is in the code and in both vault files.

**The open design question answered itself, and needs no mechanism.** It was: should a card hold its
slot once placed, or move only on a genuine rank change? A live bounty's start time **never
changes** — `setBountyStart`'s only caller is `placeBounty`, guarded by `not getBountyStart(target)`,
and every other write to either table is a clear — so the relative order of surviving entries is
fixed for the life of the list. Cards move only when one *leaves* it, everything below shifting up,
which is the legitimate case and is what should happen. **Sticky slots would be a no-op**; the
ordering is already sticky by construction. Do not add one.

**Verified by simulation against the shipped constants, since MCP playtesting is unavailable — and
the symptom was reproduced first.** Driving both comparators over a pair placed 0.6s apart across
120 publishes at the real 1s cadence: the old one swapped on **119 of 120**, the new one on **0**.
A broader sweep of 4,000 random configurations (2–5 bounties placed within 8s of each other, 60
publishes each, 240,000 samples) found **zero** cases of a cheaper bounty ranked above a richer one
and **zero** reorders while the set was unchanged, and a claim of the oldest bounty still shifts the
rest up correctly. Both scripts compile.

*Also corrected while here:* `BountyListClient.md` claimed `applySnapshot` "assigns `LayoutOrder` by
rank". It does not — `LayoutOrder` is stamped once at registration (`slot.LayoutOrder = index`) to
fix the three authored slots in the list layout, and nothing writes it again.

**Regression checklist if this area is touched again:** get two bounties up within a second of each
other and confirm the cards hold their positions for the life of both; confirm a genuine overtake
(one bounty claimed and re-posted, so the order really does change) still reorders. Note that a
bot-only match reproduces the original bug perfectly well — bots share the list and are ranked on
the same key — so this does not need a full server to exercise.
