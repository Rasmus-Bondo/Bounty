# Server Consolidation Spec

**Status: BUILT 2026-08-27, unverified live.** Written 2026-08-27. Kept as the design record —
the rationale in §0 is still the reason the code looks the way it does. Verification is §9, and
none of it is reachable from Studio: `/preflight`, then a DEV soak.

Two deviations from the spec as written, both deliberate:
- **§7 is wrong about the mirror tier and was not followed.** It says `MatchDirectoryService` is
  on the 20-module universe-wide list. It is not, and Bounty has no `RoundSystem` at all — so
  `MatchDirectoryService`, `RoundController`, `Config` and `MapVoteClient` are all mirrored
  Redwater ↔ Frostbite only. The single Bounty edit is the §5 cross-reference comment.
- **The empty-server exit is gated on `everHadPlayers`, not on a bare `#Players == 0`.** §1's
  literal wording ("An empty server with no retirement flag still has nothing to loop for")
  introduces a boot race: the round loop can reach its first `MIN_PLAYERS` wait before the party
  that caused the server to exist has finished joining, and `closeServer` there would bounce them
  off a server that had not started yet. Today's `matchmakingRetired and empty` test could not hit
  it because the flag is false at boot. A latch set once in `setupPlayer` restores that safety.

Replaces the end-of-match map ballot with a routing decision, and deletes server retirement.
The goal is fewer, fuller servers: small servers dissolve into big ones on their own, and no
rule anywhere makes a healthy server unjoinable.

Read `RESERVED_SERVER_MIGRATION.md` first if you have not - it is the design record for the
reserved-server routing this spec extends, and every constraint in it still holds.

---

## 0. The decisions behind this, so they are not re-litigated

**Map is a routing consequence, not a player choice.** Players vote gamemode only. The map is
whatever the server they get packed into happens to be running. With two maps a map vote is a
coin flip, not agency; spending it on consolidation buys a real thing. Hand the map vote back
when there are five or six maps and the population to fill them.

**All three gamemodes are always offered.** No population gating on the ballot. A menu that
shrinks reads as a broken game to a player, and the population signal belongs in routing, not
in the UI. Do NOT add live player counts to the tiles - players will not know what the number
means.

**A player landing in a match with ten seconds left is accepted.** That is under 3% of a 360s
round, and every fix for it (preferring Summary-phase servers, carrying ballots in TeleportData)
costs more complexity than the case is worth. Packing wins.

**Retirement is redundant once servers rotate maps.** `SERVER_RETIRE_AFTER_ROUNDS` exists for
code freshness - publishing does not update running servers. A map rotation is a fresh boot on
the sibling place, so it does retirement's job for free, and retirement is the one rule left in
the system that deliberately makes a full server unjoinable.

**Size does NOT decide who merges into whom - phase does.** The outcome is identical whichever
side travels (2 joining 5 and 5 joining 2 both produce a server of 7), and under rotate-every-round
the server that just ended its round is teleporting regardless. So refusing to let a bigger roster
join a smaller one saves nobody a loading screen; it just sends more people to an emptier room.
An earlier draft of this spec gated merges on the destination being fuller than us. That was
wrong, and the case that shows it is a 4-player server ending its round beside a 3-player one: it
fits, both outcomes cost the same four loading screens, and the size rule sent them somewhere
worse.

**What a direction rule IS still needed for is the simultaneous-move race**, where two servers
each merge into the other and both land in a room the other has just abandoned. That race only
exists between two servers that are both at their decision point, and that is a phase you can
read off the entry:

- Candidate in `Fight` / `Waiting` / `Countdown` / `Starting` - it is not deciding anything.
  Merge on capacity alone, in either size direction.
- Candidate also in `Summary` - it may be moving too, so the tie is broken on `privateServerId`
  and exactly one side travels.

Do not "fix" this by excluding `Summary` candidates outright. Two servers whose round timers are
in sync hit `Summary` together every round, so an exclusion would leave that pair missing each
other forever; the tie-break resolves them on the first attempt.

---

## 1. Remove server retirement

