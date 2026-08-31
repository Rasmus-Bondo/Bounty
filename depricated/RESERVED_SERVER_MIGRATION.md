# Reserved Server Migration — Build Spec

**Status:** **BUILT 2026-08-03, unverified live.** Written 2026-08-01 for a fresh session to
implement. Kept as the design record — the rationale in "Decisions" is still the reason the code
looks the way it does. Manual test order: `RESERVED_SERVER_TEST_CHECKLIST.md`.

Two deviations from §4, both deliberate and both documented in the code:
- **A provisional directory entry is published for a just-reserved server.** Not in §4's build
  list, but §7 case 8 requires the behaviour: without it every Play press made while nothing is
  open reserves its *own* server, because the real entry does not exist until Redwater boots and
  a burst of presses falls entirely inside that window. Roblox used to do that packing on the
  blank path; nothing does now unless the lobby says the server exists.
- **`initFailBatches` was kept, not deleted.** §2 assumed one group call means one failure.
  `TeleportAsync` throwing is one failure, but `TeleportInitFailed` fires **once per player**
  regardless — so deleting the regrouping would have restored the per-player re-pick that splits
  parties. What did go is everything §4 actually targeted: `partyDestinations`/`sent`,
  `forceDestination`, `forceBlank`, and the batch's own re-pick-vs-blank ladder.
**Amended:** 2026-08-03 — §3.4 pinning rule (the valve must not re-pick a destination).
**Supersedes:** launch issue #13 (`changelog/OPEN-ITEMS.md`), and closes the friend-slot and join-lock gaps alongside it.
**Rollback point:** Bounty r2265 · Redwater r2055 (Hotfix 2, see `changelog/2026-08-01-hotfix-2.md`).

This document is the design record and the build order. Everything in "Decisions" was
argued through with the owner and should **not** be re-litigated — if a decision looks
wrong, read its rationale first, then raise it.

---

## 1 — The problem

Redwater join gating is enforced at the *sending* end, in Bounty, because a Roblox server
cannot refuse matchmaking (`Players.MaxPlayers` is not scriptable). Bounty picks a jobId
from a MemoryStore directory and passes it as `TeleportOptions.ServerInstanceId`.

When nothing is open, `MatchmakingService.chooseDestination` returns a **blank**
`ServerInstanceId` and Roblox's own matchmaker decides. **That is a second entrance we do
not control, and it has never read our directory.** Every rule we enforce is enforced at
the door we own; Roblox uses the other one.

At launch population (1-2 live Redwater servers) "nothing is open" is the *common* case,
not the edge case, so this happens constantly. Four separate launch complaints are all
this one root cause:

| Symptom | Mechanism |
|---|---|
| Players dropped into a match that shuts down ~10s later | Roblox fills a server in its 30s post-game window |
| The 3-minute join lock "just gets ignored" | Roblox never saw `JOIN_LOCK_SECONDS` |
| Randoms freely eat the 3 reserved friend slots | Roblox fills to the place's 10 seats, has never heard of `MATCH_PLAYER_CAP = 7` |
| `MATCH_PLAYER_CAP` not respected | same |

### The original launch issue #13 note was wrong

It said *"fix is on the directory side (retire the entry when the round enters its end
phase)"*. **The directory side is already correct** — verified branch by branch:

- `MatchDirectoryService.isOpen` returns false for `Ended` (fallthrough, L99-100) and for
  `Fight` with `secondsLeft <= JOIN_LOCK_SECONDS` (L96).
- `MatchmakingService.acceptsMatchmaking` re-derives `remaining = secondsLeft - age`, so
  even an 8s-stale entry is rejected (L123-136).
- `FriendJoinService.evaluateEntry` explicitly refuses `entry.closing or entry.phase == "Ended"` (L107).

No path through our own routing can select a closing match. Do not "fix" the directory.

### Why the symptom is a cage

`RoundController` L822-831 — a player arriving while `roundPhase == "Ended"` is sent to the
jail spawn and frozen, until `closeServer()` (L1496) unfreezes and teleports everyone to
Bounty. `POST_GAME_VICTORY_TIME = 30`, so arriving ~20-25s in gives exactly the reported
5-10 second cage.

