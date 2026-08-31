# Match routing — manual test checklist

Built 2026-07-25. Nothing below can be verified from Studio alone: MemoryStore needs API access
even to run, and the routing only means anything with two or more live Redwater servers.

## Before anything else

1. **Enable API services.** Game Settings → Security → "Enable Studio Access to API Services".
   Without it every `MatchDirectoryService` write warns and the lobby silently falls back to
   plain Roblox matchmaking (i.e. today's behaviour — the feature is simply off).
2. **Publish both places.** Bounty and Redwater changed; publishing only one leaves the lobby
   reading an empty directory.
3. **Redwater Access settings** (Creator Hub → Redwater Canyon → Access). These are the real
   ceiling and the code is written to match them exactly:

   | Setting | Value | Why |
   |---|---|---|
   | Maximum Visitor Count | **14** | Must equal `MATCH_PLAYER_CAP` + `FRIEND_SLOTS`. Lower and FriendJoinService admits players Roblox rejects with `GameFull`; higher and Roblox's own fallback overfills past our cap |
   | Social Slots | **Customize = 4** | Roblox's native friend reserve. Matching it to `FRIEND_SLOTS` makes the blank-fallback path honour the same split we do. "Roblox optimized" picks an unknown number, which our published `cap` cannot agree with |
   | Direct Access Control | Limited to same Universe | Already set. This is what makes the rules airtight — Redwater is reachable only by teleports from inside the universe, i.e. only through our code |

   Matchmaking therefore fills a match to 10, and friends may take it to 14.

   > Note: Studio's `Players.MaxPlayers` read **60** while the dashboard said 12. The edit-mode
   > DataModel is not a reliable mirror of place settings — trust the Creator Hub.

## Reading the logs

Every Play press emits **one warning** from the Bounty server, so it aggregates on
Creator Hub → your experience → **Errors** across every live server. Four possible messages,
each a fixed string so the page can count them:

| Message | Meaning |
|---|---|
| `[Matchmaking] routed into an open match` | The gate worked — we chose the server |
| `[Matchmaking] no open match - Roblox picks or starts a server` | Fell through to Roblox |
| `[Matchmaking] directory unavailable - falling back to Roblox matchmaking` | MemoryStore unreadable — check API services |
| `[Matchmaking] re-routing a player after a failed teleport` | A destination refused the teleport; retrying elsewhere |

**The ratio of the first two is the number that matters.** Mostly the first: the gate is
holding, matches are reaching the 10-player cap inside their first 3 minutes, leave it alone.
Mostly the second: matches are ageing past 3 minutes while still under 10 players, Roblox is
choosing for you more often than not, and reserved servers stop being optional.

Constant strings are deliberate — that page groups by exact message, so putting a jobId in the
text would produce one row per server and no usable count. The variable detail (jobId, party
size, player name) goes to a `print` alongside each warning, visible via **F9 → Server** while
sitting in that specific lobby.

Redwater-side failures still warn separately: `[MatchDirectoryService] publish failed` means
servers are not advertising, which shows up in Bounty as a steady stream of the second message.

> Caveat: these warnings fire once per Play press, so they will be among the highest-volume
> rows on the Errors page and will dilute the real errors tracked in
> `Errors and warnings by count.csv`. That is the accepted trade for cross-server aggregation
> without building custom analytics events.

## The core behaviour

- [ ] **Soft lock.** Start a match, wait until the round clock passes 3:00 remaining, then
      press Play from a second account in the lobby. It must land in a *different* server —
      confirm the two jobIds differ, not just that the match "felt new".
- [ ] **Before the lock.** Repeat with more than 3:00 left. It must land in the *same* server.
- [ ] **Nothing open.** With no live match (or all of them locked), press Play. Expect a `new`
      line and an ordinary successful teleport into a fresh server.

      > **Settled 2026-07-25:** the forced-new-server hint does not work. Passing a
      > `ServerInstanceId` that matches no server does *not* make Roblox create one, despite
      > the `ShouldReserveServer` docs saying so — it fails the teleport with **"Server is no
      > longer available (Error Code: 771)"**. `chooseDestination` now returns nil for this
      > case and the teleport goes out with a blank `ServerInstanceId`. The consequence: when
      > every live match is locked, Roblox may still route the player into one of them. That
      > is the single case this system cannot force, and closing it needs
      > `ShouldReserveServer = true` — reserved servers, with friend joins teleporting by
      > access code instead of jobId.
- [ ] **Cap.** Fill a match to 10 and press Play. Should route elsewhere or start a new server.
- [ ] **Dying server.** Press Play repeatedly during a match's victory showcase / drain. Nobody
      should be routed into it — this is the old "Connection Failed" case.

## Friend joins

- [ ] **Past the lock.** Friend in a match with under 3:00 left. Join them from the Roblox
      friends list. Must land in *their* server, not a new one.
- [ ] **Past the cap.** Same with their match at 10 players — matchmaking has stopped filling
      it, but a friend join is allowed into the reserved slots, up to 14.
- [ ] **Hard cap.** At 14, the joiner stays in the lobby and sees the failure line rather than
      bouncing off a Roblox `GameFull`.
- [ ] **Dying server.** Join a friend whose match is in the victory showcase. Expected: held in
      the lobby with "that match is wrapping up", *not* a round trip through the dead server.
- [ ] **Party teleport is unaffected.** A party of 2–4 still arrives together in one server.

## The banner (Home tab, above the multiplier panel)

- [ ] Appears only after the intro and only on the Home tab; disappears on Loot / Collection /
      Battle Pass / Trading Post.
- [ ] Shows nothing when no friend is in a match.
- [ ] Row shows avatar, name, and a clock that ticks down between refreshes.
- [ ] JOIN lands you in that friend's match.
- [ ] A refused join shows the reason in the panel for a few seconds.
- [ ] **On a phone** (or the device emulator at a phone resolution): rows stay tappable, and
      the panel does not cover the party panel's INVITE button. Expect 2 rows on a phone, 3 on
      desktop, with the header still reporting the true total ("3 FRIENDS IN A MATCH" above
      2 rows is correct, not a bug).

## If a teleport fails with 771 again

"Server is no longer available" means the `ServerInstanceId` we passed is not a live server.
Two causes remain, both self-healing:

- A Redwater server crashed without withdrawing its directory entry, which lingers until the
  30s TTL. The failed jobId is now blocklisted for 60s on the first failure, so the retry
  picks something else instead of failing identically.
- Testing **both places in Studio**: Studio servers have no JobId and no longer publish at all,
  so the lobby sees an empty directory and falls back to plain matchmaking. Redwater routing
  can only be exercised in a published session.

## Known limits

- The time lock is ours alone and Roblox knows nothing about it. A match with, say, 6 of 10
  slots filled and one minute left still looks fillable, so when nothing is open and we fall
  back to a blank teleport, Roblox can still drop someone into it. This is the one case the
  system cannot force; only reserved servers close it.
- The directory pages at 100 servers per read. Past that the lobby only sees the fullest 100,
  which biases toward packing rather than spreading — fine until the game is far bigger.
- Entries are up to ~8s stale; the lobby age-corrects the clock before applying the 3-minute
  rule, so the effective lock is 3:00 with a couple of seconds of slack, never less.
