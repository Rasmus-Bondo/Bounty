# 100 — Friend-join and tutorial-dispatch fixes are unverified on live

[Open items index](../OPEN-ITEMS.md) · [Conventions](../CONVENTIONS.md)

**Closed 2026-08-15 — owner decision. Never playtested; the test below was never run.** Live since
2026-08-13 (Hotfix 16) with no recurrence reported. Closed on elapsed time, not on evidence. If it
resurfaces, raise a **new id**.

**Status:** CLOSED 2026-08-15 (never verified) · **Sev:** P1 · **Area:** cross-place — join routing, onboarding
*(raised: Hotfix 16)*

---

**Symptom.** Hotfix 16 splits the single "your friend's match has already ended" answer into four
distinct outcomes, adds a tutorial-server marker map, retries a directory miss on its own ladder, and
lets `TutorialDispatchService` claim a follow-joiner only after `FollowJoinService` gives up. None of
it has been run.

**Repro.** Not reproducible in Studio. The path needs MemoryStore, two live servers and two accounts;
an edit session has none of them. Every touched script recompiles and that is the whole of the
verification.

**The test that closes it.** On live, with two accounts:

1. Account A starts the onboarding tutorial. Account B joins A from the Roblox app. **Expect** B to get
   the tutorial-specific message, not "match already ended".
2. Account A joins a normal Redwater match. B joins A from the app. **Expect** B forwarded into A's
   server.
3. Account A leaves the match entirely. B joins A from the app. **Expect** a plain lobby hop, not an
   error card.
4. A brand-new account follow-joins a friend in the tutorial and the forward fails. **Expect** the
   new account to land in onboarding rather than cold in the lobby menu.

Then read the `FollowJoin` telemetry event: `CF03` carries `<Match|Lobby|None>|R<retries>`, so a
`Forwarded` at `R1+` proves the retry ladder did work.

**Both places must publish together.** Bounty alone leaves the tutorial lookup permanently answering
"no"; Redwater alone writes a map nobody reads.

**Note the data cost of step 4** — a dispatched follow-joiner spends a `Tutorial.Attempts` (ceiling 2),
and reverting does not return it.

**Shipped in:** [Hotfix 16](../2026-08-13-hotfix-16.md) — the two friend-join entries under `## Fixed`,
plus the `FollowJoin` telemetry entry under `## Added`.
