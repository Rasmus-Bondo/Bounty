# 98 — Join-lock removal is unverifiable in Studio

[Open items index](../OPEN-ITEMS.md) · [Conventions](../CONVENTIONS.md)

**Closed 2026-08-15 — owner decision. Never playtested; the test below was never run.** Live since
2026-08-12 (Hotfix 15) with no recurrence reported. Closed on elapsed time, not on evidence. If it
resurfaces, raise a **new id**.

**Status:** CLOSED 2026-08-15 (never verified) · **Sev:** P2 · **Area:** cross-place — match routing
*(raised: Hotfix 15)*

---

**Symptom.** Hotfix 15 sets Redwater's `Config.JOIN_LOCK_SECONDS` to 0 and makes Bounty's
`MatchmakingService` apply the time rule only when an entry publishes a lock above 0, so a match in
its last stretch accepts new players instead of reserving them a fresh server.

**Repro.** Not reproducible in Studio at all. Routing needs MemoryStore and two or more live servers,
neither of which exists in an edit session — both modules recompile and that is the whole of the
verification.

**The test that closes it.** On live, with one match already running: join from the lobby with under
30 seconds left on that match's timer and confirm you land in **it** rather than in a fresh server
with 1 human and 4 bots. Then confirm the round rolls over and you play a full round after it.

**Expect a window of mixed behaviour on publish, and do not read it as a failure.** A lobby on the
new code reading an *old* Redwater server's entry still sees `open = false` and refuses it, so the
lock stays in force for every server on the old build until it empties out.

**Reverting is one edit in Redwater's `Config`** — but it is a cross-place contract, so publish both
or neither.

**Shipped in:** [Hotfix 15](../2026-08-12-hotfix-15.md) — last entry under `## Changed`.