`ServerScriptService.RoundSystem.Config`
- Delete `SERVER_RETIRE_AFTER_ROUNDS = 5` (line 249) and its comment block.
- KEEP `SERVER_MAX_LIFETIME = 3600` (line 250). It is the backstop for a server that somehow
  never rotates, and it is load-bearing for a second reason: `RedwaterAccessCodes_v1` entries
  carry a 3600s TTL, so a server older than that loses the key the lobby resolves it through.
  The two numbers matching is not a coincidence - do not raise one without the other.

`ServerScriptService.RoundSystem.RoundController`
- Delete the `matchmakingRetired` local (line 107) and its header comment (line 102).
- Delete the retirement block at lines 2855-2862.
- Line 2865 `if matchmakingRetired and #Players:GetPlayers() == 0 then closeServer()` becomes
  `if #Players:GetPlayers() == 0 then closeServer()`. An empty server with no retirement flag
  still has nothing to loop for.
- Line 2461 `if (matchmakingRetired and #Players:GetPlayers() == 0) or os.clock() - serverStartClock >= Config.SERVER_MAX_LIFETIME`
  loses its first clause the same way.

`ServerScriptService.RoundSystem.MatchDirectoryService`
- Delete `setMatchmakingClosed()` (line 782) and the `matchmakingClosed` flag it sets, plus its
  term in `isOpen` (line 192). Nothing else calls it.
- Its docstring at line 773 goes with it.

Nothing in Bounty changes. `acceptsMatchmaking` reads `entry.open`, which simply stops being
forced false.

---

## 2. Remove the map ballot

`RoundController.runBallotsDuringSummary()` (line 956).

- Delete the map ballot block, lines 975-998. `nextMapId` stops existing as a vote outcome.
- The mode ballot's option list currently intersects `MapCatalog.get(nextMapId).gamemodes` with
  the local `MapConfig.Gamemodes`. With no map vote there is no remote destination to validate
  against at ballot time, so the list is just the local `MapConfig.Gamemodes` filtered through
  `GamemodeConfig.get`. Both live maps declare all three modes today, so this yields three tiles.
- Keep the `#modeOptions >= 2` guard. It is a safety for a future map that runs one mode, not a
  population gate.
- The function returns `nextModeId` only. Its callers change per section 3.
- Ties and no-mandate still resolve to `incumbentMode` via the existing `resolveBallot`. With
  three tiles always up, ties get common and staying is the right default.

`StarterPlayer.StarterPlayerScripts.MapVoteClient` needs almost nothing. It is already
`kind`-driven and already renders mode tiles with a solid plate instead of a thumbnail frame -
it simply never receives `kind = "map"` again. Check only that the grid maths at item 4 of its
vault doc still lands on three tiles, and update the header copy if it names maps.

**Do not delete `MapVoteGui` or rename the `MapVote` remote.** The panel and the remote now
serve the mode ballot alone. Renaming is a three-place cutover for zero behaviour change.

---

## 3. The end-of-round destination decision

This replaces `if nextMapId ~= MapConfig.Id then moveToMap(...)` at RoundController lines
2827-2837. One decision point, three outcomes, evaluated in this order.

### 3.1 Merge

Read the match directory and look for a server to dissolve into. A candidate qualifies when ALL
hold, where `roster` is `#Players:GetPlayers()` at the decision point:

```
entry.privateServerId ~= game.PrivateServerId       -- not ourselves
entry.mode == nextModeId                            -- the mode that just won
isRoutableMap(entry.map)                            -- MapCatalog live + placeIdFor resolves
isRegionMatch(entry, ourRegion)                     -- absent on either side routes freely
entry.age <= 25                                     -- ENTRY_MAX_AGE; older is a dead server
not entry.closing and entry.open
free >= roster    where free = ceilingFor(entry, roster) - entry.players - pending

-- Direction, and ONLY when the candidate may be deciding at the same moment we are.
-- Any other phase imposes no size constraint whatsoever: capacity alone decides, and a
-- bigger roster joining a smaller server is allowed and correct. Section 0.
entry.phase ~= "Summary"
  or game.PrivateServerId < entry.privateServerId
```

`ourRegion` is `MatchDirectoryService.getRegion()`. The match server already knows its own
bucket, so no RegionService dependency crosses into the match place.

`ceilingFor` is the existing rule: `soloCap` (8) when `roster == 1`, `cap` (7) otherwise. Do not
invent a new ceiling here - the numbers ride on the entry so they cannot drift from Config.

