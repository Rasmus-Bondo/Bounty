# 92 — Match players into Redwater by ping

[Open items index](../OPEN-ITEMS.md) · [Conventions](../CONVENTIONS.md)

**Area:** Matchmaking · **Sev:** — · **Status:** BUILT (unverified)
**Raised:** owner request 2026-08-05 · **Built:** 2026-08-15

---

## Symptom

Matchmaking sorted on one axis: fullest-first, regardless of where in the world the match was, so a
player could be packed into a server on another continent and play the whole round at 250-300ms.

Built 2026-08-15 as a region filter in `MatchmakingService` — see the release entry. **Nothing is
known to be wrong; what is missing is that no routing decision has ever run against real players.**

## Two deviations from this item as originally written

Both were the owner's explicit call on 2026-08-15 and should not be "corrected" back by a later
reader of the original text:

1. **A hard filter, not a soft preference.** This item argued for a preference that relaxes, on the
   grounds that splitting a small pool risks bot-heavy matches. The owner chose the opposite trade
   — *"I would rather play against bots than play a match with 300 ping, it's unplayable for an FPS
   to run nice on so high ping."* The bot cost is accepted, not overlooked.
2. **Region is stamped at reservation, not inferred from members.** This item listed the modal
   country of current members as a proxy. That was rejected: a friend join from another continent
   would shift a running server's published region and pack the wrong people into it for the rest
   of its life. The value is resolved once, from the reserving party, and never recomputed.

The constraint that **parties outrank ping** was kept — a party takes one region (the owner's) and
is never split.

## The assumption the whole design rests on

**That Roblox allocates a reserved server in a datacenter near whoever joins it first.** This item
flagged it on 2026-08-05 as "verify it first"; it still has not been verified, because it cannot be
from Studio — `ReserveServer` does not create the instance, and there is no API that reports where
one lives. It is standard observed behaviour and undocumented.

It is load-bearing: it is what makes "no local match open → reserve a fresh one" produce a *local*
server, which is the only reason a hard filter can have no cross-region fallback without stranding
anyone. If it is false, the pool fragments and buys nothing.

## Repro

Not applicable — first-run verification, not a defect. Studio cannot exercise any of it: MemoryStore
needs API access, teleports do not run in playtests, and the gate needs concurrent players in two
regions.

## The test that closes it

Read the new `MatchPing` event on the Creator Hub (value = ping ms, CF02 = the server's region,
CF03 = `bucketPing`) once live traffic has accumulated, and check three things:

1. **Same-region rows should sit under ~100ms.** Volume above that means either the datacenter
   assumption above is false, or a country is in the wrong bucket. `RegionService`'s table is the
   place to look; the buckets are datacenters, not continents.
2. **`Unknown` in CF02 should be rare.** Each one is a server that lost its region write and is
   therefore advertised to every continent — a hole in the gate, not a cosmetic gap.
3. **Whether the fragmentation cost is real.** Compare match sizes against the previous release. If
   a region is too thin to ever produce a second concurrent player, everyone in it plays bots
   indefinitely — the accepted downside, and the point at which the answer is to merge two buckets,
   not to weaken the filter.

Also worth one live check that needs no chart: a party spanning two regions must still land in one
match together.

## Release entry

Region-based matchmaking, in [Hotfix 1.1](../2026-08-15-hotfix-1-1.md).
