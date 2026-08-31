# Reserved servers — manual test checklist

Built 2026-08-03, for the migration in `RESERVED_SERVER_MIGRATION.md`.

**Nothing below can be verified from Studio.** Teleports do not run in playtests, MemoryStore
needs API access even to run, and MCP playtesting is unavailable (`start_playtest` hangs the
plugin connection). This is a live test on published places.

Supersedes `depricated/MATCH_ROUTING_TEST_CHECKLIST.md`, whose Access-settings table (Maximum
Visitor Count 14, Social Slots 4) predates this change and is now wrong.

## Before anything else

1. **Enable API services.** Game Settings → Security → "Enable Studio Access to API Services".
   Without it every `MatchDirectoryService` write warns and no server ever advertises itself.
2. **Publish both places.** Never one alone. A half-published experience leaves one place
   teleporting by jobId and the other keyed on `PrivateServerId` — a total join outage.
3. **Redwater Access settings** (Creator Hub → Redwater Canyon → Access):

   | Setting | Value | Why |
   |---|---|---|
   | Maximum Visitor Count | **10** | Must equal `SOLO_PLAYER_CAP` + `FRIEND_SLOTS` (8 + 2). Lower and FriendJoinService admits players Roblox rejects with `GameFull` |
   | Social Slots | **anything — it is a no-op** | Roblox's matchmaker no longer places anyone in Redwater, so it has nothing to reserve. The friend slots are real because our code counts them. No change needed |
   | Direct Access Control | Limited to same Universe | Already set |

   > Studio's `Players.MaxPlayers` once read **60** while the dashboard said 12. The edit-mode
   > DataModel is not a reliable mirror of place settings — trust the Creator Hub.

## Run in this order

The first two are the ones that would otherwise fail **silently**.

1. **Party of 2 presses Play.** Both players land in the same fresh Redwater server.
   **Watch the Bounty server log for `group teleport rejected - falling back to per-member
   dispatch`.** That is the safety valve, and it firing means the one unverified assumption in
   this migration — that a multi-player `TeleportAsync` accepts `ReservedServerAccessCode` — is
   wrong. Stop and fix that before testing anything else. If it does not fire, the valve can be
   deleted from `PartyService.dispatchTeleport` and `FriendJoinService.joinFriend`.
2. **App-side friend join.** With a friend in a live Redwater match, tap Join from the Roblox
   app. Should land in Bounty and then forward into their match. Failing with *"Your friend's
   match has already ended"* means the jobId → entry lookup is broken, not that the match ended.
3. **Solo backfill.** With a match at 7 players, a solo Play press joins it (seat 8).
4. **Party denied at 7.** With a match at 6 players, a party of 2 gets a *fresh* server, not
   seats 7+8. This is intended, not a bug — see `RESERVED_SERVER_MIGRATION.md` §3.2.
5. **Friend pair into a busy match.** With a match at 8, two friends join together (9, 10).
6. **The original bug (launch issue #13).** Press Play repeatedly while a match is in its
   post-game showcase. Nobody should ever land in it — no cage, no 5-10 second freeze, no
   bounce back to Bounty.
7. **Join lock.** A match with under 90 seconds left takes no matchmade players, but still
   takes friend joins.
8. **Fresh-server path under load.** Several solos press Play at once with nothing open. They
   should not each get their own server — the provisional directory entry plus slot reservation
   should pack them together.

## Reading the logs

Every Play press emits **one warning** from the Bounty server, so it aggregates on
Creator Hub → your experience → **Errors** across every live server. The message text is a
fixed string per outcome on purpose — that page groups by exact message, so interpolating a
server id would shatter the counts.

| Warning | Meaning |
|---|---|
| `routed into an open match` | Joined a live server. The ratio of this to the next line is the health metric |
| `no open match - reserved a fresh server` | Normal at low population |
| `directory unavailable - reserved a fresh server` | MemoryStore read failed. Fine occasionally; a stream of these means the directory is down and every press is fragmenting |
| `could not reserve a Redwater server` | `ReserveServer` itself failed. The player sees "Teleport failed". There is no fallback below this |
| `retrying into the match the rest of the party is in` | A pinned retry. Expected only after the safety valve fired |
| `group teleport rejected - falling back to per-member dispatch` | **The valve.** See test 1 |

Two warnings worth grepping the Redwater logs for:

- `no access code for this reserved server after 5 lookups` — that server is an **orphan**: full
  of players, advertised, and unjoinable for its whole life. Check Bounty is writing
  `RedwaterAccessCodes_v1`.
- `no access code for <id>; skipping it` (Bounty side) — same condition, seen from the lobby.

## What "pass" does not cover

- **Data.** No profile schema change, so a revert to `Bounty r2265 · Redwater r2055` is clean.
- **The fragmentation guard** is deliberately not built. If parties start badly outnumbering
  solos, the knob is letting parties take the solo seat when server count is high — add it from
  telemetry, not from a guess.