Sort surviving candidates by `players` descending. Probe at most 5 (`PENDING_PROBE_LIMIT`)
for pending claims, take the first that still fits, resolve its access code, claim `roster`
slots, and teleport. If none survives the probe, fall through to 3.2.

**Capacity is the whole consolidation mechanism and it needs no threshold.** A roster of 2 merges
into a 5 and makes a 7; a roster of 4 merges into a 3 and makes a 7; a roster of 6 needs 6 free
seats against a cap of 7 and so can only land on a server holding 1, which makes a 7 as well and
rescues a lone seeder. Every merge that fits is a merge worth making, because the alternative is
never "stay put" - it is rotating to an empty server.

The `players` descending sort is what makes this behave: the fullest candidate that fits is
always tried first, so a downward merge only happens when nothing fuller had room.

**The roster travels whole.** Do not partition it and route groups independently to squeeze out
more packing. Keeping the people you just played with together is the point, and a partition
scatters parties across destinations.

### 3.2 Rotate

Nothing to merge into. Rotate to a different map. **There is no round-count gate** - a rotation
happens at EVERY round end that did not merge, so no server ever plays the same map twice in a
row. Playing one map for several rounds is the boring outcome this replaces, and a fresh server
on the other map is worth exactly as much as staying put, so there is nothing to trade away.

The only condition is that at least two live maps in `MapCatalog` run `nextModeId`. One live map
means there is nowhere to rotate to, which falls through to 3.3.

Pick the destination map by weight: each eligible map weighted by the live player count for
`nextModeId` on that map, taken from the directory read 3.1 already did, **excluding the map we
are on**. All weights zero falls back to uniform. With two maps this is just "the other one" and
the rotation strictly alternates; the weighting is there so a third map does not fragment the
mode it was added to.

Then reserve, wire up, and teleport - see section 4 for the ordering change.

**Three consequences of rotating every round, all of them wanted:**

- It fully replaces retirement. Code is never more than one round old, so a server can no longer
  outlive a publish and there is nothing left for `SERVER_RETIRE_AFTER_ROUNDS` to do.
- Every round boundary becomes a repack point. The whole population turns over every round
  instead of freezing into whatever servers people first landed in, so thin servers dissolve
  continuously rather than only when someone happens to vote a change.
- The freshly reserved server is advertised the moment it is reserved (section 4), so it is a
  merge target for the next small server that ends its round, not a private room.

**The one cost to watch in the soak.** Every round now ends in a teleport, so any per-teleport
failure rate compounds per round rather than per map vote. The existing machinery covers it -
the group-call safety valve falling back to per-member fan-out, `TeleportInitFailed` regrouping
via `initFailBatches`, the 12s drain, then kicks - but the exposure is genuinely higher than it
was, and a rise in "Teleport failed. Please try again." is the signal to look at.

### 3.3 Stay

The exception path, not a normal outcome. Reached only when there is nothing to merge into AND
nowhere to rotate to (one live map for this mode), or when the reservation in 3.2 fails. Play
another round on this map.

Note that a mode change never forces a move: both live maps run all three modes and
`switchGamemode` already changes mode in place. The ONLY reason this server ever teleports is
consolidation or rotation.

---

## 4. Move-path changes

`RoundController.moveToMap` (line 1823) is reshaped to serve both 3.1 and 3.2. Signature becomes
`moveToMap(destination)` where `destination` carries `{ accessCode, privateServerId, placeId,
mapId, modeId, isFresh }`.

**Reverse the withdraw ordering on the fresh path.** Today `setClosing()` runs at line 1848
BEFORE `ReserveServer` at 1851, which is why a failed reserve has to degrade into `closeServer` -
the entry is already gone and playing on would leave a healthy server invisible for life. With
the reserve moved ahead of the withdrawal, a failed reserve is simply a stay, and that branch
disappears. This deliberately contradicts the existing comment at lines 1843-1847: it trades a
permanent-orphan risk for a join race of roughly one web call, and a joiner landing in that race
gets drained to the lobby exactly as one racing a shutdown does today. Update the comment; do not
leave the old reasoning sitting above the new order.

On the merge path there is no reserve at all, so `setClosing()` is the first thing that runs, as
it does today.