Exposure today: with `ROUND_TIME = 360` and `JOIN_LOCK_SECONDS = 180`, a server is
unroutable-by-us but fillable-by-Roblox for **210 of every ~395 seconds — 53% of its life.**

---

## 2 — The fix: reserved servers

`ShouldReserveServer` / `ReservedServerAccessCode` makes Redwater servers unreachable by
Roblox's public matchmaker. Only our code can place anyone. All four symptoms above are
closed by the same change, because they are all "the other door".

### It also deletes code

`ReservedServerAccessCode` supports a **multi-player** `TeleportAsync`. `ServerInstanceId`
is the one that does not — that undocumented limit ("InstanceId is not currently supported
for multiple players") is what forced the per-member fan-out on 2026-07-28. Switching to
access codes lets a party go out as one group call again, retiring:

- `PartyService` per-member dispatch and the `partyDestinations` / `sent` bookkeeping
- the `forceDestination` `"rejoin"` latch and the partial-dispatch split risk
- `initFailBatches` groupId batching (one call → one failure, not N)
- `FriendJoinService` L313's "still one player per call even for a party"

### Confirmed clear

- **No VIP-server branching to break.** Grepped all 286 Redwater scripts for
  `PrivateServerId` / `PrivateServerOwnerId` / `VIPServer` — zero hits.
- **The Roblox app's Join button still works.** Owner tested live on 2026-08-01 with
  friends in a Redwater match. It already routes through Bounty today (Direct Access
  Control is "Limited to same Universe"), so reserved servers do not change it — but see
  trap 3, there is a lookup that must be fixed for it to keep working.

---

## 3 — Decisions

Each of these was argued to a conclusion. The rationale is the load-bearing part.

### 3.1 `ReserveServer()` must be called explicitly

Do **not** just set `ShouldReserveServer = true` and let Roblox create the server. The
created server's access code would then be known to nobody — and a reserved server
**cannot read its own access code** (there is no API; `game.PrivateServerId` is available,
the code is not). That match becomes a permanent one-party island no second player can
ever join.

Bounty must call `TeleportService:ReserveServer(redwaterPlaceId)`, which returns
`(accessCode, privateServerId)`, and register the pair so later joiners can be routed in.
Cost: one extra web call on the fresh-server path.

### 3.2 Ceilings — a semi-reserved seat for solo players

| Joiner | Ceiling | Behaviour |
|---|---|---|
| Matchmade party of 2-4 | **7** | joins an existing match if it fits; fresh server if not |
| Matchmade solo | **8** | seat 8 is theirs alone |
| Friend join | **10** | unchanged; ignores the matchmaking caps entirely |

**Rationale (owner's, and it is the point of the design).** Parties are *seeds*: a party
turned away creates a partially-full match, which is exactly what a solo player needs to
land in. A party denied entry still has a fine game — 2-4 real humans plus bots. A solo
denied entry gets 1 human and 4 bots, the worst experience the game produces, and also the
one that scores ~0 RP against a bot-padded field (the small totals and 1-RP entries are the
*intended* placement bonus — see *Resolved* in `changelog/OPEN-ITEMS.md`). So the
reserved seat goes to the joiner who has nothing without it. Parties still do the packing
that creates good lobbies; they just cannot consume the solo's seat.

**A superseded example.** An earlier framing was *"let a group of 4 join a 4-player server,
exceeding the limit by 1"* — that is 8, above the party ceiling, so it is now **denied** and
that party seeds a new match. The solo seat and that example cannot both sit at 8. The
owner chose the solo seat. If this is ever revisited, the alternative is party 8 / solo 9 /
friends 10, which honours both but leaves only one friend seat and kills friend-*pair* joins.

**Why 8 and not 9 for solos:** at 8, a friend pair still fits (8 + 2 = 10). At 9 only a lone
friend fits. 8 is the last value that keeps pair joins working.

### 3.3 `JOIN_LOCK_SECONDS` 180 → 90

Today the 180s lock is aspirational and Roblox overrides it. Make it real and it bites
hard: 180 of a 360s round means over half of every server's life is genuinely closed, so a
large share of Play presses would spawn a fresh solo server. 90 roughly doubles the
joinable window (~47% → ~70% of the cycle) while still keeping a joined match meaningfully
long. Retuned in the same release *because* enforcement is what changes, not the number.

### 3.4 Party single-call teleport lands in the same pass

The fan-out exists solely because of the `ServerInstanceId` limit being removed. Keeping it
alongside access codes means maintaining dead complexity and a partial-dispatch failure
mode that can no longer occur.

**Keep one safety valve:** if the group `TeleportAsync` is rejected by the engine, log it
loudly (not swallowed) and fall back to per-member dispatch. ~10 lines, marked for deletion
once verified live. This is insurance against the assumption in §6 being wrong; it must not
fail silently the way 2026-07-28 did.

**The valve must pin the access code it already holds and never re-pick.** This is the one
way a split party survives into the new system, and it is created by this section and §4
landing together: the valve's fan-out can be partial, `forceDestination` is being deleted,
so a straggler's retry would re-run `chooseDestination` and could be handed a *different*
open match. That is verbatim the bug the latch was written for — `PartyService` L1017,
*"Blocklisting it here is exactly how the stragglers would get re-routed somewhere else and
the party split, so keep aiming them at the same jobId instead. Slower, but together."*
Inside the valve every retry targets the same `accessCode`, and `reportBadServer` is not
called. The deliberate trade is unchanged from today: a straggler who cannot reach their
party's match exhausts its retries and sees "Teleport failed. Please try again." rather
than being silently placed somewhere else.

This keeps the valve small rather than growing it — with a pinned destination there is no
re-pick branch, no blocklist call, and no blank fallback left to reach (trap 5). It is one
constant and a counter.

### 3.5 No shared matchmaking module is needed

An earlier plan (for a different fix) proposed extracting an 18th mirrored module so
Redwater could pick a destination too. **Reserved servers remove the need entirely** —
Redwater never chooses a destination. Its `Ended`-arrival backstop just sends the player to
Bounty. Do not build `MatchDirectoryStore`.

---

## 4 — What to build

Live source is in Roblox Studio via MCP; the paths below are Studio paths. Line numbers are
as of 2026-08-01 and will drift — grep, don't trust them.

### Redwater Canyon (`place:98517073248449`)

**`ServerScriptService.RoundSystem.Config`**
```lua
JOIN_LOCK_SECONDS = 90,   -- was 180
MATCH_PLAYER_CAP  = 7,    -- matchmade PARTY ceiling (value unchanged, meaning narrowed)
SOLO_PLAYER_CAP   = 8,    -- NEW: matchmade SOLO ceiling; seat 8 is the semi-reserved one
FRIEND_SLOTS      = 2,    -- was 3; seats 9-10
-- SOLO_PLAYER_CAP + FRIEND_SLOTS = 10 = Maximum Visitor Count (Creator Hub)
```
Update the L17-34 comment block — it currently explains a 7+3 split that no longer
describes the system.

**`ServerScriptService.RoundSystem.MatchDirectoryService`**
- Key entries on `game.PrivateServerId` instead of `game.JobId`.
- Studio guard moves from `JobId == ""` to `PrivateServerId == ""` (L45-46).
- Publish **three identifiers** (see trap 3): `privateServerId`, `accessCode`, `jobId`.
- `accessCode` is read from the first arriving player's `TeleportData`, and redundantly
  from Bounty's reserve map.
- Publish `soloCap` alongside `cap`, so Bounty stays free of hardcoded numbers.
- `isOpen` uses the **most permissive** matchmaking ceiling (`SOLO_PLAYER_CAP`), so an entry
  never reads closed to a solo. Bounty narrows per party size.

**`ServerScriptService.RoundSystem.RoundController`**
- Replace the cage at L822-831 and the `serverClosing` bounce at L845-863 with a single
  `forwardLateJoiner(player)` that sends them to Bounty. Should be unreachable once Roblox
  cannot place people — this is a backstop, not the fix.
- **Gate it on an arrival flag set in `setupPlayer`, never on `roundPhase`** (trap 4).

### Bounty (`place:131701626847012`)

**`ServerScriptService.Party.MatchmakingService`**
- `chooseDestination(partySize)` returns `(accessCode, privateServerId, kind)`.
- Party ceiling vs solo ceiling: `local ceiling = (partySize == 1) and (entry.soloCap or entry.cap) or entry.cap`.
- Fresh path calls `ReserveServer`, then registers `privateServerId → accessCode` in a new
  MemoryStore hash map (`RedwaterAccessCodes_v1`, same `_studio` suffix rule).
- New `getServerByJobId(jobId)` — linear scan of `listServers()` matching the `jobId` field
  (trap 3).
- Directory unreadable → **reserve a fresh server**, not a blank teleport (trap 5).
- Delete `newServerDestination`'s "blank fallback" comment block (L185-201); it documents a
  behaviour that no longer exists.

**`ServerScriptService.Party.PartyService`**
- `dispatchTeleport` sets `ReservedServerAccessCode`; one group call for the whole party.
- Delete `partyDestinations`, `forceDestination`, `initFailBatches` and the `sent` /
  `#players >= sent` partial-dispatch logic. **Read §3.4 before deleting `forceDestination`**
  — the safety valve still needs the guarantee that latch provided (pin the destination,
  never re-pick), just not its cross-attempt bookkeeping.
- Keep the §3.4 safety valve, pinning rule included.

**`ServerScriptService.Lobby.FriendJoinService`**
- `options.ServerInstanceId = entry.jobId` (L303) → `ReservedServerAccessCode = entry.accessCode`.
- Party friend joins become one group call; drop the L313 fan-out comment.
- **Fallback defaults at L113-114 must move** (trap 6).
- `evaluateEntry` is otherwise unchanged — friend joins still ignore the lock and cap and
  gate only on `closing` / `Ended` / `hardCap`.

**`ServerScriptService.Lobby.FollowJoinService`**
- `options.ServerInstanceId = entry.jobId` (L114) → access code, resolved via
  `getServerByJobId` (trap 3).

---

## 5 — Traps

Each of these cost real time to find. They are the reason this document exists.

1. **A reserved server cannot read its own access code.** See §3.1. The code must
   round-trip: Bounty reserves → registers `privateServerId → accessCode` → Redwater
   publishes its entry keyed on `game.PrivateServerId` → Bounty joins the two on read.
   Carry it in `TeleportData` as well; if that mapping is ever missing, the server is an
   orphan — full of players, invisible to matchmaking, unfillable for its whole life.

2. **`ShouldReserveServer` alone creates orphans.** See §3.1. Always `ReserveServer()`.

3. **`GetPlayerPlaceInstanceAsync` returns a jobId, not a privateServerId.**
   `FollowJoinService` L74-85 resolves the friend's server that way, then calls
   `evaluateTarget` → `MatchmakingService.getServer(jobId)`. If the directory is keyed on
   `privateServerId` and does not also *carry* `jobId`, that lookup returns nil and every
   app-initiated friend join fails with the lie *"Your friend's match has already ended."*
   Publish all three identifiers and add `getServerByJobId`.

4. **Do not forward legitimate players during `Ended`.** `hookCharacter` L822 fires on
   *every* character load, and `SpawnService.ensureAllPlayersAlive()` (L1474) deliberately
   reloads characters for the players who just finished the round. Forwarding on the phase
   alone ejects the winners mid-showcase. The discriminator must be a flag set in
   `setupPlayer` meaning "this player *arrived* during the end phase".

5. **There is no blank-teleport fallback anymore.** Today a MemoryStore failure degrades to
   Roblox matchmaking. Under reserved servers that path does not exist, so an unreadable
   directory must degrade to "reserve a fresh server" — otherwise nobody can join anything.
   Fragmenting is acceptable; failing closed is not.

6. **`FriendJoinService` L113-114 fallbacks are right by coincidence.** `hardCap = cap + 3`
   still lands on 10 (7 + 3) even though `FRIEND_SLOTS` becomes 2, because the solo seat
   fills the gap. Right number, wrong reasoning, and a comment saying "+3 friend slots"
   next to a constant that says 2. Make it explicit.

7. **Do not re-derive these dead ends** (all previously tried and reverted):
   - A fake `ServerInstanceId` matching no server does **not** make Roblox create one. It
     fails with *"Server is no longer available (771)"*. Reverted 2026-07-25.
   - `CAPACITY_MARGIN` for a supposed starved last seat. Wrong diagnosis, reverted.
   - Studio lies about place settings. `Players.MaxPlayers` read 60 while the dashboard said
     12. Maximum Visitor Count comes from Creator Hub → Redwater Canyon → Access, nowhere else.

8. **Social Slots becomes a no-op.** It is Roblox's native friend reserve and Roblox is no
   longer matchmaking into Redwater. The 3 friend slots become real because *our*
   `FriendJoinService` enforces `hardCap`. No Creator Hub change is needed — leave Maximum
   Visitor Count at 10.

---

## 6 — The one unverified assumption

**A multi-player `TeleportAsync` accepts `ReservedServerAccessCode`.** ~95% confident: it is
the standard "send my party to a private server" pattern, and every documented
incompatibility is *with* `ServerInstanceId`, which is being removed.

It cannot be tested from Studio — teleports do not run in playtests, MemoryStore needs API
access, and MCP playtesting is unavailable (`start_playtest` hangs the plugin connection).
**The first live party-of-2 Play press is the test.**

This API surface has already lied once (the undocumented `ServerInstanceId` multi-player
limit, which broke every party join for days *silently*). Hence the §3.4 safety valve, and
hence the test order below.

---

## 7 — Verification

Nothing here is verifiable from Studio. Append to `MATCH_ROUTING_TEST_CHECKLIST.md` and run
in this order — the first two are the ones that would otherwise fail silently.

1. **Party of 2 presses Play.** Both players land in the same fresh Redwater server. Watch
   the server log for a group-teleport rejection; if the safety valve fires, stop and fix
   before anything else.
2. **App-side friend join.** With a friend in a live Redwater match, tap Join from the
   Roblox app. Should land in Bounty then forward into their match — *not* fail with "your
   friend's match has already ended" (that message means trap 3).
3. **Solo backfill.** With a match at 7 players, a solo Play press joins it (seat 8).
4. **Party denied at 7.** With a match at 6 players, a party of 2 gets a *fresh* server,
   not seat 7+8.
5. **Friend pair into a busy match.** With a match at 8, two friends join together (9, 10).
6. **The original bug.** Press Play repeatedly while a match is in its post-game showcase.
   Nobody should ever land in it — no cage, no 5-10s freeze, no bounce to Bounty.
7. **Join lock.** A match with under 90s left takes no matchmade players, but still takes
   friend joins.
8. **Fresh-server path under load.** Several solos press Play at once with nothing open;
   they should not each get their own server (slot reservation).

---

## 8 — Bookkeeping

Non-negotiable, per `CLAUDE.md`:

- **Both places publish together.** Never one alone — the mirrored modules make a
  half-published experience a live drift bug.
- **Vault `.md` for every touched script**, then `python update_bounty_graph.py` and
  `python update_redwater_canyon_graph.py` (bare commands, one per tool call, issued
  together so they run in parallel). Verify new edges with a `Grep` on `graph.json` for
  `"_src": "<lowercased script name>"` — every `_tgt` must be a real `require()` /
  RemoteEvent / BindableEvent.
- **`changelog/UNRELEASED.md`** — append with an `Edit` anchored on a section heading, never a
  whole file `Write`. Re-read immediately before editing; other agents may have written since.
  (The changelog became a folder on 2026-08-03; the root `CHANGELOG.md` is an index only.)
- **Launch issue #13** in `changelog/OPEN-ITEMS.md` → `FIXED (unverified)`, and correct the "fix is
  on the directory side" note. Mention that this also closes the friend-slot and join-lock gaps.
- **`/preflight` before publishing**, not after. It hard-gates on mirror drift.
- **Record the place versions** in the release's `Published` field immediately after
  publishing, or it cannot be rolled back to.
- No profile schema change here, so a revert to Bounty r2265 · Redwater r2055 is clean.

Memory worth writing after the build: the `project_match_routing` memory describes the
*current* jobId/`ServerInstanceId` system and will be substantially wrong once this ships.
Update it rather than adding a second one.

---

## 9 — Known, deliberately not built

- **Fragmentation guard.** With parties packing into existing matches up to 7 this is not a
  launch-population concern. If parties ever outnumber solos badly, the knob is to let
  parties take the solo seat when server count is high. Add it from telemetry, not from
  a guess.
- **Bot count.** Unchanged; the fill is floored at 4, so 8 humans still gets 4 bots.
- **The `Ended` backstop does not requeue.** It returns the player to Bounty and they press
  Play again. A requeue flag risks a bounce loop for a path that should be unreachable.
