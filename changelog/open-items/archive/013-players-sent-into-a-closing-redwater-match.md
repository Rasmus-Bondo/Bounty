# 13 — Players sent into a closing Redwater match

[Open items index](../../OPEN-ITEMS.md) · [Conventions](../../CONVENTIONS.md)

**Closed 2026-08-11** — owner decision: no recurrence in the ~2 weeks since the 2026-08-01 launch. Closed on elapsed time, **not** on a playtest — the status below was still `FIXED (unverified)`.

---

**Status:** FIXED (unverified) · **Sev:** P1 · **Area:** Matchmaking / teleport · **Shipped:** [Hotfix 4](../../2026-08-03-hotfix-4.md)

Full design record in `RESERVED_SERVER_MIGRATION.md`. **Do not "fix" the directory side** — it was verified branch by branch and was never the bug; the second entrance was Roblox's own matchmaker filling a blank destination.

**Still to verify.** Run in this order; the first two are the ones that would otherwise fail silently. Also appended to `MATCH_ROUTING_TEST_CHECKLIST.md`:
1. **Party of 2 presses Play.** Both land in the same fresh server. Watch the log for a group-teleport rejection — if the safety valve fires, stop and fix that before anything else.
2. **App-side friend join.** With a friend in a live match, tap Join from the Roblox app. Should land in Bounty then forward in — *not* fail with "your friend's match has already ended", which would mean the jobId lookup is broken.
3. **Solo backfill.** With a match at 7, a solo Play press joins it (seat 8).
4. **Party denied at 7.** With a match at 6, a party of 2 gets a *fresh* server, not seats 7+8.
5. **Friend pair into a busy match.** With a match at 8, two friends join together (9, 10).
6. **The original bug.** Press Play repeatedly during a post-game showcase. Nobody should ever land in it — no cage, no freeze, no bounce.
7. **Join lock.** A match with under 90s left takes no matchmade players but still takes friend joins.
8. **Fresh-server path under load.** Several solos press Play at once with nothing open — they should not each get their own server.

---