**Publish a provisional entry for a freshly reserved destination.** Today `setClosing()` withdraws
us and then everyone is in flight for ~10s with nothing published for that match, so a lobby Play
press in that window finds nothing open and reserves its own server. This fires on every rotation.
Write the same shape Bounty's `publishProvisionalEntry` writes (MatchmakingService line 476):
`provisional = true`, sortKey 0, `PROVISIONAL_TTL` 30s, with `map`, `mode`, `region` and
`accessCode` all stated.

**One field differs from Bounty's version and it matters: publish `players = roster`, not 0.**
Bounty writes 0 because a Play-press reservation genuinely has nobody in it yet, and it reserves
the seats through `claimSlots` instead. A rotation knows exactly who is arriving, and stating it
is what makes the new server a usable merge target the moment it exists rather than 20 seconds
later - a 4-player server rotating advertises 4, and a 2-player server ending its round right
after can merge straight into it and make 6. Publishing 0 would fail the direction test in 3.1
against every possible roster and waste the window entirely.

Because `players` already counts our travellers, do **not** also claim slots for them - the
lobby adds `players` and pending together, so doing both double-books the seats. Claim slots only
on the merge path of 3.1, where the destination's own `players` count does not include us.

If the teleport then fails and nobody arrives, the entry advertises phantom players for up to
the 30s TTL. That fails in the safe direction - other servers read it as full and decline to
merge - and it expires on its own.

`registerAccessCode` and `registerRegion` stay exactly as they are on the fresh path, and are
skipped on the merge path - the destination already has both.

Everything else in `moveToMap` is untouched: the group/solo teleport split, the
`characterSelections` rewrite from each traveller's LIVE hunter, the 12s drain, the kicks.

---

## 5. New surface in MatchDirectoryService

The merge decision needs a directory READ, which this module has never had - it is a writer. Add,
all inside the existing pcall-and-count discipline:

| Function | What it does |
|---|---|
| `readDirectory()` | `GetRangeAsync` over `RedwaterMatchDirectory_v1`, `RANGE_COUNT` 100, normalising `map` absent to `"redwater"` and stamping `age` from `updatedAt`, exactly as Bounty's `readServers` does. Returns nil on failure. |
| `chooseMergeTarget(roster, modeId)` | The 3.1 filter, sort and probe. Returns a destination table or nil. |
| `resolveAccessCodeFor(entry)` | Entry's own `accessCode` field first, then a `RedwaterAccessCodes_v1` lookup on its `privateServerId`, accepting both the bare-string and `{ code, tutorial }` shapes. |
| `claimSlots(privateServerId, count)` | `UpdateAsync` on `RedwaterPendingJoins_v1`, `PENDING_TTL` 25. |
| `publishProvisionalFor(privateServerId, accessCode, mapId, modeId, region, roster)` | Section 4. |
| `livePlayersByMap(modeId)` | Feeds the 3.2 weighting off the read 3.1 already did. |

`RedwaterPendingJoins_v1` is new to the match place; the other three map names already exist here.
The `_studio` suffix rule applies to all of them - Studio talks to the production MemoryStore.

**This duplicates predicates that also live in Bounty's MatchmakingService** (`isFresh`,
`isRegionMatch`, `acceptsMatchmaking`, `ceilingFor`, and the pending/access-code readers). That is
deliberate and it follows the precedent `registerAccessCode` already set - Bounty's job done from
inside a match, because there is no cross-place RPC. Comment BOTH copies pointing at each other,
the way `registerAccessCode` does. The ceilings themselves cannot drift because they ride on the
published entry rather than being read from a local Config.

Do not extract a shared `MatchRouting` module for this. It is the right shape if a third caller
ever appears, but it means refactoring the most safety-critical module in the project - four
launch complaints came out of this code path - to ship a behaviour change that does not need it.

`MatchDirectoryService` is one of the mirrored modules, so every line of this lands byte-identical
in all three places. See section 7.

---

## 6. Config changes

`ServerScriptService.RoundSystem.Config`:

```
SERVER_RETIRE_AFTER_ROUNDS   deleted
MAP_VOTE_TIME                deleted
MAP_VOTE_RESULT_TIME         deleted
MODE_VOTE_TIME = 7           was 6
SUMMARY_COUNTDOWN_TIME = 7   was 13
POST_GAME_VICTORY_TIME = 4.1 + 2.4 + 7 + 0.5 = 14.0   was 20.0
```

