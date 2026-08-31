# 57 — The duplicate kill-feed line is guarded, not diagnosed

[Open items index](../../OPEN-ITEMS.md) · [Conventions](../../CONVENTIONS.md)

**Closed 2026-08-11** — owner review of the standing-concern list.

---

**The duplicate kill-feed line is guarded, not diagnosed.** `KillFeedGate` refuses a second
announcement for a death already announced — sound on its own terms, since a character can only
die once — but every announcing path was audited and each already tested correctly for the
killing blow, so **the cause is still unknown and could not be reproduced by reading**. The guard
writes a detailed warning naming both announcements and their origins whenever it catches one.
**Read the next live log export**: warnings appearing is the good outcome, and they are the only
route to the root cause.

**First sample, 2026-08-05: no catches logged — and that settles nothing in either direction.**
Do not read a clean log as "fixed and understood". The guard only speaks when it blocks a
duplicate, so silence means the race did not occur in that sample, not that it cannot. The
original report came from real play, so it does happen; the sample was a handful of matches,
largely against bots, on a build hours old. Three things have to accumulate before absence of
warnings becomes evidence: **enough live player-vs-player deaths** (a bot's killing blow takes a
different path), **varied latency**, and **round boundaries**, which is where the related #20 race
concentrated. Until then #10 stays `FIXED (unverified)` — the symptom is suppressed by
construction, which is exactly why the symptom disappearing is not a signal.
*(raised: #10, [Hotfix 6](../../2026-08-05-hotfix-6.md))*