**The invariant at Config lines 208-209 changes and must be rewritten, not just retuned.** It
reads `MAP_VOTE_TIME + MAP_VOTE_RESULT_TIME + MODE_VOTE_TIME must EQUAL SUMMARY_COUNTDOWN_TIME`.
With one ballot it becomes `MODE_VOTE_TIME must EQUAL SUMMARY_COUNTDOWN_TIME`. `MODE_VOTE_RESULT_TIME`
stays the 0.5 tail of `POST_GAME_VICTORY_TIME` and is not a term of the countdown.

Dropping the summary from 20s to 14s is a straight win - six fewer seconds between rounds on every
loop, and the removed beat was a coin-flip ballot.

---

## 7. Mirror and drift obligations

`MatchDirectoryService` and `MapCatalog` are on the 20-module mirrored list. Every change in
sections 1 and 5 lands in **Bounty, Redwater Canyon and Frostbite Claim**, byte-identical.
`RoundController`, `Config` and `MapVoteClient` are gamemode code and are mirrored between
Redwater and Frostbite by `/mirror` - not into Bounty, which does not have them.

`MapConfig` is per-place and must NEVER be mirrored.

Run `/mirror` after the edits and `/preflight` before publishing. The byte-length plus checksum
compare is a hard gate. Drift here fails silently: a Frostbite `MatchDirectoryService` without
`chooseMergeTarget` does not error, it just never merges, and nothing on screen says so.

Never publish one place alone.

---

## 8. What this does NOT fix

Fragmentation ACROSS the three modes. Destinations are still mode x region, and at low population
a mode with four players in your region seeds a bot-padded match. This spec consolidates within a
mode; the two levers for the other half are unchanged and unshipped:

- **QuickPlay as the Play button default in Bounty.** It already exists
  (`MatchmakingService.QUICKPLAY_ID`) and already exempts the mode filter. Making a specific mode
  the deliberate act rather than the default collapses the mode axis on the lobby path.
- **Region folding when a bucket is thin.** The region filter deliberately splits the pool and has
  no cross-region fallback (open item #92). Folding SA into NA and OC into AS below a population
  threshold is the biggest single packing lever left, at a ping cost.

Both are separate decisions. Do not fold either into this build.

---

## 9. Verification

Nothing here is verifiable from Studio: MemoryStore needs API access, teleports do not run in
playtests, and routing needs two or more live servers. `/preflight`, then a DEV soak.

Manual checklist, on DEV with at least two servers:

1. Retirement gone - a server plays six or more rounds and stays matchmakable the whole time.
2. Three mode tiles every summary, on both maps.
3. Ballot window is 7s and the summary is 14s end to end; the NEXT MATCH IN counter reaches zero
   exactly as the curtain falls.
4. A four-player server ending its round beside a three-player server mid-`Fight` merges INTO it,
   for one seven-player server. The bigger roster moving is correct - verify it is not refused.
5. Two servers whose rounds end together merge on the `privateServerId` tie-break: exactly one
   moves, and neither arrives at a room the other has just abandoned. Run this twice with the
   round timers deliberately in sync - the pair must resolve on the first attempt, not stalemate.
6. No server plays the same map twice in a row. A server that finds no merge rotates at EVERY
   round end, alternating maps.
7. A rotating server's provisional entry states its real headcount and is usable as a merge
   target - a small server ending its round during the teleport window merges into it.
8. A failed `ReserveServer` on rotation leaves everyone playing, NOT teleported to the lobby.
9. A party of two survives both a merge and a rotation intact, with its mid-match hunter swap
   still applied at the destination.
10. Friend join into a merged destination resolves the access code.

`RESERVED_SERVER_TEST_CHECKLIST.md` still covers the routing invariants underneath all of this
and should be re-run, since section 4 reorders the withdrawal.

---

## 10. Rollback

Code-only - nothing here touches the profile shape, Wallet reasons, the XP curve or any grant, so
reverting the three places to the prior version is a clean undo. Record the place versions in the
release entry before publishing or there is nothing to roll back to.

The one irreversible piece is operational, not stored: servers already running keep the old code
until they empty, so during a rollout there will be a window where retiring servers and
non-retiring servers coexist in the same directory. That is survivable - a retired entry publishes
`open = false` and is simply skipped as a merge candidate.
